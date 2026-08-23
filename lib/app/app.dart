import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/theme/app_theme.dart';
import '../domain/app_theme_mode.dart';
import 'product_identity.dart';
import 'router.dart';
import 'windows_shell.dart';
import 'providers.dart';

/// 应用根 Widget —— 主题 + 路由装配。
class XaocenApp extends ConsumerWidget {
  const XaocenApp({super.key});

  static const ThemeMode appThemeMode = ThemeMode.system;
  // Single app-locale source for the current Chinese product UI. Future
  // localization can update this value and the Tray bridge will follow it.
  static const Locale appLocale = Locale('zh', 'CN');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(appThemeModeProvider).valueOrNull;
    return WindowsShellHost(
      localeTag: appLocale.toLanguageTag(),
      child: MaterialApp(
        title: productNameForPlatform(),
        debugShowCheckedModeBanner: false,
        locale: appLocale,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: (appTheme ?? AppThemeMode.system).materialMode,
        initialRoute: AppRouter.root,
        routes: AppRouter.routes,
      ),
    );
  }
}
