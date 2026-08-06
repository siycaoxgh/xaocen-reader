import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/app.dart';
import 'package:xaocen_reader/app/constants.dart';
import 'package:xaocen_reader/app/placeholder_page.dart';
import 'package:xaocen_reader/app/router.dart';

void main() {
  group('M0 骨架', () {
    testWidgets('占位页渲染三段关键文案', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: XaocenApp()));

      expect(find.text('XAOCEN Reader v4'), findsOneWidget);
      expect(find.text('工程骨架已初始化'), findsOneWidget);
      expect(find.text('当前阶段：M0'), findsOneWidget);
    });

    testWidgets('根路由指向占位页', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: XaocenApp()));

      expect(find.byType(PlaceholderPage), findsOneWidget);
    });

    testWidgets('深色主题生效', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: XaocenApp()));

      final context = tester.element(find.byType(PlaceholderPage));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });

  group('版本与代际常量', () {
    test('应用版本为全新代际 0.1.0-dev.1+1', () {
      expect(appVersion, '0.1.0-dev.1+1');
      expect(appVersion.startsWith('0.1.0'), isTrue);
    });

    test('数据代际为 v4-local-1', () {
      expect(dataEpoch, 'v4-local-1');
    });

    test('根路由路径为 /', () {
      expect(AppRouter.root, '/');
      expect(AppRouter.routes.containsKey('/'), isTrue);
    });
  });
}
