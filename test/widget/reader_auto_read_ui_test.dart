import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/auto_read_controller.dart';
import 'package:xaocen_reader/domain/reader/auto_read_preferences.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
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
              speedPixelsPerSecond:
                  controller.preferences.verticalVelocityPixelsPerSecond,
              onStart: controller.start,
              onPause: () =>
                  controller.pause(AutoReadPauseReason.manualNavigation),
              onResume: controller.resume,
              onStop: controller.stop,
              onSpeedChanged: (velocity) => controller.updatePreferences(
                controller.preferences.copyWith(
                  verticalVelocityPixelsPerSecond: velocity,
                ),
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

    await tester.drag(
      find.byKey(const Key('reader-auto-read-speed-slider')),
      const Offset(-37, 0),
    );
    await tester.pump();
    expect(find.textContaining('\u81ea\u5b9a\u4e49 \u00b7'), findsWidgets);

    await tester.tap(find.byKey(const Key('reader-auto-read-stop')));
    await tester.pump();
    expect(find.byKey(const Key('reader-auto-read-start')), findsOneWidget);
    controller.dispose();
  });

  testWidgets('ReaderChrome exposes AutoRead as a primary bottom action', (
    tester,
  ) async {
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
            onMore: () async {
              await showReaderMorePreview(
                tester.element(find.byType(ReaderChrome)),
              );
            },
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
    tapped = false;
    await tester.tap(find.byKey(readerMoreActionKey));
    await tester.pumpAndSettle();
    expect(find.byKey(readerSearchActionKey), findsNothing);
    // More no longer owns AutoRead; the one primary action remains visible
    // behind the modal sheet.
    expect(find.byKey(readerAutoReadActionKey), findsOneWidget);
  });

  testWidgets('ReaderChrome status bar keeps pause and stop actions visible', (
    tester,
  ) async {
    var paused = false;
    var stopped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              ReaderAutoReadStatusBar(
                mode: ReaderMode.vertical,
                state: AutoReadState.running,
                speedPixelsPerSecond: 28,
                pagedIntervalSeconds: 5,
                onPause: () => paused = true,
                onStop: () => stopped = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('自动阅读中 · 28 px/s'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reader-auto-read-status-pause')));
    await tester.tap(find.byKey(const Key('reader-auto-read-status-stop')));
    expect(paused, isTrue);
    expect(stopped, isTrue);
  });

  testWidgets('AutoRead status bar follows Reader Chrome visibility', (
    tester,
  ) async {
    Widget chrome(bool visible) => MaterialApp(
      home: Scaffold(
        body: ReaderChrome(
          visible: visible,
          title: 'Book',
          mode: ReaderMode.vertical,
          onBack: () {},
          onToc: () {},
          onAppearance: () {},
          onMore: () {},
          onBookmarks: () {},
          onSearch: () {},
          onModeSelected: (_) {},
          onAutoRead: () {},
          autoReadState: AutoReadState.running,
          autoReadSpeedPixelsPerSecond: 28,
          onPauseAutoRead: () {},
          onStopAutoRead: () {},
        ),
      ),
    );

    await tester.pumpWidget(chrome(false));
    expect(
      find.byKey(const Key('reader-auto-read-status-pause')),
      findsNothing,
    );
    await tester.pumpWidget(chrome(true));
    await tester.pump();
    expect(
      find.byKey(const Key('reader-auto-read-status-pause')),
      findsOneWidget,
    );
  });

  testWidgets('Reader info clock renders both 24-hour and 12-hour strings', (
    tester,
  ) async {
    Widget info(ReaderTimeDisplayMode mode) => MaterialApp(
      home: Scaffold(
        body: ReaderMinimalInfoLayer(
          mode: ReaderMode.vertical,
          currentChapterTitle: null,
          currentChapterNumber: null,
          chapterProgressPercent: null,
          chapterPageNumber: null,
          chapterPageCount: null,
          progressPercent: .37,
          showTopInfoBar: false,
          showBottomInfoBar: true,
          showProgressInfo: true,
          statusBarMode: ReaderStatusBarMode.readerInfo,
          timeDisplayMode: mode,
        ),
      ),
    );

    await tester.pumpWidget(info(ReaderTimeDisplayMode.twentyFourHour));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data ?? ''),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(info(ReaderTimeDisplayMode.twelveHour));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            RegExp(r'^\d{2}:\d{2} (AM|PM)$').hasMatch(widget.data ?? ''),
      ),
      findsOneWidget,
    );
  });

  testWidgets('paged AutoRead sheet exposes interval controls and status', (
    tester,
  ) async {
    final controller = AutoReadController();
    var interval = AutoReadPreferences.defaultPagedIntervalSeconds;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreamBuilder<AutoReadEvent>(
            stream: controller.events,
            builder: (context, _) => ReaderAutoReadSheet(
              mode: ReaderMode.paged,
              state: controller.state,
              speedPixelsPerSecond:
                  controller.preferences.verticalVelocityPixelsPerSecond,
              pagedIntervalSeconds: interval,
              onStart: controller.start,
              onPause: () =>
                  controller.pause(AutoReadPauseReason.manualNavigation),
              onResume: controller.resume,
              onStop: controller.stop,
              onSpeedChanged: (_) {},
              onPagedIntervalChanged: (seconds) {
                interval = seconds;
                controller.updatePreferences(
                  controller.preferences.copyWith(
                    pagedIntervalSeconds: seconds,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('reader-auto-read-intervals')), findsOneWidget);
    expect(find.text('\u6bcf 5 \u79d2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reader-auto-read-start')));
    await tester.pump();
    expect(
      find.text('\u81ea\u52a8\u7ffb\u9875\u4e2d \u00b7 5 \u79d2/\u9875'),
      findsOneWidget,
    );

    await tester.tap(find.text('\u6bcf 15 \u79d2'));
    await tester.pump();
    expect(interval, 15);
    expect(
      find.text('\u81ea\u52a8\u7ffb\u9875\u4e2d \u00b7 15 \u79d2/\u9875'),
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
    await tester.tap(find.byKey(const Key('reader-auto-read-stop')));
    await tester.pump();
    expect(find.byKey(const Key('reader-auto-read-start')), findsOneWidget);
    controller.dispose();
  });
}
