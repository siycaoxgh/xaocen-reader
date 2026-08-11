import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/reader/reader_bookmark.dart';
import '../domain/reader/auto_read_controller.dart';
import '../domain/reader/auto_read_preferences.dart';
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
const readerAutoReadActionKey = Key('reader-auto-read-action');
const readerAutoReadSheetKey = Key('reader-auto-read-sheet');
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
const readerTextColorControlKey = Key('reader-text-color-control');
const readerBackgroundColorControlKey = Key('reader-background-color-control');
const readerBackgroundImageActionKey = Key('reader-background-image-action');
const readerBackgroundImageOpacityKey = Key('reader-background-image-opacity');
const readerBackgroundOverlayOpacityKey = Key(
  'reader-background-overlay-opacity',
);
const readerResetAppearanceKey = Key('reader-reset-appearance');
const readerSettingsModeControlKey = Key('reader-settings-mode-control');
const readerResetPreferencesKey = Key('reader-reset-preferences');

abstract final class ReaderProgressLabels {
  static const chapter = '本章';
  static const wholeBook = '全书';
  static const wholeDocument = '全文';
  static const pages = '页';
}

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
    this.onAutoRead,
    this.autoReadState = AutoReadState.idle,
    this.autoReadSpeedPixelsPerSecond =
        AutoReadPreferences.defaultVerticalVelocityPixelsPerSecond,
    this.autoReadPagedIntervalSeconds =
        AutoReadPreferences.defaultPagedIntervalSeconds,
    this.currentChapterTitle,
    this.currentChapterNumber,
    this.chapterProgressPercent,
    this.chapterPageNumber,
    this.chapterPageCount,
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
  final VoidCallback? onAutoRead;
  final AutoReadState autoReadState;
  final int autoReadSpeedPixelsPerSecond;
  final int autoReadPagedIntervalSeconds;
  final String? currentChapterTitle;
  final int? currentChapterNumber;
  final double? chapterProgressPercent;
  final int? chapterPageNumber;
  final int? chapterPageCount;
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
                  // Vertical mode shows a second line for chapter and book
                  // progress, so reserve enough room for the extra row while
                  // keeping the paged chrome at its existing height.
                  height: 78,
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
                            if (mode == ReaderMode.vertical &&
                                (currentChapterTitle != null ||
                                    progressPercent != null)) ...[
                              Text(
                                currentChapterNumber == null
                                    ? (currentChapterTitle ??
                                          ReaderProgressLabels.wholeDocument)
                                    : '第$currentChapterNumber章  ${currentChapterTitle ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (chapterProgressPercent != null)
                                    Text(
                                      '${ReaderProgressLabels.chapter} ${(chapterProgressPercent! * 100).round()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  const Spacer(),
                                  if (progressPercent != null)
                                    Text(
                                      '${ReaderProgressLabels.wholeBook} ${(progressPercent! * 100).round()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ] else if (mode == ReaderMode.paged &&
                                (chapterPageNumber != null ||
                                    currentChapterTitle != null ||
                                    progressPercent != null)) ...[
                              Text(
                                currentChapterNumber == null
                                    ? (currentChapterTitle ??
                                          ReaderProgressLabels.wholeDocument)
                                    : '第$currentChapterNumber章  ${currentChapterTitle ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (chapterPageNumber != null &&
                                      chapterPageCount != null)
                                    Text(
                                      '${ReaderProgressLabels.chapter} $chapterPageNumber / $chapterPageCount ${ReaderProgressLabels.pages}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  const Spacer(),
                                  if (progressPercent != null)
                                    Text(
                                      '${ReaderProgressLabels.wholeBook} ${(progressPercent! * 100).round()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ],
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
                        if (isDesktop)
                          _ChromeAction(
                            key: readerSearchActionKey,
                            icon: Icons.search,
                            label: '搜索',
                            onPressed: onSearch,
                          ),
                        if (isDesktop && onAutoRead != null)
                          _ChromeAction(
                            key: readerAutoReadActionKey,
                            icon: autoReadState == AutoReadState.running
                                ? Icons.pause_circle_outline
                                : Icons.auto_stories_outlined,
                            label: autoReadState == AutoReadState.idle
                                ? '\u81ea\u52a8\u9605\u8bfb'
                                : _autoReadStatusLabel(
                                    mode,
                                    autoReadState,
                                    autoReadSpeedPixelsPerSecond,
                                    autoReadPagedIntervalSeconds,
                                  ),
                            selected: autoReadState == AutoReadState.running,
                            onPressed: onAutoRead!,
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

String _autoReadPresetLabel(VerticalSpeedPreset preset) => switch (preset) {
  VerticalSpeedPreset.slow => '\u6162',
  VerticalSpeedPreset.slower => '\u8f83\u6162',
  VerticalSpeedPreset.standard => '\u6807\u51c6',
  VerticalSpeedPreset.faster => '\u8f83\u5feb',
  VerticalSpeedPreset.fast => '\u5feb',
};

String _autoReadSpeedLabel(int velocity) {
  final preset = VerticalSpeedPresetValues.fromVelocity(velocity);
  return preset == null
      ? '\u81ea\u5b9a\u4e49 \u00b7 $velocity px/s'
      : _autoReadPresetLabel(preset);
}

String _autoReadStatusLabel(
  ReaderMode mode,
  AutoReadState state,
  int speedPixelsPerSecond,
  int pagedIntervalSeconds,
) => switch (state) {
  AutoReadState.running =>
    mode == ReaderMode.vertical
        ? '\u81ea\u52a8\u9605\u8bfb\u4e2d \u00b7 ${_autoReadSpeedLabel(speedPixelsPerSecond)}'
        : '\u81ea\u52a8\u9605\u8bfb\u4e2d \u00b7 \u6bcf $pagedIntervalSeconds \u79d2\u7ffb\u9875',
  AutoReadState.paused => '\u81ea\u52a8\u9605\u8bfb\u5df2\u6682\u505c',
  AutoReadState.stoppedAtEnd => '\u5df2\u8bfb\u5230\u672c\u4e66\u672b\u5c3e',
  AutoReadState.idle => '\u81ea\u52a8\u9605\u8bfb',
};

Future<void> showReaderAutoReadControls(
  BuildContext context, {
  required ReaderMode mode,
  required AutoReadState Function() stateOf,
  required int Function() speedOf,
  required Stream<AutoReadEvent> events,
  required VoidCallback onStart,
  required VoidCallback onPause,
  required VoidCallback onResume,
  required VoidCallback onStop,
  required ValueChanged<int> onSpeedChanged,
  ValueGetter<int>? pagedIntervalOf,
  ValueChanged<int>? onPagedIntervalChanged,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 720;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxWidth: isDesktop ? 560 : double.infinity),
    builder: (context) => StreamBuilder<AutoReadEvent>(
      stream: events,
      builder: (context, _) => ReaderAutoReadSheet(
        key: readerAutoReadSheetKey,
        mode: mode,
        state: stateOf(),
        speedPixelsPerSecond: speedOf(),
        pagedIntervalSeconds:
            pagedIntervalOf?.call() ??
            AutoReadPreferences.defaultPagedIntervalSeconds,
        onStart: onStart,
        onPause: onPause,
        onResume: onResume,
        onStop: onStop,
        onSpeedChanged: onSpeedChanged,
        onPagedIntervalChanged: onPagedIntervalChanged,
      ),
    ),
  );
}

class ReaderAutoReadSheet extends StatelessWidget {
  const ReaderAutoReadSheet({
    super.key,
    required this.mode,
    required this.state,
    required this.speedPixelsPerSecond,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onSpeedChanged,
    this.pagedIntervalSeconds = AutoReadPreferences.defaultPagedIntervalSeconds,
    this.onPagedIntervalChanged,
  });

  final ReaderMode mode;
  final AutoReadState state;
  final int speedPixelsPerSecond;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final ValueChanged<int> onSpeedChanged;
  final int pagedIntervalSeconds;
  final ValueChanged<int>? onPagedIntervalChanged;

  String get _status => _autoReadStatusLabel(
    mode,
    state,
    speedPixelsPerSecond,
    pagedIntervalSeconds,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vertical = mode == ReaderMode.vertical;
    final running = state == AutoReadState.running;
    final paused = state == AutoReadState.paused;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\u81ea\u52a8\u9605\u8bfb',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              key: const Key('reader-auto-read-status'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: running ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!running && !paused)
                  FilledButton.icon(
                    key: const Key('reader-auto-read-start'),
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('\u5f00\u59cb'),
                  ),
                if (running)
                  FilledButton.icon(
                    key: const Key('reader-auto-read-pause'),
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('\u6682\u505c'),
                  ),
                if (paused)
                  FilledButton.icon(
                    key: const Key('reader-auto-read-resume'),
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('\u7ee7\u7eed'),
                  ),
                if (running || paused || state == AutoReadState.stoppedAtEnd)
                  OutlinedButton.icon(
                    key: const Key('reader-auto-read-stop'),
                    onPressed: onStop,
                    icon: const Icon(Icons.stop),
                    label: const Text('\u505c\u6b62'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (vertical) ...[
              Text(
                '\u901f\u5ea6',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                key: const Key('reader-auto-read-speed-presets'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in VerticalSpeedPreset.values)
                    ChoiceChip(
                      label: Text(_autoReadPresetLabel(preset)),
                      selected:
                          speedPixelsPerSecond ==
                          preset.velocityPixelsPerSecond,
                      onSelected: (_) =>
                          onSpeedChanged(preset.velocityPixelsPerSecond),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                key: const Key('reader-auto-read-speed-slider'),
                min: AutoReadPreferences.minVerticalVelocityPixelsPerSecond
                    .toDouble(),
                max: AutoReadPreferences.maxVerticalVelocityPixelsPerSecond
                    .toDouble(),
                divisions:
                    AutoReadPreferences.maxVerticalVelocityPixelsPerSecond -
                    AutoReadPreferences.minVerticalVelocityPixelsPerSecond,
                value: speedPixelsPerSecond
                    .toDouble()
                    .clamp(
                      AutoReadPreferences.minVerticalVelocityPixelsPerSecond
                          .toDouble(),
                      AutoReadPreferences.maxVerticalVelocityPixelsPerSecond
                          .toDouble(),
                    )
                    .toDouble(),
                label: _autoReadSpeedLabel(speedPixelsPerSecond),
                onChanged: (value) => onSpeedChanged(value.round()),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  _autoReadSpeedLabel(speedPixelsPerSecond),
                  key: const Key('reader-auto-read-speed-value'),
                ),
              ),
            ] else ...[
              Text(
                '\u7ffb\u9875\u95f4\u9694',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                key: const Key('reader-auto-read-intervals'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final seconds
                      in AutoReadPreferences.supportedPagedIntervals)
                    ChoiceChip(
                      label: Text('\u6bcf $seconds \u79d2'),
                      selected: pagedIntervalSeconds == seconds,
                      onSelected: onPagedIntervalChanged == null
                          ? null
                          : (_) => onPagedIntervalChanged!(seconds),
                    ),
                ],
              ),
            ],
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
  Future<String?> Function()? onPickBackgroundImage,
  Future<void> Function(String? path)? onDeleteBackgroundImage,
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
      onPickBackgroundImage: onPickBackgroundImage,
      onDeleteBackgroundImage: onDeleteBackgroundImage,
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
    this.onPickBackgroundImage,
    this.onDeleteBackgroundImage,
  });

  final ReaderPreferences preferences;
  final ReaderMode mode;
  final ValueChanged<ReaderPreferences> onPreferencesCommitted;
  final ValueChanged<ReaderMode> onModeSelected;
  final VoidCallback onResetPreferences;
  final Future<String?> Function()? onPickBackgroundImage;
  final Future<void> Function(String? path)? onDeleteBackgroundImage;

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
            Text('阅读外观', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            _ReaderColorPalette(
              key: readerTextColorControlKey,
              label: '字体颜色',
              selectedArgb: _draft.textColorArgb,
              colors: const [
                Color(0xff1c1b1f),
                Color(0xff4b3425),
                Color(0xfff5f2ea),
                Color(0xffffffff),
              ],
              onChanged: (value) =>
                  _commit(_draft.copyWith(textColorArgb: value)),
            ),
            const SizedBox(height: 12),
            _ReaderColorPalette(
              key: readerBackgroundColorControlKey,
              label: '阅读背景颜色',
              selectedArgb: _draft.backgroundColorArgb,
              colors: const [
                Color(0xffffffff),
                Color(0xfffff8e7),
                Color(0xffe8f0e8),
                Color(0xff202124),
                Color(0xff000000),
              ],
              onChanged: (value) =>
                  _commit(_draft.copyWith(backgroundColorArgb: value)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _draft.backgroundImagePath == null
                        ? '本地图片背景：未使用'
                        : '本地图片背景：已导入',
                  ),
                ),
                OutlinedButton.icon(
                  key: readerBackgroundImageActionKey,
                  onPressed: widget.onPickBackgroundImage == null
                      ? null
                      : () async {
                          final previous = _draft.backgroundImagePath;
                          final path = await widget.onPickBackgroundImage!();
                          if (!mounted || path == null) return;
                          _commit(_draft.copyWith(backgroundImagePath: path));
                          if (previous != null && previous != path) {
                            await widget.onDeleteBackgroundImage?.call(
                              previous,
                            );
                          }
                        },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _draft.backgroundImagePath == null ? '导入图片' : '更换图片',
                  ),
                ),
                if (_draft.backgroundImagePath != null)
                  IconButton(
                    tooltip: '移除图片背景',
                    onPressed: () async {
                      final previous = _draft.backgroundImagePath;
                      _commit(_draft.copyWith(backgroundImagePath: null));
                      await widget.onDeleteBackgroundImage?.call(previous);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            if (_draft.backgroundImagePath != null) ...[
              _PreferenceSlider(
                key: readerBackgroundImageOpacityKey,
                label: '图片透明度',
                value: _draft.backgroundImageOpacity,
                min: ReaderPreferences.minAppearanceOpacity,
                max: ReaderPreferences.maxAppearanceOpacity,
                divisions: 20,
                step: 0.05,
                valueLabel: '${(_draft.backgroundImageOpacity * 100).round()}%',
                onDraftChanged: (value) => setState(
                  () => _draft = _draft.copyWith(backgroundImageOpacity: value),
                ),
                onCommitted: (value) =>
                    _commit(_draft.copyWith(backgroundImageOpacity: value)),
              ),
              _PreferenceSlider(
                key: readerBackgroundOverlayOpacityKey,
                label: '图片遮罩强度',
                value: _draft.backgroundOverlayOpacity,
                min: ReaderPreferences.minAppearanceOpacity,
                max: ReaderPreferences.maxAppearanceOpacity,
                divisions: 20,
                step: 0.05,
                valueLabel:
                    '${(_draft.backgroundOverlayOpacity * 100).round()}%',
                onDraftChanged: (value) => setState(
                  () =>
                      _draft = _draft.copyWith(backgroundOverlayOpacity: value),
                ),
                onCommitted: (value) =>
                    _commit(_draft.copyWith(backgroundOverlayOpacity: value)),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: readerResetAppearanceKey,
              onPressed: () async {
                final previous = _draft.backgroundImagePath;
                _commit(
                  _draft.copyWith(
                    textColorArgb: null,
                    backgroundColorArgb: null,
                    backgroundImagePath: null,
                    backgroundImageOpacity:
                        ReaderPreferences.defaultBackgroundImageOpacity,
                    backgroundOverlayOpacity:
                        ReaderPreferences.defaultBackgroundOverlayOpacity,
                  ),
                );
                await widget.onDeleteBackgroundImage?.call(previous);
              },
              icon: const Icon(Icons.format_color_reset_rounded),
              label: const Text('恢复默认外观（跟随主题）'),
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

class _ReaderColorPalette extends StatelessWidget {
  const _ReaderColorPalette({
    super.key,
    required this.label,
    required this.selectedArgb,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final int? selectedArgb;
  final List<Color> colors;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('跟随主题'),
              selected: selectedArgb == null,
              onSelected: (_) => onChanged(null),
            ),
            for (final color in colors)
              Semantics(
                button: true,
                selected: selectedArgb == color.toARGB32(),
                label: '$label #${color.toARGB32().toRadixString(16)}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onChanged(color.toARGB32()),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: selectedArgb == color.toARGB32()
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: selectedArgb == color.toARGB32() ? 3 : 1,
                      ),
                    ),
                    child: selectedArgb == color.toARGB32()
                        ? Icon(
                            Icons.check_rounded,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
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

Future<void> showReaderMorePreview(
  BuildContext context, {
  VoidCallback? onSearch,
  VoidCallback? onAutoRead,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.more_horiz_rounded),
                title: Text('更多阅读操作'),
                subtitle: Text('低频操作集中在这里，避免底部控制区过密。'),
              ),
              if (onSearch != null)
                ListTile(
                  key: readerSearchActionKey,
                  leading: const Icon(Icons.search),
                  title: const Text('搜索本书'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSearch();
                  },
                ),
              if (onAutoRead != null)
                ListTile(
                  key: readerAutoReadActionKey,
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: const Text('自动阅读'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onAutoRead();
                  },
                ),
              const ListTile(
                leading: Icon(Icons.record_voice_over_outlined),
                title: Text('朗读'),
                subtitle: Text('朗读当前未实现'),
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
