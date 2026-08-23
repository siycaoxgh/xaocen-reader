import 'dart:io';

import 'package:flutter/services.dart';

/// Runtime capability owned by the Windows runner.
///
/// The standard runner returns false. The validated patched runner returns
/// true only when its alpha-surface switch was present at HWND creation. No
/// reader setting or whole-window opacity fallback is inferred here.
final class WindowsTrueTransparencyCapability {
  WindowsTrueTransparencyCapability._();

  static const MethodChannel _channel = MethodChannel('xaocen/windows_shell');

  static Future<bool> load() async {
    if (!Platform.isWindows) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'getWindowsTrueTransparencyCapability',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
