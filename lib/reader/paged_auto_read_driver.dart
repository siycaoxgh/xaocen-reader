/// Timer-driven Paged AutoRead adapter.
///
/// This driver owns only pacing and operation serialization. All page
/// generation, bounded-window maintenance, chapter-first-page behavior, and
/// Locator confirmation remain inside [PagedReaderController].
library;

import 'dart:async';

import '../domain/reader/auto_read_controller.dart';
import 'paged_reader_controller.dart';

typedef PagedAutoReadConfirm = Future<void> Function();

final class PagedAutoReadDriver {
  PagedAutoReadDriver({
    required this._readerController,
    required this._controller,
    required this._confirmPosition,
    required this._canDrive,
    this._intervalOverride,
  }) {
    _events = _controller.events.listen(_onControllerEvent);
  }

  final PagedReaderController _readerController;
  final AutoReadController _controller;
  final PagedAutoReadConfirm _confirmPosition;
  final bool Function() _canDrive;
  final Duration? _intervalOverride;
  late final StreamSubscription<AutoReadEvent> _events;

  Timer? _timer;
  Future<void>? _activeNavigation;
  int? _driveGeneration;
  bool _disposed = false;

  bool get isTicking => _timer?.isActive ?? false;
  bool get isNavigationInFlight => _activeNavigation != null;

  Duration get _interval =>
      _intervalOverride ??
      Duration(seconds: _controller.preferences.pagedIntervalSeconds);

  void start() {
    if (_disposed || !_canDrive()) return;
    _controller.start();
    if (_controller.state != AutoReadState.running) return;
    _driveGeneration = _controller.captureGeneration();
    _schedule(_driveGeneration!);
  }

  void pause(AutoReadPauseReason reason) {
    if (_disposed) return;
    final wasRunning = _controller.state == AutoReadState.running;
    _controller.pause(reason);
    _cancelTimer();
    if (wasRunning) unawaited(_confirmAfterNavigation());
  }

  /// Explicit entry point for touch, keyboard, volume, chapter, TOC, search,
  /// and bookmark actions. The action layer can call this before navigation;
  /// the actual navigation remains owned by its existing controller path.
  void pauseForManualNavigation() =>
      pause(AutoReadPauseReason.manualNavigation);

  void resume() {
    if (_disposed || !_canDrive()) return;
    _controller.resume();
    if (_controller.state != AutoReadState.running) return;
    _driveGeneration = _controller.captureGeneration();
    _schedule(_driveGeneration!);
  }

  void stop() {
    if (_disposed) return;
    final shouldConfirm = _controller.state != AutoReadState.idle;
    _controller.stop();
    _cancelTimer();
    if (shouldConfirm) unawaited(_confirmAfterNavigation());
  }

  /// Pauses and invalidates a pending timer for relayout, mode/lifecycle
  /// changes, route pop, or dispose-adjacent interruptions.
  void interrupt(AutoReadPauseReason reason) {
    if (_disposed) return;
    final wasRunning = _controller.state == AutoReadState.running;
    if (wasRunning) _controller.pause(reason);
    _controller.invalidate(reason);
    _cancelTimer();
    if (wasRunning) unawaited(_confirmAfterNavigation());
  }

  void _schedule(int generation) {
    _cancelTimer();
    if (_disposed ||
        _controller.state != AutoReadState.running ||
        !_controller.isCurrentGeneration(generation) ||
        !_canDrive()) {
      return;
    }
    _timer = Timer(_interval, () => unawaited(_runTick(generation)));
  }

  Future<void> _runTick(int generation) async {
    if (_disposed ||
        _controller.state != AutoReadState.running ||
        !_controller.isCurrentGeneration(generation) ||
        !_canDrive() ||
        _activeNavigation != null) {
      final active = _activeNavigation;
      if (active != null) await active;
      if (!_disposed &&
          _controller.state == AutoReadState.running &&
          _controller.isCurrentGeneration(generation) &&
          _canDrive()) {
        _schedule(generation);
      }
      return;
    }

    final operation = _performNavigation(generation);
    _activeNavigation = operation;
    try {
      await operation;
    } finally {
      if (identical(_activeNavigation, operation)) _activeNavigation = null;
    }

    if (_disposed ||
        _controller.state != AutoReadState.running ||
        !_controller.isCurrentGeneration(generation) ||
        !_canDrive()) {
      return;
    }
    _schedule(generation);
  }

  Future<void> _performNavigation(int generation) async {
    if (!_controller.isCurrentGeneration(generation)) return;
    final result = _readerController.nextPage();
    await _confirmPosition();
    if (_disposed ||
        generation != _controller.generation ||
        !_controller.isCurrentGeneration(generation)) {
      return;
    }
    if (result == PageTurnResult.endReached) {
      _controller.stopAtEnd();
    }
  }

  Future<void> _confirmAfterNavigation({bool force = false}) async {
    final active = _activeNavigation;
    if (active != null) await active;
    if (force || !_disposed) await _confirmPosition();
  }

  void _onControllerEvent(AutoReadEvent event) {
    if (_disposed ||
        event.kind != AutoReadEventKind.preferencesChanged ||
        _controller.state != AutoReadState.running ||
        !_canDrive()) {
      return;
    }
    _driveGeneration = event.generation;
    _schedule(event.generation);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTimer();
    _events.cancel();
    _controller.invalidate(AutoReadPauseReason.lifecycle);
    unawaited(_confirmAfterNavigation(force: true));
  }
}
