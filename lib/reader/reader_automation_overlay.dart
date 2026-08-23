import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/reader/auto_read_controller.dart';
import '../domain/reader/tts_reading_controller.dart';
import 'reader_mode.dart';

const readerAutomationOverlayKey = Key('reader-automation-overlay');

/// The single inactivity contract shared by AutoRead and TTS controls.
///
/// Keep this value here rather than repeating a duration in each Reader
/// surface so the two automatic modes cannot drift apart again.
const readerAutomationHideAfter = Duration(milliseconds: 2500);

/// The unified bottom Chrome contains five 72dp actions (62dp action height
/// plus its bottom inset).  Keep the automation strip on the same visual
/// width and calculate its vertical anchor from the actual device inset so it
/// never touches or overlaps the bottom Chrome on gesture or 3-button devices.
const readerBottomChromeMaxWidth = 360.0;
const readerBottomChromeActionHeight = 62.0;
const readerBottomChromeMinimumInset = 10.0;
const readerAutomationOverlayGap = 12.0;

double readerAutomationOverlayBottomInset(BuildContext context) {
  final bottomSafe = MediaQuery.paddingOf(context).bottom;
  return readerBottomChromeActionHeight +
      math.max(readerBottomChromeMinimumInset, bottomSafe) +
      readerAutomationOverlayGap;
}

/// The two user-facing automatic reading modes share one visual contract.
enum ReaderAutomationMode { autoRead, tts }

/// A small, non-modal control strip for the active automatic reading mode.
///
/// This widget owns only presentation (including the inactivity hide timer).
/// AutoRead and TTS remain the owners of their playback state machines.
class ReaderAutomationOverlay extends StatefulWidget {
  const ReaderAutomationOverlay({
    super.key,
    required this.mode,
    required this.readerMode,
    required this.autoReadState,
    required this.ttsState,
    required this.autoReadSpeedPixelsPerSecond,
    required this.autoReadPagedIntervalSeconds,
    required this.ttsSpeechRate,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    this.interactionVersion = 0,
    this.hideAfter = readerAutomationHideAfter,
  });

  final ReaderAutomationMode mode;
  final ReaderMode readerMode;
  final AutoReadState autoReadState;
  final TtsReadingState ttsState;
  final int autoReadSpeedPixelsPerSecond;
  final int autoReadPagedIntervalSeconds;
  final double ttsSpeechRate;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;

  /// Incremented by ReaderPage when the user interacts with the Reader.
  final int interactionVersion;

  /// Injectable for widget tests; production uses the shared 2.5-second rule.
  final Duration hideAfter;

  @override
  State<ReaderAutomationOverlay> createState() =>
      _ReaderAutomationOverlayState();
}

class _ReaderAutomationOverlayState extends State<ReaderAutomationOverlay> {
  Timer? _hideTimer;
  bool _visible = true;

  bool get _active => widget.mode == ReaderAutomationMode.autoRead
      ? widget.autoReadState != AutoReadState.idle
      : widget.ttsState != TtsReadingState.idle;

  bool get _running => widget.mode == ReaderAutomationMode.autoRead
      ? widget.autoReadState == AutoReadState.running
      : widget.ttsState == TtsReadingState.playing;

  bool get _paused => widget.mode == ReaderAutomationMode.autoRead
      ? widget.autoReadState == AutoReadState.paused
      : widget.ttsState == TtsReadingState.paused;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void didUpdateWidget(covariant ReaderAutomationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interactionVersion != widget.interactionVersion ||
        oldWidget.mode != widget.mode ||
        oldWidget.autoReadState != widget.autoReadState ||
        oldWidget.ttsState != widget.ttsState) {
      _showAndSchedule();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_active || widget.hideAfter <= Duration.zero) return;
    _hideTimer = Timer(widget.hideAfter, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _showAndSchedule() {
    _hideTimer?.cancel();
    if (!_active) {
      if (mounted && _visible) setState(() => _visible = false);
      return;
    }
    if (mounted && !_visible) setState(() => _visible = true);
    _scheduleHide();
  }

  void _interact(VoidCallback? callback) {
    _showAndSchedule();
    callback?.call();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return const SizedBox.shrink();
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;
    final colors = Theme.of(context).colorScheme;
    final title = widget.mode == ReaderAutomationMode.autoRead
        ? '\u81ea\u52a8\u9605\u8bfb'
        : '\u8bed\u97f3\u6717\u8bfb';
    final speed = widget.mode == ReaderAutomationMode.autoRead
        ? (widget.readerMode == ReaderMode.vertical
              ? '${widget.autoReadSpeedPixelsPerSecond} px/s'
              : '${widget.autoReadPagedIntervalSeconds} \u79d2/\u9875')
        : '${widget.ttsSpeechRate.toStringAsFixed(1)}x';
    final icon = widget.mode == ReaderAutomationMode.autoRead
        ? Icons.auto_stories_outlined
        : Icons.record_voice_over_outlined;
    final label = _running
        ? '$title \u00b7 $speed'
        : _paused
        ? '$title \u00b7 \u6682\u505c'
        : '$title \u00b7 \u5df2\u505c\u6b62';

    return IgnorePointer(
      key: readerAutomationOverlayKey,
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            minimum: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              readerAutomationOverlayBottomInset(context),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: readerBottomChromeMaxWidth,
              ),
              child: Material(
                color: colors.surfaceContainerHighest.withValues(alpha: .98),
                elevation: 3,
                borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                  child: Row(
                    children: [
                      Icon(icon, size: 19, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      if (_running && widget.onPause != null)
                        TextButton(
                          key: const Key('reader-auto-read-status-pause'),
                          onPressed: () => _interact(widget.onPause),
                          child: const Text('\u6682\u505c'),
                        ),
                      if (_paused && widget.onResume != null)
                        TextButton(
                          key: const Key('reader-auto-read-status-resume'),
                          onPressed: () => _interact(widget.onResume),
                          child: const Text('\u7ee7\u7eed'),
                        ),
                      if ((_running || _paused) && widget.onStop != null)
                        TextButton(
                          key: const Key('reader-auto-read-status-stop'),
                          onPressed: () => _interact(widget.onStop),
                          child: const Text('\u505c\u6b62'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
