import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/theme/app_theme.dart';
import 'router.dart';

/// 应用根 Widget —— 主题 + 路由装配。
class XaocenApp extends ConsumerWidget {
  const XaocenApp({super.key});

  static const ThemeMode appThemeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'XAOCEN Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: appThemeMode,
      initialRoute: AppRouter.root,
      routes: AppRouter.routes,
    );
  }
}
