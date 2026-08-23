import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../platform/tts_background_session.dart';
import 'tts_readable_text.dart';

enum TtsReadingState { idle, playing, paused, stoppedAtEnd }

/// Commands shared by Reader controls, headset/media buttons and the Android
/// notification.  Keeping this enum at the controller boundary prevents a
/// platform from creating a second playback state machine.
enum TtsCommand { playPause, previous, next, stop }

enum TtsSleepTimerMode { off, minutes15, minutes30, minutes60, endOfChapter }

enum TtsSleepTimerStatus { inactive, active, expired }

@immutable
class TtsSleepTimerState {
  const TtsSleepTimerState({
    required this.mode,
    required this.status,
    this.remaining,
  });

  const TtsSleepTimerState.inactive()
    : mode = TtsSleepTimerMode.off,
      status = TtsSleepTimerStatus.inactive,
      remaining = null;

  final TtsSleepTimerMode mode;
  final TtsSleepTimerStatus status;
  final Duration? remaining;

  bool get isActive => status == TtsSleepTimerStatus.active;
  bool get isExpired => status == TtsSleepTimerStatus.expired;
}

@immutable
class TtsSpeechProgress {
  const TtsSpeechProgress({required this.start, required this.end});

  /// UTF-16 offsets within the currently spoken segment.
  final int start;
  final int end;
}

@immutable
class TtsVoice {
  const TtsVoice({required this.name, required this.locale, this.identifier});

  final String name;
  final String locale;
  final String? identifier;

  String get displayName => name.isEmpty ? locale : name;

  Map<String, String> toPlatformMap() {
    final result = <String, String>{'name': name, 'locale': locale};
    final value = identifier;
    if (value != null) result['identifier'] = value;
    return result;
  }

  @override
  bool operator ==(Object other) =>
      other is TtsVoice &&
      other.name == name &&
      other.locale == locale &&
      other.identifier == identifier;

  @override
  int get hashCode => Object.hash(name, locale, identifier);
}

/// Small platform boundary around the system TTS implementation.
///
/// A fake can be injected in tests; the Reader never depends on Android or
/// Windows APIs directly.
abstract interface class TtsEngine {
  void setOnComplete(VoidCallback callback);
  void setOnError(ValueChanged<Object?> callback);
  void setOnProgress(ValueChanged<TtsSpeechProgress> callback);
  Future<void> speak(String text);
  Future<void> pause();
  Future<void> resume(String text);
  Future<void> stop();
  Future<void> setRate(double rate);
  Future<List<TtsVoice>> voices();
  Future<void> setVoice(TtsVoice voice);
  Future<void> dispose();
}

final class FlutterTtsEngine implements TtsEngine, TtsAudioFocusAware {
  FlutterTtsEngine({FlutterTts? tts, TtsAudioFocusAware? backgroundSession})
    : _tts = tts ?? FlutterTts(),
      _backgroundSession = backgroundSession ?? AndroidTtsBackgroundSession() {
    _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(() {
      // Some Windows/SAPI providers deliver a completion notification for
      // the utterance that was just stopped.  That callback belongs to the
      // old utterance and must not terminate a new rate-restarted utterance.
      // The active flag is cleared by stop() before the native callback can
      // be observed, while a genuine completion still arrives with it set.
      final wasActive = _hasActiveUtterance;
      _hasActiveUtterance = false;
      if (!_disposed && wasActive) _onComplete?.call();
    });
    _tts.setCancelHandler(() {
      _hasActiveUtterance = false;
    });
    _tts.setErrorHandler((message) {
      _hasActiveUtterance = false;
      if (!_disposed) _onError?.call(message);
    });
    _tts.setProgressHandler((ignoredText, start, end, ignoredWord) {
      if (!_disposed) {
        _onProgress?.call(TtsSpeechProgress(start: start, end: end));
      }
    });
  }

  final FlutterTts _tts;
  final TtsAudioFocusAware _backgroundSession;
  VoidCallback? _onComplete;
  ValueChanged<Object?>? _onError;
  ValueChanged<TtsSpeechProgress>? _onProgress;
  bool _disposed = false;
  bool _hasActiveUtterance = false;

  @override
  void setOnComplete(VoidCallback callback) => _onComplete = callback;

  @override
  void setOnError(ValueChanged<Object?> callback) => _onError = callback;

  @override
  void setOnProgress(ValueChanged<TtsSpeechProgress> callback) =>
      _onProgress = callback;

  @override
  Future<void> speak(String text) async {
    if (_disposed || text.trim().isEmpty) return;
    _hasActiveUtterance = true;
    try {
      await _tts.speak(text);
    } catch (_) {
      _hasActiveUtterance = false;
      // TTS is optional.  A missing or unhealthy Windows provider must leave
      // Reader usable and report an unavailable playback attempt to the
      // controller instead of escaping through the Reader route.
    }
  }

  @override
  Future<void> pause() async {
    if (_disposed) return;
    try {
      await _tts.pause();
    } catch (_) {
      // TTS is optional; a missing Windows provider must not take down the
      // Reader or turn a pause command into an uncaught platform exception.
    }
  }

  @override
  Future<void> resume(String text) async {
    // flutter_tts resumes the paused utterance when speak is called again.
    if (_disposed) return;
    _hasActiveUtterance = true;
    try {
      await _tts.speak(text);
    } catch (_) {
      _hasActiveUtterance = false;
      // Provider unavailable; the controller remains in its safe idle/error
      // transition without taking down the Reader.
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    if (!_hasActiveUtterance) return;
    try {
      await _tts.stop();
    } catch (_) {
      // Provider unavailable: the controller still reaches its idle state.
    } finally {
      _hasActiveUtterance = false;
    }
  }

  @override
  Future<void> setRate(double rate) async {
    if (_disposed) return;
    try {
      await _tts.setSpeechRate(rate.clamp(0.1, 2.0).toDouble());
    } catch (_) {
      // Speech-rate persistence remains valid even when Windows has no SAPI
      // voice; playback will report TTS unavailable when attempted.
    }
  }

  @override
  Future<List<TtsVoice>> voices() async {
    if (_disposed) return const [];
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((entry) {
            final name = entry['name']?.toString() ?? '';
            final locale = entry['locale']?.toString() ?? '';
            final identifier = entry['identifier']?.toString();
            return TtsVoice(name: name, locale: locale, identifier: identifier);
          })
          .where((voice) => voice.name.isNotEmpty || voice.locale.isNotEmpty)
          .toList();
    } catch (_) {
      // Voice enumeration is optional and must never block Reader startup.
      return const [];
    }
  }

  @override
  Future<void> setVoice(TtsVoice voice) async {
    if (_disposed) return;
    try {
      await _tts.setVoice(voice.toPlatformMap());
    } catch (_) {
      // Keep the Reader usable when a saved/provider voice disappears.
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _onComplete = null;
    _onError = null;
    _onProgress = null;
    await _backgroundSession.disposeBackgroundSession();
    if (!_hasActiveUtterance) return;
    try {
      await _tts.stop();
    } catch (_) {
      // A platform channel can already be detached during app shutdown.
    } finally {
      _hasActiveUtterance = false;
    }
  }

  @override
  void setOnAudioFocusLost(VoidCallback callback) =>
      _backgroundSession.setOnAudioFocusLost(callback);

  @override
  void setOnAudioFocusGained(VoidCallback callback) =>
      _backgroundSession.setOnAudioFocusGained(callback);

  @override
  void setOnMediaCommand(ValueChanged<String> callback) =>
      _backgroundSession.setOnMediaCommand(callback);

  @override
  Future<void> startBackgroundSession() =>
      _backgroundSession.startBackgroundSession();

  @override
  Future<void> stopBackgroundSession() =>
      _backgroundSession.stopBackgroundSession();

  @override
  Future<void> disposeBackgroundSession() =>
      _backgroundSession.disposeBackgroundSession();

  @override
  Future<void> updateMediaPlaybackState(String state) =>
      _backgroundSession.updateMediaPlaybackState(state);
}

/// Owns the TTS state for one Reader route.
///
/// It stores only the transient speech segment index. Reading progress remains
/// owned by the existing Reader Locator/progress controller.
final class TtsReadingController extends ChangeNotifier {
  TtsReadingController({
    TtsEngine? engine,
    DateTime Function()? now,
    this._sleepTimerTickInterval = const Duration(seconds: 1),
  }) : _engine = engine ?? FlutterTtsEngine(),
       _now = now ?? DateTime.now {
    _engine.setOnComplete(_onSpeechComplete);
    _engine.setOnError(_onSpeechError);
    _engine.setOnProgress(_onSpeechProgress);
    final focusAware = _focusAware;
    focusAware?.setOnAudioFocusLost(_onAudioFocusLost);
    focusAware?.setOnAudioFocusGained(_onAudioFocusGained);
    focusAware?.setOnMediaCommand(_onMediaCommand);
  }

  final TtsEngine _engine;
  final DateTime Function() _now;
  final Duration _sleepTimerTickInterval;
  ReadableTextSource _source = ReadableTextSource.fromText('');
  TtsReadingState _state = TtsReadingState.idle;
  int? _currentIndex;
  double _speechRate = 1.0;
  TtsVoice? _selectedVoice;
  List<TtsVoice> _voices = const [];
  int _generation = 0;
  bool _completionArmed = false;
  int? _activeSpeechCharacterOffset;
  // Absolute UTF-16 offset represented by the current platform utterance.
  // Normally this is the segment start; a live-rate restart begins at the
  // current speech offset and must keep progress mapping continuous.
  int? _utteranceStartOffset;
  Timer? _sleepTimerTicker;
  DateTime? _sleepTimerDeadline;
  int? _sleepTimerChapterEndOffset;
  TtsSleepTimerState _sleepTimer = const TtsSleepTimerState.inactive();
  bool _resumeAfterAudioFocus = false;
  int _lastReaderOffset = 0;
  String? _publishedMediaState;
  bool _disposed = false;

  TtsAudioFocusAware? get _focusAware =>
      _engine is TtsAudioFocusAware ? _engine as TtsAudioFocusAware : null;

  TtsReadingState get state => _state;
  List<ReadableTextSegment> get segments => _source.segments;
  ReadableTextSegment? get activeSegment =>
      _currentIndex == null || _currentIndex! >= segments.length
      ? null
      : segments[_currentIndex!];
  double get speechRate => _speechRate;
  TtsVoice? get selectedVoice => _selectedVoice;
  List<TtsVoice> get voicesList => List.unmodifiable(_voices);
  int? get activeSpeechCharacterOffset => _activeSpeechCharacterOffset;
  TtsSleepTimerState get sleepTimer => _sleepTimer;

  void setSource(ReadableTextSource source) {
    if (_disposed) return;
    // Opening a Reader starts in the idle state.  Do not call into an
    // optional native TTS provider just to stop a session that does not
    // exist; some Windows providers fault inside their stop implementation
    // when no utterance has been started.  An active session is still stopped
    // before replacing its source.
    if (_state != TtsReadingState.idle &&
        _state != TtsReadingState.stoppedAtEnd) {
      unawaited(stop());
    }
    _source = source;
    _currentIndex = null;
    _activeSpeechCharacterOffset = null;
    _utteranceStartOffset = null;
    _notify();
  }

  /// Clears an unavailable persisted voice so the platform TTS engine can use
  /// its own current system default without guessing another voice.
  void clearVoiceSelection() {
    if (_disposed || _selectedVoice == null) return;
    _selectedVoice = null;
    _notify();
  }

  Future<void> setSleepTimer(
    TtsSleepTimerMode mode, {
    int? currentChapterEndOffset,
  }) async {
    if (_disposed) return;
    _cancelSleepTimer();
    if (mode == TtsSleepTimerMode.off) {
      _sleepTimer = const TtsSleepTimerState.inactive();
      _notify();
      return;
    }

    _sleepTimerChapterEndOffset = mode == TtsSleepTimerMode.endOfChapter
        ? _resolveChapterEndOffset(currentChapterEndOffset)
        : null;
    final duration = _durationForSleepTimer(mode);
    _sleepTimerDeadline = duration == null ? null : _now().add(duration);
    _sleepTimer = TtsSleepTimerState(
      mode: mode,
      status: TtsSleepTimerStatus.active,
      remaining: duration,
    );
    if (duration != null) {
      _sleepTimerTicker = Timer.periodic(
        _sleepTimerTickInterval,
        (_) => _tickSleepTimer(),
      );
      _tickSleepTimer();
    } else {
      _notify();
      _stopIfChapterAlreadyFinished();
    }
  }

  int _resolveChapterEndOffset(int? requested) {
    final lastEnd = segments.isEmpty ? 0 : segments.last.endCharacterOffset;
    if (requested == null) return lastEnd;
    return requested.clamp(0, lastEnd).toInt();
  }

  Duration? _durationForSleepTimer(TtsSleepTimerMode mode) => switch (mode) {
    TtsSleepTimerMode.off || TtsSleepTimerMode.endOfChapter => null,
    TtsSleepTimerMode.minutes15 => const Duration(minutes: 15),
    TtsSleepTimerMode.minutes30 => const Duration(minutes: 30),
    TtsSleepTimerMode.minutes60 => const Duration(minutes: 60),
  };

  void _tickSleepTimer() {
    if (_disposed || !_sleepTimer.isActive) return;
    final deadline = _sleepTimerDeadline;
    if (deadline == null) return;
    final remaining = deadline.difference(_now());
    if (remaining <= Duration.zero) {
      _expireSleepTimer();
      return;
    }
    _sleepTimer = TtsSleepTimerState(
      mode: _sleepTimer.mode,
      status: TtsSleepTimerStatus.active,
      remaining: remaining,
    );
    _notify();
  }

  void _stopIfChapterAlreadyFinished() {
    final end = _sleepTimerChapterEndOffset;
    final offset = _activeSpeechCharacterOffset;
    if (end != null && offset != null && offset >= end) {
      _expireSleepTimer();
    }
  }

  void _cancelSleepTimer() {
    _sleepTimerTicker?.cancel();
    _sleepTimerTicker = null;
    _sleepTimerDeadline = null;
    _sleepTimerChapterEndOffset = null;
  }

  void _clearExpiredSleepTimer() {
    if (!_sleepTimer.isExpired) return;
    _cancelSleepTimer();
    _sleepTimer = const TtsSleepTimerState.inactive();
  }

  Future<void> _expireSleepTimer() async {
    if (_disposed || !_sleepTimer.isActive) return;
    _cancelSleepTimer();
    _sleepTimer = TtsSleepTimerState(
      mode: _sleepTimer.mode,
      status: TtsSleepTimerStatus.expired,
    );
    ++_generation;
    _completionArmed = false;
    _activeSpeechCharacterOffset = null;
    _utteranceStartOffset = null;
    _currentIndex = null;
    _state = TtsReadingState.idle;
    _notify();
    await _engine.stop();
    await _stopBackgroundSession();
  }

  Future<void> loadVoices({bool selectDefault = true}) async {
    if (_disposed) return;
    try {
      _voices = await _engine.voices();
      if (_selectedVoice != null && !_voices.contains(_selectedVoice)) {
        _selectedVoice = null;
      }
      if (selectDefault && _selectedVoice == null) {
        final chinese = _voices.where((voice) {
          final locale = voice.locale.toLowerCase();
          return locale == 'zh-cn' || locale.startsWith('zh-');
        }).firstOrNull;
        if (chinese != null) {
          await _engine.setVoice(chinese);
          _selectedVoice = chinese;
        }
      }
      _notify();
    } catch (_) {
      _voices = const [];
      _notify();
    }
  }

  Future<void> startFromOffset(int absoluteOffset) async {
    if (_disposed || segments.isEmpty) return;
    _lastReaderOffset = absoluteOffset;
    _clearExpiredSleepTimer();
    _resumeAfterAudioFocus = false;
    final index = _indexForOffset(absoluteOffset);
    await _startIndex(index);
  }

  Future<void> toggleFromOffset(int absoluteOffset) async {
    _lastReaderOffset = absoluteOffset;
    switch (_state) {
      case TtsReadingState.playing:
        await pause();
      case TtsReadingState.paused:
        await resume();
      case TtsReadingState.idle || TtsReadingState.stoppedAtEnd:
        await startFromOffset(absoluteOffset);
    }
  }

  /// Dispatches every external playback command through the same controller
  /// methods used by the Reader UI.  `currentOffset` is only needed when a
  /// fresh play command is initiated by an in-app control.
  Future<void> dispatchCommand(TtsCommand command, {int? currentOffset}) async {
    if (currentOffset != null) _lastReaderOffset = currentOffset;
    switch (command) {
      case TtsCommand.playPause:
        await toggleFromOffset(currentOffset ?? _lastReaderOffset);
      case TtsCommand.previous:
        await previous();
      case TtsCommand.next:
        await next();
      case TtsCommand.stop:
        await stop();
    }
  }

  Future<void> pause({bool fromAudioFocus = false}) async {
    if (_disposed || _state != TtsReadingState.playing) return;
    if (!fromAudioFocus) _resumeAfterAudioFocus = false;
    _completionArmed = false;
    _state = TtsReadingState.paused;
    _notify();
    await _engine.pause();
  }

  Future<void> resume() async {
    final segment = activeSegment;
    if (_disposed || segment == null || _state != TtsReadingState.paused) {
      return;
    }
    _resumeAfterAudioFocus = false;
    final generation = ++_generation;
    _completionArmed = true;
    _state = TtsReadingState.playing;
    _notify();
    try {
      await _engine.resume(segment.text);
      if (generation != _generation && !_disposed) return;
    } catch (error) {
      _onSpeechError(error);
    }
  }

  Future<void> stop() async {
    if (_disposed) return;
    _resumeAfterAudioFocus = false;
    _cancelSleepTimer();
    _sleepTimer = const TtsSleepTimerState.inactive();
    final generation = ++_generation;
    _completionArmed = false;
    _activeSpeechCharacterOffset = null;
    _utteranceStartOffset = null;
    await _engine.stop();
    if (_disposed || generation != _generation) return;
    await _stopBackgroundSession();
    _state = TtsReadingState.idle;
    _currentIndex = null;
    _notify();
  }

  Future<void> previous() async {
    if (segments.isEmpty) return;
    _resumeAfterAudioFocus = false;
    _clearExpiredSleepTimer();
    final index = (_currentIndex ?? 0) - 1;
    await _startIndex(index.clamp(0, segments.length - 1).toInt());
  }

  Future<void> next() async {
    if (segments.isEmpty) return;
    _resumeAfterAudioFocus = false;
    _clearExpiredSleepTimer();
    final index = (_currentIndex ?? -1) + 1;
    if (index >= segments.length) {
      _cancelSleepTimer();
      _sleepTimer = const TtsSleepTimerState.inactive();
      _state = TtsReadingState.stoppedAtEnd;
      _notify();
      unawaited(_stopBackgroundSession());
      return;
    }
    if (_sleepTimer.mode == TtsSleepTimerMode.endOfChapter &&
        _sleepTimer.isActive &&
        _sleepTimerChapterEndOffset != null &&
        segments[index].startCharacterOffset >= _sleepTimerChapterEndOffset!) {
      unawaited(_expireSleepTimer());
      return;
    }
    await _startIndex(index);
  }

  /// Called after a user scroll/page/chapter action. TTS follows the existing
  /// Reader position and discards the previous utterance.  A forced restart
  /// is important when navigation remains within one long speech segment: the
  /// old utterance must not continue from a stale location.
  void followReaderPosition(
    int absoluteOffset, {
    bool forceRestart = false,
    int? chapterEndOffset,
  }) {
    _lastReaderOffset = absoluteOffset;
    if (_disposed ||
        (_state != TtsReadingState.playing &&
            _state != TtsReadingState.paused)) {
      return;
    }
    if (_sleepTimer.mode == TtsSleepTimerMode.endOfChapter &&
        chapterEndOffset != null) {
      _sleepTimerChapterEndOffset = _resolveChapterEndOffset(chapterEndOffset);
      _stopIfChapterAlreadyFinished();
      if (_state == TtsReadingState.idle) return;
    }
    final index = _indexForOffset(absoluteOffset);
    if (index == _currentIndex && !forceRestart) return;
    unawaited(_startIndex(index));
  }

  Future<void> setSpeechRate(double value) async {
    if (_disposed) return;
    final nextRate = value.clamp(0.5, 2.0).toDouble();
    final wasPlaying = _state == TtsReadingState.playing;
    final segment = activeSegment;
    final offset = _activeSpeechCharacterOffset;
    _speechRate = nextRate;

    // Most platform engines apply speech rate to the next utterance only.
    // Restart the current short segment from its live UTF-16 position so a
    // slider change is audible without replaying already spoken text.
    if (wasPlaying && segment != null && offset != null) {
      await _restartCurrentUtteranceAt(offset);
      return;
    }
    try {
      await _engine.setRate(_speechRate);
    } catch (_) {
      // A missing provider must not make a settings change abort Reader.
    }
    _notify();
  }

  Future<void> setVoice(TtsVoice voice) async {
    if (_disposed) return;
    await _engine.setVoice(voice);
    _selectedVoice = voice;
    _notify();
  }

  int _indexForOffset(int offset) {
    if (segments.isEmpty) return 0;
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].contains(offset) ||
          (offset < segments[i].startCharacterOffset && i == 0)) {
        return i;
      }
      if (offset < segments[i].startCharacterOffset) return i - 1;
    }
    return segments.length - 1;
  }

  Future<void> _startIndex(int index) async {
    if (_disposed || segments.isEmpty) return;
    final safeIndex = index.clamp(0, segments.length - 1).toInt();
    if (_sleepTimer.mode == TtsSleepTimerMode.endOfChapter &&
        _sleepTimer.isActive &&
        _sleepTimerChapterEndOffset != null &&
        segments[safeIndex].startCharacterOffset >=
            _sleepTimerChapterEndOffset!) {
      unawaited(_expireSleepTimer());
      return;
    }
    final generation = ++_generation;
    _completionArmed = false;
    await _engine.stop();
    if (_disposed || generation != _generation) return;
    _currentIndex = safeIndex;
    _activeSpeechCharacterOffset = segments[safeIndex].startCharacterOffset;
    _utteranceStartOffset = segments[safeIndex].startCharacterOffset;
    _completionArmed = true;
    _state = TtsReadingState.playing;
    _notify();
    try {
      await _startBackgroundSession();
      // The state notification may have happened before MediaSession was
      // created; publish once more after the native session is active.
      _publishMediaState(force: true);
      await _engine.setRate(_speechRate);
      if (_selectedVoice != null) await _engine.setVoice(_selectedVoice!);
      await _engine.speak(segments[safeIndex].text);
    } catch (error) {
      _onSpeechError(error);
    }
  }

  void _onSpeechComplete() {
    if (_disposed || _state != TtsReadingState.playing || !_completionArmed) {
      return;
    }
    _completionArmed = false;
    final index = _currentIndex;
    if (index == null || index >= segments.length - 1) {
      if (_sleepTimer.mode == TtsSleepTimerMode.endOfChapter &&
          _sleepTimer.isActive) {
        unawaited(_expireSleepTimer());
        return;
      }
      _cancelSleepTimer();
      _sleepTimer = const TtsSleepTimerState.inactive();
      _activeSpeechCharacterOffset = null;
      _utteranceStartOffset = null;
      _state = TtsReadingState.stoppedAtEnd;
      _notify();
      unawaited(_stopBackgroundSession());
      return;
    }
    final nextIndex = index + 1;
    final chapterEnd = _sleepTimerChapterEndOffset;
    if (_sleepTimer.mode == TtsSleepTimerMode.endOfChapter &&
        _sleepTimer.isActive &&
        chapterEnd != null &&
        segments[nextIndex].startCharacterOffset >= chapterEnd) {
      unawaited(_expireSleepTimer());
      return;
    }
    _currentIndex = nextIndex;
    _activeSpeechCharacterOffset =
        segments[_currentIndex!].startCharacterOffset;
    _utteranceStartOffset = segments[_currentIndex!].startCharacterOffset;
    _notify();
    unawaited(_speakCurrent());
  }

  void _onSpeechProgress(TtsSpeechProgress progress) {
    final segment = activeSegment;
    if (_disposed ||
        segment == null ||
        _state != TtsReadingState.playing ||
        !_completionArmed) {
      return;
    }
    final relative = progress.start.clamp(0, segment.text.length).toInt();
    final maxOffset = segment.endCharacterOffset > segment.startCharacterOffset
        ? segment.endCharacterOffset - 1
        : segment.startCharacterOffset;
    final utteranceStart =
        _utteranceStartOffset ?? segment.startCharacterOffset;
    final absolute = (utteranceStart + relative).clamp(
      segment.startCharacterOffset,
      maxOffset,
    );
    final chapterEnd = _sleepTimerChapterEndOffset;
    if (_sleepTimer.mode == TtsSleepTimerMode.endOfChapter &&
        _sleepTimer.isActive &&
        chapterEnd != null &&
        absolute >= chapterEnd) {
      unawaited(_expireSleepTimer());
      return;
    }
    if (absolute == _activeSpeechCharacterOffset) return;
    _activeSpeechCharacterOffset = absolute;
    _notify();
  }

  Future<void> _speakCurrent() async {
    final index = _currentIndex;
    final generation = _generation;
    if (_disposed || index == null || generation != _generation) return;
    try {
      _completionArmed = true;
      await _engine.speak(segments[index].text);
    } catch (error) {
      _onSpeechError(error);
    }
  }

  Future<void> _restartCurrentUtteranceAt(int absoluteOffset) async {
    final segment = activeSegment;
    if (_disposed || segment == null) return;
    final maxOffset = segment.endCharacterOffset > segment.startCharacterOffset
        ? segment.endCharacterOffset - 1
        : segment.startCharacterOffset;
    final start = absoluteOffset
        .clamp(segment.startCharacterOffset, maxOffset)
        .toInt();
    final relative = (start - segment.startCharacterOffset).clamp(
      0,
      segment.text.length,
    );
    final remaining = segment.text.substring(relative);
    if (remaining.trim().isEmpty) return;

    final generation = ++_generation;
    _completionArmed = false;
    await _engine.stop();
    if (_disposed || generation != _generation) return;
    _utteranceStartOffset = start;
    _activeSpeechCharacterOffset = start;
    _completionArmed = true;
    _state = TtsReadingState.playing;
    _notify();
    try {
      await _engine.setRate(_speechRate);
      if (_selectedVoice != null) await _engine.setVoice(_selectedVoice!);
      await _engine.speak(remaining);
    } catch (error) {
      _onSpeechError(error);
    }
  }

  void _onSpeechError(Object? error) {
    if (_disposed) return;
    _cancelSleepTimer();
    _sleepTimer = const TtsSleepTimerState.inactive();
    _completionArmed = false;
    _activeSpeechCharacterOffset = null;
    _utteranceStartOffset = null;
    _state = TtsReadingState.idle;
    _notify();
    unawaited(_stopBackgroundSession());
  }

  void _onAudioFocusLost() {
    if (_disposed || _state != TtsReadingState.playing) return;
    _resumeAfterAudioFocus = true;
    unawaited(pause(fromAudioFocus: true));
  }

  void _onAudioFocusGained() {
    if (_disposed || !_resumeAfterAudioFocus) return;
    if (_state == TtsReadingState.paused) {
      unawaited(resume());
    }
  }

  Future<void> _startBackgroundSession() async {
    try {
      await _focusAware?.startBackgroundSession();
    } catch (_) {
      // Foreground execution is an optional platform capability. TTS itself
      // remains usable when a host cannot provide it.
    }
  }

  Future<void> _stopBackgroundSession() async {
    try {
      await _focusAware?.stopBackgroundSession();
    } catch (_) {
      // The Android activity may already be detached during shutdown.
    }
  }

  void _onMediaCommand(String command) {
    final parsed = switch (command) {
      'playPause' => TtsCommand.playPause,
      'previous' => TtsCommand.previous,
      'next' => TtsCommand.next,
      'stop' => TtsCommand.stop,
      _ => null,
    };
    if (parsed != null) unawaited(dispatchCommand(parsed));
  }

  void _publishMediaState({bool force = false}) {
    final focusAware = _focusAware;
    if (focusAware == null) return;
    final state = switch (_state) {
      TtsReadingState.playing => 'playing',
      TtsReadingState.paused => 'paused',
      TtsReadingState.idle || TtsReadingState.stoppedAtEnd => 'stopped',
    };
    if (!force && state == _publishedMediaState) return;
    _publishedMediaState = state;
    unawaited(focusAware.updateMediaPlaybackState(state));
  }

  void _notify() {
    if (_disposed) return;
    _publishMediaState();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_generation;
    _cancelSleepTimer();
    unawaited(_stopBackgroundSession());
    unawaited(_engine.dispose());
    super.dispose();
  }
}
