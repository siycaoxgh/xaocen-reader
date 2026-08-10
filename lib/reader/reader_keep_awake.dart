import 'package:flutter/services.dart';

/// Best-effort platform boundary for Reader keep-awake behavior.
///
/// Android handles the flag in the host activity. Desktop/test hosts may not
/// implement the channel; in that case the capability safely degrades to a
/// no-op without adding a third-party dependency.
final class ReaderKeepAwake {
  ReaderKeepAwake._();

  static const MethodChannel _channel = MethodChannel(
    'xaocen.reader/paged_input',
  );
  static bool _enabled = false;

  static Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', enabled);
    } on MissingPluginException {
      // Windows and test hosts have no native implementation in this slice.
    } on PlatformException {
      // Keep-awake is an optional capability; Reader behavior must continue.
    }
  }

  static Future<void> release() => setEnabled(false);
}
