import 'dart:io';

import 'package:flutter/services.dart';

/// A color sampled from a physical desktop pixel.
///
/// Coordinates are physical virtual-screen coordinates. They may be negative
/// on a monitor positioned to the left or above the primary display.
final class ColorSample {
  const ColorSample({
    required this.x,
    required this.y,
    required this.r,
    required this.g,
    required this.b,
    required this.hex,
  });

  final int x;
  final int y;
  final int r;
  final int g;
  final int b;
  final String hex;

  factory ColorSample.fromMap(Map<Object?, Object?> raw) {
    int readInt(String key) => (raw[key] as num).toInt();
    return ColorSample(
      x: readInt('x'),
      y: readInt('y'),
      r: readInt('r'),
      g: readInt('g'),
      b: readInt('b'),
      hex: raw['hex'] as String,
    );
  }
}

/// Windows-only bridge for one-shot desktop pixel sampling.
///
/// This API samples the native virtual desktop at the requested physical
/// coordinate. It never captures a screenshot and never depends on Reader or
/// Flutter rendering surfaces.
final class DesktopColorSampler {
  DesktopColorSampler._();

  static const MethodChannel _channel = MethodChannel(
    'xaocen/windows_desktop_color_sampler',
  );

  static bool get supported => Platform.isWindows;

  static Future<ColorSample> sampleDesktopPixel({
    required int x,
    required int y,
  }) async {
    if (!supported) {
      throw UnsupportedError('Desktop pixel sampling is Windows-only.');
    }
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
      'sampleDesktopPixel',
      <String, Object?>{'x': x, 'y': y},
    );
    if (raw == null) {
      throw StateError('Windows pixel sampler returned no data.');
    }
    return ColorSample.fromMap(raw);
  }

  /// Development/diagnostic helper: samples the current physical mouse point.
  static Future<ColorSample> sampleAtCursor() async {
    if (!supported) {
      throw UnsupportedError('Desktop pixel sampling is Windows-only.');
    }
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
      'sampleDesktopPixelAtCursor',
    );
    if (raw == null) {
      throw StateError('Windows pixel sampler returned no data.');
    }
    return ColorSample.fromMap(raw);
  }
}
