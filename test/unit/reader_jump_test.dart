import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';
import 'package:xaocen_reader/reader/reader_text_block.dart';

/// M3.2 Reader 对齐测试（任务书 §十三 Reader 测试的块/字符层部分）。
///
/// 核心：RenderReaderTextBlock 的 local offset → 行 Rect 映射，
/// 多章节同块定位、块末、surrogate、空文本等边界。
void main() {
  const style = TextStyle(fontSize: 17, height: 1.7, color: Color(0xFF222222));

  RenderReaderTextBlock buildBlock(String text, {double width = 300}) {
    final block = RenderReaderTextBlock(
      text: text,
      style: style,
      styleVersion: 1,
      textDirection: TextDirection.ltr,
      maxWidth: width,
    );
    block.layout(BoxConstraints(maxWidth: width));
    return block;
  }

  group('M3.2 块内字符对齐', () {
    test('1. 目标 offset 行 Rect 可解析（标题行在块中间）', () {
      // 多行文本：标题行 + 正文
      final text = '第1章 开端\n正文内容第一行\n正文内容第二行\n';
      final block = buildBlock(text);
      expect(block.layoutCompleted, isTrue);
      // 标题行首 offset=0
      final rect0 = block.rectForCharacterOffset(0);
      expect(rect0, isNotNull);
      // 第二行行首（第1章 开端\n = 6 字符 + 1 换行 = 7）
      final rect7 = block.rectForCharacterOffset(7);
      expect(rect7, isNotNull);
      // 不同行的 rect.top 不同
      expect(rect7!.top, greaterThan(rect0!.top));
    });

    test('2. 多章节位于同一 block 时仍能定位各自标题', () {
      final text = '第1章 开端\n正文一\n第2章 发展\n正文二\n第3章 结局\n';
      final block = buildBlock(text);
      // 第2章 行首 = 第1章 开端(5) + \n(1) + 正文一(3) + \n(1) = 10
      final rectCh2 = block.rectForCharacterOffset(10);
      expect(rectCh2, isNotNull);
      // 第3章 行首 = 10 + 第2章 发展(5) + \n(1) + 正文二(3) + \n(1) = 20
      final rectCh3 = block.rectForCharacterOffset(20);
      expect(rectCh3, isNotNull);
      expect(rectCh3!.top, greaterThan(rectCh2!.top));
    });

    test('3. 目标在 block 末尾时正确', () {
      final text = '第1章 开端\n正文最后一行';
      final block = buildBlock(text);
      final rect = block.rectForCharacterOffset(text.length);
      expect(rect, isNotNull);
    });

    test('4. surrogate pair 中间位置不崩溃（clamp 到合法范围）', () {
      final text = '第1章 开端\n正文𠀀𠀀\n';
      final block = buildBlock(text);
      // 在 surrogate 内部的位置（正文中 𠀀 是 4 字节 → 2 个 UTF-16 码元）
      // 不精确指向 surrogate 中间，但确保不越界不崩溃
      for (var i = 0; i <= text.length; i++) {
        final rect = block.rectForCharacterOffset(i);
        expect(rect, isNotNull, reason: 'offset $i 应可解析');
      }
    });

    test('5. 空文本 block 不崩溃', () {
      final block = buildBlock('');
      expect(block.rectForCharacterOffset(0), isNotNull);
      expect(block.characterOffsetAtLocalY(0), 0);
    });

    test('6. 越界 offset 返回 null（不崩溃）', () {
      final block = buildBlock('第1章 开端\n');
      expect(block.rectForCharacterOffset(100), isNull);
      expect(block.rectForCharacterOffset(-1), isNull);
    });

    test('7. 本地 y 坐标 → 字符偏移映射', () {
      final text = '第1章 开端\n正文内容\n';
      final block = buildBlock(text);
      // y=0 → offset 0
      expect(block.characterOffsetAtLocalY(0), 0);
      // 非常大的 y → clamp 到末尾附近
      final off = block.characterOffsetAtLocalY(100000);
      expect(off, greaterThanOrEqualTo(0));
      expect(off, lessThanOrEqualTo(text.length));
    });
  });

  group('M3.2 ReaderBlockIndex 定位', () {
    test('8. blockForOffset 覆盖全文（多章同块）', () {
      final text = StringBuffer();
      for (var i = 0; i < 20; i++) {
        text.write('第${i + 1}章 标题$i\n');
        for (var j = 0; j < 30; j++) {
          text.write('正文内容段落第$j 行，汉字混排𠀀𠀀𠀀。\n');
        }
      }
      final index = ReaderBlockIndex.build(
        text: text.toString(),
        targetBlockSize: 4096,
      );
      expect(index.blockCount, greaterThan(1));
      // 每个 block 的 offset 连续、无遗漏
      var expected = 0;
      for (final b in index.blocks) {
        expect(b.startCharacterOffset, expected);
        expected = b.endCharacterOffset;
      }
      expect(expected, text.length);
      // 任意 offset 都能定位
      for (var off = 0; off < text.length; off += 137) {
        final b = index.blockForOffset(off);
        expect(b, isNotNull);
        expect(off, greaterThanOrEqualTo(b!.startCharacterOffset));
        expect(off, lessThanOrEqualTo(b.endCharacterOffset));
      }
    });

    test('9. 目标 offset 所在 block 定位（block 中间）', () {
      final body = '正文内容\n' * 200;
      final text = '第1章 开端\n$body第2章 发展\n$body';
      final index = ReaderBlockIndex.build(text: text, targetBlockSize: 4096);
      // 第2章 offset
      final ch2Offset = '第1章 开端\n'.length + '正文内容\n'.length * 200;
      final b = index.blockForOffset(ch2Offset);
      expect(b, isNotNull);
      expect(
        ch2Offset,
        inInclusiveRange(b!.startCharacterOffset, b.endCharacterOffset),
      );
    });

    test('10. 块边界不切 surrogate pair', () {
      // 构造大段含 𠀀 的文本
      final sb = StringBuffer('第1章 开端\n');
      for (var i = 0; i < 3000; i++) {
        sb.write('𠀀正文𠀀\n');
      }
      final index = ReaderBlockIndex.build(
        text: sb.toString(),
        targetBlockSize: 4096,
      );
      for (final b in index.blocks) {
        final start = b.startCharacterOffset;
        final end = b.endCharacterOffset;
        if (start > 0) {
          final prev = sb.toString().codeUnitAt(start - 1);
          expect(
            prev >= 0xD800 && prev <= 0xDBFF,
            isFalse,
            reason: 'block start 不能在 high surrogate 之后',
          );
        }
        expect(start, lessThanOrEqualTo(end));
      }
    });

    test('11. 最后一章无法置顶时仍可见（block 内 offset 解析不失败）', () {
      final text = '第1章 开端\n${'正文内容\n' * 5000}';
      final index = ReaderBlockIndex.build(text: text, targetBlockSize: 4096);
      final last = index.blocks.last;
      // 末 block 末尾的字符 offset 可解析（对应"最后一章"场景）
      final block = buildBlock(
        text.substring(last.startCharacterOffset, last.endCharacterOffset),
      );
      final off = last.endCharacterOffset - last.startCharacterOffset;
      final rect = block.rectForCharacterOffset(off);
      expect(rect, isNotNull);
    });
  });
}
