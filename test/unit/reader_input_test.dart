import 'package:flutter_test/flutter_test.dart';
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
}
