import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/reader/reader_input.dart';

void main() {
  test('supported plain Windows primary keys map predictably', () {
    expect(
      readerInputGestureForKey(LogicalKeyboardKey.keyA),
      ReaderInputGesture.single(PhysicalInputId.keyboardKeyA),
    );
    expect(
      readerInputGestureForKey(LogicalKeyboardKey.space),
      ReaderInputGesture.single(PhysicalInputId.keyboardSpace),
    );
    expect(
      readerInputGestureForKey(LogicalKeyboardKey.pageDown),
      ReaderInputGesture.single(PhysicalInputId.keyboardPageDown),
    );
  });

  test('Ctrl, Alt, and Shift gestures are canonical', () {
    final ctrlA = readerInputGestureForKey(
      LogicalKeyboardKey.keyA,
      control: true,
    )!;
    final ctrlPageDown = readerInputGestureForKey(
      LogicalKeyboardKey.pageDown,
      control: true,
    )!;
    final shiftSpace = readerInputGestureForKey(
      LogicalKeyboardKey.space,
      shift: true,
    )!;
    final ctrlShiftK = readerInputGestureForKey(
      LogicalKeyboardKey.keyK,
      shift: true,
      control: true,
    )!;
    expect(ctrlA.canonicalKey, 'ctrl+keyboard.keyA');
    expect(ctrlPageDown.canonicalKey, 'ctrl+keyboard.pageDown');
    expect(shiftSpace.canonicalKey, 'shift+keyboard.space');
    expect(ctrlShiftK.canonicalKey, 'ctrl+shift+keyboard.keyK');
    expect(
      ReaderInputGesture(
        primaryInput: PhysicalInputId.keyboardKeyK,
        modifiers: [ReaderInputModifier.shift, ReaderInputModifier.ctrl],
      ),
      ctrlShiftK,
    );
  });

  test(
    'modifier-only, Escape, and unsupported keys do not form candidates',
    () {
      expect(readerInputGestureForKey(LogicalKeyboardKey.controlLeft), isNull);
      expect(readerInputGestureForKey(LogicalKeyboardKey.shiftLeft), isNull);
      expect(readerInputGestureForKey(LogicalKeyboardKey.altLeft), isNull);
      expect(readerInputGestureForKey(LogicalKeyboardKey.escape), isNull);
    },
  );
}
