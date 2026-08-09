import 'package:flutter/material.dart';

import '../domain/reader/reader_preferences.dart';
import 'reader_mode.dart';

const readerChromeToggleKey = Key('reader-chrome-toggle');
const readerTopChromeKey = Key('reader-top-chrome');
const readerBottomChromeKey = Key('reader-bottom-chrome');
const readerTocActionKey = Key('reader-toc-action');
const readerAppearanceActionKey = Key('reader-appearance-action');
const readerMoreActionKey = Key('reader-more-action');
const readerModeActionKey = Key('reader-mode-action');

class ReaderChrome extends StatelessWidget {
  const ReaderChrome({
    super.key,
    required this.visible,
    required this.title,
    required this.mode,
    required this.onBack,
    required this.onToc,
    required this.onAppearance,
    required this.onMore,
    required this.onModeSelected,
  });

  final bool visible;
  final String title;
  final ReaderMode mode;
  final VoidCallback onBack;
  final VoidCallback onToc;
  final VoidCallback onAppearance;
  final VoidCallback onMore;
  final ValueChanged<ReaderMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 120),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                bottom: false,
                child: Container(
                  key: readerTopChromeKey,
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.96),
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: '返回书架',
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              mode == ReaderMode.paged ? '分页阅读' : '滚动阅读',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<ReaderMode>(
                        key: readerModeActionKey,
                        tooltip: '阅读模式',
                        onSelected: onModeSelected,
                        icon: Icon(
                          mode == ReaderMode.paged
                              ? Icons.menu_book_rounded
                              : Icons.view_stream_rounded,
                        ),
                        itemBuilder: (context) => [
                          CheckedPopupMenuItem(
                            value: ReaderMode.vertical,
                            checked: mode == ReaderMode.vertical,
                            child: const Text('滚动'),
                          ),
                          CheckedPopupMenuItem(
                            value: ReaderMode.paged,
                            checked: mode == ReaderMode.paged,
                            child: const Text('分页'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 520 : double.infinity,
                  ),
                  child: Material(
                    key: readerBottomChromeKey,
                    color: colorScheme.surface.withValues(alpha: 0.97),
                    elevation: 4,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(isDesktop ? 18 : 14),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        _ChromeAction(
                          key: readerTocActionKey,
                          icon: Icons.list,
                          label: '目录',
                          onPressed: onToc,
                        ),
                        _ChromeAction(
                          icon: mode == ReaderMode.paged
                              ? Icons.menu_book_rounded
                              : Icons.view_stream_rounded,
                          label: mode == ReaderMode.paged ? '分页' : '滚动',
                          selected: true,
                          onPressed: () => onModeSelected(
                            mode == ReaderMode.paged
                                ? ReaderMode.vertical
                                : ReaderMode.paged,
                          ),
                        ),
                        _ChromeAction(
                          key: readerAppearanceActionKey,
                          icon: Icons.text_fields_rounded,
                          label: '界面',
                          onPressed: onAppearance,
                        ),
                        _ChromeAction(
                          key: readerMoreActionKey,
                          icon: Icons.more_horiz_rounded,
                          label: '更多',
                          onPressed: onMore,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChromeAction extends StatelessWidget {
  const _ChromeAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: SizedBox(
            height: 62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showReaderAppearancePreview(
  BuildContext context, {
  required ReaderPreferences preferences,
  required ReaderMode mode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('阅读界面', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '字号 ${preferences.fontSize.toStringAsFixed(0)}  ·  '
              '行距 ${preferences.lineHeight.toStringAsFixed(1)}  ·  '
              '${mode == ReaderMode.paged ? '分页' : '滚动'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '字号、行距、边距与主题调节将在 M5.1e 提供。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showReaderMorePreview(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        leading: const Icon(Icons.settings_outlined),
        title: const Text('更多阅读设置'),
        subtitle: const Text('更多功能将在后续阶段逐步开放；朗读当前未实现。'),
      ),
    ),
  );
}
