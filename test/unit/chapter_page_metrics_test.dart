import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/reader/chapter_page_metrics.dart';
import 'package:xaocen_reader/reader/paged_layout_engine.dart';

LibraryTocEntry _chapter(String id, int start, int order) => LibraryTocEntry(
  id: id,
  collectionId: 'book',
  itemId: id,
  parentId: null,
  kind: 'chapter',
  level: 1,
  title: id,
  orderIndex: order,
  startCharacterOffset: start,
  endCharacterOffset: start + 1,
);

PagedLayoutEngine _engine(String text, Iterable<int> starts) =>
    PagedLayoutEngine(
      text: text,
      style: const TextStyle(fontSize: 10, height: 1),
      textDirection: TextDirection.ltr,
      width: 100,
      height: 100,
      horizontalPadding: 0,
      verticalPadding: 0,
      chapterStartOffsets: starts,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'derives current and total page within only the current chapter',
    () async {
      final text = 'a' * 260;
      final resolver = ChapterPageMetricsResolver();
      final result = await resolver.resolve(
        engine: _engine(text, [0, 130]),
        locator: const ReaderLocator(
          collectionId: 'book',
          absoluteCharacterOffset: 160,
        ),
        toc: [_chapter('a', 0, 0), _chapter('b', 130, 1)],
        normalizedLength: text.length,
        collectionId: 'book',
        isCurrent: () => true,
      );

      expect(result, isNotNull);
      expect(result!.boundary.chapter.id, 'b');
      expect(result.currentPageNumber, 1);
      expect(result.totalPageCount, 2);
      expect(result.currentPage.startCharacterOffset, 130);
      expect(result.currentPage.endCharacterOffset, 230);
    },
  );

  test('chapter start is page one and cache is bounded/observable', () async {
    final text = 'x' * 300;
    final cache = ChapterPageMetricsCache(capacity: 1);
    final resolver = ChapterPageMetricsResolver(cache: cache);
    final toc = [_chapter('a', 0, 0), _chapter('b', 150, 1)];
    final first = await resolver.resolve(
      engine: _engine(text, [0, 150]),
      locator: const ReaderLocator(
        collectionId: 'book',
        absoluteCharacterOffset: 0,
      ),
      toc: toc,
      normalizedLength: text.length,
      collectionId: 'book',
      isCurrent: () => true,
    );
    final second = await resolver.resolve(
      engine: _engine(text, [0, 150]),
      locator: const ReaderLocator(
        collectionId: 'book',
        absoluteCharacterOffset: 0,
      ),
      toc: toc,
      normalizedLength: text.length,
      collectionId: 'book',
      isCurrent: () => true,
    );

    expect(first?.currentPageNumber, 1);
    expect(second?.currentPageNumber, 1);
    expect(cache.misses, 1);
    expect(cache.hits, 1);
  });

  test('middle and final chapter pages are derived from the locator', () async {
    final text = 'm' * 350;
    final resolver = ChapterPageMetricsResolver();
    final toc = [_chapter('only', 0, 0)];
    final metrics = await resolver.resolve(
      engine: _engine(text, [0]),
      locator: const ReaderLocator(
        collectionId: 'book',
        absoluteCharacterOffset: 250,
      ),
      toc: toc,
      normalizedLength: text.length,
      collectionId: 'book',
      isCurrent: () => true,
    );
    expect(metrics?.currentPageNumber, 3);
    expect(metrics?.totalPageCount, 4);
    expect(metrics?.currentPage.contains(250), isTrue);

    final last = await resolver.resolve(
      engine: _engine(text, [0]),
      locator: const ReaderLocator(
        collectionId: 'book',
        absoluteCharacterOffset: 349,
      ),
      toc: toc,
      normalizedLength: text.length,
      collectionId: 'book',
      isCurrent: () => true,
    );
    expect(last?.currentPageNumber, 4);
    expect(last?.totalPageCount, 4);
  });

  test('stale generation stops before publishing metrics', () async {
    final text = 'z' * 1200;
    var current = true;
    final result = await ChapterPageMetricsResolver().resolve(
      engine: _engine(text, [0]),
      locator: const ReaderLocator(
        collectionId: 'book',
        absoluteCharacterOffset: 0,
      ),
      toc: [_chapter('a', 0, 0)],
      normalizedLength: text.length,
      collectionId: 'book',
      isCurrent: () {
        current = false;
        return current;
      },
    );

    expect(result, isNull);
  });
}
