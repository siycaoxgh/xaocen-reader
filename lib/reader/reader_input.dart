import 'package:flutter/services.dart';

import '../domain/reader/reader_input_bindings.dart';

export '../domain/reader/reader_input_bindings.dart';

/// Legacy adapter retained for standalone PagedReaderView tests. The active
/// ReaderPage route uses [ReaderInputRouter] and persisted profiles.
final class InputBinding {
  const InputBinding._(this._bindings);

  static const defaults = InputBinding._({
    PhysicalInput.volumeUp: ReaderCommand.previousPage,
    PhysicalInput.volumeDown: ReaderCommand.nextPage,
    PhysicalInput.wheelUp: ReaderCommand.previousPage,
    PhysicalInput.wheelDown: ReaderCommand.nextPage,
    PhysicalInput.arrowLeft: ReaderCommand.previousPage,
    PhysicalInput.arrowRight: ReaderCommand.nextPage,
    PhysicalInput.pageUp: ReaderCommand.previousPage,
    PhysicalInput.pageDown: ReaderCommand.nextPage,
  });

  final Map<PhysicalInput, ReaderCommand> _bindings;

  ReaderCommand? commandFor(PhysicalInput input) => _bindings[input];
}

/// Physical inputs are deliberately separate from Reader actions so future
/// user-configurable bindings do not touch the pagination engine.
enum PhysicalInput {
  volumeUp,
  volumeDown,
  wheelUp,
  wheelDown,
  arrowLeft,
  arrowRight,
  pageUp,
  pageDown,
}

PhysicalInputId? physicalInputIdForKey(LogicalKeyboardKey key) => switch (key) {
  LogicalKeyboardKey.arrowRight => PhysicalInputId.keyboardArrowRight,
  LogicalKeyboardKey.arrowLeft => PhysicalInputId.keyboardArrowLeft,
  LogicalKeyboardKey.arrowUp => PhysicalInputId.keyboardArrowUp,
  LogicalKeyboardKey.arrowDown => PhysicalInputId.keyboardArrowDown,
  LogicalKeyboardKey.pageUp => PhysicalInputId.keyboardPageUp,
  LogicalKeyboardKey.pageDown => PhysicalInputId.keyboardPageDown,
  LogicalKeyboardKey.home => PhysicalInputId.keyboardHome,
  LogicalKeyboardKey.end => PhysicalInputId.keyboardEnd,
  LogicalKeyboardKey.space => PhysicalInputId.keyboardSpace,
  LogicalKeyboardKey.enter => PhysicalInputId.keyboardEnter,
  LogicalKeyboardKey.keyA => PhysicalInputId.keyboardKeyA,
  LogicalKeyboardKey.keyB => PhysicalInputId.keyboardKeyB,
  LogicalKeyboardKey.keyC => PhysicalInputId.keyboardKeyC,
  LogicalKeyboardKey.keyD => PhysicalInputId.keyboardKeyD,
  LogicalKeyboardKey.keyE => PhysicalInputId.keyboardKeyE,
  LogicalKeyboardKey.keyF => PhysicalInputId.keyboardKeyF,
  LogicalKeyboardKey.keyG => PhysicalInputId.keyboardKeyG,
  LogicalKeyboardKey.keyH => PhysicalInputId.keyboardKeyH,
  LogicalKeyboardKey.keyI => PhysicalInputId.keyboardKeyI,
  LogicalKeyboardKey.keyJ => PhysicalInputId.keyboardKeyJ,
  LogicalKeyboardKey.keyK => PhysicalInputId.keyboardKeyK,
  LogicalKeyboardKey.keyL => PhysicalInputId.keyboardKeyL,
  LogicalKeyboardKey.keyM => PhysicalInputId.keyboardKeyM,
  LogicalKeyboardKey.keyN => PhysicalInputId.keyboardKeyN,
  LogicalKeyboardKey.keyO => PhysicalInputId.keyboardKeyO,
  LogicalKeyboardKey.keyP => PhysicalInputId.keyboardKeyP,
  LogicalKeyboardKey.keyQ => PhysicalInputId.keyboardKeyQ,
  LogicalKeyboardKey.keyR => PhysicalInputId.keyboardKeyR,
  LogicalKeyboardKey.keyS => PhysicalInputId.keyboardKeyS,
  LogicalKeyboardKey.keyT => PhysicalInputId.keyboardKeyT,
  LogicalKeyboardKey.keyU => PhysicalInputId.keyboardKeyU,
  LogicalKeyboardKey.keyV => PhysicalInputId.keyboardKeyV,
  LogicalKeyboardKey.keyW => PhysicalInputId.keyboardKeyW,
  LogicalKeyboardKey.keyX => PhysicalInputId.keyboardKeyX,
  LogicalKeyboardKey.keyY => PhysicalInputId.keyboardKeyY,
  LogicalKeyboardKey.keyZ => PhysicalInputId.keyboardKeyZ,
  LogicalKeyboardKey.digit0 => PhysicalInputId.keyboardDigit0,
  LogicalKeyboardKey.digit1 => PhysicalInputId.keyboardDigit1,
  LogicalKeyboardKey.digit2 => PhysicalInputId.keyboardDigit2,
  LogicalKeyboardKey.digit3 => PhysicalInputId.keyboardDigit3,
  LogicalKeyboardKey.digit4 => PhysicalInputId.keyboardDigit4,
  LogicalKeyboardKey.digit5 => PhysicalInputId.keyboardDigit5,
  LogicalKeyboardKey.digit6 => PhysicalInputId.keyboardDigit6,
  LogicalKeyboardKey.digit7 => PhysicalInputId.keyboardDigit7,
  LogicalKeyboardKey.digit8 => PhysicalInputId.keyboardDigit8,
  LogicalKeyboardKey.digit9 => PhysicalInputId.keyboardDigit9,
  LogicalKeyboardKey.numpad0 => PhysicalInputId.keyboardNumpad0,
  LogicalKeyboardKey.numpad1 => PhysicalInputId.keyboardNumpad1,
  LogicalKeyboardKey.numpad2 => PhysicalInputId.keyboardNumpad2,
  LogicalKeyboardKey.numpad3 => PhysicalInputId.keyboardNumpad3,
  LogicalKeyboardKey.numpad4 => PhysicalInputId.keyboardNumpad4,
  LogicalKeyboardKey.numpad5 => PhysicalInputId.keyboardNumpad5,
  LogicalKeyboardKey.numpad6 => PhysicalInputId.keyboardNumpad6,
  LogicalKeyboardKey.numpad7 => PhysicalInputId.keyboardNumpad7,
  LogicalKeyboardKey.numpad8 => PhysicalInputId.keyboardNumpad8,
  LogicalKeyboardKey.numpad9 => PhysicalInputId.keyboardNumpad9,
  LogicalKeyboardKey.numpadAdd => PhysicalInputId.keyboardNumpadAdd,
  LogicalKeyboardKey.numpadSubtract => PhysicalInputId.keyboardNumpadSubtract,
  LogicalKeyboardKey.numpadMultiply => PhysicalInputId.keyboardNumpadMultiply,
  LogicalKeyboardKey.numpadDivide => PhysicalInputId.keyboardNumpadDivide,
  LogicalKeyboardKey.comma => PhysicalInputId.keyboardComma,
  LogicalKeyboardKey.period => PhysicalInputId.keyboardPeriod,
  LogicalKeyboardKey.slash => PhysicalInputId.keyboardSlash,
  LogicalKeyboardKey.semicolon => PhysicalInputId.keyboardSemicolon,
  LogicalKeyboardKey.quote => PhysicalInputId.keyboardQuote,
  LogicalKeyboardKey.bracketLeft => PhysicalInputId.keyboardBracketLeft,
  LogicalKeyboardKey.bracketRight => PhysicalInputId.keyboardBracketRight,
  LogicalKeyboardKey.backslash => PhysicalInputId.keyboardBackslash,
  LogicalKeyboardKey.minus => PhysicalInputId.keyboardMinus,
  LogicalKeyboardKey.equal => PhysicalInputId.keyboardEqual,
  LogicalKeyboardKey.backquote => PhysicalInputId.keyboardBackquote,
  LogicalKeyboardKey.f1 => PhysicalInputId.keyboardF1,
  LogicalKeyboardKey.f2 => PhysicalInputId.keyboardF2,
  LogicalKeyboardKey.f3 => PhysicalInputId.keyboardF3,
  LogicalKeyboardKey.f4 => PhysicalInputId.keyboardF4,
  LogicalKeyboardKey.f5 => PhysicalInputId.keyboardF5,
  LogicalKeyboardKey.f6 => PhysicalInputId.keyboardF6,
  LogicalKeyboardKey.f7 => PhysicalInputId.keyboardF7,
  LogicalKeyboardKey.f8 => PhysicalInputId.keyboardF8,
  LogicalKeyboardKey.f9 => PhysicalInputId.keyboardF9,
  LogicalKeyboardKey.f10 => PhysicalInputId.keyboardF10,
  LogicalKeyboardKey.f11 => PhysicalInputId.keyboardF11,
  LogicalKeyboardKey.f12 => PhysicalInputId.keyboardF12,
  _ => null,
};

/// Resolves the hardware position before the logical/IME-produced key. This
/// keeps OEM punctuation and numpad bindings stable across keyboard layouts.
PhysicalInputId? physicalInputIdForPhysicalKey(
  PhysicalKeyboardKey key,
) => switch (key) {
  PhysicalKeyboardKey.arrowRight => PhysicalInputId.keyboardArrowRight,
  PhysicalKeyboardKey.arrowLeft => PhysicalInputId.keyboardArrowLeft,
  PhysicalKeyboardKey.arrowUp => PhysicalInputId.keyboardArrowUp,
  PhysicalKeyboardKey.arrowDown => PhysicalInputId.keyboardArrowDown,
  PhysicalKeyboardKey.pageUp => PhysicalInputId.keyboardPageUp,
  PhysicalKeyboardKey.pageDown => PhysicalInputId.keyboardPageDown,
  PhysicalKeyboardKey.home => PhysicalInputId.keyboardHome,
  PhysicalKeyboardKey.end => PhysicalInputId.keyboardEnd,
  PhysicalKeyboardKey.space => PhysicalInputId.keyboardSpace,
  PhysicalKeyboardKey.enter => PhysicalInputId.keyboardEnter,
  PhysicalKeyboardKey.keyA => PhysicalInputId.keyboardKeyA,
  PhysicalKeyboardKey.keyB => PhysicalInputId.keyboardKeyB,
  PhysicalKeyboardKey.keyC => PhysicalInputId.keyboardKeyC,
  PhysicalKeyboardKey.keyD => PhysicalInputId.keyboardKeyD,
  PhysicalKeyboardKey.keyE => PhysicalInputId.keyboardKeyE,
  PhysicalKeyboardKey.keyF => PhysicalInputId.keyboardKeyF,
  PhysicalKeyboardKey.keyG => PhysicalInputId.keyboardKeyG,
  PhysicalKeyboardKey.keyH => PhysicalInputId.keyboardKeyH,
  PhysicalKeyboardKey.keyI => PhysicalInputId.keyboardKeyI,
  PhysicalKeyboardKey.keyJ => PhysicalInputId.keyboardKeyJ,
  PhysicalKeyboardKey.keyK => PhysicalInputId.keyboardKeyK,
  PhysicalKeyboardKey.keyL => PhysicalInputId.keyboardKeyL,
  PhysicalKeyboardKey.keyM => PhysicalInputId.keyboardKeyM,
  PhysicalKeyboardKey.keyN => PhysicalInputId.keyboardKeyN,
  PhysicalKeyboardKey.keyO => PhysicalInputId.keyboardKeyO,
  PhysicalKeyboardKey.keyP => PhysicalInputId.keyboardKeyP,
  PhysicalKeyboardKey.keyQ => PhysicalInputId.keyboardKeyQ,
  PhysicalKeyboardKey.keyR => PhysicalInputId.keyboardKeyR,
  PhysicalKeyboardKey.keyS => PhysicalInputId.keyboardKeyS,
  PhysicalKeyboardKey.keyT => PhysicalInputId.keyboardKeyT,
  PhysicalKeyboardKey.keyU => PhysicalInputId.keyboardKeyU,
  PhysicalKeyboardKey.keyV => PhysicalInputId.keyboardKeyV,
  PhysicalKeyboardKey.keyW => PhysicalInputId.keyboardKeyW,
  PhysicalKeyboardKey.keyX => PhysicalInputId.keyboardKeyX,
  PhysicalKeyboardKey.keyY => PhysicalInputId.keyboardKeyY,
  PhysicalKeyboardKey.keyZ => PhysicalInputId.keyboardKeyZ,
  PhysicalKeyboardKey.digit0 => PhysicalInputId.keyboardDigit0,
  PhysicalKeyboardKey.digit1 => PhysicalInputId.keyboardDigit1,
  PhysicalKeyboardKey.digit2 => PhysicalInputId.keyboardDigit2,
  PhysicalKeyboardKey.digit3 => PhysicalInputId.keyboardDigit3,
  PhysicalKeyboardKey.digit4 => PhysicalInputId.keyboardDigit4,
  PhysicalKeyboardKey.digit5 => PhysicalInputId.keyboardDigit5,
  PhysicalKeyboardKey.digit6 => PhysicalInputId.keyboardDigit6,
  PhysicalKeyboardKey.digit7 => PhysicalInputId.keyboardDigit7,
  PhysicalKeyboardKey.digit8 => PhysicalInputId.keyboardDigit8,
  PhysicalKeyboardKey.digit9 => PhysicalInputId.keyboardDigit9,
  PhysicalKeyboardKey.numpad0 => PhysicalInputId.keyboardNumpad0,
  PhysicalKeyboardKey.numpad1 => PhysicalInputId.keyboardNumpad1,
  PhysicalKeyboardKey.numpad2 => PhysicalInputId.keyboardNumpad2,
  PhysicalKeyboardKey.numpad3 => PhysicalInputId.keyboardNumpad3,
  PhysicalKeyboardKey.numpad4 => PhysicalInputId.keyboardNumpad4,
  PhysicalKeyboardKey.numpad5 => PhysicalInputId.keyboardNumpad5,
  PhysicalKeyboardKey.numpad6 => PhysicalInputId.keyboardNumpad6,
  PhysicalKeyboardKey.numpad7 => PhysicalInputId.keyboardNumpad7,
  PhysicalKeyboardKey.numpad8 => PhysicalInputId.keyboardNumpad8,
  PhysicalKeyboardKey.numpad9 => PhysicalInputId.keyboardNumpad9,
  PhysicalKeyboardKey.numpadAdd => PhysicalInputId.keyboardNumpadAdd,
  PhysicalKeyboardKey.numpadSubtract => PhysicalInputId.keyboardNumpadSubtract,
  PhysicalKeyboardKey.numpadMultiply => PhysicalInputId.keyboardNumpadMultiply,
  PhysicalKeyboardKey.numpadDivide => PhysicalInputId.keyboardNumpadDivide,
  PhysicalKeyboardKey.comma => PhysicalInputId.keyboardComma,
  PhysicalKeyboardKey.period => PhysicalInputId.keyboardPeriod,
  PhysicalKeyboardKey.slash => PhysicalInputId.keyboardSlash,
  PhysicalKeyboardKey.semicolon => PhysicalInputId.keyboardSemicolon,
  PhysicalKeyboardKey.quote => PhysicalInputId.keyboardQuote,
  PhysicalKeyboardKey.bracketLeft => PhysicalInputId.keyboardBracketLeft,
  PhysicalKeyboardKey.bracketRight => PhysicalInputId.keyboardBracketRight,
  PhysicalKeyboardKey.backslash => PhysicalInputId.keyboardBackslash,
  PhysicalKeyboardKey.minus => PhysicalInputId.keyboardMinus,
  PhysicalKeyboardKey.equal => PhysicalInputId.keyboardEqual,
  PhysicalKeyboardKey.backquote => PhysicalInputId.keyboardBackquote,
  PhysicalKeyboardKey.f1 => PhysicalInputId.keyboardF1,
  PhysicalKeyboardKey.f2 => PhysicalInputId.keyboardF2,
  PhysicalKeyboardKey.f3 => PhysicalInputId.keyboardF3,
  PhysicalKeyboardKey.f4 => PhysicalInputId.keyboardF4,
  PhysicalKeyboardKey.f5 => PhysicalInputId.keyboardF5,
  PhysicalKeyboardKey.f6 => PhysicalInputId.keyboardF6,
  PhysicalKeyboardKey.f7 => PhysicalInputId.keyboardF7,
  PhysicalKeyboardKey.f8 => PhysicalInputId.keyboardF8,
  PhysicalKeyboardKey.f9 => PhysicalInputId.keyboardF9,
  PhysicalKeyboardKey.f10 => PhysicalInputId.keyboardF10,
  PhysicalKeyboardKey.f11 => PhysicalInputId.keyboardF11,
  PhysicalKeyboardKey.f12 => PhysicalInputId.keyboardF12,
  _ => null,
};

/// Normalizes Flutter keyboard events into one press cycle.
///
/// Windows can surface a held key as an initial [KeyDownEvent] followed by
/// either [KeyRepeatEvent]s or, for some drivers, another [KeyDownEvent]. The
/// latter must not be treated as a second short press. Repeats remain
/// available, but are paced at a modest interval so a long press is stable
/// rather than a burst of page commands.
final class ReaderKeyEventGate {
  ReaderKeyEventGate({
    DateTime Function()? now,
    this.repeatInterval = const Duration(milliseconds: 180),
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration repeatInterval;
  final Set<PhysicalKeyboardKey> _pressed = <PhysicalKeyboardKey>{};
  final Map<PhysicalKeyboardKey, DateTime> _lastAccepted =
      <PhysicalKeyboardKey, DateTime>{};

  /// Returns whether [event] should dispatch a semantic Reader command.
  /// Key-up events always release the cycle and never dispatch a command.
  bool accept(KeyEvent event, {bool allowRepeat = true}) {
    final key = event.physicalKey;
    if (event is KeyUpEvent) {
      _pressed.remove(key);
      _lastAccepted.remove(key);
      return false;
    }

    final now = _now();
    if (event is KeyDownEvent) {
      if (!_pressed.add(key)) return false;
      _lastAccepted[key] = now;
      return true;
    }
    if (event is KeyRepeatEvent) {
      _pressed.add(key);
      if (!allowRepeat) return false;
      final previous = _lastAccepted[key];
      if (previous != null && now.difference(previous) < repeatInterval) {
        return false;
      }
      _lastAccepted[key] = now;
      return true;
    }
    return false;
  }

  void clear() {
    _pressed.clear();
    _lastAccepted.clear();
  }
}

/// One logical page command per high-frequency wheel burst.
///
/// Pointer-scroll events are delivered as a stream on Windows (including for
/// one physical wheel detent). The gate keeps the first event, suppresses the
/// burst, and allows the next intentional detent after the short interval.
final class ReaderWheelEventGate {
  ReaderWheelEventGate({
    DateTime Function()? now,
    this.throttle = const Duration(milliseconds: 140),
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration throttle;
  DateTime? _lastAccepted;

  bool accept(double delta) {
    if (delta == 0) return false;
    final now = _now();
    final previous = _lastAccepted;
    if (previous != null && now.difference(previous) < throttle) return false;
    _lastAccepted = now;
    return true;
  }

  void clear() => _lastAccepted = null;
}

ReaderInputGesture? readerInputGestureForKey(
  LogicalKeyboardKey key, {
  bool control = false,
  bool alt = false,
  bool shift = false,
}) {
  final primary = physicalInputIdForKey(key);
  if (primary == null) return null;
  return ReaderInputGesture(
    primaryInput: primary,
    modifiers: [
      if (control) ReaderInputModifier.ctrl,
      if (alt) ReaderInputModifier.alt,
      if (shift) ReaderInputModifier.shift,
    ],
  );
}

ReaderInputGesture? readerInputGestureForEvent(
  KeyEvent event, {
  bool control = false,
  bool alt = false,
  bool shift = false,
}) {
  final primary =
      physicalInputIdForPhysicalKey(event.physicalKey) ??
      physicalInputIdForKey(event.logicalKey);
  if (primary == null) return null;
  return ReaderInputGesture(
    primaryInput: primary,
    modifiers: [
      if (control) ReaderInputModifier.ctrl,
      if (alt) ReaderInputModifier.alt,
      if (shift) ReaderInputModifier.shift,
    ],
  );
}

/// Minimal Android host bridge. The host only reports physical volume input;
/// the binding above decides which ReaderCommand it means.
final class ReaderInputBridge {
  ReaderInputBridge._();

  static const _channel = MethodChannel('xaocen.reader/paged_input');

  static Future<void> activate({
    required bool pagedActive,
    required bool inputCaptureActive,
    bool volumeBindingActive = false,
    bool volumeUpBindingActive = false,
    bool volumeDownBindingActive = false,
    required void Function(PhysicalInputId input) onInput,
  }) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'volumeInput') return null;
      final value = call.arguments as String?;
      final input = switch (value) {
        'android.volumeUp' || 'volumeUp' => PhysicalInputId.androidVolumeUp,
        'android.volumeDown' ||
        'volumeDown' => PhysicalInputId.androidVolumeDown,
        _ => null,
      };
      if (input != null) onInput(input);
      return null;
    });
    await setActiveState(
      pagedActive: pagedActive,
      inputCaptureActive: inputCaptureActive,
      volumeBindingActive: volumeBindingActive,
      volumeUpBindingActive: volumeUpBindingActive,
      volumeDownBindingActive: volumeDownBindingActive,
    );
  }

  static Future<void> activatePaged(
    void Function(PhysicalInput input) onInput,
  ) async {
    await activate(
      pagedActive: true,
      inputCaptureActive: false,
      onInput: (input) {
        final legacy = switch (input) {
          PhysicalInputId.androidVolumeUp => PhysicalInput.volumeUp,
          PhysicalInputId.androidVolumeDown => PhysicalInput.volumeDown,
          _ => null,
        };
        if (legacy != null) onInput(legacy);
      },
    );
  }

  static Future<void> setActiveState({
    required bool pagedActive,
    required bool inputCaptureActive,
    bool volumeBindingActive = false,
    bool volumeUpBindingActive = false,
    bool volumeDownBindingActive = false,
  }) async {
    try {
      await _channel.invokeMethod<void>('setPagedActive', pagedActive);
      await _channel.invokeMethod<void>(
        'setInputCaptureActive',
        inputCaptureActive,
      );
      await _channel.invokeMethod<void>('setVolumeBindingActive', {
        'all': volumeBindingActive,
        'up': volumeUpBindingActive,
        'down': volumeDownBindingActive,
      });
    } on MissingPluginException {
      // Desktop and test hosts have no Android bridge.
    }
  }

  static Future<void> deactivatePaged() async {
    _channel.setMethodCallHandler(null);
    await setActiveState(
      pagedActive: false,
      inputCaptureActive: false,
      volumeBindingActive: false,
      volumeUpBindingActive: false,
      volumeDownBindingActive: false,
    );
  }

  static Future<void> deactivate() async {
    _channel.setMethodCallHandler(null);
    await setActiveState(
      pagedActive: false,
      inputCaptureActive: false,
      volumeBindingActive: false,
      volumeUpBindingActive: false,
      volumeDownBindingActive: false,
    );
  }
}
