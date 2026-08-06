import 'dart:io';

import '../../domain/local_txt/txt_index.dart';

/// 缓存命中/失效结果。
class TxtCacheCheck {
  const TxtCacheCheck({required this.hit, this.reason = ''});

  final bool hit;
  final String reason;
}

/// 本地 TXT 索引缓存 —— 原子写入 + 内容身份校验。
///
/// - 缓存保存到应用管理目录（由调用方传入 cacheDirectory），不写到原 TXT 旁边；
/// - 命中校验：sourceSize + sourceContentHash + encoding + parserVersion +
///   normalizationVersion + indexFormatVersion（不依赖 mtime）；
/// - 写入：index.tmp → 完整序列化 → flush → 校验可读取 → 原子替换正式缓存；
/// - 失败：删除不完整临时文件、不覆盖原有效缓存、返回明确错误；
/// - 正文不写入索引缓存。
class TxtIndexCache {
  TxtIndexCache({
    required this.cacheDirectory,
    required this.parserVersion,
    required this.normalizationVersion,
  });

  final Directory cacheDirectory;
  final String parserVersion;
  final String normalizationVersion;

  /// 缓存文件名：以源文件名+内容hash 定位，避免不同文件互相覆盖。
  String _cacheFileName(String sourceFileName, String contentHash) {
    final base = sourceFileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
    return '$base.$contentHash.json';
  }

  File _cacheFile(String sourceFileName, String contentHash) => File(
    '${cacheDirectory.path}${Platform.pathSeparator}'
    '${_cacheFileName(sourceFileName, contentHash)}',
  );

  /// 读取缓存并校验。命中返回 TxtIndex；未命中/损坏返回 null。
  /// [TxtCacheCheck] 说明是否命中及原因。
  Future<(TxtIndex?, TxtCacheCheck)> readIfValid({
    required String sourceFileName,
    required int sourceSize,
    required String sourceContentHash,
    required String encodingName,
    required int indexFormatVersion,
  }) async {
    if (!await cacheDirectory.exists()) {
      return (
        null,
        const TxtCacheCheck(hit: false, reason: 'cache dir missing'),
      );
    }
    final file = _cacheFile(sourceFileName, sourceContentHash);
    if (!await file.exists()) {
      return (null, const TxtCacheCheck(hit: false, reason: 'no cache file'));
    }
    try {
      final s = await file.readAsString();
      final index = TxtIndex.decode(s);
      // 校验
      if (index.sourceSize != sourceSize) {
        return (null, const TxtCacheCheck(hit: false, reason: 'size mismatch'));
      }
      if (index.sourceContentHash != sourceContentHash) {
        return (null, const TxtCacheCheck(hit: false, reason: 'hash mismatch'));
      }
      if (index.encoding.name != encodingName) {
        return (
          null,
          const TxtCacheCheck(hit: false, reason: 'encoding mismatch'),
        );
      }
      if (index.parserVersion != parserVersion) {
        return (
          null,
          const TxtCacheCheck(hit: false, reason: 'parser version mismatch'),
        );
      }
      if (index.normalizationVersion != normalizationVersion) {
        return (
          null,
          const TxtCacheCheck(
            hit: false,
            reason: 'normalization version mismatch',
          ),
        );
      }
      if (index.indexFormatVersion != indexFormatVersion) {
        return (
          null,
          const TxtCacheCheck(hit: false, reason: 'index format mismatch'),
        );
      }
      return (index, const TxtCacheCheck(hit: true, reason: 'cache hit'));
    } catch (e) {
      // 缓存损坏：不伪装成功，返回未命中（调用方可选择重扫覆盖）
      return (null, TxtCacheCheck(hit: false, reason: 'corrupt cache: $e'));
    }
  }

  /// 原子写入缓存。
  ///
  /// 流程：tmp 写入 → flush → 重新读取校验 → 原子重命名替换正式文件。
  /// 任何失败：删除 tmp、不覆盖原文件、抛 [TxtCacheWriteException]。
  Future<void> write(TxtIndex index) async {
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    final finalFile = _cacheFile(index.sourceFileName, index.sourceContentHash);
    final tmpFile = File('${finalFile.path}.tmp');
    try {
      final content = index.encode();
      await tmpFile.writeAsString(content, flush: true);
      // 校验可读取
      final back = await tmpFile.readAsString();
      final parsed = TxtIndex.decode(back);
      if (parsed.chapterCount != index.chapterCount ||
          parsed.sourceContentHash != index.sourceContentHash) {
        throw const TxtCacheWriteException('validation after write failed');
      }
      // 原子替换
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tmpFile.rename(finalFile.path);
    } catch (e) {
      // 清理不完整临时文件
      try {
        if (await tmpFile.exists()) await tmpFile.delete();
      } catch (_) {}
      if (e is TxtCacheWriteException) rethrow;
      throw TxtCacheWriteException('write failed: $e');
    }
  }
}

class TxtCacheWriteException implements Exception {
  const TxtCacheWriteException(this.message);
  final String message;

  @override
  String toString() => 'TxtCacheWriteException: $message';
}
