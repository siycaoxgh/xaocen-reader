import '../reader/reader_locator.dart';
import 'chapter_boundary_resolver.dart';
import 'library_entities.dart';

final class CurrentChapterProgress {
  const CurrentChapterProgress({
    required this.boundary,
    required this.progress,
  });

  final CurrentChapterBoundary boundary;
  final double progress;
}

/// Derives progress inside the current chapter without introducing another
/// persistence coordinate. The result is transient UI state only.
abstract final class CurrentChapterProgressResolver {
  static CurrentChapterProgress? resolve({
    required ReaderLocator locator,
    required List<LibraryTocEntry> toc,
    required int normalizedLength,
  }) {
    final boundary = ChapterBoundaryResolver.resolve(
      locatorOffset: locator.absoluteCharacterOffset,
      toc: toc,
      normalizedLength: normalizedLength,
    );
    if (boundary == null || boundary.endOffset <= boundary.startOffset) {
      return null;
    }
    final offset = locator.absoluteCharacterOffset.clamp(
      boundary.startOffset,
      boundary.endOffset,
    );
    final value =
        (offset - boundary.startOffset) /
        (boundary.endOffset - boundary.startOffset);
    return CurrentChapterProgress(
      boundary: boundary,
      progress: value.clamp(0.0, 1.0).toDouble(),
    );
  }
}
