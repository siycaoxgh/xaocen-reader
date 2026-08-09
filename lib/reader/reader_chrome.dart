import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/reader/reader_bookmark.dart';
import '../domain/reader/reader_preferences.dart';
import '../domain/reader/reader_search.dart';
import 'reader_mode.dart';

const readerChromeToggleKey = Key('reader-chrome-toggle');
const readerTopChromeKey = Key('reader-top-chrome');
const readerBottomChromeKey = Key('reader-bottom-chrome');
const readerTocActionKey = Key('reader-toc-action');
const readerAppearanceActionKey = Key('reader-appearance-action');
const readerMoreActionKey = Key('reader-more-action');
const readerBookmarksActionKey = Key('reader-bookmarks-action');
const readerSearchActionKey = Key('reader-search-action');
const readerBookmarkCreateKey = Key('reader-bookmark-create');
const readerBookmarkListKey = Key('reader-bookmark-list');
const readerModeActionKey = Key('reader-mode-action');
const readerSettingsSheetKey = Key('reader-settings-sheet');
const readerFontSizeSliderKey = Key('reader-font-size-slider');
const readerLineHeightSliderKey = Key('reader-line-height-slider');
const readerLetterSpacingSliderKey = Key('reader-letter-spacing-slider');
const readerParagraphSpacingSliderKey = Key('reader-paragraph-spacing-slider');
const readerFirstLineIndentSliderKey = Key('reader-first-line-indent-slider');
const readerHorizontalPaddingSliderKey = Key(
  'reader-horizontal-padding-slider',
);
const readerVerticalPaddingSliderKey = Key('reader-vertical-padding-slider');
const readerPaddingRightSliderKey = Key('reader-padding-right-slider');
const readerPaddingBottomSliderKey = Key('reader-padding-bottom-slider');
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
    required this.onBookmarks,
    required this.onSearch,
    required this.onModeSelected,
    this.currentChapterTitle,
    this.progressPercent,
  });

  final bool visible;
  final String title;
  final ReaderMode mode;
  final VoidCallback onBack;
  final VoidCallback onToc;
  final VoidCallback onAppearance;
  final VoidCallback onMore;
  final VoidCallback onBookmarks;
  final VoidCallback onSearch;
  final ValueChanged<ReaderMode> onModeSelected;
  final String? currentChapterTitle;
  final double? progressPercent;

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
                            if (currentChapterTitle != null ||
                                progressPercent != null)
                              Text(
                                '${currentChapterTitle ?? '全文'} · ${progressPercent == null ? '--' : '${(progressPercent! * 100).round()}%'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
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
                          key: readerBookmarksActionKey,
                          icon: Icons.bookmark_outline,
                          label: '书签',
                          onPressed: onBookmarks,
                        ),
                        _ChromeAction(
                          key: readerSearchActionKey,
                          icon: Icons.search,
                          label: '搜索',
                          onPressed: onSearch,
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
              step: ReaderPreferences.fontSizeStep,
              valueLabel: _draft.fontSize.toStringAsFixed(0),
              onDraftChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(fontSize: value)),
              onCommitted: (value) => _commit(_draft.copyWith(fontSize: value)),
            ),
            _PreferenceSlider(
              key: readerLetterSpacingSliderKey,
              label: '字距',
              value: _draft.letterSpacing,
              min: ReaderPreferences.minLetterSpacing,
              max: ReaderPreferences.maxLetterSpacing,
              divisions: 30,
              step: ReaderPreferences.letterSpacingStep,
              valueLabel: _draft.letterSpacing.toStringAsFixed(2),
              onDraftChanged: (value) => setState(
                () => _draft = _draft.copyWith(letterSpacing: value),
              ),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(letterSpacing: value)),
            ),
            _PreferenceSlider(
              key: readerLineHeightSliderKey,
              label: '行距',
              value: _draft.lineHeight,
              min: ReaderPreferences.minLineHeight,
              max: ReaderPreferences.maxLineHeight,
              divisions: 12,
              step: ReaderPreferences.lineHeightStep,
              valueLabel: _draft.lineHeight.toStringAsFixed(1),
              onDraftChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(lineHeight: value)),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(lineHeight: value)),
            ),
            _PreferenceSlider(
              key: readerParagraphSpacingSliderKey,
              label: '段距',
              value: _draft.paragraphSpacing,
              min: ReaderPreferences.minParagraphSpacing,
              max: ReaderPreferences.maxParagraphSpacing,
              divisions: 32,
              step: ReaderPreferences.paragraphSpacingStep,
              valueLabel: _draft.paragraphSpacing.toStringAsFixed(0),
              onDraftChanged: (value) => setState(
                () => _draft = _draft.copyWith(paragraphSpacing: value),
              ),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(paragraphSpacing: value)),
            ),
            _PreferenceSlider(
              key: readerFirstLineIndentSliderKey,
              label: '首行缩进（字宽）',
              value: _draft.firstLineIndent,
              min: ReaderPreferences.minFirstLineIndent,
              max: ReaderPreferences.maxFirstLineIndent,
              divisions: 8,
              step: ReaderPreferences.firstLineIndentStep,
              valueLabel: _draft.firstLineIndent.toStringAsFixed(1),
              onDraftChanged: (value) => setState(
                () => _draft = _draft.copyWith(firstLineIndent: value),
              ),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(firstLineIndent: value)),
            ),
            _PreferenceSlider(
              key: readerHorizontalPaddingSliderKey,
              label: '左边距',
              value: _draft.paddingLeft,
              min: ReaderPreferences.minHorizontalPadding,
              max: ReaderPreferences.maxHorizontalPadding,
              divisions: 16,
              step: ReaderPreferences.paddingStep,
              valueLabel: _draft.paddingLeft.toStringAsFixed(0),
              onDraftChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(paddingLeft: value)),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(paddingLeft: value)),
            ),
            _PreferenceSlider(
              key: readerPaddingRightSliderKey,
              label: '右边距',
              value: _draft.paddingRight,
              min: ReaderPreferences.minHorizontalPadding,
              max: ReaderPreferences.maxHorizontalPadding,
              divisions: 16,
              step: ReaderPreferences.paddingStep,
              valueLabel: _draft.paddingRight.toStringAsFixed(0),
              onDraftChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(paddingRight: value)),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(paddingRight: value)),
            ),
            _PreferenceSlider(
              key: readerVerticalPaddingSliderKey,
              label: '上边距',
              value: _draft.paddingTop,
              min: ReaderPreferences.minVerticalPadding,
              max: ReaderPreferences.maxVerticalPadding,
              divisions: 12,
              step: ReaderPreferences.paddingStep,
              valueLabel: _draft.paddingTop.toStringAsFixed(0),
              onDraftChanged: (value) =>
                  setState(() => _draft = _draft.copyWith(paddingTop: value)),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(paddingTop: value)),
            ),
            _PreferenceSlider(
              key: readerPaddingBottomSliderKey,
              label: '下边距',
              value: _draft.paddingBottom,
              min: ReaderPreferences.minVerticalPadding,
              max: ReaderPreferences.maxVerticalPadding,
              divisions: 12,
              step: ReaderPreferences.paddingStep,
              valueLabel: _draft.paddingBottom.toStringAsFixed(0),
              onDraftChanged: (value) => setState(
                () => _draft = _draft.copyWith(paddingBottom: value),
              ),
              onCommitted: (value) =>
                  _commit(_draft.copyWith(paddingBottom: value)),
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
    required this.step,
    required this.valueLabel,
    required this.onDraftChanged,
    required this.onCommitted,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final double step;
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
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: '$label 减少',
              onPressed: value <= min
                  ? null
                  : () => onCommitted((value - step).clamp(min, max)),
              icon: const Icon(Icons.remove, size: 18),
            ),
            SizedBox(
              width: 42,
              child: Text(
                valueLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: '$label 增加',
              onPressed: value >= max
                  ? null
                  : () => onCommitted((value + step).clamp(min, max)),
              icon: const Icon(Icons.add, size: 18),
            ),
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

Future<void> showReaderSearch(
  BuildContext context, {
  required Future<List<ReaderSearchResult>> Function(String) onQueryChanged,
  required Future<void> Function(ReaderSearchResult) onResultTap,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 720;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxWidth: isDesktop ? 680 : double.infinity),
    builder: (sheetContext) => _ReaderSearchSheet(
      onQueryChanged: onQueryChanged,
      onResultTap: onResultTap,
    ),
  );
}

class _ReaderSearchSheet extends StatefulWidget {
  const _ReaderSearchSheet({
    required this.onQueryChanged,
    required this.onResultTap,
  });

  final Future<List<ReaderSearchResult>> Function(String) onQueryChanged;
  final Future<void> Function(ReaderSearchResult) onResultTap;

  @override
  State<_ReaderSearchSheet> createState() => _ReaderSearchSheetState();
}

class _ReaderSearchSheetState extends State<_ReaderSearchSheet> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  List<ReaderSearchResult> _results = const [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    final generation = ++_generation;
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 220), () async {
      try {
        final results = await widget.onQueryChanged(query);
        if (!mounted || generation != _generation) return;
        setState(() {
          _results = results;
          _searching = false;
        });
      } catch (_) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _results = const [];
          _searching = false;
        });
      }
    });
  }

  void _clear() {
    _queryController.clear();
    _onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                autofocus: true,
                controller: _queryController,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '搜索当前书正文',
                  suffixIcon: _queryController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空搜索',
                          onPressed: _clear,
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_searching) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _queryController.text.isEmpty ? '输入关键词开始搜索' : '无结果',
                      ),
                    )
                  : ListView.separated(
                      key: const Key('reader-search-results'),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return ListTile(
                          key: Key('reader-search-result-$index'),
                          title: Text(
                            '#${index + 1} · ${result.derivedChapterTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: _highlightedSnippet(context, result),
                          onTap: () {
                            Navigator.of(context).pop();
                            Future<void>.microtask(
                              () => widget.onResultTap(result),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightedSnippet(BuildContext context, ReaderSearchResult result) {
    final start = (result.startOffset - result.contextStartOffset).clamp(
      0,
      result.snippet.length,
    );
    final end = (result.endOffset - result.contextStartOffset).clamp(
      start,
      result.snippet.length,
    );
    final style = Theme.of(context).textTheme.bodyMedium;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: result.snippet.substring(0, start)),
          TextSpan(
            text: result.snippet.substring(start, end),
            style: style?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          TextSpan(text: result.snippet.substring(end)),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

@immutable
class ReaderBookmarkViewData {
  const ReaderBookmarkViewData({
    required this.bookmark,
    required this.chapterTitle,
    required this.snippet,
    required this.status,
  });

  final ReaderBookmark bookmark;
  final String chapterTitle;
  final String snippet;
  final ReaderBookmarkStatus status;
}

Future<void> showReaderBookmarks(
  BuildContext context, {
  required String collectionTitle,
  required List<ReaderBookmarkViewData> bookmarks,
  required Future<List<ReaderBookmarkViewData>> Function() onCreate,
  required Future<void> Function(ReaderBookmark) onJump,
  required Future<List<ReaderBookmarkViewData>> Function(ReaderBookmark)
  onDelete,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 720;
  var visibleBookmarks = bookmarks;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxWidth: isDesktop ? 640 : double.infinity),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '书签 · $collectionTitle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(sheetContext).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      key: readerBookmarkCreateKey,
                      onPressed: () async {
                        final latest = await onCreate();
                        setSheetState(() => visibleBookmarks = latest);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: visibleBookmarks.isEmpty
                    ? const Center(child: Text('暂无书签'))
                    : ListView.separated(
                        key: readerBookmarkListKey,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                        itemCount: visibleBookmarks.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = visibleBookmarks[index];
                          final orphan = item.status.isOrphan;
                          return ListTile(
                            key: Key('reader-bookmark-${item.bookmark.id}'),
                            leading: Icon(
                              orphan
                                  ? Icons.bookmark_remove_outlined
                                  : Icons.bookmark,
                              color: orphan
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              orphan
                                  ? '不可定位 · ${item.chapterTitle}'
                                  : item.chapterTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                if (item.snippet.isNotEmpty) item.snippet,
                                if (item.bookmark.note?.isNotEmpty == true)
                                  '备注：${item.bookmark.note}',
                                'Offset ${item.bookmark.absoluteCharacterOffset} · ${_formatBookmarkTime(item.bookmark.createdAt)}',
                                if (orphan)
                                  '不可定位：${_orphanReasonLabel(item.status.reason!)}',
                              ].join('\n'),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            onTap: orphan
                                ? null
                                : () {
                                    Navigator.of(sheetContext).pop();
                                    Future<void>.microtask(
                                      () => onJump(item.bookmark),
                                    );
                                  },
                            trailing: IconButton(
                              tooltip: '删除书签',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final latest = await onDelete(item.bookmark);
                                setSheetState(() => visibleBookmarks = latest);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatBookmarkTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _orphanReasonLabel(ReaderBookmarkOrphanReason reason) =>
    switch (reason) {
      ReaderBookmarkOrphanReason.collectionRemoved => '书籍已移出书架',
      ReaderBookmarkOrphanReason.normalizedHashMismatch => '正文版本已变化',
      ReaderBookmarkOrphanReason.offsetOutOfBounds => '位置超出正文范围',
    };

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
