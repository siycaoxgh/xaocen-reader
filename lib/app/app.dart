import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/theme/app_theme.dart';
import '../domain/reader/reader_preferences.dart';
import 'providers.dart';
import 'router.dart';

/// 应用根 Widget —— 主题 + 路由装配。
class XaocenApp extends ConsumerWidget {
  const XaocenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences =
        ref.watch(readerPreferencesProvider).valueOrNull ??
        ReaderPreferences.defaults;
    return MaterialApp(
      title: 'XAOCEN Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _materialThemeMode(preferences.themeMode),
      initialRoute: AppRouter.root,
      routes: AppRouter.routes,
    );
  }
}

ThemeMode _materialThemeMode(ReaderThemeMode mode) => switch (mode) {
  ReaderThemeMode.system => ThemeMode.system,
  ReaderThemeMode.light => ThemeMode.light,
  ReaderThemeMode.dark => ThemeMode.dark,
};
