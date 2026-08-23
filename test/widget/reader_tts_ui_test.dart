import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/tts_readable_text.dart';
import 'package:xaocen_reader/domain/reader/tts_reading_controller.dart';
import 'package:xaocen_reader/reader/tts_controls.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';
import 'package:xaocen_reader/reader/reader_text_block.dart';

class _HandoffTtsEngine implements TtsEngine {
  VoidCallback? _onComplete;
  final spoken = <String>[];

  @override
  void setOnComplete(VoidCallback callback) => _onComplete = callback;

  @override
  void setOnError(ValueChanged<Object?> callback) {}

  @override
  void setOnProgress(ValueChanged<TtsSpeechProgress> callback) {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume(String text) async => spoken.add('resume:$text');

  @override
  Future<void> stop() async {}

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<List<TtsVoice>> voices() async => const [
    TtsVoice(name: 'Test voice', locale: 'zh-CN'),
  ];

  @override
  Future<void> setVoice(TtsVoice voice) async {}

  @override
  Future<void> dispose() async {}

  void finish() => _onComplete?.call();
}

void main() {
  testWidgets('Reader operation chrome exposes a TTS entry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderChrome(
            visible: true,
            title: 'Test title',
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
          ),
        ),
      ),
    );

    expect(find.byKey(readerTtsActionKey), findsOneWidget);
  });

  testWidgets('TTS highlight is paint-only on ReaderTextBlock', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: ReaderTextBlock(
              text: 'A test paragraph',
              style: TextStyle(fontSize: 18),
              styleVersion: 1,
              textDirection: TextDirection.ltr,
              maxWidth: 240,
              highlightStart: 1,
              highlightEnd: 3,
              highlightColor: Color(0x2233AABB),
            ),
          ),
        ),
      ),
    );

    final render = tester.renderObject<RenderReaderTextBlock>(
      find.byType(ReaderTextBlock),
    );
    expect(render.highlightStart, 1);
    expect(render.highlightEnd, 3);
    expect(render.size.height, greaterThan(0));
  });

  testWidgets(
    'starting a fresh TTS session requests automatic-mode handoff once',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final engine = _HandoffTtsEngine();
      final controller = TtsReadingController(engine: engine)
        ..setSource(ReadableTextSource.fromText('第一段。第二段。'));
      var handoffCount = 0;
      Future<void>? sheet;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                sheet = showReaderTtsControls(
                  context,
                  controller: controller,
                  currentOffset: () => 0,
                  onBeforePlayback: () async => handoffCount++,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(readerTtsPlayPauseKey));
      await tester.pump();
      expect(handoffCount, 1);
      expect(controller.state, TtsReadingState.playing);

      // Pausing/resuming the same TTS session must not hand off again.
      await tester.tap(find.byKey(readerTtsPlayPauseKey));
      await tester.pump();
      expect(handoffCount, 1);
      await tester.tap(find.byKey(readerTtsPlayPauseKey));
      await tester.pump();
      expect(handoffCount, 1);

      await tester.tap(find.byKey(readerTtsStopKey));
      await tester.pump();
      await tester.tap(find.byKey(readerTtsPlayPauseKey));
      await tester.pump();
      expect(handoffCount, 2);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      await sheet;
      controller.dispose();
    },
  );
}
