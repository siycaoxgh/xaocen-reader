import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../reader/supported_shortcut_key_registry.dart';

const _guideAsset = 'assets/shortcuts/xc-jpkjjsyt.png';

/// Opens the static keyboard capability guide used by Windows shortcut setup.
///
/// The image is documentation only. Validation and persistence continue to
/// use [SupportedShortcutKeyRegistry].
Future<void> showWindowsShortcutGuide(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const WindowsShortcutGuideDialog(),
  );
}

class WindowsShortcutGuideDialog extends StatelessWidget {
  const WindowsShortcutGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageWidth = math.min(constraints.maxWidth - 32, 720.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '支持哪些按键？',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      _guideAsset,
                      width: imageWidth,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '当前已验证支持：${SupportedShortcutKeyRegistry.categories.keys.join('、')}。',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '绿色区域表示当前可作为 XAOCEN 快捷键使用的按键，灰色区域表示暂不支持的按键。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '按键位置可能因键盘型号、笔记本或外接键盘而有所不同，图片仅用于说明 XAOCEN 支持的快捷键范围。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '数字键盘仅适用于具备独立数字键盘的设备。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '鼠标左右键同时按下为固定手势，不参与普通快捷键录入。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '常用符号键目前未纳入可靠支持集合，录入时会提示“该按键暂不支持作为 XAOCEN 快捷键”。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
