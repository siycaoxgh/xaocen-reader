import 'library_entities.dart';
import 'toc_index.dart';
import '../reader/reader_locator.dart';

/// Resolves the current chapter from a confirmed ReaderLocator offset.
/// Volumes and no-chapter documents intentionally resolve to null.
abstract final class CurrentChapterResolver {
  static LibraryTocEntry? resolve(
    int absoluteCharacterOffset,
    List<LibraryTocEntry> toc,
  ) => TocIndexLogic.currentChapterFor(absoluteCharacterOffset, toc);

  static LibraryTocEntry? resolveLocator(
    ReaderLocator locator,
    List<LibraryTocEntry> toc,
  ) => resolve(locator.absoluteCharacterOffset, toc);
}
