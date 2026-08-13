import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/reader/reader_input.dart';
import 'package:xaocen_reader/reader/supported_shortcut_key_registry.dart';

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

  test('physical punctuation and middle mouse inputs have stable IDs', () {
    expect(
      readerInputGestureForKey(LogicalKeyboardKey.comma)?.primaryInput,
      PhysicalInputId.keyboardComma,
    );
    expect(
      readerInputGestureForKey(
        LogicalKeyboardKey.bracketLeft,
        shift: true,
      )?.canonicalKey,
      'shift+keyboard.bracketLeft',
    );
    expect(
      PhysicalInputId.parse('mouse.middleButton'),
      PhysicalInputId.mouseMiddleButton,
    );
  });

  test('shifted punctuation keeps physical primary identity', () {
    final gesture = readerInputGestureForKey(
      LogicalKeyboardKey.equal,
      shift: true,
    );
    expect(gesture?.primaryInput, PhysicalInputId.keyboardEqual);
    expect(gesture?.modifiers, contains(ReaderInputModifier.shift));
  });

  test('event capture prefers physical OEM identity over IME character', () {
    final event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.slash,
      logicalKey: LogicalKeyboardKey.question,
      timeStamp: Duration.zero,
    );
    final gesture = readerInputGestureForEvent(event, shift: true);
    expect(gesture?.primaryInput, PhysicalInputId.keyboardSlash);
    expect(gesture?.canonicalKey, 'shift+keyboard.slash');
  });

  test('all required physical OEM keys are capturable', () {
    final expected = <PhysicalKeyboardKey, PhysicalInputId>{
      PhysicalKeyboardKey.minus: PhysicalInputId.keyboardMinus,
      PhysicalKeyboardKey.equal: PhysicalInputId.keyboardEqual,
      PhysicalKeyboardKey.bracketLeft: PhysicalInputId.keyboardBracketLeft,
      PhysicalKeyboardKey.bracketRight: PhysicalInputId.keyboardBracketRight,
      PhysicalKeyboardKey.backslash: PhysicalInputId.keyboardBackslash,
      PhysicalKeyboardKey.semicolon: PhysicalInputId.keyboardSemicolon,
      PhysicalKeyboardKey.quote: PhysicalInputId.keyboardQuote,
      PhysicalKeyboardKey.backquote: PhysicalInputId.keyboardBackquote,
      PhysicalKeyboardKey.comma: PhysicalInputId.keyboardComma,
      PhysicalKeyboardKey.period: PhysicalInputId.keyboardPeriod,
      PhysicalKeyboardKey.slash: PhysicalInputId.keyboardSlash,
    };
    for (final entry in expected.entries) {
      expect(physicalInputIdForPhysicalKey(entry.key), entry.value);
    }
  });

  test(
    'shortcut capability registry is sourced from physical input support',
    () {
      expect(
        SupportedShortcutKeyRegistry.inputFor(PhysicalKeyboardKey.slash),
        PhysicalInputId.keyboardSlash,
      );
      expect(
        SupportedShortcutKeyRegistry.categories['小键盘'],
        contains(PhysicalInputId.keyboardNumpadAdd),
      );
      expect(
        SupportedShortcutKeyRegistry.displayName(PhysicalInputId.keyboardSlash),
        '/',
      );
    },
  );
}
