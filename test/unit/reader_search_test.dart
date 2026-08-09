import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/reader/reader_search.dart';

void main() {
  const toc = [
    LibraryTocEntry(
      id: 'chapter-1',
      collectionId: 'book-a',
      itemId: 'item-1',
      parentId: null,
      kind: 'chapter',
      level: 1,
      title: '第一章',
      orderIndex: 0,
      startCharacterOffset: 0,
      endCharacterOffset: 20,
    ),
    LibraryTocEntry(
      id: 'chapter-2',
      collectionId: 'book-a',
      itemId: 'item-2',
      parentId: null,
      kind: 'chapter',
      level: 1,
      title: '第二章',
      orderIndex: 1,
      startCharacterOffset: 20,
      endCharacterOffset: 100,
    ),
  ];

  test(
    'Chinese, ASCII case-insensitive, digits and chapter derivation',
    () async {
      final service = ReaderSearchService();
      final results = await service.search(
        text: '第一章 Hello 123 hello 第二章',
        query: 'HELLO',
        toc: toc,
        contextBefore: 2,
        contextAfter: 2,
      );
      expect(results, hasLength(2));
      expect(results[0].startOffset, 4);
      expect(results[0].endOffset, 9);
      expect(results[0].derivedChapterTitle, '第一章');
      expect(results[1].derivedChapterTitle, '第一章');

      final digits = await service.search(
        text: '第一章 Hello 123 hello 第二章',
        query: '123',
        toc: toc,
      );
      expect(digits.single.startOffset, 10);
    },
  );

  test('UTF-16 surrogate offsets and safe context boundaries', () async {
    final service = ReaderSearchService();
    const text = '甲😀乙😀丙';
    final results = await service.search(
      text: text,
      query: '😀',
      toc: const [],
      contextBefore: 0,
      contextAfter: 0,
    );
    expect(results, hasLength(2));
    expect(results[0].startOffset, 1);
    expect(results[0].endOffset, 3);
    expect(results[0].contextStartOffset, 1);
    expect(results[0].contextEndOffset, 3);
    expect(results[1].startOffset, 4);
    expect(text.substring(results[1].startOffset, results[1].endOffset), '😀');
  });

  test('empty/no-result and result limit are deterministic', () async {
    final service = ReaderSearchService();
    expect(
      await service.search(text: 'abc', query: '', toc: const []),
      isEmpty,
    );
    expect(
      await service.search(text: 'abc', query: 'z', toc: const []),
      isEmpty,
    );
    final limited = await service.search(
      text: 'x x x x',
      query: 'x',
      toc: const [],
      maxResults: 2,
    );
    expect(limited, hasLength(2));
  });

  test('new query wins and cancellation rejects stale isolate', () async {
    final service = ReaderSearchService();
    final oldFuture = service.search(
      text: '${List.filled(200000, 'old query ').join()}needle',
      query: 'needle',
      toc: const [],
    );
    final oldExpectation = expectLater(
      oldFuture,
      throwsA(isA<ReaderSearchCancelled>()),
    );
    final newFuture = service.search(
      text: 'new query needle',
      query: 'new',
      toc: const [],
    );
    expect((await newFuture).single.startOffset, 0);
    await oldExpectation;
    service.cancel();
  });

  test('book-specific text never crosses a search service request', () async {
    final service = ReaderSearchService();
    final a = await service.search(
      text: 'Book A only',
      query: 'Book',
      toc: const [],
    );
    final b = await service.search(
      text: 'Book B only',
      query: 'Book',
      toc: const [],
    );
    expect(a.single.snippet, contains('Book A'));
    expect(b.single.snippet, contains('Book B'));
  });
}
