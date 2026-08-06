import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';

void main() {
  group('ReaderBlockIndex.build', () {
    test('空文本 → 0 块', () {
      final idx = ReaderBlockIndex.build(text: '', targetBlockSize: 4096);
      expect(idx.blockCount, 0);
      expect(idx.textLength, 0);
    });

    test('正常文本：块连续、无重叠、无遗漏、首 0 尾全文长', () {
      final text = '第一章 开端\n' * 200; // 1400 字符
      final idx = ReaderBlockIndex.build(text: text, targetBlockSize: 512);
      expect(idx.blockCount, greaterThan(1));
      expect(idx.blocks.first.startCharacterOffset, 0);
      expect(idx.blocks.last.endCharacterOffset, text.length);
      for (var i = 0; i < idx.blockCount; i++) {
        final b = idx.blocks[i];
        expect(b.length, greaterThan(0), reason: '块 $i 不能为空');
        if (i > 0) {
          expect(
            b.startCharacterOffset,
            idx.blocks[i - 1].endCharacterOffset,
            reason: '块 $i 起始必须接上一块末尾',
          );
        }
      }
    });

    test('块大小在目标范围内（不切中段超过 2 倍目标）', () {
      // 大量无换行的文本：无法按 LF 切分时允许超长，但应尽量接近目标
      final text = '汉' * 5000;
      final idx = ReaderBlockIndex.build(text: text, targetBlockSize: 512);
      expect(idx.blocks.length, greaterThan(1));
      // 无换行时：向后找不到 LF → 向前找不到 → 切在目标位置（含 surrogate 检查）
      // 所以块长应为 512 左右
      for (final b in idx.blocks) {
        expect(b.length, lessThanOrEqualTo(640), reason: '块 ${b.index} 长度异常');
      }
    });

    test('surrogate pair 不被切断', () {
      // 𠀀 = U+20000 = surrogate pair \uD840\uDC00
      final text = '𠀀𠀀𠀀𠀀𠀀𠀀𠀀𠀀' * 100; // 8 个 surrogate pairs 每段
      final idx = ReaderBlockIndex.build(text: text, targetBlockSize: 100);
      for (final b in idx.blocks) {
        final start = b.startCharacterOffset;
        final end = b.endCharacterOffset;
        // 起点不能在 low surrogate
        if (start > 0) {
          expect(
            isLowSurrogate(text.codeUnitAt(start)),
            isFalse,
            reason: '块起始不能在 low surrogate',
          );
        }
        if (end < text.length) {
          expect(
            isLowSurrogate(text.codeUnitAt(end)),
            isFalse,
            reason: '块结束不能在 low surrogate',
          );
        }
      }
      // 拼接后应还原原文
      final rebuilt = idx.blocks
          .map(
            (b) => text.substring(b.startCharacterOffset, b.endCharacterOffset),
          )
          .join();
      expect(rebuilt, text);
    });

    test('只有换行的文本', () {
      final text = '\n\n\n\n\n\n\n\n\n\n';
      final idx = ReaderBlockIndex.build(text: text, targetBlockSize: 4);
      expect(idx.blockCount, greaterThan(0));
      final rebuilt = idx.blocks
          .map(
            (b) => text.substring(b.startCharacterOffset, b.endCharacterOffset),
          )
          .join();
      expect(rebuilt, text);
    });

    test('超长单段（无换行超长文本）也能构建', () {
      final text = 'a' * 50000;
      final idx = ReaderBlockIndex.build(text: text, targetBlockSize: 4096);
      expect(idx.blockCount, greaterThan(1));
      expect(idx.blocks.last.endCharacterOffset, 50000);
    });

    test('blockForOffset 定位正确', () {
      final text = '0123456789' * 50; // 500 字符
      final idx = ReaderBlockIndex.build(text: text, targetBlockSize: 50);
      // 每块 50 字符
      for (var offset = 0; offset < text.length; offset += 7) {
        final b = idx.blockForOffset(offset);
        expect(b, isNotNull);
        expect(
          offset,
          inInclusiveRange(b!.startCharacterOffset, b.endCharacterOffset - 1),
          reason: 'offset $offset 应在块 ${b.index} 内',
        );
      }
    });

    test('blockForOffset 越界 clamp', () {
      final text = '0123456789' * 5;
      final idx = ReaderBlockIndex.build(text: text, targetBlockSize: 50);
      expect(idx.blockForOffset(-5), idx.blocks.first);
      expect(idx.blockForOffset(text.length + 100), idx.blocks.last);
      expect(idx.blockForOffset(text.length), idx.blocks.last);
    });

    test('块索引确定性：相同输入相同结果', () {
      final text = '第一章\n正文内容\n' * 300;
      final a = ReaderBlockIndex.build(text: text, targetBlockSize: 4096);
      final b = ReaderBlockIndex.build(text: text, targetBlockSize: 4096);
      expect(a.blocks.length, b.blocks.length);
      for (var i = 0; i < a.blocks.length; i++) {
        expect(
          a.blocks[i].startCharacterOffset,
          b.blocks[i].startCharacterOffset,
        );
        expect(a.blocks[i].endCharacterOffset, b.blocks[i].endCharacterOffset);
      }
    });
  });
}

bool isLowSurrogate(int codeUnit) => codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
