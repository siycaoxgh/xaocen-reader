import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';
import 'app_typography.dart';

/// 应用主题入口 —— M0 建立基础主题，V3 统一 UI 原型后续单独落地。
///
/// P1：浅色/深色双主题，跟随系统 ThemeMode（app.dart 配置）。
abstract final class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.dark(
      primary: AppTokens.primary,
      secondary: AppTokens.accent,
      tertiary: AppTokens.secondary,
      surface: AppTokens.surface,
      onSurface: AppTokens.onSurface,
      outline: AppTokens.outline,
    );
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.background,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
    );
    return theme.copyWith(textTheme: AppTypography.textTheme(theme.textTheme));
  }

  static ThemeData light() {
    final scheme = ColorScheme.light(
      primary: AppTokens.primary,
      secondary: AppTokens.accent,
      tertiary: AppTokens.secondary,
      surface: AppTokens.lightSurface,
      onSurface: AppTokens.lightOnSurface,
      outline: AppTokens.lightOutline,
    );
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.lightBackground,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
    );
    return theme.copyWith(textTheme: AppTypography.textTheme(theme.textTheme));
  }
}
