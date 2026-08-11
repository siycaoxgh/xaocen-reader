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

  static bool get supported => Platform.isWindows;

  static Future<bool> apply(WindowsShellPreferences preferences) async {
    currentPreferences = preferences;
    if (!supported) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setShellVisibility', {
        'taskbar': preferences.showTaskbarIcon,
        'tray': preferences.showTrayIcon,
      });
      return result ?? false;
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
}

/// App-local left+right mouse chord recognizer. It is intentionally scoped to
/// the Flutter window and never installs a global mouse hook.
final class BossKeyTracker {
  bool _leftDown = false;
  bool _rightDown = false;
  bool _triggered = false;

  void clear() {
    _leftDown = false;
    _rightDown = false;
    _triggered = false;
  }

  bool update({required bool left, required bool right}) {
    _leftDown = left;
    _rightDown = right;
    if (!_leftDown || !_rightDown) {
      _triggered = false;
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
    final buttons = event.buttons;
    final left = buttons & kPrimaryMouseButton != 0;
    final right = buttons & kSecondaryMouseButton != 0;
    if (!_tracker.update(left: left, right: right)) return;
    final preferences = WindowsShellBridge.currentPreferences ?? _preferences;
    if (preferences?.showTrayIcon == true) {
      unawaited(WindowsShellBridge.hideWindow());
    }
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
