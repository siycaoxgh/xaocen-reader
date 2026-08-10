import 'library_entities.dart';
import 'chapter_boundary_resolver.dart';
import '../reader/reader_locator.dart';

/// Resolves the current chapter from a confirmed ReaderLocator offset.
/// Volumes and no-chapter documents intentionally resolve to null.
abstract final class CurrentChapterResolver {
  static LibraryTocEntry? resolve(
    int absoluteCharacterOffset,
    List<LibraryTocEntry> toc, {
    int? normalizedLength,
  }) {
    final length =
        normalizedLength ??
        toc.fold<int>(
          0,
          (max, entry) =>
              entry.endCharacterOffset > max ? entry.endCharacterOffset : max,
        );
    return ChapterBoundaryResolver.resolve(
      locatorOffset: absoluteCharacterOffset,
      toc: toc,
      normalizedLength: length,
    )?.chapter;
  }

  static LibraryTocEntry? resolveLocator(
    ReaderLocator locator,
    List<LibraryTocEntry> toc, {
    int? normalizedLength,
  }) => resolve(
    locator.absoluteCharacterOffset,
    toc,
    normalizedLength: normalizedLength,
  );
}
