import 'library_entities.dart';

/// A normalized, chapter-only interval in the UTF-16 coordinate space of a
/// normalized document. This is transient derived state; it is never stored.
final class CurrentChapterBoundary {
  const CurrentChapterBoundary({
    required this.chapter,
    required this.startOffset,
    required this.endOffset,
    required this.chapterNumber,
  });

  final LibraryTocEntry chapter;
  final int startOffset;
  final int endOffset;
  final int chapterNumber;
}

/// Shared chapter boundary normalization for Reader, TOC-derived UI, search,
/// and bookmark display. Only real `kind == chapter` entries participate.
abstract final class ChapterBoundaryResolver {
  static List<CurrentChapterBoundary> boundaries(
    List<LibraryTocEntry> toc,
    int normalizedLength,
  ) {
    final length = normalizedLength < 0 ? 0 : normalizedLength;
    final indexed = <({LibraryTocEntry entry, int sourceIndex})>[];
    for (var i = 0; i < toc.length; i++) {
      final entry = toc[i];
      if (entry.kind != 'chapter') continue;
      final offset = entry.startCharacterOffset;
      if (offset < 0 || offset > length) continue;
      indexed.add((entry: entry, sourceIndex: i));
    }
    indexed.sort((a, b) {
      final byOffset = a.entry.startCharacterOffset.compareTo(
        b.entry.startCharacterOffset,
      );
      return byOffset == 0 ? a.sourceIndex.compareTo(b.sourceIndex) : byOffset;
    });

    final unique = <LibraryTocEntry>[];
    for (final item in indexed) {
      if (unique.isEmpty ||
          unique.last.startCharacterOffset != item.entry.startCharacterOffset) {
        unique.add(item.entry);
      }
    }

    return [
      for (var i = 0; i < unique.length; i++)
        CurrentChapterBoundary(
          chapter: unique[i],
          startOffset: unique[i].startCharacterOffset,
          endOffset: i + 1 < unique.length
              ? unique[i + 1].startCharacterOffset
              : length,
          chapterNumber: i + 1,
        ),
    ];
  }

  static CurrentChapterBoundary? resolve({
    required int locatorOffset,
    required List<LibraryTocEntry> toc,
    required int normalizedLength,
  }) {
    final length = normalizedLength < 0 ? 0 : normalizedLength;
    final offset = locatorOffset.clamp(0, length).toInt();
    CurrentChapterBoundary? current;
    for (final boundary in boundaries(toc, length)) {
      if (boundary.startOffset > offset) break;
      current = boundary;
    }
    return current;
  }
}
