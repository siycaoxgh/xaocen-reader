import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/design/theme/app_theme.dart';
import 'package:xaocen_reader/reader/reader_appearance.dart';

/// P1：ReaderResolvedAppearance 解析 + 对比度验收（≥4.5:1）。
void main() {
  group('对比度工具', () {
    test('黑/白对比度为 21', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21.0, 0.5));
    });

    test('同色对比度为 1', () {
      expect(contrastRatio(Colors.grey, Colors.grey), 1.0);
    });

    test('正文可读性判断', () {
      expect(isReadable(Colors.black, Colors.white), isTrue);
      expect(isReadable(Colors.grey.shade400, Colors.white), isFalse);
    });

    test('低对比自定义颜色安全回退为可读前景色', () {
      final resolved = ensureReadableTextColor(
        const Color(0xffeeeeee),
        Colors.white,
      );
      expect(isReadable(resolved, Colors.white), isTrue);
      expect(resolved, Colors.black);
    });
  });

  group('P1 外观解析', () {
    testWidgets('1. 浅色 Theme：正文深色且可读（≥4.5:1）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final a = resolveReaderAppearance(tester.element(find.byType(Scaffold)));
      expect(
        isReadable(a.textColor, a.backgroundColor),
        isTrue,
        reason:
            '浅色主题正文对比度不足: '
            '${contrastRatio(a.textColor, a.backgroundColor)}',
      );
      expect(
        a.textColor.computeLuminance(),
        lessThan(0.5),
        reason: '浅色主题正文应为深色',
      );
    });

    testWidgets('2. 深色 Theme：正文浅色且可读（≥4.5:1）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final a = resolveReaderAppearance(tester.element(find.byType(Scaffold)));
      expect(
        isReadable(a.textColor, a.backgroundColor),
        isTrue,
        reason:
            '深色主题正文对比度不足: '
            '${contrastRatio(a.textColor, a.backgroundColor)}',
      );
      expect(
        a.textColor.computeLuminance(),
        greaterThan(0.5),
        reason: '深色主题正文应为浅色',
      );
    });

    testWidgets('3. 章节标题（headingColor）对比度达标', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final a = resolveReaderAppearance(tester.element(find.byType(Scaffold)));
      expect(
        isReadable(a.headingColor, a.backgroundColor),
        isTrue,
        reason: '标题对比度不足',
      );
    });

    testWidgets('4. 浅色主题标题/次要文字可辨认', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final a = resolveReaderAppearance(tester.element(find.byType(Scaffold)));
      expect(isReadable(a.headingColor, a.backgroundColor), isTrue);
      expect(
        contrastRatio(a.secondaryTextColor, a.backgroundColor),
        greaterThan(2.0),
        reason: '次要文字不能低到无法辨认',
      );
    });
  });
}
