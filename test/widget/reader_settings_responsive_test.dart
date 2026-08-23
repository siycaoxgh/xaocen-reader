import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/domain/reader/reader_input_bindings.dart';
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

Widget _settingsSheetWithTheme(
  Size size,
  ReaderThemeMode mode,
  ValueChanged<ReaderPreferences> onCommit,
) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: Theme(
          data: mode == ReaderThemeMode.dark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
          child: Material(
            color: mode == ReaderThemeMode.dark
                ? const Color(0xff121212)
                : const Color(0xffffffff),
            child: ReaderSettingsSheet(
              preferences: ReaderPreferences.defaults.copyWith(themeMode: mode),
              mode: ReaderMode.vertical,
              onPreferencesCommitted: onCommit,
              onModeSelected: (_) {},
              onResetPreferences: () {},
            ),
          ),
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

  testWidgets('interface settings handle shares the themed sheet surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showReaderSettings(
              context,
              preferences: ReaderPreferences.defaults,
              mode: ReaderMode.vertical,
              onPreferencesCommitted: (_) {},
              onModeSelected: (_) {},
              onResetPreferences: () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(readerSettingsSheetHandleKey), findsOneWidget);
    final handleMaterial = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(readerSettingsSheetHandleKey),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(handleMaterial.color, isNot(Colors.transparent));
    expect(tester.takeException(), isNull);
  });

  testWidgets('appearance controls remain usable at narrow width', (
    tester,
  ) async {
    await tester.pumpWidget(_settings(const Size(360, 720)));
    await tester.tap(
      find.byKey(const ValueKey('reader-settings-category-appearance')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Android exposes one shared automatic volume-key policy',
    (tester) async {
      AndroidAutoModeVolumeBehavior? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderSettingsSheet(
              preferences: ReaderPreferences.defaults,
              mode: ReaderMode.vertical,
              androidAutoModeVolumeBehavior:
                  AndroidAutoModeVolumeBehavior.followNormal,
              onAndroidAutoModeVolumeBehaviorChanged: (value) =>
                  selected = value,
              onPreferencesCommitted: (_) {},
              onModeSelected: (_) {},
              onResetPreferences: () {},
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('reader-settings-category-advanced')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(readerAutoModeVolumeBehaviorKey), findsOneWidget);
      expect(
        find.textContaining('\u81ea\u52a8\u6a21\u5f0f\u4e0b'),
        findsOneWidget,
      );
      expect(find.text('\u8ddf\u968f\u666e\u901a\u9605\u8bfb'), findsOneWidget);
      await tester.tap(find.byKey(readerAutoModeVolumeBehaviorKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('\u63a7\u5236\u81ea\u52a8\u6a21\u5f0f').last);
      expect(selected, AndroidAutoModeVolumeBehavior.controlAutomaticMode);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'true transparency control is available only on supported Windows',
    (tester) async {
      ReaderPreferences? latest;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderSettingsSheet(
              preferences: ReaderPreferences.defaults,
              mode: ReaderMode.vertical,
              supportsWindowsTrueTransparency: true,
              onPreferencesCommitted: (value) => latest = value,
              onModeSelected: (_) {},
              onResetPreferences: () {},
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('reader-settings-category-appearance')),
      );
      await tester.pumpAndSettle();
      if (Platform.isWindows) {
        expect(find.byKey(readerBackgroundOpacityKey), findsOneWidget);
        expect(find.byType(Slider), findsWidgets);
        expect(find.textContaining('背景透明度'), findsOneWidget);
        expect(latest, isNull);
      }
    },
  );

  testWidgets('standard engine transparency control is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderSettingsSheet(
            preferences: ReaderPreferences.defaults,
            mode: ReaderMode.vertical,
            supportsWindowsTrueTransparency: false,
            onPreferencesCommitted: (_) {},
            onModeSelected: (_) {},
            onResetPreferences: () {},
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('reader-settings-category-appearance')),
    );
    await tester.pumpAndSettle();
    if (Platform.isWindows) {
      final slider = tester.widget<Slider>(
        find.descendant(
          of: find.byKey(readerBackgroundOpacityKey),
          matching: find.byType(Slider),
        ),
      );
      expect(slider.onChanged, isNull);
      expect(find.textContaining('不支持真透明'), findsOneWidget);
    }
  });

  testWidgets('Reader Aa sheet surface follows the selected Reader theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      _settingsSheetWithTheme(
        const Size(1024, 720),
        ReaderThemeMode.light,
        (_) {},
      ),
    );
    await tester.pumpAndSettle();
    final lightMaterial = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(readerSettingsSheetKey),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(lightMaterial.color, const Color(0xffffffff));

    await tester.pumpWidget(
      _settingsSheetWithTheme(
        const Size(1024, 720),
        ReaderThemeMode.dark,
        (_) {},
      ),
    );
    await tester.pumpAndSettle();
    final darkMaterial = tester.widget<Material>(
      find
          .ancestor(
            of: find.byKey(readerSettingsSheetKey),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(darkMaterial.color, const Color(0xff121212));
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
    'Windows font list and settings use separate scrollbar rails',
    (tester) async {
      await tester.pumpWidget(_settings(const Size(1024, 720)));
      await tester.tap(find.byKey(const ValueKey('reader-font-list')));
      await tester.pumpAndSettle();

      final outerAndInner = tester.widgetList<Scrollbar>(
        find.byType(Scrollbar),
      );
      expect(
        outerAndInner.any(
          (scrollbar) =>
              scrollbar.scrollbarOrientation == ScrollbarOrientation.right,
        ),
        isTrue,
      );
      expect(
        outerAndInner.any(
          (scrollbar) =>
              scrollbar.scrollbarOrientation == ScrollbarOrientation.left,
        ),
        isTrue,
      );

      final fontList = find.descendant(
        of: find.byKey(const ValueKey('reader-font-list')),
        matching: find.byType(ListView),
      );
      expect(fontList, findsOneWidget);
      expect(tester.widget<ListView>(fontList).primary, isFalse);
      expect(find.byType(Scrollbar), findsNWidgets(2));
      expect(
        tester
            .widgetList<ListTile>(find.byType(ListTile))
            .any((tile) => tile.selected),
        isTrue,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Windows font preview includes Chinese, Latin, and digits',
    (tester) async {
      await tester.pumpWidget(_settings(const Size(1024, 720)));
      await tester.tap(
        find.byKey(const ValueKey('reader-settings-category-typography')),
      );
      await tester.pumpAndSettle();
      expect(find.text('晓枨阅读 Aa 123'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'font list stays bounded at narrow Windows width',
    (tester) async {
      await tester.pumpWidget(_settings(const Size(360, 720)));
      await tester.tap(find.byKey(const ValueKey('reader-font-list')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byKey(const ValueKey('reader-font-list')),
                matching: find.byType(ListView),
              ),
            )
            .height,
        lessThanOrEqualTo(190),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets('advanced screen awake policy exposes typed controls', (
    tester,
  ) async {
    await tester.pumpWidget(_settings(const Size(1024, 720)));
    await tester.tap(
      find.byKey(const ValueKey('reader-settings-category-advanced')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(readerScreenAwakeModeKey), findsOneWidget);
    expect(find.byKey(readerScreenAwakeTimeoutKey), findsNothing);
    await tester.tap(find.text('\u667a\u80fd\u5e38\u4eae'));
    await tester.pumpAndSettle();
    expect(find.byKey(readerScreenAwakeTimeoutKey), findsOneWidget);
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
