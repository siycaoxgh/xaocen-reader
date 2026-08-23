import 'package:flutter/foundation.dart';

/// The semantic purpose of a content transform.  These are contracts only;
/// no sanitiser, replacement engine, or translation service is implemented
/// in this stage.
enum ContentTransformKind { sanitize, replace, translate, custom }

/// A half-open range in the canonical or derived UTF-16 coordinate space.
@immutable
final class ContentOffsetRange {
  const ContentOffsetRange(this.start, this.end)
    : assert(start >= 0),
      assert(end >= start);

  final int start;
  final int end;

  int get length => end - start;

  bool contains(int offset) => offset >= start && offset < end;

  bool containsBoundary(int offset) => offset >= start && offset <= end;

  @override
  String toString() => '[$start,$end)';

  @override
  bool operator ==(Object other) =>
      other is ContentOffsetRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// How safely an offset can be carried between the two text representations.
enum ContentMappingQuality {
  /// Same text span and same length; the exact UTF-16 offset is preserved.
  exact,

  /// The transform can identify a source span, but not an exact character
  /// offset (for example a replacement or a translated sentence).
  coarse,

  /// No safe source span exists (for example removed advertisement text).
  unavailable,
}

/// A local mapping anchor between canonical and derived text.
@immutable
final class ContentPositionAnchor {
  const ContentPositionAnchor({
    required this.canonicalRange,
    required this.derivedRange,
    required this.quality,
  });

  final ContentOffsetRange canonicalRange;
  final ContentOffsetRange derivedRange;
  final ContentMappingQuality quality;

  bool get isUsable => quality != ContentMappingQuality.unavailable;
}

/// Result of resolving a position through a transform boundary.
@immutable
final class ContentOffsetMapping {
  const ContentOffsetMapping({
    required this.sourceRange,
    required this.targetRange,
    required this.quality,
  });

  final ContentOffsetRange sourceRange;
  final ContentOffsetRange targetRange;
  final ContentMappingQuality quality;

  bool get isExact => quality == ContentMappingQuality.exact;
}

/// Explicit position boundary for transformed content.
///
/// ReaderLocator remains anchored to the canonical text.  This map is a
/// transient adapter aid: callers may use it to find a canonical range, but
/// must never persist a derived offset as a ReaderLocator.
@immutable
final class ContentPositionMap {
  ContentPositionMap({
    required this.canonicalLength,
    required this.derivedLength,
    Iterable<ContentPositionAnchor> anchors = const <ContentPositionAnchor>[],
  }) : assert(canonicalLength >= 0),
       assert(derivedLength >= 0),
       anchors = _validateAnchors(canonicalLength, derivedLength, anchors);

  final int canonicalLength;
  final int derivedLength;
  final List<ContentPositionAnchor> anchors;

  /// True only when the whole text has exact, length-preserving anchors.
  bool get preservesCanonicalLocator =>
      canonicalLength == derivedLength &&
      _coversExactly(anchors, derivedLength) &&
      anchors.every((anchor) => anchor.quality == ContentMappingQuality.exact);

  ContentOffsetMapping? canonicalForDerivedOffset(int offset) {
    if (offset < 0 || offset >= derivedLength) return null;
    for (final anchor in anchors) {
      if (anchor.derivedRange.contains(offset) && anchor.isUsable) {
        return ContentOffsetMapping(
          sourceRange: anchor.derivedRange,
          targetRange: anchor.canonicalRange,
          quality: anchor.quality,
        );
      }
    }
    return null;
  }

  ContentOffsetMapping? derivedForCanonicalOffset(int offset) {
    if (offset < 0 || offset >= canonicalLength) return null;
    for (final anchor in anchors) {
      if (anchor.canonicalRange.contains(offset) && anchor.isUsable) {
        return ContentOffsetMapping(
          sourceRange: anchor.canonicalRange,
          targetRange: anchor.derivedRange,
          quality: anchor.quality,
        );
      }
    }
    return null;
  }

  /// Returns an exact canonical offset only when the mapping contract permits
  /// it. Coarse and removed spans intentionally return null.
  int? exactCanonicalOffsetForDerived(int offset) {
    final mapping = canonicalForDerivedOffset(offset);
    if (mapping == null || !mapping.isExact) return null;
    return mapping.targetRange.start + (offset - mapping.sourceRange.start);
  }

  static List<ContentPositionAnchor> _validateAnchors(
    int canonicalLength,
    int derivedLength,
    Iterable<ContentPositionAnchor> input,
  ) {
    final result = List<ContentPositionAnchor>.unmodifiable(
      input.toList(growable: false),
    );
    var previousDerivedEnd = 0;
    for (final anchor in result) {
      if (anchor.quality == ContentMappingQuality.exact &&
          anchor.canonicalRange.length != anchor.derivedRange.length) {
        throw ArgumentError('exact anchors must preserve range length');
      }
      if (anchor.canonicalRange.end > canonicalLength ||
          anchor.derivedRange.end > derivedLength) {
        throw ArgumentError('position anchor exceeds text length');
      }
      if (anchor.derivedRange.start < previousDerivedEnd) {
        throw ArgumentError('derived position anchors must be ordered');
      }
      previousDerivedEnd = anchor.derivedRange.end;
    }
    return result;
  }

  static bool _coversExactly(List<ContentPositionAnchor> anchors, int length) {
    var cursor = 0;
    for (final anchor in anchors) {
      if (anchor.derivedRange.start != cursor ||
          anchor.derivedRange.length != anchor.canonicalRange.length) {
        return false;
      }
      cursor = anchor.derivedRange.end;
    }
    return cursor == length;
  }
}

/// Immutable, source-owned text and revision. This is the only text that may
/// be used as the ReaderLocator coordinate space.
@immutable
final class CanonicalContent {
  const CanonicalContent({
    required this.contentId,
    required this.sourceRevision,
    required this.text,
  });

  final String contentId;
  final String sourceRevision;
  final String text;

  /// Dart String length is the UTF-16 code-unit length used by ReaderLocator.
  int get utf16Length => text.length;
}

/// A derived view of canonical content. It is disposable/cacheable and does
/// not become a second progress or Locator truth.
@immutable
final class DerivedContent {
  const DerivedContent({
    required this.canonical,
    required this.transformId,
    required this.transformVersion,
    required this.kind,
    required this.text,
    required this.positionMap,
  });

  final CanonicalContent canonical;
  final String transformId;
  final int transformVersion;
  final ContentTransformKind kind;
  final String text;
  final ContentPositionMap positionMap;

  bool get canPersistCanonicalLocator => positionMap.preservesCanonicalLocator;
}

/// Platform-neutral transform contract. Implementations must not mutate the
/// canonical content or write Reader progress/database state.
abstract interface class ContentTransform {
  String get transformId;

  int get transformVersion;

  ContentTransformKind get kind;

  DerivedContent apply(CanonicalContent canonical);
}

/// A no-op implementation used by adapters that need an explicit transform
/// boundary without changing the content.
final class IdentityContentTransform implements ContentTransform {
  const IdentityContentTransform({this.transformId = 'identity'});

  @override
  final String transformId;

  @override
  int get transformVersion => 1;

  @override
  ContentTransformKind get kind => ContentTransformKind.custom;

  @override
  DerivedContent apply(CanonicalContent canonical) {
    final map = canonical.utf16Length == 0
        ? ContentPositionMap(canonicalLength: 0, derivedLength: 0)
        : ContentPositionMap(
            canonicalLength: canonical.utf16Length,
            derivedLength: canonical.utf16Length,
            anchors: <ContentPositionAnchor>[
              ContentPositionAnchor(
                canonicalRange: ContentOffsetRange(0, canonical.utf16Length),
                derivedRange: ContentOffsetRange(0, canonical.utf16Length),
                quality: ContentMappingQuality.exact,
              ),
            ],
          );
    return DerivedContent(
      canonical: canonical,
      transformId: transformId,
      transformVersion: transformVersion,
      kind: kind,
      text: canonical.text,
      positionMap: map,
    );
  }
}
