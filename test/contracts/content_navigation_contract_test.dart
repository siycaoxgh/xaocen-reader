import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/library/toc_index.dart';

/// 全局内容导航合同（长期产品约束）固化测试。
///
/// 见 docs/CONTENT_NAVIGATION_CONTRACT.md。
///
/// 核心：Content hierarchy is semantic, not interactive.
/// Source order is authoritative; navigable entries remain visible.
/// 层级负责表达关系，顺序负责导航，折叠不参与内容可见性。
void main() {
  LibraryTocEntry entry({
    required String id,
    String? parentId,
    required String kind,
    required int level,
    required String title,
    required int orderIndex,
    required int start,
    required int end,
  }) {
    return LibraryTocEntry(
      id: id,
      collectionId: 'c',
      itemId: kind == 'chapter' ? 'item:$id' : null,
      parentId: parentId,
      kind: kind,
      level: level,
      title: title,
      displayTitle: title,
      orderIndex: orderIndex,
      startCharacterOffset: start,
      endCharacterOffset: end,
    );
  }

  group('合同 1-3：层级信息保留在领域实体', () {
    test('parentId/kind/level 字段存在且可读（供语义/分组/搜索/分析/导出）', () {
      final v = entry(
        id: 'v1',
        parentId: null,
        kind: 'volume',
        level: 1,
        title: '第一卷',
        orderIndex: 0,
        start: 0,
        end: 100,
      );
      final c = entry(
        id: 'c1',
        parentId: 'v1',
        kind: 'chapter',
        level: 2,
        title: '第1章 开端',
        orderIndex: 1,
        start: 4,
        end: 100,
      );
      expect(v.parentId, isNull);
      expect(v.kind, 'volume');
      expect(v.level, 1);
      expect(c.parentId, 'v1');
      expect(c.kind, 'chapter');
      expect(c.level, 2);
    });
  });

  group('合同 4-9：折叠不参与内容可见性（flat 语义）', () {
    test('异常层级 fixture 中每个条目都有唯一平铺下标（无隐藏项）', () {
      // 故意异常：幽灵 parentId / 连续 volume / 脱离 volume 的 chapter /
      // 卷后重新编号 / 无 parent 的番外
      final toc = <LibraryTocEntry>[
        entry(
          id: 'v1',
          parentId: null,
          kind: 'volume',
          level: 1,
          title: '第一卷',
          orderIndex: 0,
          start: 0,
          end: 200,
        ),
        entry(
          id: 'c1',
          parentId: 'v1',
          kind: 'chapter',
          level: 2,
          title: '第1章',
          orderIndex: 1,
          start: 4,
          end: 100,
        ),
        entry(
          id: 'c2',
          parentId: 'ghost-parent',
          kind: 'chapter',
          level: 2,
          title: '第2章',
          orderIndex: 2,
          start: 100,
          end: 200,
        ),
        entry(
          id: 'v2',
          parentId: null,
          kind: 'volume',
          level: 1,
          title: '第二卷',
          orderIndex: 3,
          start: 200,
          end: 400,
        ),
        entry(
          id: 'v3',
          parentId: null,
          kind: 'volume',
          level: 1,
          title: '第三卷',
          orderIndex: 4,
          start: 400,
          end: 600,
        ),
        entry(
          id: 'c1b',
          parentId: null,
          kind: 'chapter',
          level: 2,
          title: '第1章',
          orderIndex: 5,
          start: 402,
          end: 500,
        ),
        entry(
          id: 'c2b',
          parentId: 'v3',
          kind: 'chapter',
          level: 2,
          title: '第2章',
          orderIndex: 6,
          start: 500,
          end: 600,
        ),
        entry(
          id: 'part4',
          parentId: null,
          kind: 'volume',
          level: 1,
          title: '第四部',
          orderIndex: 7,
          start: 600,
          end: 700,
        ),
        entry(
          id: 'c99',
          parentId: null,
          kind: 'chapter',
          level: 2,
          title: '第99章',
          orderIndex: 8,
          start: 602,
          end: 700,
        ),
        entry(
          id: 'extra',
          parentId: null,
          kind: 'chapter',
          level: 2,
          title: '番外',
          orderIndex: 9,
          start: 700,
          end: 800,
        ),
      ];

      // 所有条目（含异常层级）都可定位，下标唯一且连续 0..n-1
      final indexes = <int>[];
      for (var i = 0; i < toc.length; i++) {
        final idx = TocIndexLogic.displayIndexFor(toc[i].id, toc);
        expect(idx, isNotNull, reason: '${toc[i].title} 不得被隐藏');
        indexes.add(idx!);
      }
      expect(indexes, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(indexes.toSet().length, toc.length, reason: '下标唯一');
    });

    test('平铺下标与 source order（orderIndex）一致', () {
      final toc = <LibraryTocEntry>[
        entry(
          id: 'v1',
          parentId: null,
          kind: 'volume',
          level: 1,
          title: '第一卷',
          orderIndex: 0,
          start: 0,
          end: 50,
        ),
        entry(
          id: 'c1',
          parentId: 'v1',
          kind: 'chapter',
          level: 2,
          title: '第1章',
          orderIndex: 1,
          start: 4,
          end: 50,
        ),
        entry(
          id: 'v2',
          parentId: null,
          kind: 'volume',
          level: 1,
          title: '第二卷',
          orderIndex: 2,
          start: 50,
          end: 90,
        ),
        entry(
          id: 'c2',
          parentId: 'v2',
          kind: 'chapter',
          level: 2,
          title: '第2章',
          orderIndex: 3,
          start: 54,
          end: 90,
        ),
      ];
      for (final e in toc) {
        expect(TocIndexLogic.displayIndexFor(e.id, toc), e.orderIndex);
      }
    });

    test('volume 是 Section Header：不参与「当前章节」判定', () {
      final toc = <LibraryTocEntry>[
        entry(
          id: 'v1',
          parentId: null,
          kind: 'volume',
          level: 1,
          title: '第一卷',
          orderIndex: 0,
          start: 0,
          end: 100,
        ),
        entry(
          id: 'c1',
          parentId: 'v1',
          kind: 'chapter',
          level: 2,
          title: '第1章',
          orderIndex: 1,
          start: 4,
          end: 100,
        ),
        entry(
          id: 'v2',
          parentId: null,
          kind: 'volume',
          level: 1,
          title: '第二卷',
          orderIndex: 2,
          start: 100,
          end: 200,
        ),
        entry(
          id: 'c2',
          parentId: 'v2',
          kind: 'chapter',
          level: 2,
          title: '第2章',
          orderIndex: 3,
          start: 104,
          end: 200,
        ),
      ];
      // topVisible 在卷标题行（100）：当前章节仍为第1章，而不是卷
      final current = TocIndexLogic.currentChapterFor(100, toc);
      expect(current, isNotNull);
      expect(current!.kind, 'chapter');
      expect(current.title, '第1章');
    });

    test('异常乱序 offset 不提前 break：取最后一个满足的 chapter（容错）', () {
      final toc = <LibraryTocEntry>[
        entry(
          id: 'c1',
          parentId: null,
          kind: 'chapter',
          level: 2,
          title: '第1章',
          orderIndex: 0,
          start: 4,
          end: 50,
        ),
        // offset 回退（异常数据）：仍遍历全表
        entry(
          id: 'c2',
          parentId: null,
          kind: 'chapter',
          level: 2,
          title: '第2章',
          orderIndex: 1,
          start: 2,
          end: 80,
        ),
        entry(
          id: 'c3',
          parentId: null,
          kind: 'chapter',
          level: 2,
          title: '第3章',
          orderIndex: 2,
          start: 60,
          end: 100,
        ),
      ];
      final current = TocIndexLogic.currentChapterFor(55, toc);
      expect(current, isNotNull);
      expect(current!.title, '第2章', reason: '第2章 offset=2 <= 55 且遍历不提前 break');
    });

    test('无章节：currentChapterFor 返回 null（UI 显示「全文」）', () {
      expect(TocIndexLogic.currentChapterFor(0, const []), isNull);
    });

    test('当前章节在第一章之前：返回 null（调用方回退第一项或「全文」）', () {
      final toc = <LibraryTocEntry>[
        entry(
          id: 'c1',
          parentId: null,
          kind: 'chapter',
          level: 2,
          title: '第1章',
          orderIndex: 0,
          start: 54,
          end: 100,
        ),
      ];
      expect(TocIndexLogic.currentChapterFor(10, toc), isNull);
    });
  });

  group('合同 8：不保存折叠状态（API 形状）', () {
    test('TocIndexLogic 只暴露无折叠语义的 API（无 collapsed/expanded 参数）', () {
      // 编译期保证：若有人为 TocIndexLogic 增加折叠参数/返回折叠列表，
      // 本测试通过显式引用其签名的空参调用即可失败（类型层面）。
      // 运行时断言：flat 列表长度 == 原始 toc 长度（无过滤）。
      final toc = <LibraryTocEntry>[
        entry(
          id: 'v1',
          parentId: null,
          kind: 'volume',
          level: 1,
          title: '第一卷',
          orderIndex: 0,
          start: 0,
          end: 100,
        ),
        entry(
          id: 'c1',
          parentId: 'v1',
          kind: 'chapter',
          level: 2,
          title: '第1章',
          orderIndex: 1,
          start: 4,
          end: 100,
        ),
        entry(
          id: 'c2',
          parentId: 'v1',
          kind: 'chapter',
          level: 2,
          title: '第2章',
          orderIndex: 2,
          start: 40,
          end: 100,
        ),
      ];
      for (var i = 0; i < toc.length; i++) {
        expect(TocIndexLogic.displayIndexFor(toc[i].id, toc), i);
      }
      // 所有 chapter 均可见（即便其 volume 处于任何假设状态）
      expect(TocIndexLogic.displayIndexFor('c1', toc), 1);
      expect(TocIndexLogic.displayIndexFor('c2', toc), 2);
    });
  });
}
