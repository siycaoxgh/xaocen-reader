import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/reader/tts_reading_controller.dart';

const readerTtsControlsSheetKey = Key('reader-tts-controls-sheet');
const readerTtsPlayPauseKey = Key('reader-tts-play-pause');
const readerTtsPreviousKey = Key('reader-tts-previous');
const readerTtsNextKey = Key('reader-tts-next');
const readerTtsStopKey = Key('reader-tts-stop');
const readerTtsRateKey = Key('reader-tts-rate');
const readerTtsVoiceKey = Key('reader-tts-voice');
const readerTtsSleepTimerKey = Key('reader-tts-sleep-timer');

Future<void> showReaderTtsControls(
  BuildContext context, {
  required TtsReadingController controller,
  required int Function() currentOffset,
  int? currentChapterEndOffset,
  Future<void> Function()? onBeforePlayback,
  Future<void> Function(TtsReadingController controller)? onPreferencesChanged,
}) async {
  await controller.loadVoices();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _TtsControlsSheet(
      controller: controller,
      currentOffset: currentOffset,
      currentChapterEndOffset: currentChapterEndOffset,
      onBeforePlayback: onBeforePlayback,
      onPreferencesChanged: onPreferencesChanged,
    ),
  );
}

class _TtsControlsSheet extends StatelessWidget {
  const _TtsControlsSheet({
    required this.controller,
    required this.currentOffset,
    this.onBeforePlayback,
    this.currentChapterEndOffset,
    this.onPreferencesChanged,
  });

  final TtsReadingController controller;
  final int Function() currentOffset;
  final Future<void> Function()? onBeforePlayback;
  final int? currentChapterEndOffset;
  final Future<void> Function(TtsReadingController controller)?
  onPreferencesChanged;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final state = controller.state;
      final playing = state == TtsReadingState.playing;
      final paused = state == TtsReadingState.paused;
      final canStart = controller.segments.isNotEmpty;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Padding(
                  key: readerTtsControlsSheetKey,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u6717\u8bfb',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _ttsStateLabel(state),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              key: readerTtsPreviousKey,
                              tooltip: '\u4e0a\u4e00\u6bb5',
                              onPressed: canStart
                                  ? () => unawaited(
                                      _dispatchPlaybackCommand(
                                        TtsCommand.previous,
                                      ),
                                    )
                                  : null,
                              icon: const Icon(Icons.skip_previous_rounded),
                            ),
                            FilledButton.icon(
                              key: readerTtsPlayPauseKey,
                              onPressed: !canStart
                                  ? null
                                  : () => unawaited(
                                      _dispatchPlaybackCommand(
                                        TtsCommand.playPause,
                                        startOffset: currentOffset,
                                      ),
                                    ),
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              label: Text(
                                playing
                                    ? '\u6682\u505c'
                                    : paused
                                    ? '\u7ee7\u7eed'
                                    : '\u5f00\u59cb',
                              ),
                            ),
                            IconButton(
                              key: readerTtsStopKey,
                              tooltip: '\u505c\u6b62',
                              onPressed: state == TtsReadingState.idle
                                  ? null
                                  : () => unawaited(
                                      controller.dispatchCommand(
                                        TtsCommand.stop,
                                      ),
                                    ),
                              icon: const Icon(Icons.stop_rounded),
                            ),
                            IconButton(
                              key: readerTtsNextKey,
                              tooltip: '\u4e0b\u4e00\u6bb5',
                              onPressed: canStart
                                  ? () => unawaited(
                                      _dispatchPlaybackCommand(TtsCommand.next),
                                    )
                                  : null,
                              icon: const Icon(Icons.skip_next_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 32,
                              height: 48,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.speed),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 36,
                              height: 48,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('\u8bed\u901f'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: SliderTheme(
                                  data: SliderTheme.of(
                                    context,
                                  ).copyWith(trackHeight: 4),
                                  child: Slider(
                                    key: readerTtsRateKey,
                                    min: .5,
                                    max: 2,
                                    divisions: 15,
                                    value: controller.speechRate,
                                    label:
                                        '${controller.speechRate.toStringAsFixed(1)}x',
                                    onChanged: (value) =>
                                        unawaited(_setRate(controller, value)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 44,
                              height: 48,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${controller.speechRate.toStringAsFixed(1)}x',
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (controller.voicesList.isNotEmpty)
                          DropdownButtonFormField<TtsVoice>(
                            key: readerTtsVoiceKey,
                            initialValue: controller.selectedVoice,
                            decoration: const InputDecoration(
                              labelText: '\u58f0\u97f3',
                              prefixIcon: Icon(
                                Icons.record_voice_over_outlined,
                              ),
                            ),
                            items: [
                              for (final voice in controller.voicesList)
                                DropdownMenuItem<TtsVoice>(
                                  value: voice,
                                  child: Text(
                                    '${voice.displayName} · ${voice.locale}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (voice) {
                              if (voice != null) {
                                unawaited(_setVoice(controller, voice));
                              }
                            },
                          )
                        else
                          Text(
                            '\u4f7f\u7528\u7cfb\u7edf\u9ed8\u8ba4\u58f0\u97f3\uff08\u672a\u53d1\u73b0\u53ef\u9009\u8bed\u97f3\uff09',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<TtsSleepTimerMode>(
                          key: readerTtsSleepTimerKey,
                          initialValue: controller.sleepTimer.mode,
                          decoration: const InputDecoration(
                            labelText: '\u6717\u8bfb\u5b9a\u65f6\u505c\u6b62',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: TtsSleepTimerMode.off,
                              child: Text('\u5173\u95ed'),
                            ),
                            DropdownMenuItem(
                              value: TtsSleepTimerMode.minutes15,
                              child: Text('15 \u5206\u949f'),
                            ),
                            DropdownMenuItem(
                              value: TtsSleepTimerMode.minutes30,
                              child: Text('30 \u5206\u949f'),
                            ),
                            DropdownMenuItem(
                              value: TtsSleepTimerMode.minutes60,
                              child: Text('60 \u5206\u949f'),
                            ),
                            DropdownMenuItem(
                              value: TtsSleepTimerMode.endOfChapter,
                              child: Text(
                                '\u5f53\u524d\u7ae0\u8282\u7ed3\u675f\u540e\u505c\u6b62',
                              ),
                            ),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              unawaited(
                                controller.setSleepTimer(
                                  mode,
                                  currentChapterEndOffset:
                                      currentChapterEndOffset,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _sleepTimerStatusLabel(controller.sleepTimer),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _dispatchPlaybackCommand(
    TtsCommand command, {
    int Function()? startOffset,
  }) async {
    final startsNewSession =
        controller.state == TtsReadingState.idle ||
        controller.state == TtsReadingState.stoppedAtEnd;
    if (startsNewSession) await onBeforePlayback?.call();
    await controller.dispatchCommand(
      command,
      currentOffset: startOffset?.call(),
    );
  }

  Future<void> _setRate(TtsReadingController controller, double value) async {
    await controller.setSpeechRate(value);
    await onPreferencesChanged?.call(controller);
  }

  Future<void> _setVoice(
    TtsReadingController controller,
    TtsVoice voice,
  ) async {
    await controller.setVoice(voice);
    await onPreferencesChanged?.call(controller);
  }
}

String _ttsStateLabel(TtsReadingState state) => switch (state) {
  TtsReadingState.idle =>
    '\u4ece\u5f53\u524d\u9605\u8bfb\u4f4d\u7f6e\u5f00\u59cb',
  TtsReadingState.playing => '\u6b63\u5728\u6717\u8bfb\u5f53\u524d\u6bb5\u843d',
  TtsReadingState.paused => '\u5df2\u6682\u505c',
  TtsReadingState.stoppedAtEnd => '\u5df2\u8bfb\u5230\u7ed3\u5c3e',
};

String _sleepTimerStatusLabel(TtsSleepTimerState timer) {
  if (timer.isExpired) {
    return '\u5b9a\u65f6\u7ed3\u675f\uff0c\u6717\u8bfb\u5df2\u505c\u6b62';
  }
  switch (timer.mode) {
    case TtsSleepTimerMode.off:
      return '\u5b9a\u65f6\u505c\u6b62\uff1a\u5173\u95ed';
    case TtsSleepTimerMode.endOfChapter:
      return '\u5f53\u524d\u7ae0\u8282\u7ed3\u675f\u540e\u505c\u6b62\uff08\u6682\u505c\u65f6\u8ba1\u65f6\u7ee7\u7eed\uff09';
    case TtsSleepTimerMode.minutes15:
    case TtsSleepTimerMode.minutes30:
    case TtsSleepTimerMode.minutes60:
      final remaining = timer.remaining;
      if (remaining == null) {
        return '\u5b9a\u65f6\u505c\u6b62\u5df2\u8bbe\u7f6e';
      }
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      return '\u5269\u4f59 $minutes:$seconds\uff08\u6682\u505c\u65f6\u8ba1\u65f6\u7ee7\u7eed\uff09';
  }
}
