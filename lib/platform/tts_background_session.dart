import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform-neutral hooks used by the TTS controller for a foreground speech
/// session and audio-focus changes. The Android implementation is deliberately
/// small; Windows and other platforms remain no-ops.
abstract interface class TtsAudioFocusAware {
  void setOnAudioFocusLost(VoidCallback callback);
  void setOnAudioFocusGained(VoidCallback callback);
  void setOnMediaCommand(ValueChanged<String> callback);
  Future<void> startBackgroundSession();
  Future<void> stopBackgroundSession();
  Future<void> updateMediaPlaybackState(String state);
  Future<void> disposeBackgroundSession();
}

final class AndroidTtsBackgroundSession implements TtsAudioFocusAware {
  AndroidTtsBackgroundSession({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('xaocen.reader/tts_background') {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  VoidCallback? _onFocusLost;
  VoidCallback? _onFocusGained;
  ValueChanged<String>? _onMediaCommand;

  @override
  void setOnAudioFocusLost(VoidCallback callback) => _onFocusLost = callback;

  @override
  void setOnAudioFocusGained(VoidCallback callback) =>
      _onFocusGained = callback;

  @override
  void setOnMediaCommand(ValueChanged<String> callback) =>
      _onMediaCommand = callback;

  @override
  Future<void> startBackgroundSession() => _invoke('start');

  @override
  Future<void> stopBackgroundSession() => _invoke('stop');

  @override
  Future<void> updateMediaPlaybackState(String state) =>
      _invokeWithArguments('setPlaybackState', state);

  @override
  Future<void> disposeBackgroundSession() async {
    _onFocusLost = null;
    _onFocusGained = null;
    _onMediaCommand = null;
    _channel.setMethodCallHandler(null);
  }

  Future<void> _invoke(String method) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Desktop/test hosts and old Android builds have no service channel.
    } on PlatformException {
      // TTS remains usable if the optional foreground session is unavailable.
    }
  }

  Future<void> _invokeWithArguments(String method, Object? arguments) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Desktop/test hosts and old Android builds have no media channel.
    } on PlatformException {
      // TTS remains usable if the optional media session is unavailable.
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'audioFocusLost':
        _onFocusLost?.call();
      case 'audioFocusGained':
        _onFocusGained?.call();
      case 'mediaCommand':
        final command = call.arguments?.toString();
        if (command != null && command.isNotEmpty) {
          _onMediaCommand?.call(command);
        }
    }
  }
}
