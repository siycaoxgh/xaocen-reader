enum ReaderFontFormat { ttf, otf, ttc }

enum ReaderFontAvailability { available, missing, invalid }

/// Stable per-book font selection. A null id means system default.
final class ReaderFontRef {
  const ReaderFontRef({this.fontId});

  final String? fontId;

  static const systemDefault = ReaderFontRef();
}

/// Shared app-managed font metadata. The bytes are referenced by a root-
/// relative path and identified by their full SHA-256 content hash.
final class ReaderFontAsset {
  const ReaderFontAsset({
    required this.fontId,
    required this.contentHash,
    required this.relativePath,
    required this.format,
    required this.familyNameSnapshot,
    required this.styleNameSnapshot,
    required this.faceIndex,
    required this.fileSize,
    required this.createdAt,
    required this.lastUsedAt,
    required this.availability,
  });

  final String fontId;
  final String contentHash;
  final String relativePath;
  final ReaderFontFormat format;
  final String familyNameSnapshot;
  final String? styleNameSnapshot;
  final int? faceIndex;
  final int fileSize;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final ReaderFontAvailability availability;

  String get runtimeFamily => 'xaocen_font_$fontId';
}
