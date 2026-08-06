import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../domain/local_txt/large_file_policy.dart';
import '../../domain/local_txt/pipeline_progress.dart';
import '../../domain/local_txt/text_encoding.dart';
import '../../domain/local_txt/toc_entry.dart';
import '../../domain/local_txt/txt_index.dart';
import 'gb18030_decoder.dart';
import 'gb18030_index_data.dart';
import 'txt_cancellation.dart';
import 'txt_content_identity.dart';
import 'txt_encoding_detector.dart';
import 'txt_import_request.dart';
import 'txt_import_result.dart';
import 'txt_index_cache.dart';
import 'txt_normalizer.dart';
import 'txt_toc_scanner.dart';

/// 本地 TXT 导入服务 —— 标准化与索引管线编排。
///
/// 流程：
/// 文件校验 → 大文件策略 → 内容身份 → 编码检测 → 缓存检查
/// → GB18030 解码 → 后台 Isolate 规范化+卷章扫描+去重 → 原子缓存写入。
///
/// 性能合同：
/// - 扫描/规范化在后台 Isolate 执行（不在 UI Isolate 上跑数秒任务）；
/// - 单次顺序扫描 O(n) 累计 UTF-16 offset；
/// - 打开前完成扫描与索引缓存；正文不入缓存。
class TxtImportService {
  TxtImportService({
    required this.encodingTableLoader,
    this.parserVersion = '1.0.0',
    this.normalizationVersion = '1.0.0',
    this.indexFormatVersion = 1,
    this.onNormalizedText,
  });

  /// GB18030 索引数据加载器（懒加载；首次需要时调用一次，进程内缓存由调用方保证）。
  final Future<Gb18030IndexData> Function() encodingTableLoader;

  final String parserVersion;
  final String normalizationVersion;
  final int indexFormatVersion;

  /// 规范化文本回调（isolate 内生成后回传；正文不入缓存，但可经此提供给调用方）。
  final void Function(String normalizedText)? onNormalizedText;

  /// 导入入口。
  ///
  /// 抛 [TxtImportCancelledException] 表示取消；抛 [TxtImportException] 表示业务错误。
  Future<TxtImportResult> import(
    TxtImportRequest request, {
    TxtImportCancellationToken? token,
  }) async {
    final totalSw = Stopwatch()..start();
    final stats = <String, int>{};
    final progress = request.progressSink;
    void emit(
      PipelinePhase phase, {
      String message = '',
      int? processed,
      int? total,
    }) {
      if (progress == null) return;
      final elapsed = totalSw.elapsed;
      progress(
        PipelineProgress(
          phase: phase,
          processedBytes: processed ?? 0,
          totalBytes: total ?? 0,
          elapsed: elapsed,
          message: message,
        ),
      );
    }

    _throwIfCancelled(token);

    // 1. 文件校验
    emit(PipelinePhase.validatingFile, message: '校验文件');
    final file = request.file;
    if (!await file.exists()) {
      throw TxtImportException('文件不存在: ${file.path}');
    }
    final fileStat = await file.stat();
    if (fileStat.type == FileSystemEntityType.directory) {
      throw TxtImportException('路径是目录，不是文件: ${file.path}');
    }
    final size = fileStat.size;
    if (size == 0) {
      throw TxtImportException('文件为空: ${file.path}');
    }

    // 2. 大文件策略
    final fileClass = LargeFilePolicy.classify(size);
    if (fileClass == LargeFileClass.unsupported) {
      throw TxtImportException(
        '文件超过 ${LargeFilePolicy.confirmedMaxBytes ~/ (1024 * 1024)}MB，'
        '0.1.x 不支持打开（$size bytes）',
      );
    }
    if (fileClass == LargeFileClass.requiresConfirmation &&
        !request.allowLargeFileConfirmation) {
      throw TxtImportRequiresConfirmation(
        size: size,
        message: '文件超过 20MB，需要确认后处理（$size bytes）',
      );
    }
    _throwIfCancelled(token);

    // 3. 读取字节 + 内容身份
    emit(
      PipelinePhase.readingBytes,
      message: '读取文件',
      processed: 0,
      total: size,
    );
    final readSw = Stopwatch()..start();
    final bytes = await file.readAsBytes();
    readSw.stop();
    stats['fileReadMs'] = readSw.elapsedMilliseconds;
    _throwIfCancelled(token);
    emit(
      PipelinePhase.readingBytes,
      message: '读取完成',
      processed: bytes.length,
      total: size,
    );

    final identity = TxtContentIdentity(
      fileName: file.path.split(Platform.pathSeparator).last,
      size: bytes.length,
      contentHash: sha256Of(bytes),
    );

    // 4. 编码检测
    emit(PipelinePhase.detectingEncoding, message: '检测编码');
    final encodingResult = const TxtEncodingDetector().detect(bytes);
    final encoding = encodingResult.encoding;
    if (encoding == TextEncoding.unknown) {
      throw TxtImportException(
        '无法识别编码：${encodingResult.errorMessage}（${encodingResult.reason}）',
      );
    }
    _throwIfCancelled(token);

    // 5. 缓存检查（命中直接返回）
    final cache = TxtIndexCache(
      cacheDirectory: request.cacheDirectory,
      parserVersion: parserVersion,
      normalizationVersion: normalizationVersion,
    );
    final cacheReadSw = Stopwatch()..start();
    final (cachedIndex, cacheCheck) = await cache.readIfValid(
      sourceFileName: identity.fileName,
      sourceSize: identity.size,
      sourceContentHash: identity.contentHash,
      encodingName: encoding.name,
      indexFormatVersion: indexFormatVersion,
    );
    cacheReadSw.stop();
    stats['cacheReadMs'] = cacheReadSw.elapsedMilliseconds;
    if (cachedIndex != null) {
      stats['totalMs'] = totalSw.elapsedMilliseconds;
      emit(
        PipelinePhase.completed,
        message: '缓存命中，无需重新扫描',
        processed: size,
        total: size,
      );
      return TxtImportResult(
        index: cachedIndex,
        cacheHit: true,
        stats: _buildStats(stats),
      );
    }
    _throwIfCancelled(token);

    // 6. 加载编码表（仅 GB18030 需要）
    Gb18030IndexData? indexData;
    if (encoding == TextEncoding.gb18030) {
      emit(PipelinePhase.loadingEncodingTable, message: '加载 GB18030 索引');
      final loadSw = Stopwatch()..start();
      indexData = await encodingTableLoader();
      loadSw.stop();
      stats['tableLoadMs'] = loadSw.elapsedMilliseconds;
      _throwIfCancelled(token);
    }

    // 7. 后台 Isolate：解码 + 规范化 + 卷章扫描 + 去重
    emit(PipelinePhase.decoding, message: '后台解码与扫描', processed: 0, total: size);
    final scanSw = Stopwatch()..start();
    final scanOutcome = await _runScanIsolate(
      bytes: bytes,
      encoding: encoding,
      bomLength: encodingResult.bomLength,
      indexData: indexData,
      token: token,
    );
    scanSw.stop();
    _throwIfCancelled(token);

    // 回传规范化文本（供 M2 写 normalized.txt）
    onNormalizedText?.call(scanOutcome.normalizedText);

    stats['decodeMs'] = scanOutcome.decodeMs;
    stats['normalizeMs'] = scanOutcome.normalizeMs;
    stats['scanMs'] = scanOutcome.scanMs;
    stats['dedupeMs'] = scanOutcome.dedupeMs;

    final index = TxtIndex(
      indexFormatVersion: indexFormatVersion,
      parserVersion: parserVersion,
      normalizationVersion: normalizationVersion,
      sourceFileName: identity.fileName,
      sourceSize: identity.size,
      sourceContentHash: identity.contentHash,
      encoding: encoding,
      normalizedCharacterLength: scanOutcome.normalizedLength,
      volumeCount: scanOutcome.volumeCount,
      chapterCount: scanOutcome.chapterCount,
      tocEntries: scanOutcome.entries,
      generatedAt: DateTime.now(),
    );

    // 8. 原子缓存写入
    emit(PipelinePhase.writingCache, message: '写入索引缓存');
    final cacheWriteSw = Stopwatch()..start();
    await cache.write(index);
    cacheWriteSw.stop();
    stats['cacheWriteMs'] = cacheWriteSw.elapsedMilliseconds;
    _throwIfCancelled(token);

    stats['totalMs'] = totalSw.elapsedMilliseconds;
    emit(PipelinePhase.completed, message: '完成', processed: size, total: size);
    return TxtImportResult(
      index: index,
      cacheHit: false,
      stats: _buildStats(stats),
    );
  }

  TxtImportStats _buildStats(Map<String, int> s) => TxtImportStats(
    fileReadMs: s['fileReadMs'] ?? 0,
    decodeMs: s['decodeMs'] ?? 0,
    normalizeMs: s['normalizeMs'] ?? 0,
    scanMs: s['scanMs'] ?? 0,
    dedupeMs: s['dedupeMs'] ?? 0,
    cacheWriteMs: s['cacheWriteMs'] ?? 0,
    cacheReadMs: s['cacheReadMs'] ?? 0,
    totalMs: s['totalMs'] ?? 0,
  );

  void _throwIfCancelled(TxtImportCancellationToken? token) {
    if (token != null && token.isCancelled) {
      throw const TxtImportCancelledException();
    }
  }

  /// 在后台 Isolate 执行解码+规范化+扫描。
  Future<_ScanOutcome> _runScanIsolate({
    required Uint8List bytes,
    required TextEncoding encoding,
    required int bomLength,
    required Gb18030IndexData? indexData,
    required TxtImportCancellationToken? token,
  }) {
    // 捕获的数据会被复制到 isolate（Dart 3 Isolate.run 语义）。
    return Isolate.run(() {
      final outcome = _ScanOutcome();
      final decodeSw = Stopwatch()..start();
      final String raw;
      switch (encoding) {
        case TextEncoding.utf8:
        case TextEncoding.utf8Bom:
          raw = utf8.decode(bytes, allowMalformed: false);
        case TextEncoding.utf16Le:
          raw = _decodeUtf16(bytes, Endian.little);
        case TextEncoding.utf16Be:
          raw = _decodeUtf16(bytes, Endian.big);
        case TextEncoding.gb18030:
          final decoder = Gb18030Decoder(indexData!);
          raw = decoder.decode(bytes, allowMalformed: false);
        case TextEncoding.unknown:
          throw StateError('unreachable');
      }
      decodeSw.stop();
      outcome.decodeMs = decodeSw.elapsedMilliseconds;

      final normalizeSw = Stopwatch()..start();
      final normalized = TxtNormalizer.normalize(
        raw,
        sourceEncodingBomLength: bomLength,
      );
      normalizeSw.stop();
      outcome.normalizeMs = normalizeSw.elapsedMilliseconds;
      outcome.normalizedLength = normalized.length;
      outcome.normalizedText = normalized.text;

      final scanSw = Stopwatch()..start();
      const TxtTocScanner().scanRaw(normalized);
      scanSw.stop();
      outcome.scanMs = scanSw.elapsedMilliseconds;

      final dedupeSw = Stopwatch()..start();
      final scanResult = const TxtTocScanner().scan(normalized);
      dedupeSw.stop();
      outcome.dedupeMs = dedupeSw.elapsedMilliseconds;
      outcome.volumeCount = scanResult.volumeCount;
      outcome.chapterCount = scanResult.chapterCount;
      outcome.entries = scanResult.entries;
      return outcome;
    });
  }

  static String _decodeUtf16(Uint8List bytes, Endian endian) {
    final n = bytes.length ~/ 2;
    final units = Uint16List(n);
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < n; i++) {
      units[i] = bd.getUint16(i * 2, endian);
    }
    // 去掉 BOM 单元（若有）
    var start = 0;
    if (units.isNotEmpty) {
      if (units[0] == 0xFEFF) start = 1;
    }
    return String.fromCharCodes(units.sublist(start));
  }

  static String sha256Of(Uint8List bytes) => sha256.convert(bytes).toString();
}

/// 扫描 isolate 输出（可变，仅 isolate 内使用）。
class _ScanOutcome {
  int decodeMs = 0;
  int normalizeMs = 0;
  int scanMs = 0;
  int dedupeMs = 0;
  int normalizedLength = 0;
  int volumeCount = 0;
  int chapterCount = 0;
  List<TocEntry> entries = const [];
  String normalizedText = '';
}

/// 业务错误。
class TxtImportException implements Exception {
  const TxtImportException(this.message);
  final String message;

  @override
  String toString() => 'TxtImportException: $message';
}

/// 需要大文件确认。
class TxtImportRequiresConfirmation implements Exception {
  const TxtImportRequiresConfirmation({
    required this.size,
    required this.message,
  });
  final int size;
  final String message;

  @override
  String toString() => 'TxtImportRequiresConfirmation: $message';
}
