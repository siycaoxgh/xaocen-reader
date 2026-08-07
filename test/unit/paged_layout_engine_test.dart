/// PagedLayoutEngine 单元测试（M4 §四十一）。
///
/// 使用 flutter_test 的 Ahem 字体（每字形 = fontSize 方块）保证确定性：
/// fontSize 10、width 100、无 padding → 每行 10 字符、每页 10 行 = 100 字符。
library;

// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/paged_text_range.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';
import 'package:xaocen_reader/reader/paged_layout_engine.dart';

const _style = TextStyle(fontSize: 10, height: 1.0);

PagedLayoutEngine _engine(
  String text, {
  double width = 100,
  double height = 100,
}) {
  return PagedLayoutEngine(
    text: text,
    style: _style,
    textDirection: TextDirection.ltr,
    width: width,
    height: height,
    horizontalPadding: 0,
    verticalPadding: 0,
  );
}

/// 页面边界不切 surrogate pair。
bool _noSurrogateSplit(String text, PagedTextRange p) {
  final e = p.endCharacterOffset;
  if (e > 0 && e < text.length) {
    final cu = text.codeUnitAt(e);
    if (cu >= 0xDC00 &&
        cu <= 0xDFFF &&
        text.codeUnitAt(e - 1) >= 0xD800 &&
        text.codeUnitAt(e - 1) <= 0xDBFF) {
      return false;
    }
  }
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('正向分页（§41-1 forward continuity）', () {
    test('纯文本每页 100 字符且连续', () {
      final e = _engine('a' * 1000);
      final pages = <PagedTextRange>[];
      var p = e.layoutForwardPage(0);
      while (p != null) {
        pages.add(p);
        p = e.layoutForwardPage(p.endCharacterOffset);
      }
      expect(pages.length, 10);
      expect(pages.first.startCharacterOffset, 0);
      expect(pages.last.endCharacterOffset, 1000);
      for (var i = 0; i < pages.length; i++) {
        expect(pages[i].length, 100, reason: '第 $i 页应为 100 字符');
        if (i > 0) {
          expect(
            pages[i].startCharacterOffset,
            pages[i - 1].endCharacterOffset,
            reason: '页面必须连续不重不漏',
          );
        }
      }
    });

    test('无遗漏覆盖全文', () {
      final e = _engine('a' * 1000);
      var p = e.layoutForwardPage(0);
      var prevEnd = 0;
      while (p != null) {
        expect(p.startCharacterOffset, prevEnd);
        prevEnd = p.endCharacterOffset;
        p = e.layoutForwardPage(p.endCharacterOffset);
      }
      expect(prevEnd, 1000);
    });
  });

  group('反向分页（§41-2/3 backward + symmetry）', () {
    test('backward.end == 传入 end', () {
      final e = _engine('a' * 1000);
      final prev = e.layoutPreviousPage(500)!;
      expect(prev.endCharacterOffset, 500);
      expect(prev.startCharacterOffset, 400);
    });

    test('100 页前进 → 100 页回退完全对称（字符链连续）', () {
      final e = _engine('a' * 10000);
      final pages = <PagedTextRange>[];
      var p = e.layoutForwardPage(0);
      for (var i = 0; i < 100 && p != null; i++) {
        pages.add(p);
        p = e.layoutForwardPage(p.endCharacterOffset);
      }
      expect(pages.length, 100);
      // 回退 100 页
      var q = pages.last;
      for (var i = pages.length - 2; i >= 0; i--) {
        q = e.layoutPreviousPage(q.startCharacterOffset)!;
        expect(q, pages[i], reason: '第 $i 页回退不对称：$q vs ${pages[i]}');
      }
      expect(q.startCharacterOffset, 0);
    });

    test('prev/next 反复往返不漂移', () {
      final e = _engine('a' * 5000);
      final p5 = e.layoutForwardPage(0)!;
      var p = p5;
      for (var i = 0; i < 30; i++) {
        p = e.layoutForwardPage(p.endCharacterOffset)!;
      }
      // 回退 30 页再前进 30 页
      var q = p;
      for (var i = 0; i < 30; i++) {
        q = e.layoutPreviousPage(q.startCharacterOffset)!;
      }
      expect(q, p5);
      var r = q;
      for (var i = 0; i < 30; i++) {
        r = e.layoutForwardPage(r.endCharacterOffset)!;
      }
      expect(r, p);
    });
  });

  group('边界（§41-4/5/6/7）', () {
    test('document start：previous(0) 为 null；首页 start=0', () {
      final e = _engine('a' * 100);
      expect(e.layoutPreviousPage(0), isNull);
      expect(e.layoutForwardPage(0)!.startCharacterOffset, 0);
    });

    test('document end：末页 end=len；forward(len) 为 null', () {
      final e = _engine('a' * 1000);
      final last = e.layoutForwardPage(950)!;
      expect(last.endCharacterOffset, 1000);
      expect(e.layoutForwardPage(1000), isNull);
    });

    test('empty text：null / 空页', () {
      final e = _engine('');
      expect(e.layoutForwardPage(0), isNull);
      expect(e.layoutPreviousPage(0), isNull);
      final c = e.pageContaining(0);
      expect(c, isNotNull);
      expect(c!.length, 0);
    });

    test('short text：整块一页', () {
      final e = _engine('hello');
      final p = e.layoutForwardPage(0)!;
      expect(p.startCharacterOffset, 0);
      expect(p.endCharacterOffset, 5);
    });
  });

  group('长段落 / 换行 / surrogate（§41-8/9/10）', () {
    test('long paragraph（5000 字符无换行）连续且不切 surrogate', () {
      final e = _engine('a' * 5000);
      var p = e.layoutForwardPage(0);
      var prevEnd = 0;
      var count = 0;
      while (p != null) {
        expect(p.startCharacterOffset, prevEnd);
        expect(_noSurrogateSplit('a' * 5000, p), isTrue);
        prevEnd = p.endCharacterOffset;
        p = e.layoutForwardPage(p.endCharacterOffset);
        count++;
      }
      expect(prevEnd, 5000);
      expect(count, 50);
    });

    test('CR/LF 规范化文本：行边界分页连续', () {
      final text = '第1章 开端\n' + ('正文内容abc\n' * 60) + '结尾\n';
      final e = _engine(text);
      final pages = <PagedTextRange>[];
      var p = e.layoutForwardPage(0);
      while (p != null) {
        pages.add(p);
        p = e.layoutForwardPage(p.endCharacterOffset);
      }
      expect(pages.last.endCharacterOffset, text.length);
      for (var i = 1; i < pages.length; i++) {
        expect(pages[i].startCharacterOffset, pages[i - 1].endCharacterOffset);
      }
    });

    test('surrogate pair（𠀀）不被页面边界拆开', () {
      final text = 'a' * 95 + '\uD840\uDC00' + 'b' * 400;
      final e = _engine(text);
      var p = e.layoutForwardPage(0);
      while (p != null) {
        expect(
          _noSurrogateSplit(text, p),
          isTrue,
          reason: '页面 $p 切开了 surrogate pair',
        );
        p = e.layoutForwardPage(p.endCharacterOffset);
      }
      // backward 同理
      var q = e.layoutPreviousPage(text.length)!;
      while (q.startCharacterOffset > 0) {
        expect(_noSurrogateSplit(text, q), isTrue);
        q = e.layoutPreviousPage(q.startCharacterOffset)!;
      }
    });
  });

  group('offset → page（§41-11/12/13）', () {
    test('pageContaining 覆盖目标且不从 0 逐页排（用 blockIndex 锚定）', () {
      final text = 'a' * 20000;
      final e = _engine(text);
      final bi = ReaderBlockIndex.build(text: text, targetBlockSize: 6144);
      final p = e.pageContaining(7958, blockIndex: bi)!;
      expect(p.startCharacterOffset <= 7958, isTrue);
      expect(p.endCharacterOffset > 7958, isTrue);
      expect(p.length, lessThanOrEqualTo(100));
    });

    test('page contains target（无 blockIndex 回退 anchor=0）', () {
      final e = _engine('a' * 1000);
      final p = e.pageContaining(250)!;
      expect(p.startCharacterOffset <= 250, isTrue);
      expect(250 < p.endCharacterOffset, isTrue);
    });

    test('exact TOC anchor：目标在页内且页首可早于目标', () {
      final text = '第一章 开头\n' + 'a' * 300 + '\n第二章 中间\n' + 'b' * 300;
      final e = _engine(text);
      final target = text.indexOf('第二章 中间');
      final p = e.pageContaining(target)!;
      expect(p.startCharacterOffset <= target, isTrue);
      expect(target < p.endCharacterOffset, isTrue);
      // 页面开头可以早于 target（§十七）
      expect(p.startCharacterOffset <= target, isTrue);
    });
  });

  group('确定性 / cache key（§41-15/16/17/18/19）', () {
    test('同参数重复执行结果一致（确定性）', () {
      final e = _engine('a' * 500);
      final p1 = e.layoutForwardPage(0)!;
      final p2 = e.layoutForwardPage(0)!;
      expect(p1, p2);
      expect(e.signature.cacheKey, e.signature.cacheKey);
    });

    test('layout signature：尺寸/样式变化使 key 变化', () {
      final a = _engine('x', width: 100).signature.cacheKey;
      final b = _engine('x', width: 200).signature.cacheKey;
      expect(a, isNot(b));
      final e2 = PagedLayoutEngine(
        text: 'x',
        style: const TextStyle(fontSize: 20),
        textDirection: TextDirection.ltr,
        width: 100,
        height: 100,
      );
      expect(e2.signature.cacheKey, isNot(a));
    });

    test('theme color-only 不改变签名（§三十二）', () {
      final s1 = textStyleMetricsKey(
        const TextStyle(fontSize: 10, color: Colors.black),
      );
      final s2 = textStyleMetricsKey(
        const TextStyle(fontSize: 10, color: Colors.white),
      );
      expect(s1, s2);
    });

    test('resize 后页大小变化（重分页语义）', () {
      final narrow = _engine('a' * 500, width: 50); // 每行 5 字符
      final wide = _engine('a' * 500, width: 100); // 每行 10 字符
      expect(narrow.layoutForwardPage(0)!.length, 50);
      expect(wide.layoutForwardPage(0)!.length, 100);
    });

    test('orientation 等价：宽高互换产生不同页（对应重分页）', () {
      final portrait = _engine('a' * 2000, width: 100, height: 200);
      final landscape = _engine('a' * 2000, width: 200, height: 100);
      final pp = portrait.layoutForwardPage(0)!;
      final lp = landscape.layoutForwardPage(0)!;
      // 100x200：每行 10 字符 × 20 行 = 200/页
      // 200x100：每行 20 字符 × 10 行 = 200/页 —— 相同大小但不同签名
      expect(pp.length, 200);
      expect(lp.length, 200);
      expect(portrait.signature.cacheKey, isNot(landscape.signature.cacheKey));
    });
  });
}
