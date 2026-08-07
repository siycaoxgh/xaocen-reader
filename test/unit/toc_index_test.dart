import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/library/toc_index.dart';

/// M3.3 目录索引纯逻辑测试（§十 Unit）。
LibraryTocEntry _ch(String id, int start, {String? parentId, int order = 1}) {
  return LibraryTocEntry(
    id: id,
    collectionId: 'c',
    itemId: 'item:$id',
    parentId: parentId,
    kind: 'chapter',
    level: parentId == null ? 1 : 2,
    title: id,
    displayTitle: id,
    orderIndex: order,
    startCharacterOffset: start,
    endCharacterOffset: start + 100,
  );
}

LibraryTocEntry _vol(String id, int start, {String? parentId}) {
  return LibraryTocEntry(
    id: id,
    collectionId: 'c',
    itemId: null,
    parentId: parentId,
    kind: 'volume',
    level: 1,
    title: id,
    displayTitle: id,
    orderIndex: 1,
    startCharacterOffset: start,
    endCharacterOffset: start + 1000,
  );
}

void main() {
  // 卷1(v1): 第1/2章；卷2(v2): 第3/4章；卷3(v3): 第5/6章；游离第7章
  final toc = [
    _vol('v1', 0),
    _ch('c1', 10, parentId: 'v1', order: 1),
    _ch('c2', 110, parentId: 'v1', order: 2),
    _vol('v2', 300),
    _ch('c3', 310, parentId: 'v2', order: 1),
    _ch('c4', 410, parentId: 'v2', order: 2),
    _vol('v3', 500),
    _ch('c5', 510, parentId: 'v3', order: 1),
    _ch('c6', 610, parentId: 'v3', order: 2),
    _ch('c7', 700, order: 3),
  ];

  group('M3.3 目录索引', () {
    test('1. 当前 offset 映射到正确 chapter', () {
      expect(TocIndexLogic.currentChapterFor(150, toc)?.id, 'c2');
      expect(TocIndexLogic.currentChapterFor(399, toc)?.id, 'c3');
      expect(TocIndexLogic.currentChapterFor(600, toc)?.id, 'c5');
      expect(TocIndexLogic.currentChapterFor(750, toc)?.id, 'c7');
    });

    test('2. 第一章前位置 → null（调用方回退第一项）', () {
      expect(TocIndexLogic.currentChapterFor(0, toc), isNull);
      expect(TocIndexLogic.currentChapterFor(5, toc), isNull);
    });

    test('3. 最后一章', () {
      expect(TocIndexLogic.currentChapterFor(100000, toc)?.id, 'c7');
    });

    test('4. 无章节 → null（调用方显示全文）', () {
      final noChapters = [_vol('v1', 0)];
      expect(TocIndexLogic.currentChapterFor(50, noChapters), isNull);
      expect(TocIndexLogic.currentChapterFor(50, const []), isNull);
    });

    test('5. 当前 chapter 父卷自动展开（全部父级）', () {
      // 多级：v0 > v1 > c1（构造嵌套父级）
      final nested = [
        _vol('v0', 0),
        _vol('v1', 1, parentId: 'v0'),
        _ch('c1', 10, parentId: 'v1'),
        _ch('c2', 20, parentId: 'v0'),
      ];
      // c1 的父级链：v1 → v0
      expect(TocIndexLogic.parentVolumeIdsOf('c1', nested), ['v1', 'v0']);
      // c2 的父级链：v0
      expect(TocIndexLogic.parentVolumeIdsOf('c2', nested), ['v0']);
      // 无父级
      expect(TocIndexLogic.parentVolumeIdsOf('c1', toc), ['v1']);
      expect(TocIndexLogic.parentVolumeIdsOf(null, toc), isEmpty);
    });

    test('6. 展开后 visibleIndex 重新计算', () {
      // 全展开：v1,c1,c2,v2,c3,c4,v3,c5,c6,c7 → c5 下标 7
      final all = TocIndexLogic.visibleEntries(toc, {});
      expect(TocIndexLogic.visibleIndexFor('c5', all), 7);
      // 折叠 v3：v1,c1,c2,v2,c3,c4,v3,c7 → c5 隐藏
      final collapsed = TocIndexLogic.visibleEntries(toc, {'v3'});
      expect(TocIndexLogic.visibleIndexFor('c5', collapsed), isNull);
      expect(TocIndexLogic.visibleIndexFor('c7', collapsed), 7);
    });

    test('7. 折叠前后索引变化', () {
      final before = TocIndexLogic.visibleEntries(toc, {});
      final after = TocIndexLogic.visibleEntries(toc, {'v2'});
      // c4 在折叠后不可见
      expect(TocIndexLogic.visibleIndexFor('c4', before), 5);
      expect(TocIndexLogic.visibleIndexFor('c4', after), isNull);
      // 折叠后后续项下标前移（c5: 7 → 5）
      expect(TocIndexLogic.visibleIndexFor('c5', after), 5);
    });

    test('8. 远距离第400章索引', () {
      // 400 章平铺（无卷）
      final flat = [for (var i = 1; i <= 400; i++) _ch('ch$i', i * 1000)];
      final visible = TocIndexLogic.visibleEntries(flat, {});
      expect(TocIndexLogic.visibleIndexFor('ch400', visible), 399);
      // 当前章节为 ch400
      expect(
        TocIndexLogic.currentChapterFor(400 * 1000 + 50, flat)?.id,
        'ch400',
      );
    });

    test('9. visibleIndexFor 对不存在条目返回 null', () {
      final visible = TocIndexLogic.visibleEntries(toc, {});
      expect(TocIndexLogic.visibleIndexFor('nope', visible), isNull);
      expect(TocIndexLogic.visibleIndexFor(null, visible), isNull);
    });
  });
}
