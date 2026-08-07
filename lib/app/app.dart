import 'package:flutter/material.dart';

import '../design/theme/app_theme.dart';
import 'router.dart';

/// 应用根 Widget —— 主题 + 路由装配。
class XaocenApp extends StatelessWidget {
  const XaocenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XAOCEN Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: AppRouter.root,
      routes: AppRouter.routes,
    );
  }
}
