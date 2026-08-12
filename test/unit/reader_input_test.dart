import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:xaocen_reader/reader/reader_input.dart';

void main() {
  test('default physical bindings map to Reader commands', () {
    const binding = InputBinding.defaults;
    expect(
      binding.commandFor(PhysicalInput.volumeUp),
      ReaderCommand.previousPage,
    );
    expect(
      binding.commandFor(PhysicalInput.volumeDown),
      ReaderCommand.nextPage,
    );
    expect(
      binding.commandFor(PhysicalInput.wheelUp),
      ReaderCommand.previousPage,
    );
    expect(binding.commandFor(PhysicalInput.wheelDown), ReaderCommand.nextPage);
    expect(
      binding.commandFor(PhysicalInput.arrowLeft),
      ReaderCommand.previousPage,
    );
    expect(
      binding.commandFor(PhysicalInput.arrowRight),
      ReaderCommand.nextPage,
    );
    expect(
      binding.commandFor(PhysicalInput.pageUp),
      ReaderCommand.previousPage,
    );
    expect(binding.commandFor(PhysicalInput.pageDown), ReaderCommand.nextPage);
  });

  test(
    'Windows single-key registry maps stable IDs without runtime objects',
    () {
      expect(
        physicalInputIdForKey(LogicalKeyboardKey.keyA),
        PhysicalInputId.keyboardKeyA,
      );
      expect(
        physicalInputIdForKey(LogicalKeyboardKey.space),
        PhysicalInputId.keyboardSpace,
      );
      expect(
        physicalInputIdForKey(LogicalKeyboardKey.enter),
        PhysicalInputId.keyboardEnter,
      );
      expect(
        physicalInputIdForKey(LogicalKeyboardKey.pageDown),
        PhysicalInputId.keyboardPageDown,
      );
      expect(
        PhysicalInputId.parse('keyboard.keyA'),
        PhysicalInputId.keyboardKeyA,
      );
      expect(
        PhysicalInputId.parse('keyboard.space'),
        PhysicalInputId.keyboardSpace,
      );
      expect(
        PhysicalInputId.windowsInputs,
        contains(PhysicalInputId.keyboardDigit9),
      );
      expect(
        physicalInputIdForKey(LogicalKeyboardKey.numpad1),
        PhysicalInputId.keyboardNumpad1,
      );
      expect(
        physicalInputIdForKey(LogicalKeyboardKey.numpadAdd),
        PhysicalInputId.keyboardNumpadAdd,
      );
      expect(
        physicalInputIdForKey(LogicalKeyboardKey.f12),
        PhysicalInputId.keyboardF12,
      );
    },
  );
}
