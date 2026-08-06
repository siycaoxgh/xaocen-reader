import 'package:flutter/material.dart';

/// 设计令牌 —— 来自 V3 统一 UI 原型的品牌色板。
///
/// M0 仅建立令牌入口，不实现完整视觉系统。
abstract final class AppTokens {
  // 品牌主色
  static const Color primary = Color(0xFF44D9E6); // 青靛
  static const Color accent = Color(0xFFFFBD4A); // 橙黄
  static const Color secondary = Color(0xFF2EB3FF); // 天蓝
  static const Color tertiary = Color(0xFFAFCFEE); // 青灰

  // 中性色（M0 最小集）
  static const Color background = Color(0xFF0F1A1E); // 深色背景
  static const Color surface = Color(0xFF16262B);
  static const Color onBackground = Color(0xFFE6F0F3);
  static const Color onSurface = Color(0xFFC9DDE3);
  static const Color outline = Color(0xFF2E434A);
}
