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
  _ => null,
};

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

/// Minimal Android host bridge. The host only reports physical volume input;
/// the binding above decides which ReaderCommand it means.
final class ReaderInputBridge {
  ReaderInputBridge._();

  static const _channel = MethodChannel('xaocen.reader/paged_input');

  static Future<void> activate({
    required bool pagedActive,
    required bool inputCaptureActive,
    bool volumeBindingActive = false,
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
  }) async {
    try {
      await _channel.invokeMethod<void>('setPagedActive', pagedActive);
      await _channel.invokeMethod<void>(
        'setInputCaptureActive',
        inputCaptureActive,
      );
      await _channel.invokeMethod<void>(
        'setVolumeBindingActive',
        volumeBindingActive,
      );
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
    );
  }

  static Future<void> deactivate() async {
    _channel.setMethodCallHandler(null);
    try {
      await _channel.invokeMethod<void>('setPagedActive', false);
      await _channel.invokeMethod<void>('setInputCaptureActive', false);
      await _channel.invokeMethod<void>('setVolumeBindingActive', false);
    } on MissingPluginException {
      // Desktop and test hosts have no Android bridge.
    }
  }
}
