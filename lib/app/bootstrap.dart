import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// 启动入口 —— M0 只做最小引导：Riverpod 容器 + 应用根。
///
/// 说明：M0 不初始化数据库、不加载 GB18030 索引（M1 起按需懒加载）。
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: XaocenApp()));
}
