import 'package:flutter/material.dart';

import '../design/tokens/app_tokens.dart';
import 'product_identity.dart';

/// M0 开发占位页 —— 仅证明工程骨架可启动，不代表 V3 统一 UI 已实现。
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 64, color: AppTokens.primary),
            const SizedBox(height: 16),
            Text(productNameForPlatform(), style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('工程骨架已初始化', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('当前阶段：M0', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
