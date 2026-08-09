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
const readerSettingsSheetKey = Key('reader-settings-sheet');
const readerFontSizeSliderKey = Key('reader-font-size-slider');
const readerLineHeightSliderKey = Key('reader-line-height-slider');
const readerHorizontalPaddingSliderKey = Key(
  'reader-horizontal-padding-slider',
);
const readerVerticalPaddingSliderKey = Key('reader-vertical-padding-slider');
const readerThemeControlKey = Key('reader-theme-control');
const readerSettingsModeControlKey = Key('reader-settings-mode-control');
const readerResetPreferencesKey = Key('reader-reset-preferences');

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

Future<void> showReaderSettings(
  BuildContext context, {
  required ReaderPreferences preferences,
  required ReaderMode mode,
  required ValueChanged<ReaderPreferences> onPreferencesCommitted,
  required ValueChanged<ReaderMode> onModeSelected,
  required VoidCallback onResetPreferences,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 720;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxWidth: isDesktop ? 560 : double.infinity),
    builder: (context) => ReaderSettingsSheet(
      preferences: preferences,
      mode: mode,
      onPreferencesCommitted: onPreferencesCommitted,
      onModeSelected: onModeSelected,
      onResetPreferences: onResetPreferences,
    ),
  );
}

class ReaderSettingsSheet extends StatefulWidget {
  const ReaderSettingsSheet({
    super.key,
    required this.preferences,
    required this.mode,
    required this.onPreferencesCommitted,
    required this.onModeSelected,
    required this.onResetPreferences,
  });

  final ReaderPreferences preferences;
  final ReaderMode mode;
  final ValueChanged<ReaderPreferences> onPreferencesCommitted;
  final ValueChanged<ReaderMode> onModeSelected;
  final VoidCallback onResetPreferences;

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late ReaderPreferences _draft = widget.preferences;
  late ReaderMode _mode = widget.mode;

  void _commit(ReaderPreferences value) {
    setState(() => _draft = value);
    widget.onPreferencesCommitted(value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        key: readerSettingsSheetKey,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('阅读界面', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _PreferenceSlider(
              key: readerFontSizeSliderKey,
              label: '字号',
              value: _draft.fontSize,
              min: ReaderPreferences.minFontSize,
              max: ReaderPreferences.maxFontSize,
              divisions: 20,
              valueLabel: _draft.fontSize.toStringAsFixed(0),
              onDraftChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(fontSize: value)),
              onCommitted: (value) => _commit(_draft.copyWith(fontSize: value)),
            ),
            _PreferenceSlider(
              key: readerLineHeightSliderKey,
              label: '行距',
              value: _draft.lineHeight,
              min: ReaderPreferences.minLineHeight,
              max: ReaderPreferences.maxLineHeight,
              divisions: 12,
              valueLabel: _draft.lineHeight.toStringAsFixed(1),
              onDraftChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(lineHeight: value)),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(lineHeight: value)),
            ),
            _PreferenceSlider(
              key: readerHorizontalPaddingSliderKey,
              label: '水平正文边距',
              value: _draft.horizontalPadding,
              min: ReaderPreferences.minHorizontalPadding,
              max: ReaderPreferences.maxHorizontalPadding,
              divisions: 16,
              valueLabel: _draft.horizontalPadding.toStringAsFixed(0),
              onDraftChanged: (value) => setState(
                () => _draft = _draft.copyWith(horizontalPadding: value),
              ),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(horizontalPadding: value)),
            ),
            _PreferenceSlider(
              key: readerVerticalPaddingSliderKey,
              label: '垂直正文边距',
              value: _draft.verticalPadding,
              min: ReaderPreferences.minVerticalPadding,
              max: ReaderPreferences.maxVerticalPadding,
              divisions: 12,
              valueLabel: _draft.verticalPadding.toStringAsFixed(0),
              onDraftChanged: (value) => setState(
                () => _draft = _draft.copyWith(verticalPadding: value),
              ),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(verticalPadding: value)),
            ),
            const SizedBox(height: 12),
            Text('主题', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ReaderThemeMode>(
              key: readerThemeControlKey,
              segments: const [
                ButtonSegment(value: ReaderThemeMode.system, label: Text('系统')),
                ButtonSegment(value: ReaderThemeMode.light, label: Text('浅色')),
                ButtonSegment(value: ReaderThemeMode.dark, label: Text('深色')),
              ],
              selected: {_draft.themeMode},
              onSelectionChanged: (selection) =>
                  _commit(_draft.copyWith(themeMode: selection.single)),
            ),
            const SizedBox(height: 20),
            Text('阅读模式（本书）', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ReaderMode>(
              key: readerSettingsModeControlKey,
              segments: const [
                ButtonSegment(value: ReaderMode.vertical, label: Text('滚动')),
                ButtonSegment(value: ReaderMode.paged, label: Text('分页')),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                final next = selection.single;
                setState(() => _mode = next);
                widget.onModeSelected(next);
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: readerResetPreferencesKey,
              onPressed: () {
                setState(() => _draft = ReaderPreferences.defaults);
                widget.onResetPreferences();
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('恢复默认设置'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSlider extends StatelessWidget {
  const _PreferenceSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onDraftChanged,
    required this.onCommitted,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onDraftChanged;
  final ValueChanged<double> onCommitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(valueLabel, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onDraftChanged,
          onChangeEnd: onCommitted,
        ),
      ],
    );
  }
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
