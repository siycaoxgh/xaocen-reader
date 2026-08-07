/// 规范化正文文档 —— 加载后的不可变正文。
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../data/repositories/library_file_manager.dart';

/// 加载后的不可变规范化正文。
class NormalizedDocument {
  const NormalizedDocument({
    required this.text,
    required this.normalizedHash,
    required this.normalizationVersion,
    required this.parserVersion,
    required this.indexFormatVersion,
    required this.sourceFileName,
  });

  /// 完整正文（UTF-16 码元；Dart String 内部即 UTF-16）。
  final String text;

  /// manifest 记录的 normalizedHash（校验用）。
  final String normalizedHash;

  final String normalizationVersion;
  final String parserVersion;
  final String indexFormatVersion;
  final String sourceFileName;

  int get characterLength => text.length;
}

/// 文档加载异常。
class NormalizedDocumentException implements Exception {
  const NormalizedDocumentException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'NormalizedDocumentException($code): $message';
}

/// 根据 M2 Document / manifest 定位并加载 normalized.txt。
///
/// 职责：
/// 1. 找到 normalized.txt（storagePath 为相对路径，相对 libraryRoot）；
/// 2. 验证文件存在；
/// 3. 验证 UTF-8（无 BOM）；
/// 4. 验证 normalizedHash（manifest）；
/// 5. 验证 UTF-16 character length（manifest normalizedCharacterLength）；
/// 6. 加载为 Dart String；
/// 7. 返回不可变 [NormalizedDocument]。
///
/// 0.1.x 允许 ≤50MB normalized.txt 全文加载到内存。
/// 禁止：全文作为一个巨大 Text Widget / 正文存入数据库 /
/// 重新读取 source.txt / 再次编码检测或章节扫描 / 与 M1 不同的规范化。
class NormalizedDocumentLoader {
  NormalizedDocumentLoader({required this.fileManager});

  final LibraryFileManager fileManager;

  /// 加载指定 collection 的规范化正文。
  ///
  /// [storagePath] 为 M2 ContentDocuments.storagePath 相对路径
  /// （如 `library/local_txt/<hash>/normalized.txt`）。
  /// [expectedHash] 与 [expectedLength] 来自 manifest（缺失时跳过对应校验）。
  Future<NormalizedDocument> load({
    required String storagePath,
    String? expectedHash,
    int? expectedLength,
  }) async {
    if (storagePath.contains('..')) {
      throw const NormalizedDocumentException(
        'unsafe_path',
        'storagePath 含路径穿越',
      );
    }
    final file = fileManager.resolveStoragePath(storagePath);
    if (!await file.exists()) {
      throw NormalizedDocumentException('file_missing', '文件不存在: $storagePath');
    }

    // 从 manifest.json 读取期望 hash / 长度（唯一权威：manifest 与文件原子写入）。
    // expectedHash / expectedLength 仅在 manifest 缺失时作为调用方回退。
    final manifest = await _readManifest(storagePath);
    final wantHash = _str(manifest, 'normalizedHash').isNotEmpty
        ? _str(manifest, 'normalizedHash')
        : expectedHash;
    final wantLength =
        _int(manifest, 'normalizedCharacterLength') ?? expectedLength;

    final bytes = await file.readAsBytes();

    // 3) UTF-8 验证（无 BOM）
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      throw const NormalizedDocumentException(
        'bom_present',
        'normalized.txt 不应有 BOM',
      );
    }
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException catch (e) {
      throw NormalizedDocumentException(
        'invalid_utf8',
        'UTF-8 解码失败: ${e.message}',
      );
    }

    // 4) normalizedHash 校验
    if (wantHash != null) {
      final actual = sha256.convert(bytes).toString();
      if (actual != wantHash) {
        throw NormalizedDocumentException(
          'hash_mismatch',
          'normalizedHash 不匹配: 期望 $wantHash 实际 $actual',
        );
      }
    }

    // 5) UTF-16 长度校验
    if (wantLength != null && text.length != wantLength) {
      throw NormalizedDocumentException(
        'length_mismatch',
        'UTF-16 长度不匹配: 期望 $wantLength 实际 ${text.length}',
      );
    }

    return NormalizedDocument(
      text: text,
      normalizedHash: wantHash ?? '',
      normalizationVersion: _str(manifest, 'normalizationVersion'),
      parserVersion: _str(manifest, 'parserVersion'),
      indexFormatVersion: _str(manifest, 'indexFormatVersion'),
      sourceFileName: _str(manifest, 'originalFileName'),
    );
  }

  static String _str(Map<String, dynamic>? m, String key) {
    final v = m?[key];
    if (v == null) return '';
    return v.toString();
  }

  static int? _int(Map<String, dynamic>? m, String key) {
    final v = m?[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// 读取同目录 manifest.json（不存在返回 null）。
  Future<Map<String, dynamic>?> _readManifest(String storagePath) async {
    final manifestRel = storagePath.replaceFirst(
      RegExp(r'normalized\.txt$'),
      'manifest.json',
    );
    final manifestFile = fileManager.resolveStoragePath(manifestRel);
    if (!await manifestFile.exists()) return null;
    try {
      final raw = await manifestFile.readAsString();
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
