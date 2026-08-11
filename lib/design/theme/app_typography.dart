import 'package:flutter/material.dart';

/// Shared type scale and fallback policy for the app shell.
///
/// No concrete font is forced: the platform's default UI font remains the
/// primary face. The fallback list only helps mixed Chinese/Latin text choose
/// a readable installed face consistently on Windows and Android.
abstract final class AppTypography {
  static const fontFamilyFallback = <String>[
    'Noto Sans CJK SC',
    'Microsoft YaHei',
    'Noto Sans',
    'sans-serif',
  ];

  static TextTheme textTheme(TextTheme base) {
    final themed = base.apply(fontFamilyFallback: fontFamilyFallback);
    return themed.copyWith(
      headlineSmall: _weight(themed.headlineSmall, FontWeight.w600),
      titleLarge: _weight(themed.titleLarge, FontWeight.w600),
      titleMedium: _weight(themed.titleMedium, FontWeight.w600),
      titleSmall: _weight(themed.titleSmall, FontWeight.w600),
      bodyLarge: _weight(themed.bodyLarge, FontWeight.w400),
      bodyMedium: _weight(themed.bodyMedium, FontWeight.w400),
      bodySmall: _weight(themed.bodySmall, FontWeight.w400),
      labelLarge: _weight(themed.labelLarge, FontWeight.w600),
      labelMedium: _weight(themed.labelMedium, FontWeight.w500),
      labelSmall: _weight(themed.labelSmall, FontWeight.w500),
    );
  }

  static TextStyle? _weight(TextStyle? style, FontWeight weight) =>
      style?.copyWith(fontWeight: weight);
}

/// Reader-specific styles. The body intentionally leaves [fontFamily] null so
/// the platform's default reading font remains in use; only the shared
/// fallback policy is attached. Reader metrics changes still flow through the
/// existing relayout/Locator restore state machine.
abstract final class ReaderTypography {
  static const fontFamilyFallback = AppTypography.fontFamilyFallback;

  static TextStyle body({
    required double fontSize,
    required double lineHeight,
    required double letterSpacing,
    required Color color,
    String? fontFamily,
  }) => TextStyle(
    fontSize: fontSize,
    height: lineHeight,
    letterSpacing: letterSpacing,
    color: color,
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
  );

  static TextStyle paletteSwatch({required Color color}) => TextStyle(
    color: color,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    fontFamilyFallback: fontFamilyFallback,
  );

  static TextStyle previewLabel({required Color color}) => TextStyle(
    color: color,
    fontSize: 11,
    fontFamilyFallback: fontFamilyFallback,
  );

  static TextStyle previewBody({required Color color}) => TextStyle(
    color: color,
    fontSize: 17,
    height: 1.35,
    fontFamilyFallback: fontFamilyFallback,
  );

  static const debug = TextStyle(
    fontSize: 11,
    fontFamily: 'monospace',
    fontFamilyFallback: fontFamilyFallback,
  );
}
