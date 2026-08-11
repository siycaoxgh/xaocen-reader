/// ReaderResolvedAppearance —— Reader 最小视觉合同（P1）。
///
/// 从当前 Theme 的 ColorScheme 解析，保证正文/背景/次要文字属于同一主题上下文。
/// 禁止正文绘制硬编码 Colors.black / Colors.white / 固定深灰。
///
/// 约定：
/// - backgroundColor  来自 colorScheme.surface；
/// - textColor        来自 colorScheme.onSurface（正文/标题，对比度 ≥4.5:1）；
/// - secondaryTextColor 来自 colorScheme.onSurfaceVariant；
/// - headingColor     来自 colorScheme.onSurface（卷标题等）；
/// - selectionColor   来自 colorScheme.primaryContainer（当前章节高亮）；
/// - baseTextStyle    显示与测量共用（含解析后的 textColor）。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/theme/app_typography.dart';
import '../domain/reader/reader_palette.dart';
import '../domain/reader/reader_preferences.dart';

/// Reader 已解析外观（不可变）。
class ReaderResolvedAppearance {
  const ReaderResolvedAppearance({
    required this.backgroundColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.headingColor,
    required this.selectionColor,
    required this.baseTextStyle,
    this.paletteId = ReaderPaletteId.paperWhite,
    this.textContrastRatio = 21,
    this.hasLowContrastWarning = false,
    this.hasBackgroundImage = false,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color headingColor;
  final Color selectionColor;

  /// 正文基准样式（显示与测量使用同一实例，禁止两套）。
  final TextStyle baseTextStyle;
  final ReaderPaletteId paletteId;
  final double textContrastRatio;
  final bool hasLowContrastWarning;
  final bool hasBackgroundImage;
}

/// 从 [ThemeData] 解析 Reader 外观。
///
/// [fontSize]/[lineHeight] 为正文度量默认值（后续阅读设置阶段再放开）。
ReaderResolvedAppearance resolveReaderAppearance(
  BuildContext context, {
  ThemeData? theme,
  ReaderPreferences? preferences,
  ReaderPaletteId paletteId = ReaderPaletteId.paperWhite,
  double fontSize = 17,
  double lineHeight = 1.7,
  double letterSpacing = 0,
  int? textColorArgb,
  int? backgroundColorArgb,
  int? lightTextColorArgb,
  int? lightBackgroundColorArgb,
  int? darkTextColorArgb,
  int? darkBackgroundColorArgb,
  bool hasBackgroundImage = false,
}) {
  final scheme = (theme ?? Theme.of(context)).colorScheme;
  final dark = scheme.brightness == Brightness.dark;
  final resolvedPreferences = preferences;
  final palette = ReaderPaletteResolver.resolve(
    paletteId: resolvedPreferences?.paletteId ?? paletteId,
    dark: dark,
    lightTextArgb:
        resolvedPreferences?.lightTextColorArgb ??
        lightTextColorArgb ??
        textColorArgb,
    lightBackgroundArgb:
        resolvedPreferences?.lightBackgroundColorArgb ??
        lightBackgroundColorArgb ??
        backgroundColorArgb,
    darkTextArgb:
        resolvedPreferences?.darkTextColorArgb ??
        darkTextColorArgb ??
        textColorArgb,
    darkBackgroundArgb:
        resolvedPreferences?.darkBackgroundColorArgb ??
        darkBackgroundColorArgb ??
        backgroundColorArgb,
  );
  final backgroundColor = Color(palette.backgroundArgb);
  final textColor = Color(palette.textArgb);
  final textContrast = contrastRatio(textColor, backgroundColor);
  return ReaderResolvedAppearance(
    backgroundColor: backgroundColor,
    textColor: textColor,
    secondaryTextColor: resolvedPreferences == null && textColorArgb == null
        ? scheme.onSurfaceVariant
        : textColor.withValues(alpha: 0.72),
    headingColor: textColor,
    selectionColor: scheme.primaryContainer,
    paletteId: resolvedPreferences?.paletteId ?? paletteId,
    textContrastRatio: textContrast,
    hasLowContrastWarning: textContrast < 4.5,
    baseTextStyle: ReaderTypography.body(
      fontSize: resolvedPreferences?.fontSize ?? fontSize,
      lineHeight: resolvedPreferences?.lineHeight ?? lineHeight,
      letterSpacing: resolvedPreferences?.letterSpacing ?? letterSpacing,
      color: textColor,
    ),
    hasBackgroundImage: hasBackgroundImage,
  );
}

// ---- 对比度工具（自动颜色对比检查，P1 验收）----

/// 相对亮度（WCAG，0~1）。
double colorLuminance(Color c) {
  double ch(double v) {
    final s = v / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * ch(c.r * 255) +
      0.7152 * ch(c.g * 255) +
      0.0722 * ch(c.b * 255);
}

/// WCAG 对比度（1~21）。
double contrastRatio(Color a, Color b) {
  final la = colorLuminance(a);
  final lb = colorLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// 正文可读性验收：对比度不低于 [minimum]（默认 4.5:1）。
bool isReadable(Color fg, Color bg, {double minimum = 4.5}) {
  return contrastRatio(fg, bg) >= minimum;
}

/// Legacy compatibility helper. Custom Reader colors are user-owned values and
/// must never be silently replaced; callers should use [isReadable] to show a
/// warning instead.
Color ensureReadableTextColor(
  Color requested,
  Color background, {
  double minimum = 4.5,
}) {
  return requested;
}
