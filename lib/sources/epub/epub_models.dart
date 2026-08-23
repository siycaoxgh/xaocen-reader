import 'package:flutter/foundation.dart';

@immutable
final class EpubBookMetadata {
  const EpubBookMetadata({
    required this.title,
    this.author,
    this.description,
    this.titleSource = 'autoDetected',
    this.authorSource = 'autoDetected',
    this.coverHref,
    this.coverMediaType,
  });

  final String title;
  final String? author;
  final String? description;

  /// Provenance is kept separate from the displayed value so the library can
  /// apply its existing manual/online/automatic priority rules later.
  final String titleSource;
  final String authorSource;

  /// Normalized ZIP path of the package-declared cover image, when present.
  final String? coverHref;
  final String? coverMediaType;
}

@immutable
final class EpubSpineItem {
  const EpubSpineItem({
    required this.id,
    required this.href,
    required this.mediaType,
    required this.text,
    required this.linear,
    required this.title,
    this.styleRuns = const <EpubInlineStyleRun>[],
    this.images = const <EpubImageReference>[],
  });

  final String id;
  final String href;
  final String mediaType;
  final String text;
  final bool linear;
  final String title;
  final List<EpubInlineStyleRun> styleRuns;
  final List<EpubImageReference> images;
}

@immutable
final class EpubInlineStyleRun {
  const EpubInlineStyleRun({
    required this.startCharacterOffset,
    required this.endCharacterOffset,
    this.bold = false,
    this.italic = false,
    this.headingLevel,
  });

  final int startCharacterOffset;
  final int endCharacterOffset;
  final bool bold;
  final bool italic;
  final int? headingLevel;
}

@immutable
final class EpubImageReference {
  const EpubImageReference({
    required this.characterOffset,
    required this.href,
    this.altText,
    this.width,
    this.height,
  });

  final int characterOffset;
  final String href;
  final String? altText;
  final double? width;
  final double? height;
}

@immutable
final class EpubAsset {
  const EpubAsset({
    required this.href,
    required this.mediaType,
    required this.bytes,
  });

  final String href;
  final String mediaType;
  final List<int> bytes;
}

@immutable
final class EpubNavigationItem {
  const EpubNavigationItem({
    required this.title,
    required this.href,
    required this.level,
    required this.spineIndex,
    this.parentIndex,
  });

  final String title;
  final String href;
  final int level;
  final int? spineIndex;
  final int? parentIndex;
}

@immutable
final class EpubBook {
  EpubBook({
    required this.packagePath,
    required this.metadata,
    required List<EpubSpineItem> spine,
    required List<EpubNavigationItem> navigation,
    List<EpubAsset> assets = const <EpubAsset>[],
  }) : spine = List.unmodifiable(spine),
       navigation = List.unmodifiable(navigation),
       assets = List.unmodifiable(assets);

  final String packagePath;
  final EpubBookMetadata metadata;
  final List<EpubSpineItem> spine;
  final List<EpubNavigationItem> navigation;
  final List<EpubAsset> assets;
}
