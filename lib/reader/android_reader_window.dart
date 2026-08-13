import 'dart:math' as math;
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

  /// Extra foreground clearance around a physical display cutout. The
  /// background may still render edge-to-edge; this gap applies only to
  /// important text and controls.
  static const double cutoutForegroundSafetyGap = 4;

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

  /// Returns the real cutout bounds reported by Flutter, in logical pixels.
  /// No camera position, status-bar height, or device-specific constant is
  /// inferred here.
  static List<Rect> cutoutBoundsForData(MediaQueryData media) => [
    for (final feature in media.displayFeatures)
      if (feature.type == DisplayFeatureType.cutout && !feature.bounds.isEmpty)
        feature.bounds,
  ];

  /// Clearance below cutouts touching the top physical edge. This is a
  /// placement constraint for the divider/center slot, not a full-width
  /// TopInfo inset: left and right slots may use space beside a camera hole.
  static double topCutoutClearanceForData(MediaQueryData media) {
    var clearance = 0.0;
    for (final bounds in cutoutBoundsForData(media)) {
      if (bounds.top <= 0 && bounds.bottom > 0) {
        clearance = math.max(
          clearance,
          bounds.bottom + cutoutForegroundSafetyGap,
        );
      }
    }
    return clearance;
  }

  /// Returns the smallest local padding needed by a top slot. Edge cutouts
  /// reserve only the affected side; a centered cutout reserves vertical room
  /// for the center slot. The other slots retain their normal top position.
  static EdgeInsets topSlotPaddingForData(
    MediaQueryData media, {
    required ReaderInfoSlot slot,
  }) {
    if (slot != ReaderInfoSlot.topLeft &&
        slot != ReaderInfoSlot.topCenter &&
        slot != ReaderInfoSlot.topRight) {
      return EdgeInsets.zero;
    }
    var left = 0.0;
    var right = 0.0;
    var top = 0.0;
    final slotWidth = media.size.width / 3;
    final slotIndex = switch (slot) {
      ReaderInfoSlot.topLeft => 0,
      ReaderInfoSlot.topCenter => 1,
      ReaderInfoSlot.topRight => 2,
      _ => 1,
    };
    final slotStart = slotIndex * slotWidth;
    final slotEnd = slotStart + slotWidth;
    for (final bounds in cutoutBoundsForData(media)) {
      if (bounds.top > 0 || bounds.bottom <= 0) continue;
      final overlapsSlot = bounds.right > slotStart && bounds.left < slotEnd;
      if (!overlapsSlot) continue;
      if (slot == ReaderInfoSlot.topLeft && bounds.left <= 0) {
        left = math.max(left, bounds.right + cutoutForegroundSafetyGap);
      } else if (slot == ReaderInfoSlot.topRight &&
          bounds.right >= media.size.width) {
        right = math.max(
          right,
          media.size.width - bounds.left + cutoutForegroundSafetyGap,
        );
      } else {
        top = math.max(top, bounds.bottom + cutoutForegroundSafetyGap);
      }
    }
    return EdgeInsets.fromLTRB(left, top, right, 0);
  }

  /// Reader Info insets retain normal system-bar behavior while allowing an
  /// edge-to-edge background. A top cutout is handled locally by the region's
  /// divider/center-slot geometry rather than moving the entire row down.
  static EdgeInsets readerInfoInsetsForData(
    MediaQueryData media, {
    required bool extendIntoDisplayCutout,
    required bool hideNavigationBar,
  }) {
    final safe = safeInsetsForData(
      media,
      extendIntoDisplayCutout: false,
      hideNavigationBar: hideNavigationBar,
    );
    return EdgeInsets.fromLTRB(
      safe.left,
      extendIntoDisplayCutout ? 0 : safe.top,
      safe.right,
      safe.bottom,
    );
  }

  /// Insets for important foreground content. Unlike [safeInsetsForData],
  /// this remains active even when the user allows the background to extend
  /// behind a cutout. It is used by Info/Chrome/App Shell foreground only.
  static EdgeInsets foregroundInsetsForData(
    MediaQueryData media, {
    required bool extendIntoDisplayCutout,
    required bool hideNavigationBar,
  }) {
    final base = safeInsetsForData(
      media,
      extendIntoDisplayCutout: extendIntoDisplayCutout,
      hideNavigationBar: hideNavigationBar,
    );
    var left = base.left;
    var top = base.top;
    var right = base.right;
    var bottom = base.bottom;
    for (final bounds in cutoutBoundsForData(media)) {
      final gap = cutoutForegroundSafetyGap;
      if (bounds.top <= 0 && bounds.bottom > 0) {
        top = math.max(top, bounds.bottom + gap);
      }
      if (bounds.left <= 0 && bounds.right > 0) {
        left = math.max(left, bounds.right + gap);
      }
      if (bounds.right >= media.size.width && bounds.left < media.size.width) {
        right = math.max(right, media.size.width - bounds.left + gap);
      }
      if (bounds.bottom >= media.size.height &&
          bounds.top < media.size.height) {
        bottom = math.max(bottom, media.size.height - bounds.top + gap);
      }
    }
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }
}

final class BatteryStatus {
  const BatteryStatus({required this.percent, required this.charging});
  final int percent;
  final bool charging;
}
