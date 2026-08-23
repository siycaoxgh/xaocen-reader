import 'package:flutter/material.dart';

/// Theme preference for the application shell and Settings surfaces.
///
/// This is intentionally separate from ReaderThemeMode: a book's reading
/// palette must not change the chrome used by the application Settings UI.
enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  ThemeMode get materialMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  String get label => switch (this) {
    AppThemeMode.system => '跟随系统',
    AppThemeMode.light => '浅色',
    AppThemeMode.dark => '深色',
  };

  static AppThemeMode parse(Object? raw) => switch (raw) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    _ => AppThemeMode.system,
  };
}
