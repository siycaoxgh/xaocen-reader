import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/library/toc_index.dart';

/// M3.4 目录平铺展示纯逻辑（§三/§七/§八）。
///
/// TOC hierarchy is advisory; source order is authoritative.
void main() {
  LibraryTocEntry entry({
    required String id,
    required String kind,
    required int orderIndex,
    required int startCharacterOffset,
    String? parentId,
    String title = '',
    String displayTitle = '',
  }) {
    return LibraryTocEntry(
      id: id,
      collectionId: 'local-txt:abc',
      itemId: null,
      parentId: parentId,
      kind: kind,
      level: kind == 'volume' ? 1 : 2,
      title: title.isEmpty ? id : title,
      displayTitle: displayTitle.isEmpty
          ? (title.isEmpty ? id : title)
          : displayTitle,
      orderIndex: orderIndex,
      startCharacterOffset: startCharacterOffset,
      endCharacterOffset: 0,
    );
  }

  // 主 fixture：卷一 + 3 章 + 卷二 + 2 章
  final toc = <LibraryTocEntry>[
    entry(id: 'v1', kind: 'volume', orderIndex: 0, startCharacterOffset: 0),
    entry(
      id: 'c1',
      kind: 'chapter',
      orderIndex: 1,
      startCharacterOffset: 10,
      parentId: 'v1',
    ),
    entry(
      id: 'c2',
      kind: 'chapter',
      orderIndex: 2,
      startCharacterOffset: 100,
      parentId: 'v1',
    ),
    entry(
      id: 'c3',
      kind: 'chapter',
      orderIndex: 3,
      startCharacterOffset: 200,
      parentId: 'v1',
    ),
    entry(id: 'v2', kind: 'volume', orderIndex: 4, startCharacterOffset: 300),
    entry(
      id: 'c4',
      kind: 'chapter',
      orderIndex: 5,
      startCharacterOffset: 400,
      parentId: 'v2',
    ),
    entry(
      id: 'c5',
      kind: 'chapter',
      orderIndex: 6,
      startCharacterOffset: 500,
      parentId: 'v2',
    ),
  ];

  group('currentChapterFor（§七：volume 不算当前章节）', () {
    test('位置在第一章之前 → null（调用方回退第一项或全文）', () {
      expect(TocIndexLogic.currentChapterFor(0, toc), isNull);
      expect(TocIndexLogic.currentChapterFor(9, toc), isNull);
    });

    test('第一章起始处 → 第1章', () {
      expect(TocIndexLogic.currentChapterFor(10, toc)?.id, 'c1');
    });

    test('卷标题 offset 处 → 仍是前一章（volume 不是当前章节）', () {
      expect(TocIndexLogic.currentChapterFor(300, toc)?.id, 'c3');
      expect(TocIndexLogic.currentChapterFor(399, toc)?.id, 'c3');
    });

    test('卷二章节内 → 卷二章节', () {
      expect(TocIndexLogic.currentChapterFor(400, toc)?.id, 'c4');
      expect(TocIndexLogic.currentChapterFor(500, toc)?.id, 'c5');
    });

    test('最后一章之后 → 最后一章', () {
      expect(TocIndexLogic.currentChapterFor(9999, toc)?.id, 'c5');
    });

    test('无章节 → null（调用方显示全文）', () {
      expect(TocIndexLogic.currentChapterFor(0, const []), isNull);
    });

    test('异常乱序 offset 不提前 break，取最后一个满足条件项，不崩溃', () {
      final messy = <LibraryTocEntry>[
        entry(
          id: 'a',
          kind: 'chapter',
          orderIndex: 0,
          startCharacterOffset: 500,
        ),
        entry(
          id: 'b',
          kind: 'chapter',
          orderIndex: 1,
          startCharacterOffset: 10,
        ),
        entry(
          id: 'c',
          kind: 'chapter',
          orderIndex: 2,
          startCharacterOffset: 300,
        ),
      ];
      // 遍历全表：<= 500 的 chapter 是 a(500) 与 b(10) 与 c(300)，最后一个 = c
      expect(TocIndexLogic.currentChapterFor(500, messy)?.id, 'c');
      expect(TocIndexLogic.currentChapterFor(20, messy)?.id, 'b');
    });
  });

  group('displayIndexFor（§三：平铺列表直接下标）', () {
    test('volume + chapter 混合列表中的条目下标', () {
      expect(TocIndexLogic.displayIndexFor('v1', toc), 0);
      expect(TocIndexLogic.displayIndexFor('c1', toc), 1);
      expect(TocIndexLogic.displayIndexFor('v2', toc), 4);
      expect(TocIndexLogic.displayIndexFor('c5', toc), 6);
    });

    test('未找到 → null', () {
      expect(TocIndexLogic.displayIndexFor('ghost', toc), isNull);
      expect(TocIndexLogic.displayIndexFor(null, toc), isNull);
    });

    test('异常层级（幽灵 parentId/连续 volume/无 parent chapter）不影响平铺下标', () {
      final abnormal = <LibraryTocEntry>[
        entry(id: 'v1', kind: 'volume', orderIndex: 0, startCharacterOffset: 0),
        entry(
          id: 'c1',
          kind: 'chapter',
          orderIndex: 1,
          startCharacterOffset: 4,
          parentId: 'ghost',
        ),
        entry(id: 'v2', kind: 'volume', orderIndex: 2, startCharacterOffset: 8),
        entry(
          id: 'v3',
          kind: 'volume',
          orderIndex: 3,
          startCharacterOffset: 12,
        ),
        entry(
          id: 'c2',
          kind: 'chapter',
          orderIndex: 4,
          startCharacterOffset: 16,
          parentId: 'v3',
        ),
        entry(
          id: 'c3',
          kind: 'chapter',
          orderIndex: 5,
          startCharacterOffset: 20,
          parentId: null,
        ),
      ];
      expect(TocIndexLogic.displayIndexFor('v1', abnormal), 0);
      expect(TocIndexLogic.displayIndexFor('c1', abnormal), 1);
      expect(TocIndexLogic.displayIndexFor('v3', abnormal), 3);
      expect(TocIndexLogic.displayIndexFor('c2', abnormal), 4);
      expect(TocIndexLogic.displayIndexFor('c3', abnormal), 5);
    });
  });
}
