import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'desktop_color_sampler.dart';

enum WindowsEyedropperState { idle, picking, confirmed, cancelled }

/// Coordinates the temporary Windows desktop-picking interaction.
///
/// This is deliberately separate from Reader color preferences. The native
/// side installs its input tracking only between [start] and confirmation or
/// cancellation, and always forwards the original input to Windows.
final class WindowsEyedropperController extends ChangeNotifier {
  WindowsEyedropperController({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('xaocen/windows_eyedropper') {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  WindowsEyedropperState _state = WindowsEyedropperState.idle;
  ColorSample? _currentSample;
  ColorSample? _confirmedSample;
  int _completedTransitions = 0;

  WindowsEyedropperState get state => _state;
  ColorSample? get currentSample => _currentSample;
  ColorSample? get confirmedSample => _confirmedSample;
  int get completedTransitions => _completedTransitions;
  bool get supported => Platform.isWindows;

  Future<bool> start() async {
    if (!supported || _state == WindowsEyedropperState.picking) return false;
    final started = await _channel.invokeMethod<bool>('startPicking') ?? false;
    if (!started) return false;
    _confirmedSample = null;
    _setState(WindowsEyedropperState.picking);
    return true;
  }

  Future<void> cancel() async {
    if (_state != WindowsEyedropperState.picking) return;
    await _channel.invokeMethod<void>('cancelPicking');
  }

  Future<void> disposePicking() async {
    if (_state == WindowsEyedropperState.picking) {
      await _channel.invokeMethod<void>('cancelPicking');
    }
    dispose();
  }

  /// Handles a native event and is public for deterministic widget/contract
  /// tests without requiring a Windows hook in the test host.
  @visibleForTesting
  Future<void> handleNativeEvent(
    String method,
    Object? arguments,
  ) async {
    await _handleNativeCall(MethodCall(method, arguments));
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'sampleUpdated':
        if (call.arguments is Map) {
          _currentSample = ColorSample.fromMap(
            Map<Object?, Object?>.from(call.arguments as Map),
          );
          if (_state == WindowsEyedropperState.picking) notifyListeners();
        }
      case 'confirmed':
        if (call.arguments is Map) {
          _confirmedSample = ColorSample.fromMap(
            Map<Object?, Object?>.from(call.arguments as Map),
          );
        }
        _complete(WindowsEyedropperState.confirmed);
      case 'cancelled':
        _complete(WindowsEyedropperState.cancelled);
    }
  }

  void _complete(WindowsEyedropperState outcome) {
    if (_state != WindowsEyedropperState.picking) return;
    _setState(outcome);
    _completedTransitions++;
    // Native hooks are already removed before the event is sent. Return to
    // idle immediately so a controller cannot accumulate a second listener.
    _setState(WindowsEyedropperState.idle);
  }

  void _setState(WindowsEyedropperState next) {
    _state = next;
    notifyListeners();
  }
}
