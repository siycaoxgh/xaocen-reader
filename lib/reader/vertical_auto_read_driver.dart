/// Ticker-driven vertical AutoRead adapter.
///
/// This adapter owns only transient scroll driving. ReaderLocator confirmation
/// and persistence remain callbacks supplied by the existing Reader layer.
library;

// Private fields retain the adapter boundary while public constructor names
// remain descriptive for Reader integration.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../domain/reader/auto_read_controller.dart';

typedef VerticalAutoReadConfirm = Future<void> Function();
typedef VerticalAutoReadFrame = void Function();

final class VerticalAutoReadDriver {
  VerticalAutoReadDriver({
    required TickerProvider vsync,
    required ScrollController scrollController,
    required AutoReadController controller,
    required VerticalAutoReadConfirm confirmPosition,
    required VerticalAutoReadFrame onFrame,
    required bool Function() canDrive,
  }) : _scrollController = scrollController,
       _controller = controller,
       _confirmPosition = confirmPosition,
       _onFrame = onFrame,
       _canDrive = canDrive {
    _ticker = vsync.createTicker(_tick);
    _events = _controller.events.listen(_onControllerEvent);
  }

  final ScrollController _scrollController;
  final AutoReadController _controller;
  final VerticalAutoReadConfirm _confirmPosition;
  final VerticalAutoReadFrame _onFrame;
  final bool Function() _canDrive;
  late final Ticker _ticker;
  late final StreamSubscription<AutoReadEvent> _events;

  Duration? _lastElapsed;
  int? _driveGeneration;
  bool _applyingAutoScroll = false;
  bool _disposed = false;

  bool get isApplyingAutoScroll => _applyingAutoScroll;
  bool get isTicking => _ticker.isActive;

  void start() {
    if (_disposed || !_canDrive()) return;
    _controller.start();
    if (_controller.state != AutoReadState.running) return;
    _driveGeneration = _controller.captureGeneration();
    _lastElapsed = null;
    if (!_ticker.isActive) _ticker.start();
  }

  void pause(AutoReadPauseReason reason) {
    if (_disposed) return;
    final wasRunning = _controller.state == AutoReadState.running;
    _controller.pause(reason);
    _stopTicker();
    if (wasRunning) unawaited(_confirmPosition());
  }

  void resume() {
    if (_disposed || !_canDrive()) return;
    _controller.resume();
    if (_controller.state != AutoReadState.running) return;
    _driveGeneration = _controller.captureGeneration();
    _lastElapsed = null;
    if (!_ticker.isActive) _ticker.start();
  }

  void stop() {
    if (_disposed) return;
    final shouldConfirm = _controller.state != AutoReadState.idle;
    _controller.stop();
    _stopTicker();
    if (shouldConfirm) unawaited(_confirmPosition());
  }

  /// Pauses and invalidates work for relayout, mode/lifecycle changes, or
  /// another interruption where a stale ticker callback must not continue.
  void interrupt(AutoReadPauseReason reason) {
    if (_disposed) return;
    final wasRunning = _controller.state == AutoReadState.running;
    if (wasRunning) _controller.pause(reason);
    _controller.invalidate(reason);
    _stopTicker();
    if (wasRunning) unawaited(_confirmPosition());
  }

  void _stopTicker() {
    _ticker.stop();
    _lastElapsed = null;
    _driveGeneration = null;
  }

  void _onControllerEvent(AutoReadEvent event) {
    if (_disposed ||
        event.kind != AutoReadEventKind.preferencesChanged ||
        _controller.state != AutoReadState.running ||
        !_canDrive()) {
      return;
    }
    _driveGeneration = event.generation;
    _lastElapsed = null;
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    if (_disposed ||
        _controller.state != AutoReadState.running ||
        _driveGeneration == null ||
        !_controller.isCurrentGeneration(_driveGeneration!)) {
      _stopTicker();
      return;
    }
    if (!_canDrive()) {
      interrupt(AutoReadPauseReason.lifecycle);
      return;
    }
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;

    final seconds =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    final delta =
        seconds.clamp(0.0, 0.1) *
        _controller.preferences.verticalVelocityPixelsPerSecond;
    if (delta <= 0) return;

    final position = _scrollController.position;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    _applyingAutoScroll = true;
    try {
      position.jumpTo(target);
      _onFrame();
    } finally {
      _applyingAutoScroll = false;
    }

    if (target >= position.maxScrollExtent - 0.5) {
      final generation = _driveGeneration;
      _stopTicker();
      if (generation != null) unawaited(_finishAtEnd(generation));
    }
  }

  Future<void> _finishAtEnd(int generation) async {
    await _confirmPosition();
    if (_disposed ||
        generation != _controller.generation ||
        !_controller.isCurrentGeneration(generation)) {
      return;
    }
    _controller.stopAtEnd();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _events.cancel();
    _stopTicker();
    _controller.invalidate(AutoReadPauseReason.lifecycle);
    unawaited(_confirmPosition());
    _ticker.dispose();
  }
}
