import 'dart:io';

import 'package:crypto/crypto.dart';

/// 内容身份 —— 源文件的身份校验信息。
///
/// 用内容 SHA-256 而非 mtime 作为身份依据（mtime 变化但内容不变仍可命中缓存；
/// 内容变化时 hash 变化 → 缓存失效）。
class TxtContentIdentity {
  const TxtContentIdentity({
    required this.fileName,
    required this.size,
    required this.contentHash,
  });

  final String fileName;
  final int size;

  /// 内容 SHA-256（hex 小写）。
  final String contentHash;

  static Future<TxtContentIdentity> fromFile(File file) async {
    final bytes = await file.readAsBytes();
    return TxtContentIdentity(
      fileName: file.path.split(Platform.pathSeparator).last,
      size: bytes.length,
      contentHash: sha256.convert(bytes).toString(),
    );
  }
}
