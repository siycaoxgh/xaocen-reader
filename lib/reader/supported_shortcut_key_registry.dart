import 'package:flutter/services.dart';

import 'reader_input.dart';

/// Capability facade for shortcut capture and help UI.
///
/// The physical-to-domain mapping remains in [physicalInputIdForPhysicalKey],
/// which is also used by Reader runtime dispatch. This facade deliberately
/// does not maintain a second key truth table.
final class SupportedShortcutKeyRegistry {
  SupportedShortcutKeyRegistry._();

  static PhysicalInputId? inputFor(PhysicalKeyboardKey key) =>
      physicalInputIdForPhysicalKey(key);

  static ReaderInputGesture? gestureForEvent(
    KeyEvent event, {
    bool control = false,
    bool alt = false,
    bool shift = false,
  }) => readerInputGestureForEvent(
    event,
    control: control,
    alt: alt,
    shift: shift,
  );

  static bool supports(PhysicalKeyboardKey key) => inputFor(key) != null;

  static List<PhysicalInputId> get keyboardInputs => PhysicalInputId
      .windowsInputs
      .where((input) => input.value.startsWith('keyboard.'))
      .toList(growable: false);

  static Map<String, List<PhysicalInputId>> get categories => {
    '字母 A-Z': PhysicalInputId.keyboardLetters,
    '数字 0-9': PhysicalInputId.keyboardDigits,
    '功能键 F1-F12': PhysicalInputId.keyboardFunctionKeys,
    '导航键': [
      PhysicalInputId.keyboardArrowLeft,
      PhysicalInputId.keyboardArrowRight,
      PhysicalInputId.keyboardArrowUp,
      PhysicalInputId.keyboardArrowDown,
      PhysicalInputId.keyboardPageUp,
      PhysicalInputId.keyboardPageDown,
      PhysicalInputId.keyboardHome,
      PhysicalInputId.keyboardEnd,
      PhysicalInputId.keyboardSpace,
      PhysicalInputId.keyboardEnter,
    ],
    '小键盘': [
      ...PhysicalInputId.keyboardNumpadDigits,
      PhysicalInputId.keyboardNumpadAdd,
      PhysicalInputId.keyboardNumpadSubtract,
      PhysicalInputId.keyboardNumpadMultiply,
      PhysicalInputId.keyboardNumpadDivide,
    ],
    '常用符号键': PhysicalInputId.windowsInputs
        .where(
          (input) =>
              input.value == 'keyboard.minus' ||
              input.value == 'keyboard.equal' ||
              input.value == 'keyboard.bracketLeft' ||
              input.value == 'keyboard.bracketRight' ||
              input.value == 'keyboard.backslash' ||
              input.value == 'keyboard.semicolon' ||
              input.value == 'keyboard.quote' ||
              input.value == 'keyboard.comma' ||
              input.value == 'keyboard.period' ||
              input.value == 'keyboard.slash' ||
              input.value == 'keyboard.backquote',
        )
        .toList(growable: false),
  };

  static const modifierDescription = 'Ctrl / Alt / Shift 组合';
  static const mouseGestureDescription = '左右键同时按下显示/隐藏窗口';

  static String displayName(PhysicalInputId input) {
    final value = input.value.substring('keyboard.'.length);
    return switch (value) {
      'arrowLeft' => '←',
      'arrowRight' => '→',
      'arrowUp' => '↑',
      'arrowDown' => '↓',
      'pageUp' => 'PageUp',
      'pageDown' => 'PageDown',
      'bracketLeft' => '[',
      'bracketRight' => ']',
      'backslash' => '\\',
      'semicolon' => ';',
      'quote' => "'",
      'backquote' => '`',
      'comma' => ',',
      'period' => '.',
      'slash' => '/',
      'minus' => '-',
      'equal' => '=',
      _ => value,
    };
  }
}
