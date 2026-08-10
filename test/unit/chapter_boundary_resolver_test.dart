import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/library/chapter_boundary_resolver.dart';
import 'package:xaocen_reader/domain/library/current_chapter_progress_resolver.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';

void main() {
  LibraryTocEntry entry(String id, String kind, int start, {int order = 0}) =>
      LibraryTocEntry(
        id: id,
        collectionId: 'book',
        itemId: id,
        parentId: null,
        kind: kind,
        level: 1,
        title: id,
        orderIndex: order,
        startCharacterOffset: start,
        endCharacterOffset: start + 1,
      );

  test('normalizes chapter-only sorted boundaries and ignores volumes', () {
    final result = ChapterBoundaryResolver.boundaries([
      entry('later', 'chapter', 40),
      entry('volume', 'volume', 20),
      entry('first', 'chapter', 0),
      entry('duplicate', 'chapter', 40),
      entry('negative', 'chapter', -1),
      entry('out', 'chapter', 101),
    ], 100);

    expect(result.map((item) => item.chapter.id), ['first', 'later']);
    expect(result[0].startOffset, 0);
    expect(result[0].endOffset, 40);
    expect(result[1].endOffset, 100);
    expect(result[1].chapterNumber, 2);
  });

  test('exact next chapter start resolves to the next chapter at zero', () {
    final toc = [entry('a', 'chapter', 0), entry('b', 'chapter', 50)];
    final progress = CurrentChapterProgressResolver.resolve(
      locator: const ReaderLocator(
        collectionId: 'book',
        absoluteCharacterOffset: 50,
      ),
      toc: toc,
      normalizedLength: 100,
    );

    expect(progress?.boundary.chapter.id, 'b');
    expect(progress?.progress, 0);
  });

  test('chapter start, last chapter, no chapter and invalid span are safe', () {
    final toc = [entry('a', 'chapter', 10), entry('b', 'chapter', 80)];
    final start = CurrentChapterProgressResolver.resolve(
      locator: const ReaderLocator(
        collectionId: 'book',
        absoluteCharacterOffset: 10,
      ),
      toc: toc,
      normalizedLength: 100,
    );
    final last = CurrentChapterProgressResolver.resolve(
      locator: const ReaderLocator(
        collectionId: 'book',
        absoluteCharacterOffset: 90,
      ),
      toc: toc,
      normalizedLength: 100,
    );

    expect(start?.progress, 0);
    expect(last?.progress, closeTo(0.5, 0.0001));
    expect(
      CurrentChapterProgressResolver.resolve(
        locator: const ReaderLocator(
          collectionId: 'book',
          absoluteCharacterOffset: 4,
        ),
        toc: toc,
        normalizedLength: 100,
      ),
      isNull,
    );
    expect(
      CurrentChapterProgressResolver.resolve(
        locator: const ReaderLocator(
          collectionId: 'book',
          absoluteCharacterOffset: 0,
        ),
        toc: const [],
        normalizedLength: 100,
      ),
      isNull,
    );
    expect(
      CurrentChapterProgressResolver.resolve(
        locator: const ReaderLocator(
          collectionId: 'book',
          absoluteCharacterOffset: 10,
        ),
        toc: [entry('zero', 'chapter', 10)],
        normalizedLength: 10,
      ),
      isNull,
    );
  });

  test('UTF-16 document length is used for surrogate-pair offsets', () {
    final text = 'A😀BC';
    expect(text.length, 5);
    final progress = CurrentChapterProgressResolver.resolve(
      locator: const ReaderLocator(
        collectionId: 'book',
        absoluteCharacterOffset: 3,
      ),
      toc: [entry('a', 'chapter', 0)],
      normalizedLength: text.length,
    );
    expect(progress?.progress, closeTo(0.6, 0.0001));
  });

  test('malformed locator offsets are clamped without crashing', () {
    final toc = [entry('a', 'chapter', 0), entry('b', 'chapter', 10)];
    expect(
      CurrentChapterProgressResolver.resolve(
        locator: const ReaderLocator(
          collectionId: 'book',
          absoluteCharacterOffset: 999,
        ),
        toc: toc,
        normalizedLength: 20,
      )?.progress,
      1,
    );
  });
}
