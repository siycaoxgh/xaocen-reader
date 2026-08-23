import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/tts_readable_text.dart';
import 'package:xaocen_reader/domain/reader/tts_reading_controller.dart';
import 'package:xaocen_reader/platform/tts_background_session.dart';

class _FakeTtsEngine implements TtsEngine, TtsAudioFocusAware {
  VoidCallback? complete;
  ValueChanged<Object?>? error;
  ValueChanged<TtsSpeechProgress>? progress;
  VoidCallback? focusLost;
  VoidCallback? focusGained;
  ValueChanged<String>? mediaCommand;
  final mediaStates = <String>[];
  final spoken = <String>[];
  final voicesValue = const [
    TtsVoice(name: '中文系统音', locale: 'zh-CN'),
    TtsVoice(name: 'English', locale: 'en-US'),
  ];
  bool paused = false;
  bool stopped = false;
  bool disposed = false;
  double rate = 1;
  TtsVoice? voice;
  int backgroundStarts = 0;
  int backgroundStops = 0;

  @override
  void setOnComplete(VoidCallback callback) => complete = callback;

  @override
  void setOnError(ValueChanged<Object?> callback) => error = callback;

  @override
  void setOnProgress(ValueChanged<TtsSpeechProgress> callback) =>
      progress = callback;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    paused = false;
  }

  @override
  Future<void> pause() async => paused = true;

  @override
  Future<void> resume(String text) async {
    spoken.add('resume:$text');
    paused = false;
  }

  @override
  Future<void> stop() async {
    stopped = true;
    paused = false;
  }

  @override
  Future<void> setRate(double value) async => rate = value;

  @override
  Future<List<TtsVoice>> voices() async => voicesValue;

  @override
  Future<void> setVoice(TtsVoice value) async => voice = value;

  @override
  Future<void> dispose() async => disposed = true;

  @override
  void setOnAudioFocusLost(VoidCallback callback) => focusLost = callback;

  @override
  void setOnAudioFocusGained(VoidCallback callback) => focusGained = callback;

  @override
  void setOnMediaCommand(ValueChanged<String> callback) =>
      mediaCommand = callback;

  @override
  Future<void> startBackgroundSession() async => backgroundStarts++;

  @override
  Future<void> stopBackgroundSession() async => backgroundStops++;

  @override
  Future<void> updateMediaPlaybackState(String state) async =>
      mediaStates.add(state);

  @override
  Future<void> disposeBackgroundSession() async {}

  void finish() => complete?.call();

  void reportProgress(int start, int end) =>
      progress?.call(TtsSpeechProgress(start: start, end: end));

  void sendMediaCommand(String command) => mediaCommand?.call(command);
}

class _UnavailableVoicesEngine extends _FakeTtsEngine {
  @override
  Future<List<TtsVoice>> voices() async {
    throw StateError('Windows TTS provider unavailable');
  }
}

/// Models providers that report completion for the utterance cancelled by
/// stop().  A rate restart must ignore that stale callback and keep playing.
class _CompletionOnStopTtsEngine extends _FakeTtsEngine {
  @override
  Future<void> stop() async {
    await super.stop();
    complete?.call();
  }
}

void main() {
  test('readable source keeps UTF-16 ranges while splitting speech input', () {
    const text = '第一段。第二句。\n\n第二段很长很长很长很长。';
    final source = ReadableTextSource.fromText(text, maxSegmentLength: 8);

    expect(source.segments, isNotEmpty);
    for (var i = 1; i < source.segments.length; i++) {
      expect(
        source.segments[i - 1].endCharacterOffset,
        lessThanOrEqualTo(source.segments[i].startCharacterOffset),
      );
    }
    expect(
      source.segments.map((segment) => segment.text).join(),
      contains('第一段。'),
    );
  });

  test(
    'starts at current offset, pauses/resumes and advances automatically',
    () async {
      final engine = _FakeTtsEngine();
      final controller = TtsReadingController(engine: engine);
      controller.setSource(
        ReadableTextSource.fromText('第一段内容。\n第二段内容。', maxSegmentLength: 20),
      );

      await controller.loadVoices();
      expect(controller.selectedVoice?.locale, 'zh-CN');
      await controller.startFromOffset(7);
      expect(controller.state, TtsReadingState.playing);
      expect(controller.activeSegment?.text, contains('第二段'));

      await controller.pause();
      expect(controller.state, TtsReadingState.paused);
      await controller.resume();
      expect(controller.state, TtsReadingState.playing);
      expect(engine.spoken.last, startsWith('resume:'));

      engine.finish();
      expect(controller.state, TtsReadingState.stoppedAtEnd);
      controller.dispose();
      expect(engine.disposed, isTrue);
    },
  );

  test('unavailable voice provider does not block Reader startup', () async {
    final controller = TtsReadingController(engine: _UnavailableVoicesEngine());

    await expectLater(controller.loadVoices(), completes);
    expect(controller.voicesList, isEmpty);
    controller.dispose();
  });

  test('idle source replacement does not call native TTS stop', () async {
    final engine = _FakeTtsEngine();
    final controller = TtsReadingController(engine: engine);

    controller.setSource(ReadableTextSource.fromText('first'));
    await Future<void>.delayed(Duration.zero);

    expect(engine.stopped, isFalse);
    controller.dispose();
  });

  test(
    'continuous reading crosses chapter boundaries and stops at end',
    () async {
      final engine = _FakeTtsEngine();
      final controller = TtsReadingController(engine: engine);
      controller.setSource(
        ReadableTextSource.fromText(
          'Chapter 1. First paragraph.\n\n'
          'Chapter 2. Second paragraph.\n'
          'Chapter 3. Final paragraph.',
          maxSegmentLength: 64,
        ),
      );

      expect(controller.segments, hasLength(3));
      expect(
        controller.segments.every((segment) => segment.text.trim().isNotEmpty),
        isTrue,
      );
      await controller.startFromOffset(0);
      expect(engine.spoken, ['Chapter 1. First paragraph.']);
      engine.reportProgress(4, 5);
      expect(controller.activeSpeechCharacterOffset, 4);

      engine.finish();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state, TtsReadingState.playing);
      expect(controller.activeSegment?.index, 1);
      expect(engine.spoken.last, 'Chapter 2. Second paragraph.');

      engine.finish();
      await Future<void>.delayed(Duration.zero);
      expect(controller.activeSegment?.index, 2);
      expect(engine.spoken.last, 'Chapter 3. Final paragraph.');

      engine.finish();
      expect(controller.state, TtsReadingState.stoppedAtEnd);
      expect(controller.activeSegment?.index, 2);
      controller.dispose();
    },
  );

  test(
    'live speech-rate change restarts from current UTF-16 position',
    () async {
      final engine = _FakeTtsEngine();
      final controller = TtsReadingController(engine: engine);
      const text =
          '0123456789 current sentence continues without replaying its prefix';
      controller.setSource(ReadableTextSource.fromText(text));

      await controller.startFromOffset(0);
      engine.reportProgress(10, 11);
      expect(controller.activeSpeechCharacterOffset, 10);

      await controller.setSpeechRate(2.0);

      expect(engine.rate, 2.0);
      expect(engine.spoken, hasLength(2));
      expect(engine.spoken.last, text.substring(10));
      expect(controller.activeSpeechCharacterOffset, 10);
      expect(controller.state, TtsReadingState.playing);
      controller.dispose();
    },
  );

  test(
    'playing rate change ignores stale stop completion and resumes',
    () async {
      final engine = _CompletionOnStopTtsEngine();
      final controller = TtsReadingController(engine: engine);
      const text = 'A sentence that continues after a live speed change.';
      controller.setSource(ReadableTextSource.fromText(text));

      await controller.startFromOffset(0);
      engine.reportProgress(4, 5);
      await controller.setSpeechRate(1.5);

      expect(controller.state, TtsReadingState.playing);
      expect(engine.spoken.last, text.substring(4));
      controller.dispose();
    },
  );

  test('paused rate change keeps TTS paused', () async {
    final engine = _FakeTtsEngine();
    final controller = TtsReadingController(engine: engine);
    controller.setSource(
      ReadableTextSource.fromText('A paused sentence for rate settings.'),
    );

    await controller.startFromOffset(0);
    await controller.pause();
    final spokenBefore = engine.spoken.length;
    await controller.setSpeechRate(0.5);

    expect(engine.rate, 0.5);
    expect(engine.spoken.length, spokenBefore);
    expect(controller.state, TtsReadingState.paused);
    controller.dispose();
  });

  test(
    'manual navigation can restart the active segment without TTS progress',
    () async {
      final engine = _FakeTtsEngine();
      final controller = TtsReadingController(engine: engine);
      controller.setSource(
        ReadableTextSource.fromText('A long paragraph that stays together.'),
      );
      await controller.startFromOffset(0);
      final firstUtteranceCount = engine.spoken.length;

      controller.followReaderPosition(4, forceRestart: true);
      await Future<void>.delayed(Duration.zero);

      expect(controller.activeSegment?.index, 0);
      expect(engine.spoken.length, greaterThan(firstUtteranceCount));
      controller.dispose();
    },
  );

  test(
    'previous/next and manual position follow do not create progress truth',
    () async {
      final engine = _FakeTtsEngine();
      final controller = TtsReadingController(engine: engine);
      controller.setSource(
        ReadableTextSource.fromText('一段。\n二段。\n三段。', maxSegmentLength: 20),
      );
      await controller.startFromOffset(0);
      await controller.next();
      expect(controller.activeSegment?.text, contains('二段'));
      await controller.previous();
      expect(controller.activeSegment?.text, contains('一段'));
      controller.followReaderPosition(999);
      await Future<void>.delayed(Duration.zero);
      expect(controller.activeSegment?.text, contains('三段'));
      await controller.stop();
      expect(controller.state, TtsReadingState.idle);
      expect(engine.stopped, isTrue);
      controller.dispose();
    },
  );

  test('duration sleep timer stops TTS after real elapsed time', () async {
    final engine = _FakeTtsEngine();
    var clock = DateTime(2026, 1, 1);
    final controller = TtsReadingController(
      engine: engine,
      now: () => clock,
      sleepTimerTickInterval: const Duration(milliseconds: 5),
    );
    controller.setSource(ReadableTextSource.fromText('A readable paragraph.'));

    await controller.setSleepTimer(TtsSleepTimerMode.minutes15);
    await controller.startFromOffset(0);
    expect(controller.sleepTimer.isActive, isTrue);

    clock = clock.add(const Duration(minutes: 15, seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(controller.sleepTimer.isExpired, isTrue);
    expect(controller.state, TtsReadingState.idle);
    expect(engine.stopped, isTrue);
    controller.dispose();
  });

  test(
    '15, 30, and 60 minute timer modes use their configured durations',
    () async {
      const modes = <(TtsSleepTimerMode, Duration)>[
        (TtsSleepTimerMode.minutes15, Duration(minutes: 15)),
        (TtsSleepTimerMode.minutes30, Duration(minutes: 30)),
        (TtsSleepTimerMode.minutes60, Duration(minutes: 60)),
      ];
      for (final (mode, duration) in modes) {
        final engine = _FakeTtsEngine();
        var clock = DateTime(2026, 1, 1);
        final controller = TtsReadingController(
          engine: engine,
          now: () => clock,
          sleepTimerTickInterval: const Duration(milliseconds: 5),
        );

        await controller.setSleepTimer(mode);
        expect(controller.sleepTimer.remaining, duration);
        clock = clock.add(duration + const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(controller.sleepTimer.isExpired, isTrue);
        controller.dispose();
      }
    },
  );

  test('sleep timer keeps counting while TTS is paused', () async {
    final engine = _FakeTtsEngine();
    var clock = DateTime(2026, 1, 1);
    final controller = TtsReadingController(
      engine: engine,
      now: () => clock,
      sleepTimerTickInterval: const Duration(milliseconds: 5),
    );
    controller.setSource(ReadableTextSource.fromText('A readable paragraph.'));

    await controller.setSleepTimer(TtsSleepTimerMode.minutes15);
    await controller.startFromOffset(0);
    await controller.pause();
    expect(controller.state, TtsReadingState.paused);

    clock = clock.add(const Duration(minutes: 15, seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(controller.sleepTimer.isExpired, isTrue);
    expect(controller.state, TtsReadingState.idle);
    controller.dispose();
  });

  test('end-of-chapter timer stops before the next chapter segment', () async {
    final engine = _FakeTtsEngine();
    final controller = TtsReadingController(engine: engine);
    controller.setSource(
      ReadableTextSource.fromText(
        'Chapter one paragraph.\n\nChapter two paragraph.',
        maxSegmentLength: 64,
      ),
    );
    expect(controller.segments, hasLength(2));

    await controller.setSleepTimer(
      TtsSleepTimerMode.endOfChapter,
      currentChapterEndOffset: controller.segments[1].startCharacterOffset,
    );
    await controller.startFromOffset(0);
    engine.finish();
    await Future<void>.delayed(Duration.zero);

    expect(controller.sleepTimer.isExpired, isTrue);
    expect(controller.state, TtsReadingState.idle);
    expect(engine.spoken, hasLength(1));
    controller.dispose();
  });

  test('sleep timer is cleared when stopped or disposed', () async {
    final engine = _FakeTtsEngine();
    final controller = TtsReadingController(
      engine: engine,
      sleepTimerTickInterval: const Duration(milliseconds: 5),
    );
    await controller.setSleepTimer(TtsSleepTimerMode.minutes15);
    await controller.stop();
    expect(controller.sleepTimer.status, TtsSleepTimerStatus.inactive);

    await controller.setSleepTimer(TtsSleepTimerMode.minutes30);
    controller.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(engine.disposed, isTrue);
  });

  test('audio focus loss pauses and focus gain resumes TTS', () async {
    final engine = _FakeTtsEngine();
    final controller = TtsReadingController(engine: engine);
    controller.setSource(ReadableTextSource.fromText('A readable paragraph.'));
    await controller.startFromOffset(0);

    expect(engine.backgroundStarts, 1);
    engine.focusLost?.call();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, TtsReadingState.paused);

    engine.focusGained?.call();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, TtsReadingState.playing);
    expect(engine.spoken.last, startsWith('resume:'));

    await controller.stop();
    expect(engine.backgroundStops, greaterThanOrEqualTo(1));
    controller.dispose();
  });

  test('media commands use the same TTS controller state and queue', () async {
    final engine = _FakeTtsEngine();
    final controller = TtsReadingController(engine: engine);
    controller.setSource(
      ReadableTextSource.fromText(
        'First paragraph.\n\nSecond paragraph.',
        maxSegmentLength: 64,
      ),
    );

    await controller.startFromOffset(0);
    expect(controller.state, TtsReadingState.playing);
    expect(engine.mediaStates, contains('playing'));

    engine.sendMediaCommand('playPause');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, TtsReadingState.paused);

    engine.sendMediaCommand('playPause');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, TtsReadingState.playing);

    engine.sendMediaCommand('next');
    await Future<void>.delayed(Duration.zero);
    expect(controller.activeSegment?.text, contains('Second'));

    engine.sendMediaCommand('stop');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, TtsReadingState.idle);
    expect(engine.mediaStates.last, 'stopped');
    controller.dispose();
  });

  test(
    'disposing a speaking Reader releases TTS and background session',
    () async {
      final engine = _FakeTtsEngine();
      final controller = TtsReadingController(engine: engine);
      controller.setSource(
        ReadableTextSource.fromText('A readable paragraph.'),
      );
      await controller.startFromOffset(0);

      controller.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(engine.disposed, isTrue);
      expect(engine.backgroundStops, greaterThanOrEqualTo(1));
    },
  );
}
