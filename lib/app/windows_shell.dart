import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/windows_shell_preferences.dart';

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
