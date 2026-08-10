import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/auto_read_controller.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

void main() {
  testWidgets('vertical AutoRead sheet exposes state and live speed controls', (
    tester,
  ) async {
    final controller = AutoReadController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreamBuilder<AutoReadEvent>(
            stream: controller.events,
            builder: (context, _) => ReaderAutoReadSheet(
              mode: ReaderMode.vertical,
              state: controller.state,
              speedPreset: controller.preferences.verticalSpeedPreset,
              onStart: controller.start,
              onPause: () =>
                  controller.pause(AutoReadPauseReason.manualNavigation),
              onResume: controller.resume,
              onStop: controller.stop,
              onSpeedSelected: (preset) => controller.updatePreferences(
                controller.preferences.copyWith(verticalSpeedPreset: preset),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('reader-auto-read-start')), findsOneWidget);
    expect(find.text('\u81ea\u52a8\u9605\u8bfb'), findsWidgets);

    await tester.tap(find.byKey(const Key('reader-auto-read-start')));
    await tester.pump();
    expect(
      find.text('\u81ea\u52a8\u9605\u8bfb\u4e2d \u00b7 \u6807\u51c6'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('reader-auto-read-pause')));
    await tester.pump();
    expect(
      find.text('\u81ea\u52a8\u9605\u8bfb\u5df2\u6682\u505c'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('reader-auto-read-resume')));
    await tester.pump();
    await tester.tap(find.text('\u5feb').last);
    await tester.pump();
    expect(
      find.text('\u81ea\u52a8\u9605\u8bfb\u4e2d \u00b7 \u5feb'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('reader-auto-read-stop')));
    await tester.pump();
    expect(find.byKey(const Key('reader-auto-read-start')), findsOneWidget);
    controller.dispose();
  });

  testWidgets('ReaderChrome exposes an AutoRead bottom action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderChrome(
            visible: true,
            title: 'Book',
            mode: ReaderMode.vertical,
            onBack: () {},
            onToc: () {},
            onAppearance: () {},
            onMore: () {},
            onBookmarks: () {},
            onSearch: () {},
            onModeSelected: (_) {},
            onAutoRead: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.byKey(readerAutoReadActionKey), findsOneWidget);
    await tester.tap(find.byKey(readerAutoReadActionKey));
    expect(tapped, isTrue);
  });
}
