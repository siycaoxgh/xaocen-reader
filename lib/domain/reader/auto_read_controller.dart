/// M5.4 AutoRead state and operation contract.
library;

import 'dart:async';

import 'auto_read_preferences.dart';

enum AutoReadState { idle, running, paused, stoppedAtEnd }

enum AutoReadPauseReason {
  manualNavigation,
  settingsPanel,
  toc,
  bookmark,
  search,
  lifecycle,
  modeSwitch,
  relayout,
}

enum AutoReadEventKind {
  stateChanged,
  preferencesChanged,
  generationInvalidated,
}

final class AutoReadEvent {
  const AutoReadEvent({
    required this.kind,
    required this.state,
    required this.generation,
    this.pauseReason,
    this.preferences,
  });

  final AutoReadEventKind kind;
  final AutoReadState state;
  final int generation;
  final AutoReadPauseReason? pauseReason;
  final AutoReadPreferences? preferences;
}

/// Maintains AutoRead state without knowing about any Reader widget/controller.
///
/// The generation is invalidated on every effective state or preference
/// change. Future ticker/timer drivers can capture it and discard stale ticks
/// before they request navigation.
final class AutoReadController {
  AutoReadController({AutoReadPreferences? preferences})
    : _preferences = preferences ?? AutoReadPreferences.defaults;

  AutoReadState _state = AutoReadState.idle;
  AutoReadPreferences _preferences;
  int _generation = 0;
  bool _disposed = false;
  final StreamController<AutoReadEvent> _events =
      StreamController<AutoReadEvent>.broadcast(sync: true);

  AutoReadState get state => _state;
  AutoReadPreferences get preferences => _preferences;
  int get generation => _generation;
  Stream<AutoReadEvent> get events => _events.stream;
  bool get isDisposed => _disposed;

  bool isCurrentGeneration(int token) => !_disposed && token == _generation;

  int captureGeneration() => _generation;

  void start() {
    if (_disposed ||
        (_state != AutoReadState.idle &&
            _state != AutoReadState.stoppedAtEnd)) {
      return;
    }
    _transition(AutoReadState.running);
  }

  void pause(AutoReadPauseReason reason) {
    if (_disposed || _state != AutoReadState.running) return;
    _transition(AutoReadState.paused, pauseReason: reason);
  }

  void resume() {
    if (_disposed || _state != AutoReadState.paused) return;
    _transition(AutoReadState.running);
  }

  void stop() {
    if (_disposed || _state == AutoReadState.idle) return;
    _transition(AutoReadState.idle);
  }

  /// Marks a real document EOF. This is distinct from [stop], so UI can show
  /// an end-of-book state while still allowing an explicit start to begin a
  /// new run if the product later permits it.
  void stopAtEnd() {
    if (_disposed || _state != AutoReadState.running) return;
    _transition(AutoReadState.stoppedAtEnd);
  }

  void updatePreferences(AutoReadPreferences preferences) {
    if (_disposed || preferences == _preferences) return;
    _preferences = preferences;
    _generation++;
    _emit(
      AutoReadEvent(
        kind: AutoReadEventKind.preferencesChanged,
        state: _state,
        generation: _generation,
        preferences: _preferences,
      ),
    );
  }

  /// Invalidates a pending driver operation without changing AutoRead state.
  ///
  /// This is used for interruptions such as a mode switch or route change
  /// when the state itself may already be paused/idle. It gives future
  /// drivers one uniform token check instead of relying on timer cancellation
  /// races.
  void invalidate(AutoReadPauseReason reason) {
    if (_disposed) return;
    _generation++;
    _emit(
      AutoReadEvent(
        kind: AutoReadEventKind.generationInvalidated,
        state: _state,
        generation: _generation,
        pauseReason: reason,
        preferences: _preferences,
      ),
    );
  }

  void _transition(AutoReadState next, {AutoReadPauseReason? pauseReason}) {
    if (_state == next) return;
    _state = next;
    _generation++;
    _emit(
      AutoReadEvent(
        kind: AutoReadEventKind.stateChanged,
        state: _state,
        generation: _generation,
        pauseReason: pauseReason,
        preferences: _preferences,
      ),
    );
  }

  void _emit(AutoReadEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    unawaited(_events.close());
  }
}
