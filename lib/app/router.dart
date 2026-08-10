import 'package:flutter/material.dart';

import 'app_shell_page.dart';
import 'reader_input_settings_page.dart';

/// 路由入口 —— M2 根路由指向本地书库（M0 占位页保留供测试引用）。
/// 后续功能页面通过 named routes 在此注册。
abstract final class AppRouter {
  static const String root = '/';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    root: (_) => const AppShellPage(),
    settings: (_) => const ReaderSettingsPage(),
  };
}
