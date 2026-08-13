// ignore_for_file: prefer_initializing_formals

import 'dart:async';

/// User-facing policy for keeping the device display awake while reading.
enum ReaderScreenAwakeMode { followSystem, smart, whileReading }

/// Lifecycle state understood by the platform-independent awake controller.
/// This deliberately does not depend on Flutter's AppLifecycleState.
enum ReaderScreenAwakeLifecycle { foreground, inactive, background, detached }

abstract interface class ReaderScreenAwakeTimer {
  void cancel();
}

abstract interface class ReaderScreenAwakeScheduler {
  ReaderScreenAwakeTimer schedule(Duration delay, void Function() callback);
}

final class SystemReaderScreenAwakeScheduler
    implements ReaderScreenAwakeScheduler {
  const SystemReaderScreenAwakeScheduler();

  @override
  ReaderScreenAwakeTimer schedule(Duration delay, void Function() callback) =>
      _SystemReaderScreenAwakeTimer(Timer(delay, callback));
}

final class _SystemReaderScreenAwakeTimer implements ReaderScreenAwakeTimer {
  _SystemReaderScreenAwakeTimer(this._timer);
  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

/// Owns the Reader-only screen-awake state machine.
///
/// The controller knows nothing about widgets or Android. A platform adapter is
/// supplied for the one side effect (setting the host window keep-awake flag),
/// and the Reader supplies a callback to pause AutoRead after smart inactivity.
final class ReaderScreenAwakeController {
  ReaderScreenAwakeController({
    required Future<void> Function(bool enabled) setKeepScreenOn,
    void Function()? onSmartTimeout,
    DateTime Function()? now,
    ReaderScreenAwakeScheduler? scheduler,
  }) : _setKeepScreenOn = setKeepScreenOn,
       _onSmartTimeout = onSmartTimeout,
       _now = now ?? DateTime.now,
       _scheduler = scheduler ?? const SystemReaderScreenAwakeScheduler();

  static const int defaultInactivityMinutes = 30;
  static const List<int> inactivityOptions = <int>[15, 30, 60];

  final Future<void> Function(bool enabled) _setKeepScreenOn;
  final void Function()? _onSmartTimeout;
  final DateTime Function() _now;
  final ReaderScreenAwakeScheduler _scheduler;

  ReaderScreenAwakeMode mode = ReaderScreenAwakeMode.followSystem;
  int inactivityMinutes = defaultInactivityMinutes;
  ReaderScreenAwakeLifecycle lifecycle = ReaderScreenAwakeLifecycle.foreground;
  bool readerForeground = false;
  bool keepScreenOn = false;
  DateTime? lastRealUserActivity;

  ReaderScreenAwakeTimer? _timer;
  bool _disposed = false;

  bool get appForeground => lifecycle == ReaderScreenAwakeLifecycle.foreground;

  bool get isActive => !_disposed && readerForeground && appForeground;

  void updatePreferences({
    required ReaderScreenAwakeMode mode,
    required int inactivityMinutes,
  }) {
    this.mode = mode;
    this.inactivityMinutes = inactivityOptions.contains(inactivityMinutes)
        ? inactivityMinutes
        : defaultInactivityMinutes;
    if (mode != ReaderScreenAwakeMode.smart) {
      lastRealUserActivity = null;
    }
    _reconcile();
  }

  /// Reader route became visible. This is a user-initiated entry, so it is a
  /// legitimate initial activity for smart mode; lifecycle callbacks alone are
  /// never treated as activity.
  void enterReader() {
    if (_disposed) return;
    readerForeground = true;
    if (mode == ReaderScreenAwakeMode.smart) {
      _recordActivityAndSchedule();
    } else {
      _reconcile();
    }
  }

  void leaveReader() {
    readerForeground = false;
    lastRealUserActivity = null;
    _cancelTimer();
    _setKeep(false);
  }

  void setLifecycle(ReaderScreenAwakeLifecycle next) {
    if (_disposed) return;
    lifecycle = next;
    if (!appForeground) {
      _cancelTimer();
      _setKeep(false);
      return;
    }
    // Resuming is not user activity. While-reading can be restored by policy;
    // smart mode waits for the next real interaction.
    if (mode == ReaderScreenAwakeMode.smart) {
      _cancelTimer();
      _setKeep(false);
    } else {
      _reconcile();
    }
  }

  /// Records only an actual user action. Automatic scroll/page ticks must not
  /// call this method.
  void recordUserActivity() {
    if (!isActive) return;
    if (mode == ReaderScreenAwakeMode.smart) {
      _recordActivityAndSchedule();
    } else if (mode == ReaderScreenAwakeMode.whileReading) {
      _setKeep(true);
    }
  }

  /// Explicitly documents that automatic Reader motion is not activity.
  void recordAutomaticActivity() {}

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    readerForeground = false;
    _cancelTimer();
    _setKeep(false);
  }

  void _recordActivityAndSchedule() {
    if (!isActive) return;
    lastRealUserActivity = _now();
    _setKeep(true);
    _scheduleTimeout();
  }

  void _reconcile() {
    if (!isActive) {
      _cancelTimer();
      _setKeep(false);
      return;
    }
    switch (mode) {
      case ReaderScreenAwakeMode.followSystem:
        _cancelTimer();
        _setKeep(false);
      case ReaderScreenAwakeMode.whileReading:
        _cancelTimer();
        _setKeep(true);
      case ReaderScreenAwakeMode.smart:
        if (lastRealUserActivity == null) {
          _cancelTimer();
          _setKeep(false);
        } else {
          _setKeep(true);
          _scheduleTimeout();
        }
    }
  }

  void _scheduleTimeout() {
    _cancelTimer();
    if (!isActive || mode != ReaderScreenAwakeMode.smart) return;
    final activity = lastRealUserActivity;
    if (activity == null) return;
    final timeout = Duration(minutes: inactivityMinutes);
    final elapsed = _now().difference(activity);
    final remaining = timeout - elapsed;
    _timer = _scheduler.schedule(
      remaining.isNegative ? Duration.zero : remaining,
      _handleTimeout,
    );
  }

  void _handleTimeout() {
    _timer = null;
    if (!isActive || mode != ReaderScreenAwakeMode.smart) return;
    final activity = lastRealUserActivity;
    if (activity == null) return;
    if (_now().difference(activity) < Duration(minutes: inactivityMinutes)) {
      _scheduleTimeout();
      return;
    }
    lastRealUserActivity = null;
    _setKeep(false);
    _onSmartTimeout?.call();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _setKeep(bool enabled) {
    if (keepScreenOn == enabled) return;
    keepScreenOn = enabled;
    unawaited(_setKeepScreenOn(enabled));
  }
}
