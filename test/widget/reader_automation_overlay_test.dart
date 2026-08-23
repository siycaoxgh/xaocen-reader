import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/auto_read_controller.dart';
import 'package:xaocen_reader/domain/reader/tts_reading_controller.dart';
import 'package:xaocen_reader/reader/reader_automation_overlay.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

void main() {
  testWidgets(
    'TTS control strip remains visible when Reader chrome is hidden',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderChrome(
              visible: false,
              title: 'Book',
              mode: ReaderMode.vertical,
              onBack: () {},
              onToc: () {},
              onAppearance: () {},
              onMore: () {},
              onBookmarks: () {},
              onSearch: () {},
              onModeSelected: (_) {},
              onTts: () {},
              ttsState: TtsReadingState.playing,
              onPauseTts: () {},
              onStopTts: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(readerAutomationOverlayKey), findsOneWidget);
      expect(find.textContaining('\u8bed\u97f3\u6717\u8bfb'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderChrome(
              visible: false,
              title: 'Book',
              mode: ReaderMode.vertical,
              onBack: () {},
              onToc: () {},
              onAppearance: () {},
              onMore: () {},
              onBookmarks: () {},
              onSearch: () {},
              onModeSelected: (_) {},
              onTts: () {},
              ttsState: TtsReadingState.paused,
              onResumeTts: () {},
              onStopTts: () {},
            ),
          ),
        ),
      );
      expect(find.byKey(readerAutomationOverlayKey), findsOneWidget);
      expect(
        find.byKey(const Key('reader-auto-read-status-resume')),
        findsOneWidget,
      );
    },
  );

  testWidgets('shared inactivity contract is 2.5 seconds and recalls', (
    tester,
  ) async {
    expect(readerAutomationHideAfter, const Duration(milliseconds: 2500));
    var interactionVersion = 0;

    Widget overlay() => MaterialApp(
      home: Scaffold(
        body: ReaderAutomationOverlay(
          mode: ReaderAutomationMode.tts,
          readerMode: ReaderMode.vertical,
          autoReadState: AutoReadState.idle,
          ttsState: TtsReadingState.playing,
          autoReadSpeedPixelsPerSecond: 25,
          autoReadPagedIntervalSeconds: 5,
          ttsSpeechRate: 1,
          interactionVersion: interactionVersion,
          onPause: () {},
          onResume: () {},
          onStop: () {},
        ),
      ),
    );

    await tester.pumpWidget(overlay());
    await tester.pump(readerAutomationHideAfter);
    expect(
      tester
          .widget<IgnorePointer>(find.byKey(readerAutomationOverlayKey))
          .ignoring,
      isTrue,
    );

    interactionVersion = 1;
    await tester.pumpWidget(overlay());
    await tester.pump();
    expect(
      tester
          .widget<IgnorePointer>(find.byKey(readerAutomationOverlayKey))
          .ignoring,
      isFalse,
    );
  });

  testWidgets('AutoRead and TTS use the same control shell', (tester) async {
    Future<void> pump(ReaderAutomationMode mode) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderAutomationOverlay(
            mode: mode,
            readerMode: ReaderMode.vertical,
            autoReadState: mode == ReaderAutomationMode.autoRead
                ? AutoReadState.running
                : AutoReadState.idle,
            ttsState: mode == ReaderAutomationMode.tts
                ? TtsReadingState.playing
                : TtsReadingState.idle,
            autoReadSpeedPixelsPerSecond: 25,
            autoReadPagedIntervalSeconds: 5,
            ttsSpeechRate: 1,
            onPause: () {},
            onResume: () {},
            onStop: () {},
          ),
        ),
      ),
    );

    await pump(ReaderAutomationMode.autoRead);
    expect(find.textContaining('\u81ea\u52a8\u9605\u8bfb'), findsOneWidget);
    final autoShape = tester.widget<Material>(find.byType(Material).last);
    await pump(ReaderAutomationMode.tts);
    expect(find.textContaining('\u8bed\u97f3\u6717\u8bfb'), findsOneWidget);
    final ttsShape = tester.widget<Material>(find.byType(Material).last);
    expect(autoShape.borderRadius, ttsShape.borderRadius);
  });

  testWidgets('automation strip matches bottom Chrome and leaves a gap', (
    tester,
  ) async {
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
            onAutoRead: () {},
            autoReadState: AutoReadState.running,
            onPauseAutoRead: () {},
            onStopAutoRead: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final bottomChrome = tester.getRect(
      find.byKey(readerUnifiedBottomChromeKey),
    );
    final overlayMaterial = find.descendant(
      of: find.byKey(readerAutomationOverlayKey),
      matching: find.byType(Material),
    ).first;
    final overlay = tester.getRect(overlayMaterial);

    expect(overlay.width, closeTo(bottomChrome.width, 0.1));
    expect(
      bottomChrome.top - overlay.bottom,
      greaterThanOrEqualTo(readerAutomationOverlayGap - 0.1),
    );
  });

  testWidgets(
    'control shell hides after inactivity and hub exposes two modes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderAutomationOverlay(
              mode: ReaderAutomationMode.autoRead,
              readerMode: ReaderMode.vertical,
              autoReadState: AutoReadState.running,
              ttsState: TtsReadingState.idle,
              autoReadSpeedPixelsPerSecond: 25,
              autoReadPagedIntervalSeconds: 5,
              ttsSpeechRate: 1,
              hideAfter: const Duration(milliseconds: 25),
              onPause: () {},
              onResume: () {},
              onStop: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
      expect(
        tester
            .widget<IgnorePointer>(find.byKey(readerAutomationOverlayKey))
            .ignoring,
        isTrue,
      );

      var autoRead = false;
      var tts = false;
      unawaited(
        showReaderAutoHub(
          tester.element(find.byType(Scaffold)),
          onAutoRead: () => autoRead = true,
          onTts: () => tts = true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(readerAutoHubKey), findsOneWidget);
      await tester.tap(find.byKey(readerAutoHubAutoReadKey));
      await tester.pumpAndSettle();
      expect(autoRead, isTrue);
      expect(tts, isFalse);
    },
  );

  testWidgets('auto hub keeps auto-read speed settings reachable', (
    tester,
  ) async {
    var openedSettings = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => unawaited(
                showReaderAutoHub(
                  context,
                  onAutoRead: () {},
                  onAutoReadSettings: () => openedSettings = true,
                  onTts: () {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(readerAutoHubAutoReadSettingsKey), findsOneWidget);
    await tester.tap(find.byKey(readerAutoHubAutoReadSettingsKey));
    await tester.pumpAndSettle();
    expect(openedSettings, isTrue);
  });
}
