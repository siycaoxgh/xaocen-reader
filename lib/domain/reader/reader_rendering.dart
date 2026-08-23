import 'package:flutter/foundation.dart';

/// Optional, source-neutral rendering annotations for a normalized Reader
/// document.  They never change the canonical UTF-16 text or its offsets.
@immutable
final class ReaderInlineStyleRun {
  const ReaderInlineStyleRun({
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

  bool get isEmpty => endCharacterOffset <= startCharacterOffset;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'start': startCharacterOffset,
    'end': endCharacterOffset,
    if (bold) 'bold': true,
    if (italic) 'italic': true,
    if (headingLevel != null) 'headingLevel': headingLevel,
  };

  factory ReaderInlineStyleRun.fromJson(Map<String, dynamic> json) {
    return ReaderInlineStyleRun(
      startCharacterOffset: _int(json['start']),
      endCharacterOffset: _int(json['end']),
      bold: json['bold'] == true,
      italic: json['italic'] == true,
      headingLevel: json['headingLevel'] == null
          ? null
          : _int(json['headingLevel']),
    );
  }
}

/// A local image placed at a canonical text offset.  The image path is a
/// managed storage path, never a source EPUB path or remote URL.
@immutable
final class ReaderImagePlacement {
  const ReaderImagePlacement({
    required this.characterOffset,
    required this.storagePath,
    this.altText,
    this.width,
    this.height,
  });

  final int characterOffset;
  final String storagePath;
  final String? altText;
  final double? width;
  final double? height;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'offset': characterOffset,
    'storagePath': storagePath,
    if (altText != null && altText!.isNotEmpty) 'alt': altText,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
  };

  factory ReaderImagePlacement.fromJson(Map<String, dynamic> json) {
    return ReaderImagePlacement(
      characterOffset: _int(json['offset']),
      storagePath: json['storagePath']?.toString() ?? '',
      altText: json['alt']?.toString(),
      width: _double(json['width']),
      height: _double(json['height']),
    );
  }
}

@immutable
final class ReaderRenderingMetadata {
  const ReaderRenderingMetadata({
    this.styleRuns = const <ReaderInlineStyleRun>[],
    this.images = const <ReaderImagePlacement>[],
  });

  final List<ReaderInlineStyleRun> styleRuns;
  final List<ReaderImagePlacement> images;

  bool get isEmpty => styleRuns.isEmpty && images.isEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': 1,
    'styleRuns': styleRuns.map((run) => run.toJson()).toList(growable: false),
    'images': images.map((image) => image.toJson()).toList(growable: false),
  };

  factory ReaderRenderingMetadata.fromJson(Object? value) {
    if (value is! Map) return const ReaderRenderingMetadata();
    final styles = value['styleRuns'];
    final images = value['images'];
    return ReaderRenderingMetadata(
      styleRuns: styles is List
          ? List.unmodifiable(
              styles.whereType<Map>().map(
                (json) => ReaderInlineStyleRun.fromJson(
                  Map<String, dynamic>.from(json),
                ),
              ),
            )
          : const <ReaderInlineStyleRun>[],
      images: images is List
          ? List.unmodifiable(
              images
                  .whereType<Map>()
                  .map(
                    (json) => ReaderImagePlacement.fromJson(
                      Map<String, dynamic>.from(json),
                    ),
                  )
                  .where((image) => image.storagePath.isNotEmpty),
            )
          : const <ReaderImagePlacement>[],
    );
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
