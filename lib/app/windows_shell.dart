import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/windows_shell_preferences.dart';
import 'providers.dart';

/// Flutter side of the Windows shell boundary. Calls are no-ops on Android.
final class WindowsShellBridge {
  WindowsShellBridge._();

  static const MethodChannel _channel = MethodChannel('xaocen/windows_shell');
  static WindowsShellPreferences? currentPreferences;
  static bool captureActive = false;

  static bool get supported => Platform.isWindows;

  static Future<bool> apply(WindowsShellPreferences preferences) async {
    currentPreferences = preferences;
    if (!supported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setShellVisibility', {
        'taskbar': preferences.showTaskbarIcon,
        'tray': preferences.showTrayIcon,
      });
      final visibilityApplied = result ?? false;
      final borderApplied = await _channel.invokeMethod<bool>(
        'setWindowBorder',
        {'show': preferences.showWindowBorder},
      );
      return visibilityApplied && (borderApplied ?? false);
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> hideWindow() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('hideWindow') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> showWindow() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('showWindow') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> setWindowBorder(bool show) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('setWindowBorder', {
            'show': show,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> quitApplication() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('quitApplication') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static void setCaptureActive(bool value) => captureActive = value;
}

/// App-local left+right mouse chord recognizer. It is intentionally scoped to
/// the Flutter window and never installs a global mouse hook.
final class BossKeyTracker {
  bool _leftDown = false;
  bool _rightDown = false;
  bool _triggered = false;
  DateTime? _leftDownAt;
  DateTime? _rightDownAt;

  static const chordWindow = Duration(milliseconds: 250);

  void clear() {
    _leftDown = false;
    _rightDown = false;
    _triggered = false;
    _leftDownAt = null;
    _rightDownAt = null;
  }

  bool updateMouse(
    WindowsBossKeyGesture gesture, {
    required bool left,
    required bool right,
  }) {
    if (!gesture.mouseChord) {
      clear();
      return false;
    }
    final now = DateTime.now();
    if (left && !_leftDown) _leftDownAt = now;
    if (right && !_rightDown) _rightDownAt = now;
    _leftDown = left;
    _rightDown = right;
    if (!_leftDown || !_rightDown) {
      _triggered = false;
      return false;
    }
    final leftAt = _leftDownAt;
    final rightAt = _rightDownAt;
    if (leftAt == null ||
        rightAt == null ||
        leftAt.difference(rightAt).abs() > chordWindow) {
      _triggered = false;
      return false;
    }
    if (_triggered) return false;
    _triggered = true;
    return true;
  }

  /// Compatibility helper for existing shell contract tests. Runtime code
  /// always supplies the persisted gesture to [updateMouse].
  bool update({required bool left, required bool right}) => updateMouse(
    const WindowsBossKeyGesture.mouseChord(),
    left: left,
    right: right,
  );

  bool updateKeyboard(
    WindowsBossKeyGesture gesture, {
    required WindowsShellKey key,
    required Set<WindowsShellModifier> modifiers,
  }) {
    if (!gesture.isKeyboard ||
        gesture.primaryKey != key ||
        gesture.modifiers.length != modifiers.length ||
        !gesture.modifiers.containsAll(modifiers)) {
      return false;
    }
    if (_triggered) return false;
    _triggered = true;
    return true;
  }
}

void unawaitedShell(Future<void> future) => unawaited(future);

/// Root-level app-local Boss Key host. It wraps MaterialApp so the chord also
/// works while a Reader or settings route is on top of the shell.
class WindowsShellHost extends ConsumerStatefulWidget {
  const WindowsShellHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<WindowsShellHost> createState() => _WindowsShellHostState();
}

class _WindowsShellHostState extends ConsumerState<WindowsShellHost> {
  final BossKeyTracker _tracker = BossKeyTracker();
  WindowsShellPreferences? _preferences;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) unawaited(_load());
  }

  Future<void> _load() async {
    final repository = ref.read(windowsShellPreferencesRepositoryProvider);
    final value = await repository.load();
    if (!mounted) return;
    setState(() => _preferences = value);
    unawaited(WindowsShellBridge.apply(value));
  }

  void _onPointer(PointerEvent event) {
    if (!Platform.isWindows) return;
    if (WindowsShellBridge.captureActive) return;
    final buttons = event.buttons;
    final left = buttons & kPrimaryMouseButton != 0;
    final right = buttons & kSecondaryMouseButton != 0;
    final preferences = WindowsShellBridge.currentPreferences ?? _preferences;
    final gesture = preferences?.bossKeyGesture;
    if (preferences?.bossKeyEnabled != true || gesture == null) return;
    if (!_tracker.updateMouse(gesture, left: left, right: right)) return;
    if (preferences?.showTrayIcon == true) {
      unawaited(WindowsShellBridge.hideWindow());
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!Platform.isWindows || WindowsShellBridge.captureActive) {
      return KeyEventResult.ignored;
    }
    if (event is KeyUpEvent || event is KeyRepeatEvent) {
      _tracker.clear();
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final preferences = WindowsShellBridge.currentPreferences ?? _preferences;
    if (preferences?.bossKeyEnabled != true) return KeyEventResult.ignored;
    final key = windowsShellKeyForLogicalKey(event.logicalKey);
    if (key == null) return KeyEventResult.ignored;
    final modifiers = <WindowsShellModifier>{
      if (HardwareKeyboard.instance.isControlPressed) WindowsShellModifier.ctrl,
      if (HardwareKeyboard.instance.isAltPressed) WindowsShellModifier.alt,
      if (HardwareKeyboard.instance.isShiftPressed) WindowsShellModifier.shift,
    };
    if (!_tracker.updateKeyboard(
      preferences!.bossKeyGesture,
      key: key,
      modifiers: modifiers,
    )) {
      return KeyEventResult.ignored;
    }
    // Native hide-to-tray is the only recovery-safe hidden state. A visible
    // taskbar entry cannot recover a window after SW_HIDE removes it.
    if (preferences.showTrayIcon) {
      unawaited(WindowsShellBridge.hideWindow());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _tracker.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) return widget.child;
    return Focus(
      canRequestFocus: false,
      onKeyEvent: _onKeyEvent,
      onFocusChange: (focused) {
        if (!focused) _tracker.clear();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointer,
        onPointerUp: _onPointer,
        onPointerCancel: _onPointer,
        child: widget.child,
      ),
    );
  }
}

WindowsShellKey? windowsShellKeyForLogicalKey(LogicalKeyboardKey key) =>
    switch (key) {
      LogicalKeyboardKey.keyA => WindowsShellKey.keyA,
      LogicalKeyboardKey.keyB => WindowsShellKey.keyB,
      LogicalKeyboardKey.keyC => WindowsShellKey.keyC,
      LogicalKeyboardKey.keyD => WindowsShellKey.keyD,
      LogicalKeyboardKey.keyE => WindowsShellKey.keyE,
      LogicalKeyboardKey.keyF => WindowsShellKey.keyF,
      LogicalKeyboardKey.keyG => WindowsShellKey.keyG,
      LogicalKeyboardKey.keyH => WindowsShellKey.keyH,
      LogicalKeyboardKey.keyI => WindowsShellKey.keyI,
      LogicalKeyboardKey.keyJ => WindowsShellKey.keyJ,
      LogicalKeyboardKey.keyK => WindowsShellKey.keyK,
      LogicalKeyboardKey.keyL => WindowsShellKey.keyL,
      LogicalKeyboardKey.keyM => WindowsShellKey.keyM,
      LogicalKeyboardKey.keyN => WindowsShellKey.keyN,
      LogicalKeyboardKey.keyO => WindowsShellKey.keyO,
      LogicalKeyboardKey.keyP => WindowsShellKey.keyP,
      LogicalKeyboardKey.keyQ => WindowsShellKey.keyQ,
      LogicalKeyboardKey.keyR => WindowsShellKey.keyR,
      LogicalKeyboardKey.keyS => WindowsShellKey.keyS,
      LogicalKeyboardKey.keyT => WindowsShellKey.keyT,
      LogicalKeyboardKey.keyU => WindowsShellKey.keyU,
      LogicalKeyboardKey.keyV => WindowsShellKey.keyV,
      LogicalKeyboardKey.keyW => WindowsShellKey.keyW,
      LogicalKeyboardKey.keyX => WindowsShellKey.keyX,
      LogicalKeyboardKey.keyY => WindowsShellKey.keyY,
      LogicalKeyboardKey.keyZ => WindowsShellKey.keyZ,
      LogicalKeyboardKey.digit0 => WindowsShellKey.digit0,
      LogicalKeyboardKey.digit1 => WindowsShellKey.digit1,
      LogicalKeyboardKey.digit2 => WindowsShellKey.digit2,
      LogicalKeyboardKey.digit3 => WindowsShellKey.digit3,
      LogicalKeyboardKey.digit4 => WindowsShellKey.digit4,
      LogicalKeyboardKey.digit5 => WindowsShellKey.digit5,
      LogicalKeyboardKey.digit6 => WindowsShellKey.digit6,
      LogicalKeyboardKey.digit7 => WindowsShellKey.digit7,
      LogicalKeyboardKey.digit8 => WindowsShellKey.digit8,
      LogicalKeyboardKey.digit9 => WindowsShellKey.digit9,
      LogicalKeyboardKey.arrowUp => WindowsShellKey.arrowUp,
      LogicalKeyboardKey.arrowDown => WindowsShellKey.arrowDown,
      LogicalKeyboardKey.arrowLeft => WindowsShellKey.arrowLeft,
      LogicalKeyboardKey.arrowRight => WindowsShellKey.arrowRight,
      LogicalKeyboardKey.pageUp => WindowsShellKey.pageUp,
      LogicalKeyboardKey.pageDown => WindowsShellKey.pageDown,
      LogicalKeyboardKey.home => WindowsShellKey.home,
      LogicalKeyboardKey.end => WindowsShellKey.end,
      LogicalKeyboardKey.space => WindowsShellKey.space,
      LogicalKeyboardKey.enter => WindowsShellKey.enter,
      _ => null,
    };
