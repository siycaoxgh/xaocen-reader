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

  test('shortcut capability registry contains only verified keys', () {
    expect(
      SupportedShortcutKeyRegistry.inputFor(PhysicalKeyboardKey.keyA),
      PhysicalInputId.keyboardKeyA,
    );
    expect(
      SupportedShortcutKeyRegistry.inputFor(PhysicalKeyboardKey.slash),
      isNull,
    );
    for (final key in <PhysicalKeyboardKey>[
      PhysicalKeyboardKey.minus,
      PhysicalKeyboardKey.equal,
      PhysicalKeyboardKey.bracketLeft,
      PhysicalKeyboardKey.bracketRight,
      PhysicalKeyboardKey.backslash,
      PhysicalKeyboardKey.semicolon,
      PhysicalKeyboardKey.quote,
      PhysicalKeyboardKey.backquote,
      PhysicalKeyboardKey.comma,
      PhysicalKeyboardKey.period,
      PhysicalKeyboardKey.slash,
    ]) {
      expect(SupportedShortcutKeyRegistry.supports(key), isFalse);
    }
    expect(
      SupportedShortcutKeyRegistry.categories['小键盘'],
      contains(PhysicalInputId.keyboardNumpadAdd),
    );
    expect(SupportedShortcutKeyRegistry.unsupportedCategories, isNotEmpty);
  });

  test('keyboard gate maps one short press and paced hold repeats', () {
    var now = DateTime(2026, 1, 1);
    final gate = ReaderKeyEventGate(
      now: () => now,
      repeatInterval: const Duration(milliseconds: 180),
    );
    KeyEvent down() => KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.pageDown,
      logicalKey: LogicalKeyboardKey.pageDown,
      timeStamp: Duration.zero,
    );
    KeyEvent repeat() => KeyRepeatEvent(
      physicalKey: PhysicalKeyboardKey.pageDown,
      logicalKey: LogicalKeyboardKey.pageDown,
      timeStamp: Duration.zero,
    );
    KeyEvent up() => KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.pageDown,
      logicalKey: LogicalKeyboardKey.pageDown,
      timeStamp: Duration.zero,
    );

    expect(gate.accept(down()), isTrue, reason: 'first short press');
    expect(gate.accept(down()), isFalse, reason: 'duplicate key-down');
    expect(gate.accept(repeat()), isFalse, reason: 'repeat too soon');
    now = now.add(const Duration(milliseconds: 200));
    expect(gate.accept(repeat()), isTrue, reason: 'controlled hold repeat');
    expect(gate.accept(up()), isFalse);
    expect(gate.accept(down()), isTrue, reason: 'next press after release');
  });

  test('wheel gate keeps one command per burst and allows next detent', () {
    var now = DateTime(2026, 1, 1);
    final gate = ReaderWheelEventGate(now: () => now);
    expect(gate.accept(120), isTrue, reason: 'single wheel detent');
    expect(gate.accept(120), isFalse, reason: 'rapid duplicate signal');
    now = now.add(const Duration(milliseconds: 150));
    expect(gate.accept(-120), isTrue, reason: 'next intentional detent');
    expect(gate.accept(0), isFalse);
  });
}
