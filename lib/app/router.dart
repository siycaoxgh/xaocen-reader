import 'package:flutter/material.dart';

import 'placeholder_page.dart';

/// 空路由入口 —— M0 仅注册根路由（占位页）。
/// 后续功能页面通过 named routes 在此注册。
abstract final class AppRouter {
  static const String root = '/';

  static Map<String, WidgetBuilder> get routes => {
        root: (_) => const PlaceholderPage(),
      };
}
