import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';

void main() {
  group('clampLocatorOffset', () {
    test('正常偏移不 clamp', () {
      const text = 'abcde';
      final r = clampLocatorOffset(
        requested: 2,
        normalizedLength: 5,
        text: text,
      );
      expect(r.clamped, 2);
      expect(r.wasClamped, isFalse);
    });

    test('负偏移 clamp 到 0', () {
      const text = 'abcde';
      final r = clampLocatorOffset(
        requested: -10,
        normalizedLength: 5,
        text: text,
      );
      expect(r.clamped, 0);
      expect(r.wasClamped, isTrue);
      expect(r.clampedFrom, -10);
    });

    test('超长偏移 clamp 到末尾', () {
      const text = 'abcde';
      final r = clampLocatorOffset(
        requested: 100,
        normalizedLength: 5,
        text: text,
      );
      expect(r.clamped, 5);
      expect(r.wasClamped, isTrue);
      expect(r.clampedTo, 100);
    });

    test('末尾边界（offset == length）不 clamp', () {
      const text = 'abcde';
      final r = clampLocatorOffset(
        requested: 5,
        normalizedLength: 5,
        text: text,
      );
      expect(r.clamped, 5);
      expect(r.wasClamped, isFalse);
    });

    test('落在 surrogate pair 中间时回退一个码元', () {
      // 𠀀 = U+20000 = \uD840\uDC00（2 个码元）
      final text = 'a\uD840\uDC00b'; // 4 码元: a, hi, lo, b
      // offset 2 = low surrogate 位置
      final r = clampLocatorOffset(
        requested: 2,
        normalizedLength: 4,
        text: text,
      );
      expect(r.clamped, 1, reason: 'low surrogate 中间应回退到 high surrogate 之前');
      expect(r.wasClamped, isTrue);
    });

    test('边界 clamp 不切 surrogate', () {
      final text = '\uD840\uDC00\uD840\uDC00'; // 4 码元
      // clamp 到 4（末尾）合法
      final r = clampLocatorOffset(
        requested: 10,
        normalizedLength: 4,
        text: text,
      );
      expect(r.clamped, 4);
    });
  });

  group('ReaderLocator', () {
    test('copyWith 保留未指定字段', () {
      const loc = ReaderLocator(
        collectionId: 'c1',
        absoluteCharacterOffset: 10,
        itemIdHint: 'h',
      );
      final c = loc.copyWith(absoluteCharacterOffset: 20);
      expect(c.collectionId, 'c1');
      expect(c.absoluteCharacterOffset, 20);
      expect(c.itemIdHint, 'h');
    });

    test('copyWith clearItemIdHint 清空', () {
      const loc = ReaderLocator(
        collectionId: 'c1',
        absoluteCharacterOffset: 10,
        itemIdHint: 'h',
      );
      final c = loc.copyWith(clearItemIdHint: true);
      expect(c.itemIdHint, isNull);
    });

    test('相等性：仅比较 collectionId + offset', () {
      const a = ReaderLocator(
        collectionId: 'c1',
        absoluteCharacterOffset: 10,
        itemIdHint: 'x',
      );
      const b = ReaderLocator(
        collectionId: 'c1',
        absoluteCharacterOffset: 10,
        itemIdHint: 'y',
      );
      const c = ReaderLocator(
        collectionId: 'c1',
        absoluteCharacterOffset: 11,
        itemIdHint: 'x',
      );
      expect(a, b);
      expect(a == c, isFalse);
    });
  });
}
