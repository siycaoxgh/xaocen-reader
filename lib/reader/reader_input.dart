import 'package:flutter/services.dart';

import '../domain/reader/reader_input_bindings.dart';

export '../domain/reader/reader_input_bindings.dart';

/// Legacy route adapter. M5.3a/b persist [ReaderInputProfile], while the
/// existing paged route continues to use its default in-memory adapter until
/// the M5.3c input router lands.
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

/// Minimal Android host bridge. The host only reports physical volume input;
/// the binding above decides which ReaderCommand it means.
final class ReaderInputBridge {
  ReaderInputBridge._();

  static const _channel = MethodChannel('xaocen.reader/paged_input');

  static Future<void> activatePaged(
    void Function(PhysicalInput input) onInput,
  ) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'volumeInput') return null;
      final value = call.arguments as String?;
      final input = switch (value) {
        'volumeUp' => PhysicalInput.volumeUp,
        'volumeDown' => PhysicalInput.volumeDown,
        _ => null,
      };
      if (input != null) onInput(input);
      return null;
    });
    try {
      await _channel.invokeMethod<void>('setPagedActive', true);
    } on MissingPluginException {
      // Desktop and test hosts have no Android bridge.
    }
  }

  static Future<void> deactivatePaged() async {
    _channel.setMethodCallHandler(null);
    try {
      await _channel.invokeMethod<void>('setPagedActive', false);
    } on MissingPluginException {
      // Desktop and test hosts have no Android bridge.
    }
  }
}
