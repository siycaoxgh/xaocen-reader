import 'dart:ui' show DisplayFeatureType, FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../domain/reader/reader_preferences.dart';

/// Platform-neutral mapping for Reader's Android window preferences.
///
/// The native channel only owns the display-cutout flag. System bars and
/// orientation remain on Flutter's supported SystemChrome APIs so the Reader
/// keeps the normal activity/input/accessibility lifecycle.
final class AndroidReaderWindow {
  AndroidReaderWindow._();

  static const MethodChannel _channel = MethodChannel('xaocen.reader/window');

  static Future<BatteryStatus?> batteryStatus() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final value = await _channel.invokeMethod<Object?>('getBatteryStatus');
      if (value is! Map) return null;
      final percent = value['percent'];
      final charging = value['charging'];
      if (percent is! num || charging is! bool) return null;
      return BatteryStatus(
        percent: percent.round().clamp(0, 100),
        charging: charging,
      );
    } on PlatformException {
      return null;
    }
  }

  static Future<void> setDisplayCutout({required bool extend}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setDisplayCutout', extend);
    } on PlatformException {
      // Older installs simply keep the platform default. The Reader remains
      // usable and the safe-inset calculation still avoids the cutout.
    }
  }

  static Future<void> setSystemBars({
    required bool showStatusBar,
    required bool hideNavigationBar,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSystemBars', {
        'showStatusBar': showStatusBar,
        'hideNavigationBar': hideNavigationBar,
      });
    } on PlatformException {
      // Keep Flutter's overlay style as the safe fallback on older hosts.
    }
  }

  static Future<void> applyOrientation(ReaderScreenOrientation orientation) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return Future<void>.value();
    }
    final value = switch (orientation) {
      ReaderScreenOrientation.system => 'system',
      ReaderScreenOrientation.autoRotate => 'autoRotate',
      ReaderScreenOrientation.portrait => 'portrait',
      ReaderScreenOrientation.landscape => 'landscape',
    };
    return _channel
        .invokeMethod<void>('setScreenOrientation', value)
        .catchError(
          (_) => SystemChrome.setPreferredOrientations(switch (orientation) {
            ReaderScreenOrientation.system ||
            ReaderScreenOrientation.autoRotate => const <DeviceOrientation>[],
            ReaderScreenOrientation.portrait => const [
              DeviceOrientation.portraitUp,
            ],
            ReaderScreenOrientation.landscape => const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
          }),
        );
  }

  static EdgeInsets safeInsets(
    FlutterView view, {
    required bool extendIntoDisplayCutout,
    required bool hideNavigationBar,
  }) {
    if (defaultTargetPlatform != TargetPlatform.android) return EdgeInsets.zero;
    return safeInsetsForData(
      MediaQueryData.fromView(view),
      extendIntoDisplayCutout: extendIntoDisplayCutout,
      hideNavigationBar: hideNavigationBar,
    );
  }

  static EdgeInsets safeInsetsForData(
    MediaQueryData media, {
    required bool extendIntoDisplayCutout,
    required bool hideNavigationBar,
  }) {
    final padding = media.padding;
    final viewPadding = media.viewPadding;
    final maxTop = padding.top > viewPadding.top
        ? padding.top
        : viewPadding.top;
    final maxBottom = padding.bottom > viewPadding.bottom
        ? padding.bottom
        : viewPadding.bottom;
    final hasCutout = media.displayFeatures.any(
      (feature) => feature.type == DisplayFeatureType.cutout,
    );
    final maxLeft = hasCutout && padding.left > viewPadding.left
        ? padding.left
        : hasCutout
        ? viewPadding.left
        : 0.0;
    final maxRight = hasCutout && padding.right > viewPadding.right
        ? padding.right
        : hasCutout
        ? viewPadding.right
        : 0.0;
    return EdgeInsets.fromLTRB(
      extendIntoDisplayCutout ? 0 : maxLeft,
      extendIntoDisplayCutout ? 0 : maxTop,
      extendIntoDisplayCutout ? 0 : maxRight,
      hideNavigationBar ? 0 : maxBottom,
    );
  }
}

final class BatteryStatus {
  const BatteryStatus({required this.percent, required this.charging});
  final int percent;
  final bool charging;
}
