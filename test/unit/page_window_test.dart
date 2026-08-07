/// PageWindow 单元测试（M4 §41-14 eviction 等）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/paged_text_range.dart';
import 'package:xaocen_reader/reader/page_window.dart';

PagedTextRange _page(int start, int end) =>
    PagedTextRange(startCharacterOffset: start, endCharacterOffset: end);

void main() {
  group('PageWindow（§14）', () {
    test('reset：单页窗口', () {
      final w = PageWindow(previousCount: 2, nextCount: 3);
      w.reset(_page(0, 100), docLength: 10000);
      expect(w.pageCount, 1);
      expect(w.currentIndex, 0);
      expect(w.current, _page(0, 100));
    });

    test('goNext 连续翻页：窗口保持有限并淘汰远端', () {
      final w = PageWindow(previousCount: 2, nextCount: 3);
      w.reset(_page(0, 100), docLength: 100000);
      for (var i = 1; i <= 20; i++) {
        final ok = w.goNext(_page(i * 100, (i + 1) * 100));
        expect(ok, isTrue);
      }
      // 当前 = 第 20 页 [2000,2100)
      expect(w.current, _page(2000, 2100));
      // 窗口有限：current 前 ≤2、后 ≤3
      expect(w.pageCount, lessThanOrEqualTo(2 + 1 + 3));
      expect(w.currentIndex, lessThanOrEqualTo(2));
      // 头部淘汰：最早页已不在窗口
      expect(w.pageAt(0)!.startCharacterOffset, greaterThan(0));
    });

    test('goPrevious：窗口向前扩展', () {
      final w = PageWindow(previousCount: 2, nextCount: 3);
      w.reset(_page(500, 600), docLength: 100000);
      // 向后翻 5 页
      for (var i = 0; i < 5; i++) {
        w.goNext(_page(600 + i * 100, 700 + i * 100));
      }
      expect(w.current, _page(1000, 1100));
      // 向前翻 8 页回到开头附近
      for (var i = 0; i < 8; i++) {
        final c = w.current!;
        if (w.atDocumentStart) break;
        final ok = w.goPrevious(
          _page(c.startCharacterOffset - 100, c.startCharacterOffset),
        );
        expect(ok, isTrue);
      }
      expect(w.current, _page(200, 300));
      expect(w.pageCount, lessThanOrEqualTo(6));
    });

    test('atDocumentStart / atDocumentEnd', () {
      final w = PageWindow();
      w.reset(_page(0, 100), docLength: 10000);
      expect(w.atDocumentStart, isTrue);
      expect(w.atDocumentEnd, isFalse);
      w.reset(_page(9900, 10000), docLength: 10000);
      expect(w.atDocumentEnd, isTrue);
      w.reset(_page(100, 200), docLength: 10000);
      expect(w.atDocumentStart, isFalse);
      expect(w.atDocumentEnd, isFalse);
    });

    test('select：窗口内切换当前页', () {
      final w = PageWindow(previousCount: 2, nextCount: 3);
      w.reset(_page(0, 100), docLength: 100000);
      w.goNext(_page(100, 200));
      w.goNext(_page(200, 300));
      // 当前 [200,300) idx 2，窗口 [0,100),[100,200),[200,300)
      expect(w.current, _page(200, 300));
      // 窗口内选择较前页 [100,200)
      w.select(1);
      expect(w.current, _page(100, 200));
      expect(w.currentIndex, 1);
    });

    test('extendTail / extendHead + 后续 select 统一 trim', () {
      final w = PageWindow(previousCount: 2, nextCount: 3);
      w.reset(_page(0, 100), docLength: 100000);
      // 尾部扩展（不 select 前不 trim 新页）
      w.extendTail(_page(100, 200));
      expect(w.pageCount, 2);
      w.select(1); // 当前 = [100,200)
      expect(w.current, _page(100, 200));
      // 头部扩展
      w.extendHead(_page(0, 100));
      expect(w.currentIndex, 2); // [0,100) 插入后原页后移
      expect(w.current, _page(100, 200));
      w.select(1);
      expect(w.current, _page(0, 100));
    });

    test('maxObserved 记录历史最大窗口（扩展瞬间）', () {
      final w = PageWindow(previousCount: 2, nextCount: 3);
      w.reset(_page(0, 100), docLength: 100000);
      for (var i = 1; i <= 6; i++) {
        w.goNext(_page(i * 100, (i + 1) * 100));
      }
      expect(w.maxObserved, greaterThanOrEqualTo(4));
      expect(w.pageCount, lessThanOrEqualTo(6));
    });

    test('clear：清空窗口', () {
      final w = PageWindow();
      w.reset(_page(0, 100), docLength: 10000);
      w.goNext(_page(100, 200));
      w.clear();
      expect(w.pageCount, 0);
      expect(w.current, isNull);
    });
  });
}
