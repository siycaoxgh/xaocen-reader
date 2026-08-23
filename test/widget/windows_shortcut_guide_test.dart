import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xaocen_reader/app/windows_shortcut_guide.dart';

void main() {
  testWidgets('keyboard guide keeps the static image responsive', (
    tester,
  ) async {
    for (final width in [360.0, 800.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        const MaterialApp(home: WindowsShortcutGuideDialog()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(
        find.text('绿色区域表示当前可作为 XAOCEN 快捷键使用的按键，灰色区域表示暂不支持的按键。'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
