import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

Widget _settings(Size size) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: ReaderSettingsSheet(
          preferences: ReaderPreferences.defaults,
          mode: ReaderMode.vertical,
          onPreferencesCommitted: (_) {},
          onModeSelected: (_) {},
          onResetPreferences: () {},
        ),
      ),
    ),
  );
}

void main() {
  for (final width in [360.0, 480.0, 600.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('settings remain accessible at width $width', (tester) async {
      await tester.pumpWidget(_settings(Size(width, 720)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final name in ['typography', 'appearance', 'paging', 'advanced']) {
        expect(
          find.byKey(ValueKey('reader-settings-category-$name')),
          findsOneWidget,
        );
      }
    });
  }

  testWidgets('narrow settings use horizontally scrollable category tabs', (
    tester,
  ) async {
    await tester.pumpWidget(_settings(const Size(480, 720)));
    expect(find.byType(ChoiceChip), findsNWidgets(4));
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('mid-width settings use icon rail with tooltips', (tester) async {
    await tester.pumpWidget(_settings(const Size(800, 720)));
    for (final name in ['typography', 'appearance', 'paging', 'advanced']) {
      expect(
        find.byKey(ValueKey('reader-settings-category-$name')),
        findsOneWidget,
      );
    }
    expect(find.byType(Tooltip), findsAtLeastNWidgets(4));
  });

  testWidgets('wide settings use labeled navigation rail', (tester) async {
    await tester.pumpWidget(_settings(const Size(1024, 720)));
    for (final name in ['typography', 'appearance', 'paging', 'advanced']) {
      expect(
        find.byKey(ValueKey('reader-settings-category-$name')),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'appearance exposes full-width preview and color picker actions',
    (tester) async {
      await tester.pumpWidget(_settings(const Size(1024, 720)));
      await tester.tap(
        find.byKey(const ValueKey('reader-settings-category-appearance')),
      );
      await tester.pumpAndSettle();
      final preview = tester.getRect(
        find.byKey(const ValueKey('reader-appearance-preview')),
      );
      expect(preview.width, greaterThan(500));
      final pickerButtons = find.text('\u53d6\u8272');
      expect(pickerButtons, findsNWidgets(2));
      await tester.ensureVisible(pickerButtons.first);
      await tester.tap(pickerButtons.first);
      await tester.pumpAndSettle();
      expect(find.text('\u9009\u62e9\u989c\u8272'), findsOneWidget);
      final pickerField = find.byType(TextField).last;
      await tester.enterText(pickerField, '#123456');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('\u786e\u8ba4'), findsOneWidget);
      await tester.tap(find.text('\u786e\u8ba4'));
      await tester.pumpAndSettle();
      expect(find.text('\u9009\u62e9\u989c\u8272'), findsNothing);
    },
  );
}
