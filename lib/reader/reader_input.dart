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
  LogicalKeyboardKey.pageDown => PhysicalInputId.keyboardPageDown,
  LogicalKeyboardKey.arrowLeft => PhysicalInputId.keyboardArrowLeft,
  LogicalKeyboardKey.pageUp => PhysicalInputId.keyboardPageUp,
  _ => null,
};

/// Minimal Android host bridge. The host only reports physical volume input;
/// the binding above decides which ReaderCommand it means.
final class ReaderInputBridge {
  ReaderInputBridge._();

  static const _channel = MethodChannel('xaocen.reader/paged_input');

  static Future<void> activate({
    required bool pagedActive,
    required bool inputCaptureActive,
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
  }) async {
    try {
      await _channel.invokeMethod<void>('setPagedActive', pagedActive);
      await _channel.invokeMethod<void>(
        'setInputCaptureActive',
        inputCaptureActive,
      );
    } on MissingPluginException {
      // Desktop and test hosts have no Android bridge.
    }
  }

  static Future<void> deactivatePaged() async {
    _channel.setMethodCallHandler(null);
    await setActiveState(pagedActive: false, inputCaptureActive: false);
  }

  static Future<void> deactivate() async {
    _channel.setMethodCallHandler(null);
    try {
      await _channel.invokeMethod<void>('setPagedActive', false);
      await _channel.invokeMethod<void>('setInputCaptureActive', false);
    } on MissingPluginException {
      // Desktop and test hosts have no Android bridge.
    }
  }
}
