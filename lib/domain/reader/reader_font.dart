enum ReaderFontFormat { ttf, otf, ttc }

enum ReaderFontAvailability { available, missing, invalid }

enum ReaderFontSource { system, imported }

/// Stable display contract shared by platform fonts and app-managed assets.
/// `fontId` is persisted; the other fields are presentation/runtime metadata.
abstract interface class ReaderFontDescriptor {
  String get fontId;
  String get displayName;
  String get familyName;
  ReaderFontSource get source;
}

/// Stable per-book font selection. A null id means system default.
final class ReaderFontRef {
  const ReaderFontRef({this.fontId});

  final String? fontId;

  static const systemDefault = ReaderFontRef();
}

/// Shared app-managed font metadata. The bytes are referenced by a root-
/// relative path and identified by their full SHA-256 content hash.
final class ReaderFontAsset implements ReaderFontDescriptor {
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

  @override
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

  @override
  String get displayName => familyNameSnapshot;

  @override
  String get familyName => familyNameSnapshot;

  @override
  ReaderFontSource get source => ReaderFontSource.imported;

  String get runtimeFamily => 'xaocen_font_$fontId';
}
