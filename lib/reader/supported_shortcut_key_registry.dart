import 'package:flutter/services.dart';

import 'reader_input.dart';

/// The single capability registry for Windows keyboard shortcut capture.
///
/// `physicalInputIdForPhysicalKey` describes the platform event mapping. This
/// registry is the narrower product contract: a key is listed here only when
/// it has been verified through capture, persistence, and runtime dispatch.
/// Mouse gestures are intentionally not part of this keyboard registry.
final class SupportedShortcutKeyRegistry {
  SupportedShortcutKeyRegistry._();

  static const _unsupportedMessage = '该按键暂不支持作为 XAOCEN 快捷键';

  /// Stable, verified keyboard capability set.
  ///
  /// Common OEM punctuation is deliberately excluded until it has a complete
  /// capture → save → runtime proof on Windows. It remains representable in
  /// the domain for backwards compatibility, but cannot be newly captured.
  static const _verifiedKeyboardInputs = <PhysicalInputId>[
    ...PhysicalInputId.keyboardLetters,
    ...PhysicalInputId.keyboardDigits,
    ...PhysicalInputId.keyboardFunctionKeys,
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
    ...PhysicalInputId.keyboardNumpadDigits,
    PhysicalInputId.keyboardNumpadAdd,
    PhysicalInputId.keyboardNumpadSubtract,
    PhysicalInputId.keyboardNumpadMultiply,
    PhysicalInputId.keyboardNumpadDivide,
  ];

  static PhysicalInputId? inputFor(PhysicalKeyboardKey key) {
    final input = physicalInputIdForPhysicalKey(key);
    return input != null && _verifiedKeyboardInputs.contains(input)
        ? input
        : null;
  }

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

  static String get unsupportedMessage => _unsupportedMessage;

  static List<PhysicalInputId> get keyboardInputs =>
      _verifiedKeyboardInputs.toList(growable: false);

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
  };

  static const unsupportedCategories = <String>['常用符号键（当前暂不支持）'];

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
