/// 规范化产物 —— 唯一 hash 合同的强类型载体。
///
/// 合同：normalizedHash = 最终落盘 normalized.txt（无 BOM UTF-8 文件字节）的 SHA-256。
/// 导入器、manifest 写入器、Drift 写入器和 Loader 必须消费同一个 NormalizedArtifact 结果，
/// 不能各自重新推导。
library;

/// 规范化产物。
class NormalizedArtifact {
  const NormalizedArtifact({
    required this.filePath,
    required this.utf8ByteLength,
    required this.utf16CharacterLength,
    required this.sha256,
    required this.normalizationVersion,
  });

  /// 落盘后的 normalized.txt 绝对路径（写入完成后）。
  final String filePath;

  /// normalized.txt 无 BOM UTF-8 字节长度。
  final int utf8ByteLength;

  /// 规范化文本 UTF-16 码元长度（Dart String.length）。
  final int utf16CharacterLength;

  /// 落盘文件字节 SHA-256（唯一 normalizedHash 合同值）。
  final String sha256;

  /// 规范化版本（与 TxtIndex.normalizationVersion 一致）。
  final String normalizationVersion;

  @override
  String toString() =>
      'NormalizedArtifact(bytes:$utf8ByteLength, utf16:$utf16CharacterLength, '
      'sha256:${sha256.substring(0, 12)}…, norm:$normalizationVersion)';
}
