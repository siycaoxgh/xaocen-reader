import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../design/theme/app_typography.dart';
import '../design/theme/app_theme.dart';
import '../domain/reader/reader_bookmark.dart';
import '../domain/reader/auto_read_controller.dart';
import '../domain/reader/auto_read_preferences.dart';
import '../domain/reader/reader_palette.dart';
import '../domain/reader/reader_preferences.dart';
import 'android_reader_window.dart';
import '../domain/reader/reader_font.dart';
import '../data/repositories/reader_system_font_repository.dart';
import '../domain/reader/reader_search.dart';
import 'reader_appearance.dart';
import 'reader_mode.dart';

const readerChromeToggleKey = Key('reader-chrome-toggle');
const readerTopChromeKey = Key('reader-top-chrome');
const readerBottomChromeKey = Key('reader-bottom-chrome');
const readerTopInfoRegionKey = Key('reader-top-info-region');
const readerBottomInfoRegionKey = Key('reader-bottom-info-region');

/// Height reserved by one minimal Reader information region, excluding the
/// device/system inset. The row itself is deliberately fixed and compact;
/// SafeArea supplies the variable cutout/navigation inset.
const double readerInfoRegionExtent = 38;

double readerInfoRegionInset(BuildContext context, {required bool top}) =>
    readerInfoRegionExtent +
    (top
        ? AndroidReaderWindow.safeInsets(
            View.of(context),
            extendIntoDisplayCutout: false,
            hideNavigationBar: false,
          ).top
        : AndroidReaderWindow.safeInsets(
            View.of(context),
            extendIntoDisplayCutout: false,
            hideNavigationBar: false,
          ).bottom);
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
const readerPaletteControlKey = Key('reader-palette-control');
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
const readerShowTopInfoKey = Key('reader-show-top-info');
const readerShowBottomInfoKey = Key('reader-show-bottom-info');
const readerShowProgressInfoKey = Key('reader-show-progress-info');
const readerShowBatteryInfoKey = Key('reader-show-battery-info');
const readerShowAutoReadMinimalInfoKey = Key(
  'reader-show-auto-read-minimal-info',
);
const readerStatusBarModeKey = Key('reader-status-bar-mode');
const readerHideNavigationBarKey = Key('reader-hide-navigation-bar');
const readerExtendIntoDisplayCutoutKey = Key(
  'reader-extend-into-display-cutout',
);
const readerScreenOrientationKey = Key('reader-screen-orientation');
const readerTimeDisplayModeKey = Key('reader-time-display-mode');
const readerTopInfoDividerKey = Key('reader-top-info-divider');
const readerBottomInfoDividerKey = Key('reader-bottom-info-divider');

const _aaSectionGap = 12.0;
const _aaControlRadius = 12.0;
const _aaControlHeight = 40.0;

abstract final class ReaderProgressLabels {
  // Keep labels in source-safe Unicode escapes so Windows/editor encoding
  // cannot turn the Reader progress chrome into mojibake.
  static const chapter = '\u672c\u7ae0';
  static const wholeBook = '\u5168\u4e66';
  static const wholeDocument = '\u5168\u6587';
  static const pages = '\u9875';
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
    this.onPauseAutoRead,
    this.onResumeAutoRead,
    this.onStopAutoRead,
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
    this.showTopInfoBar = true,
    this.showBottomInfoBar = true,
    this.showProgressInfo = true,
    this.showChapterInfo = true,
    this.showChapterProgressInfo = true,
    this.showClockInfo = true,
    this.showBatteryInfo = true,
    this.showWholeBookProgressInfo = true,
    this.showInfoDivider = false,
    this.showTopInfoDivider,
    this.showBottomInfoDivider,
    this.showInfoContent = true,
    this.showAutoReadMinimalInfo = true,
    this.showMinimalInfoOverlay = true,
    this.chapterInfoSlot = ReaderInfoSlot.topLeft,
    this.chapterProgressInfoSlot = ReaderInfoSlot.topRight,
    this.clockInfoSlot = ReaderInfoSlot.bottomLeft,
    this.batteryInfoSlot = ReaderInfoSlot.bottomCenter,
    this.wholeBookProgressInfoSlot = ReaderInfoSlot.bottomRight,
    this.infoDividerSlot = ReaderInfoSlot.topCenter,
    this.statusBarMode = ReaderStatusBarMode.system,
    this.timeDisplayMode = ReaderTimeDisplayMode.twentyFourHour,
    this.readerTextColor,
    this.readerBackgroundColor,
    this.batteryStatus,
    this.extendIntoDisplayCutout = false,
    this.hideNavigationBar = false,
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
  final VoidCallback? onPauseAutoRead;
  final VoidCallback? onResumeAutoRead;
  final VoidCallback? onStopAutoRead;
  final AutoReadState autoReadState;
  final int autoReadSpeedPixelsPerSecond;
  final int autoReadPagedIntervalSeconds;
  final String? currentChapterTitle;
  final int? currentChapterNumber;
  final double? chapterProgressPercent;
  final int? chapterPageNumber;
  final int? chapterPageCount;
  final double? progressPercent;
  final bool showTopInfoBar;
  final bool showBottomInfoBar;
  final bool showProgressInfo;
  final bool showChapterInfo;
  final bool showChapterProgressInfo;
  final bool showClockInfo;
  final bool showBatteryInfo;
  final bool showWholeBookProgressInfo;
  final bool showInfoDivider;
  final bool? showTopInfoDivider;
  final bool? showBottomInfoDivider;

  /// Keeps the top/bottom regions in the layout while Reader chrome is open.
  /// Chrome visibility must never resize the reading body or trigger a
  /// relayout/repagination jump.
  final bool showInfoContent;
  final bool showAutoReadMinimalInfo;

  /// Kept for compatibility with the standalone chrome widget tests. The
  /// production Reader renders info in [ReaderInfoScaffold], which reserves
  /// real layout space instead of overlaying the body.
  final bool showMinimalInfoOverlay;
  final ReaderInfoSlot chapterInfoSlot;
  final ReaderInfoSlot chapterProgressInfoSlot;
  final ReaderInfoSlot clockInfoSlot;
  final ReaderInfoSlot batteryInfoSlot;
  final ReaderInfoSlot wholeBookProgressInfoSlot;
  final ReaderInfoSlot infoDividerSlot;
  final ReaderStatusBarMode statusBarMode;
  final ReaderTimeDisplayMode timeDisplayMode;
  final Color? readerTextColor;
  final Color? readerBackgroundColor;
  final BatteryStatus? batteryStatus;
  final bool extendIntoDisplayCutout;
  final bool hideNavigationBar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;
    final chrome = IgnorePointer(
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
                    // Operation chrome uses the same surface as the bottom
                    // operation chrome.  Reader background belongs to the
                    // body/minimal-info layer and must not leak into the
                    // chrome palette.
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: (readerTextColor ?? colorScheme.onSurface)
                            .withValues(alpha: .28),
                      ),
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
                            if (visible &&
                                mode == ReaderMode.vertical &&
                                (currentChapterTitle != null ||
                                    progressPercent != null)) ...[
                              Text(
                                currentChapterNumber == null
                                    ? (currentChapterTitle ??
                                          ReaderProgressLabels.wholeDocument)
                                    : '\u7b2c $currentChapterNumber \u7ae0  ${currentChapterTitle ?? ''}',
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
                            ] else if (visible &&
                                mode == ReaderMode.paged &&
                                (chapterPageNumber != null ||
                                    currentChapterTitle != null ||
                                    progressPercent != null)) ...[
                              Text(
                                currentChapterNumber == null
                                    ? (currentChapterTitle ??
                                          ReaderProgressLabels.wholeDocument)
                                    : '\u7b2c $currentChapterNumber \u7ae0  ${currentChapterTitle ?? ''}',
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
                      Semantics(
                        button: false,
                        label: '当前阅读方式：${_readerModeLabel(mode)}',
                        child: Tooltip(
                          message: '当前阅读方式：${_readerModeLabel(mode)}',
                          child: Padding(
                            key: readerModeActionKey,
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              mode == ReaderMode.paged
                                  ? Icons.menu_book_rounded
                                  : Icons.view_stream_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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
                    color: colorScheme.surface,
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
                        if (onAutoRead != null)
                          _ChromeAction(
                            key: readerAutoReadActionKey,
                            icon: autoReadState == AutoReadState.running
                                ? Icons.pause_circle_outline
                                : Icons.auto_stories_outlined,
                            label: '自动阅读',
                            selected: autoReadState == AutoReadState.running,
                            onPressed: onAutoRead!,
                          ),
                        _ChromeAction(
                          key: readerBookmarksActionKey,
                          icon: Icons.bookmark_outline,
                          label: '书签',
                          onPressed: onBookmarks,
                        ),
                        _ChromeAction(
                          key: readerAppearanceActionKey,
                          icon: Icons.text_fields_rounded,
                          label: 'Aa',
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
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showMinimalInfoOverlay &&
            !visible &&
            (autoReadState != AutoReadState.running ||
                showAutoReadMinimalInfo) &&
            (showTopInfoBar || showBottomInfoBar))
          ReaderMinimalInfoLayer(
            mode: mode,
            currentChapterTitle: currentChapterTitle,
            currentChapterNumber: currentChapterNumber,
            chapterProgressPercent: chapterProgressPercent,
            chapterPageNumber: chapterPageNumber,
            chapterPageCount: chapterPageCount,
            progressPercent: progressPercent,
            showTopInfoBar: showTopInfoBar,
            showBottomInfoBar: showBottomInfoBar,
            showProgressInfo: showProgressInfo,
            showChapterInfo: showChapterInfo,
            showChapterProgressInfo: showChapterProgressInfo,
            showClockInfo: showClockInfo,
            showBatteryInfo: showBatteryInfo,
            showWholeBookProgressInfo: showWholeBookProgressInfo,
            showInfoDivider: showInfoDivider,
            showTopInfoDivider: showTopInfoDivider,
            showBottomInfoDivider: showBottomInfoDivider,
            chapterInfoSlot: chapterInfoSlot,
            chapterProgressInfoSlot: chapterProgressInfoSlot,
            clockInfoSlot: clockInfoSlot,
            batteryInfoSlot: batteryInfoSlot,
            wholeBookProgressInfoSlot: wholeBookProgressInfoSlot,
            infoDividerSlot: infoDividerSlot,
            statusBarMode: statusBarMode,
            timeDisplayMode: timeDisplayMode,
            readerTextColor: readerTextColor,
            readerBackgroundColor: readerBackgroundColor,
            batteryStatus: batteryStatus,
          ),
        chrome,
        if (visible && autoReadState != AutoReadState.idle)
          ReaderAutoReadStatusBar(
            mode: mode,
            state: autoReadState,
            speedPixelsPerSecond: autoReadSpeedPixelsPerSecond,
            pagedIntervalSeconds: autoReadPagedIntervalSeconds,
            onPause: onAutoRead == null ? null : onPauseAutoRead,
            onResume: onAutoRead == null ? null : onResumeAutoRead,
            onStop: onAutoRead == null ? null : onStopAutoRead,
          ),
      ],
    );
  }
}

/// A real top/body/bottom layout for hidden Reader chrome.
///
/// The information regions are siblings of the body, so pagination and the
/// vertical viewport receive the remaining height.  The standalone
/// [ReaderMinimalInfoLayer] remains available for legacy previews/tests, but
/// ReaderPage uses this scaffold in production.
class ReaderInfoScaffold extends StatelessWidget {
  const ReaderInfoScaffold({
    super.key,
    required this.body,
    required this.mode,
    required this.currentChapterTitle,
    required this.currentChapterNumber,
    required this.chapterProgressPercent,
    required this.chapterPageNumber,
    required this.chapterPageCount,
    required this.progressPercent,
    required this.showTopInfoBar,
    required this.showBottomInfoBar,
    required this.showProgressInfo,
    required this.showChapterInfo,
    required this.showChapterProgressInfo,
    required this.showClockInfo,
    this.showBatteryInfo = true,
    required this.showWholeBookProgressInfo,
    this.showInfoDivider = false,
    this.showTopInfoDivider,
    this.showBottomInfoDivider,
    this.showInfoContent = true,
    required this.chapterInfoSlot,
    required this.chapterProgressInfoSlot,
    required this.clockInfoSlot,
    this.batteryInfoSlot = ReaderInfoSlot.bottomCenter,
    required this.wholeBookProgressInfoSlot,
    required this.infoDividerSlot,
    required this.statusBarMode,
    required this.timeDisplayMode,
    this.readerTextColor,
    this.readerBackgroundColor,
    this.batteryStatus,
    this.extendIntoDisplayCutout = false,
    this.hideNavigationBar = false,
  });

  final Widget body;
  final ReaderMode mode;
  final String? currentChapterTitle;
  final int? currentChapterNumber;
  final double? chapterProgressPercent;
  final int? chapterPageNumber;
  final int? chapterPageCount;
  final double? progressPercent;
  final bool showTopInfoBar;
  final bool showBottomInfoBar;
  final bool showProgressInfo;
  final bool showChapterInfo;
  final bool showChapterProgressInfo;
  final bool showClockInfo;
  final bool showBatteryInfo;
  final bool showWholeBookProgressInfo;
  final bool showInfoDivider;
  final bool? showTopInfoDivider;
  final bool? showBottomInfoDivider;

  /// Keep region geometry stable while full Reader chrome is visible.
  final bool showInfoContent;
  final ReaderInfoSlot chapterInfoSlot;
  final ReaderInfoSlot chapterProgressInfoSlot;
  final ReaderInfoSlot clockInfoSlot;
  final ReaderInfoSlot batteryInfoSlot;
  final ReaderInfoSlot wholeBookProgressInfoSlot;
  final ReaderInfoSlot infoDividerSlot;
  final ReaderStatusBarMode statusBarMode;
  final ReaderTimeDisplayMode timeDisplayMode;
  final Color? readerTextColor;
  final Color? readerBackgroundColor;
  final BatteryStatus? batteryStatus;
  final bool extendIntoDisplayCutout;
  final bool hideNavigationBar;

  Widget _region(BuildContext context, {required bool top}) {
    final safe = AndroidReaderWindow.safeInsets(
      View.of(context),
      extendIntoDisplayCutout: extendIntoDisplayCutout,
      hideNavigationBar: hideNavigationBar,
    );
    final systemInset = top ? safe.top : safe.bottom;
    return SizedBox(
      key: top ? readerTopInfoRegionKey : readerBottomInfoRegionKey,
      width: double.infinity,
      height: readerInfoRegionExtent + systemInset,
      child: Padding(
        padding: EdgeInsets.only(
          top: top ? systemInset : 0,
          bottom: top ? 0 : systemInset,
        ),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: showInfoContent
              ? ReaderMinimalInfoLayer(
                  mode: mode,
                  currentChapterTitle: currentChapterTitle,
                  currentChapterNumber: currentChapterNumber,
                  chapterProgressPercent: chapterProgressPercent,
                  chapterPageNumber: chapterPageNumber,
                  chapterPageCount: chapterPageCount,
                  progressPercent: progressPercent,
                  showTopInfoBar: top,
                  showBottomInfoBar: !top,
                  showProgressInfo: showProgressInfo,
                  showChapterInfo: showChapterInfo,
                  showChapterProgressInfo: showChapterProgressInfo,
                  showClockInfo: showClockInfo,
                  showBatteryInfo: showBatteryInfo,
                  showWholeBookProgressInfo: showWholeBookProgressInfo,
                  showInfoDivider: false,
                  chapterInfoSlot: chapterInfoSlot,
                  chapterProgressInfoSlot: chapterProgressInfoSlot,
                  clockInfoSlot: clockInfoSlot,
                  batteryInfoSlot: batteryInfoSlot,
                  wholeBookProgressInfoSlot: wholeBookProgressInfoSlot,
                  infoDividerSlot: infoDividerSlot,
                  statusBarMode: statusBarMode,
                  timeDisplayMode: timeDisplayMode,
                  readerTextColor: readerTextColor,
                  readerBackgroundColor: readerBackgroundColor,
                  batteryStatus: batteryStatus,
                  useRegionKeys: false,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _divider(BuildContext context, {required bool top}) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final scheme = Theme.of(context).colorScheme;
    final background = readerBackgroundColor ?? scheme.surface;
    // Dividers are paint-only, but must remain visible on custom palettes.
    // Blend the text/on-surface color over the actual reader background and
    // strengthen it when the two luminances are too close to distinguish.
    final contrastSource = background.computeLuminance() > .5
        ? const Color(0xff303030)
        : const Color(0xffe7e7e7);
    var color = Color.alphaBlend(
      contrastSource.withValues(alpha: .42),
      background,
    );
    if ((color.computeLuminance() - background.computeLuminance()).abs() <
        .12) {
      color = contrastSource;
    }
    final dividerExtent = math.max(1.0, 1.0 / devicePixelRatio);
    return SizedBox(
      height: dividerExtent,
      child: ColoredBox(
        key: top ? readerTopInfoDividerKey : readerBottomInfoDividerKey,
        color:
            (showInfoContent &&
                (top
                    ? (showTopInfoDivider ?? showInfoDivider)
                    : (showBottomInfoDivider ?? showInfoDivider)))
            ? color
            : Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reserveTop = showTopInfoBar;
    final reserveBottom = showBottomInfoBar;
    final safe = AndroidReaderWindow.safeInsets(
      View.of(context),
      extendIntoDisplayCutout: extendIntoDisplayCutout,
      hideNavigationBar: hideNavigationBar,
    );
    final content = Column(
      children: [
        if (reserveTop) _region(context, top: true),
        if (reserveTop) _divider(context, top: true),
        Expanded(
          child: SizedBox(width: double.infinity, child: body),
        ),
        if (reserveBottom) _divider(context, top: false),
        if (reserveBottom) _region(context, top: false),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(
        left: safe.left,
        right: safe.right,
        top: reserveTop ? 0 : safe.top,
        bottom: reserveBottom ? 0 : safe.bottom,
      ),
      child: content,
    );
  }
}

/// Minimal, non-interactive information layer shown only while Reader chrome
/// is hidden.  It uses view insets rather than fixed status-bar dimensions so
/// cutouts, rounded corners and gesture navigation remain safe on Android.
class ReaderMinimalInfoLayer extends StatefulWidget {
  const ReaderMinimalInfoLayer({
    super.key,
    required this.mode,
    required this.currentChapterTitle,
    required this.currentChapterNumber,
    required this.chapterProgressPercent,
    required this.chapterPageNumber,
    required this.chapterPageCount,
    required this.progressPercent,
    required this.showTopInfoBar,
    required this.showBottomInfoBar,
    required this.showProgressInfo,
    this.showChapterInfo = true,
    this.showChapterProgressInfo = true,
    this.showClockInfo = true,
    this.showBatteryInfo = true,
    this.showWholeBookProgressInfo = true,
    this.showInfoDivider = false,
    this.showTopInfoDivider,
    this.showBottomInfoDivider,
    this.chapterInfoSlot = ReaderInfoSlot.topLeft,
    this.chapterProgressInfoSlot = ReaderInfoSlot.topRight,
    this.clockInfoSlot = ReaderInfoSlot.bottomLeft,
    this.batteryInfoSlot = ReaderInfoSlot.bottomCenter,
    this.wholeBookProgressInfoSlot = ReaderInfoSlot.bottomRight,
    this.infoDividerSlot = ReaderInfoSlot.topCenter,
    required this.statusBarMode,
    required this.timeDisplayMode,
    this.readerTextColor,
    this.readerBackgroundColor,
    this.batteryStatus,
    this.useRegionKeys = true,
  });

  final ReaderMode mode;
  final String? currentChapterTitle;
  final int? currentChapterNumber;
  final double? chapterProgressPercent;
  final int? chapterPageNumber;
  final int? chapterPageCount;
  final double? progressPercent;
  final bool showTopInfoBar;
  final bool showBottomInfoBar;
  final bool showProgressInfo;
  final bool showChapterInfo;
  final bool showChapterProgressInfo;
  final bool showClockInfo;
  final bool showBatteryInfo;
  final bool showWholeBookProgressInfo;
  final bool showInfoDivider;
  final bool? showTopInfoDivider;
  final bool? showBottomInfoDivider;
  final ReaderInfoSlot chapterInfoSlot;
  final ReaderInfoSlot chapterProgressInfoSlot;
  final ReaderInfoSlot clockInfoSlot;
  final ReaderInfoSlot batteryInfoSlot;
  final ReaderInfoSlot wholeBookProgressInfoSlot;
  final ReaderInfoSlot infoDividerSlot;
  final ReaderStatusBarMode statusBarMode;
  final ReaderTimeDisplayMode timeDisplayMode;
  final Color? readerTextColor;
  final Color? readerBackgroundColor;
  final BatteryStatus? batteryStatus;
  final bool useRegionKeys;

  @override
  State<ReaderMinimalInfoLayer> createState() => _ReaderMinimalInfoLayerState();
}

class _ReaderMinimalInfoLayerState extends State<ReaderMinimalInfoLayer> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = widget.readerTextColor ?? scheme.onSurface;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: textColor,
      shadows: [
        Shadow(
          color: widget.readerBackgroundColor ?? scheme.surface,
          blurRadius: 4,
        ),
      ],
    );

    // Keep the information layer in the same top/body/bottom geometry as the
    // Reader body. It is intentionally not a card or an overlay column at the
    // top of the screen: ReaderPage reserves these two regions before laying
    // out the scroll/page viewport.
    return IgnorePointer(
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.showTopInfoBar)
              Align(
                key: widget.useRegionKeys ? readerTopInfoRegionKey : null,
                alignment: Alignment.topCenter,
                child: _buildRow(context, top: true, style: style),
              ),
            if (widget.showBottomInfoBar)
              Align(
                key: widget.useRegionKeys ? readerBottomInfoRegionKey : null,
                alignment: Alignment.bottomCenter,
                child: _buildRow(context, top: false, style: style),
              ),
            if ((widget.showTopInfoDivider ?? widget.showInfoDivider) &&
                widget.showTopInfoBar)
              Positioned(
                top: readerInfoRegionExtent,
                left: 0,
                right: 0,
                child: Container(
                  height: math.max(
                    1.0,
                    1.0 / MediaQuery.devicePixelRatioOf(context),
                  ),
                  color: style?.color?.withValues(alpha: .45),
                ),
              ),
            if ((widget.showBottomInfoDivider ?? widget.showInfoDivider) &&
                widget.showBottomInfoBar)
              Positioned(
                bottom: readerInfoRegionExtent,
                left: 0,
                right: 0,
                child: Container(
                  height: math.max(
                    1.0,
                    1.0 / MediaQuery.devicePixelRatioOf(context),
                  ),
                  color: style?.color?.withValues(alpha: .45),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required bool top,
    required TextStyle? style,
  }) {
    final slots = [
      top ? ReaderInfoSlot.topLeft : ReaderInfoSlot.bottomLeft,
      top ? ReaderInfoSlot.topCenter : ReaderInfoSlot.bottomCenter,
      top ? ReaderInfoSlot.topRight : ReaderInfoSlot.bottomRight,
    ];
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final slot in slots) Expanded(child: _slotContent(slot, style)),
        ],
      ),
    );
  }

  Widget _slotContent(ReaderInfoSlot slot, TextStyle? style) {
    final children = <Widget>[];
    if (widget.showChapterInfo && widget.chapterInfoSlot == slot) {
      children.add(
        Text(
          _chapterTitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: _textAlign(slot),
          style: style,
        ),
      );
    }
    if (widget.showChapterProgressInfo &&
        widget.chapterProgressInfoSlot == slot) {
      final label = _chapterProgressLabel();
      if (label.isNotEmpty) {
        children.add(Text(label, textAlign: _textAlign(slot), style: style));
      }
    }
    if (widget.showClockInfo &&
        widget.clockInfoSlot == slot &&
        widget.timeDisplayMode != ReaderTimeDisplayMode.hidden) {
      children.add(
        Text(
          _formatClock(_now, widget.timeDisplayMode),
          textAlign: _textAlign(slot),
          style: style,
        ),
      );
    }
    if (widget.showBatteryInfo &&
        widget.batteryStatus != null &&
        widget.batteryInfoSlot == slot) {
      final battery = widget.batteryStatus!;
      children.add(
        Text(
          '${battery.percent}%${battery.charging ? ' ⚡' : ''}',
          textAlign: _textAlign(slot),
          style: style,
        ),
      );
    }
    if (widget.showWholeBookProgressInfo &&
        widget.wholeBookProgressInfoSlot == slot) {
      children.add(
        Text(
          _wholeBookProgressLabel(),
          textAlign: _textAlign(slot),
          style: style,
        ),
      );
    }
    if (children.isEmpty) return const SizedBox(height: 22);
    return Align(
      alignment: _alignment(slot),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: _crossAxisAlignment(slot),
        children: children,
      ),
    );
  }

  TextAlign _textAlign(ReaderInfoSlot slot) => switch (slot) {
    ReaderInfoSlot.topLeft || ReaderInfoSlot.bottomLeft => TextAlign.left,
    ReaderInfoSlot.topCenter || ReaderInfoSlot.bottomCenter => TextAlign.center,
    ReaderInfoSlot.topRight || ReaderInfoSlot.bottomRight => TextAlign.right,
  };

  Alignment _alignment(ReaderInfoSlot slot) => switch (slot) {
    ReaderInfoSlot.topLeft || ReaderInfoSlot.bottomLeft => Alignment.centerLeft,
    ReaderInfoSlot.topCenter || ReaderInfoSlot.bottomCenter => Alignment.center,
    ReaderInfoSlot.topRight ||
    ReaderInfoSlot.bottomRight => Alignment.centerRight,
  };

  CrossAxisAlignment _crossAxisAlignment(ReaderInfoSlot slot) => switch (slot) {
    ReaderInfoSlot.topLeft ||
    ReaderInfoSlot.bottomLeft => CrossAxisAlignment.start,
    ReaderInfoSlot.topCenter ||
    ReaderInfoSlot.bottomCenter => CrossAxisAlignment.center,
    ReaderInfoSlot.topRight ||
    ReaderInfoSlot.bottomRight => CrossAxisAlignment.end,
  };

  String _chapterTitle() {
    final title = widget.currentChapterTitle;
    if (title == null || title == ReaderProgressLabels.wholeDocument) {
      return ReaderProgressLabels.wholeDocument;
    }
    final number = widget.currentChapterNumber;
    return number == null ? title : '第 $number 章  $title';
  }

  String _chapterProgressLabel() {
    final title = widget.currentChapterTitle;
    if (title == null || title == ReaderProgressLabels.wholeDocument) {
      return '';
    }
    if (widget.mode == ReaderMode.paged) {
      final page = widget.chapterPageNumber;
      final count = widget.chapterPageCount;
      if (page != null && count != null) {
        return '${ReaderProgressLabels.chapter} $page / $count ${ReaderProgressLabels.pages}';
      }
      return ReaderProgressLabels.chapter;
    }
    final percent = widget.chapterProgressPercent;
    if (percent == null) {
      return '';
    }
    return '${ReaderProgressLabels.chapter} ${(percent * 100).round()}%';
  }

  String _wholeBookProgressLabel() {
    final percent = widget.progressPercent;
    if (percent == null) return ReaderProgressLabels.wholeBook;
    return '${ReaderProgressLabels.wholeBook} ${(percent * 100).round()}%';
  }
}

String _formatClock(DateTime value, ReaderTimeDisplayMode mode) {
  final minute = value.minute.toString().padLeft(2, '0');
  return switch (mode) {
    ReaderTimeDisplayMode.twentyFourHour =>
      '${value.hour.toString().padLeft(2, '0')}:$minute',
    ReaderTimeDisplayMode.twelveHour =>
      '${((value.hour % 12) == 0 ? 12 : value.hour % 12).toString().padLeft(2, '0')}:$minute ${value.hour >= 12 ? 'PM' : 'AM'}',
    ReaderTimeDisplayMode.hidden => '',
  };
}

String _readerModeLabel(ReaderMode mode) =>
    mode == ReaderMode.paged ? '分页' : '滚动';

/// A small, non-modal control strip for the active AutoRead session.
///
/// It deliberately lives outside the hideable Reader chrome so that a user
/// can pause or stop automatic movement without reopening a panel.
class ReaderAutoReadStatusBar extends StatelessWidget {
  const ReaderAutoReadStatusBar({
    super.key,
    required this.mode,
    required this.state,
    required this.speedPixelsPerSecond,
    required this.pagedIntervalSeconds,
    this.onPause,
    this.onResume,
    this.onStop,
  });

  final ReaderMode mode;
  final AutoReadState state;
  final int speedPixelsPerSecond;
  final int pagedIntervalSeconds;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;
    final colorScheme = Theme.of(context).colorScheme;
    final running = state == AutoReadState.running;
    final paused = state == AutoReadState.paused;
    final label = _autoReadStatusBarLabel(
      mode,
      state,
      speedPixelsPerSecond,
      pagedIntervalSeconds,
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 74),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 520 : double.infinity,
          ),
          child: Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
            elevation: 3,
            borderRadius: BorderRadius.circular(isDesktop ? 14 : 12),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
              child: Row(
                children: [
                  Icon(
                    running
                        ? Icons.play_circle_outline
                        : Icons.pause_circle_outline,
                    size: 19,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  if (running && onPause != null)
                    TextButton(
                      key: const Key('reader-auto-read-status-pause'),
                      onPressed: onPause,
                      child: const Text('暂停'),
                    ),
                  if (paused && onResume != null)
                    TextButton(
                      key: const Key('reader-auto-read-status-resume'),
                      onPressed: onResume,
                      child: const Text('继续'),
                    ),
                  if ((running || paused) && onStop != null)
                    TextButton(
                      key: const Key('reader-auto-read-status-stop'),
                      onPressed: onStop,
                      child: const Text('停止'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _autoReadPresetLabel(VerticalSpeedPreset preset) => switch (preset) {
  VerticalSpeedPreset.slow => '\u6781\u6162',
  VerticalSpeedPreset.slower => '\u6162',
  VerticalSpeedPreset.standard => '\u4e2d',
  VerticalSpeedPreset.faster => '\u5feb',
  VerticalSpeedPreset.fast => '\u6781\u5feb',
};

String _autoReadSpeedLabel(int velocity) {
  return '$velocity px/s';
}

String _autoReadStatusLabel(
  ReaderMode mode,
  AutoReadState state,
  int speedPixelsPerSecond,
  int pagedIntervalSeconds,
) => switch (state) {
  AutoReadState.running =>
    mode == ReaderMode.vertical
        ? '\u81ea\u52a8\u9605\u8bfb\u4e2d \u00b7 $speedPixelsPerSecond px/s'
        : '\u81ea\u52a8\u7ffb\u9875\u4e2d \u00b7 $pagedIntervalSeconds \u79d2/\u9875',
  AutoReadState.paused => '\u81ea\u52a8\u9605\u8bfb\u5df2\u6682\u505c',
  AutoReadState.stoppedAtEnd => '\u5df2\u8bfb\u5230\u672c\u4e66\u672b\u5c3e',
  AutoReadState.idle => '\u81ea\u52a8\u9605\u8bfb',
};

String _autoReadStatusBarLabel(
  ReaderMode mode,
  AutoReadState state,
  int speedPixelsPerSecond,
  int pagedIntervalSeconds,
) => switch (state) {
  AutoReadState.running =>
    mode == ReaderMode.vertical
        ? '\u81ea\u52a8\u9605\u8bfb\u4e2d \u00b7 $speedPixelsPerSecond px/s'
        : '\u81ea\u52a8\u7ffb\u9875\u4e2d \u00b7 $pagedIntervalSeconds \u79d2/\u9875',
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
    constraints: BoxConstraints(
      maxWidth: isDesktop ? 900 : double.infinity,
      maxHeight: isDesktop ? 760 : double.infinity,
    ),
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
                  for (final seconds in [
                    ...AutoReadPreferences.supportedPagedIntervals,
                  ]..sort((a, b) => b.compareTo(a)))
                    ChoiceChip(
                      label: Text('\u6bcf $seconds \u79d2'),
                      selected: pagedIntervalSeconds == seconds,
                      onSelected: onPagedIntervalChanged == null
                          ? null
                          : (_) => onPagedIntervalChanged!(seconds),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                key: const Key('reader-auto-read-interval-slider'),
                min: AutoReadPreferences.minPagedIntervalSeconds.toDouble(),
                max: AutoReadPreferences.maxPagedIntervalSeconds.toDouble(),
                divisions:
                    AutoReadPreferences.maxPagedIntervalSeconds -
                    AutoReadPreferences.minPagedIntervalSeconds,
                value: pagedIntervalSeconds.toDouble().clamp(
                  AutoReadPreferences.minPagedIntervalSeconds.toDouble(),
                  AutoReadPreferences.maxPagedIntervalSeconds.toDouble(),
                ),
                label: '$pagedIntervalSeconds \u79d2/\u9875',
                onChanged: onPagedIntervalChanged == null
                    ? null
                    : (value) => onPagedIntervalChanged!(value.round()),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  '$pagedIntervalSeconds \u79d2/\u9875',
                  key: const Key('reader-auto-read-interval-value'),
                ),
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
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(12),
        hoverColor: colorScheme.primary.withValues(alpha: .08),
        focusColor: colorScheme.primary.withValues(alpha: .12),
        splashColor: colorScheme.primary.withValues(alpha: .16),
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
  ValueListenable<ReaderPreferences>? preferencesListenable,
  required ReaderMode mode,
  required ValueChanged<ReaderPreferences> onPreferencesCommitted,
  required ValueChanged<ReaderMode> onModeSelected,
  required VoidCallback onResetPreferences,
  Future<String?> Function()? onPickBackgroundImage,
  Future<void> Function(String? path)? onDeleteBackgroundImage,
  List<ReaderFontAsset> importedFonts = const [],
  List<ReaderSystemFontChoice> systemFonts = const [],
  Future<ReaderFontAsset?> Function()? onImportFont,
  Future<void> Function(String fontId)? onDeleteFont,
  Future<String?> Function(String? fontId)? onPreviewFont,
}) {
  final isDesktop = defaultTargetPlatform == TargetPlatform.windows;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxWidth: isDesktop ? 960 : double.infinity),
    builder: (context) {
      Widget sheet(ReaderPreferences current) => Theme(
        data: _readerSettingsTheme(context, current.themeMode),
        child: ReaderSettingsSheet(
          preferences: current,
          mode: mode,
          onPreferencesCommitted: onPreferencesCommitted,
          onModeSelected: onModeSelected,
          onResetPreferences: onResetPreferences,
          onPickBackgroundImage: onPickBackgroundImage,
          onDeleteBackgroundImage: onDeleteBackgroundImage,
          importedFonts: importedFonts,
          systemFonts: systemFonts,
          onImportFont: onImportFont,
          onDeleteFont: onDeleteFont,
          onPreviewFont: onPreviewFont,
        ),
      );
      final source = preferencesListenable;
      if (source == null) return sheet(preferences);
      return ValueListenableBuilder<ReaderPreferences>(
        valueListenable: source,
        builder: (context, current, _) => sheet(current),
      );
    },
  );
}

ThemeData _readerSettingsTheme(BuildContext context, ReaderThemeMode mode) {
  final brightness = switch (mode) {
    ReaderThemeMode.light => Brightness.light,
    ReaderThemeMode.dark => Brightness.dark,
    ReaderThemeMode.system => MediaQuery.platformBrightnessOf(context),
  };
  return brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();
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
    this.importedFonts = const [],
    this.systemFonts = const [],
    this.onImportFont,
    this.onDeleteFont,
    this.onPreviewFont,
  });

  final ReaderPreferences preferences;
  final ReaderMode mode;
  final ValueChanged<ReaderPreferences> onPreferencesCommitted;
  final ValueChanged<ReaderMode> onModeSelected;
  final VoidCallback onResetPreferences;
  final Future<String?> Function()? onPickBackgroundImage;
  final Future<void> Function(String? path)? onDeleteBackgroundImage;
  final List<ReaderFontAsset> importedFonts;
  final List<ReaderSystemFontChoice> systemFonts;
  final Future<ReaderFontAsset?> Function()? onImportFont;
  final Future<void> Function(String fontId)? onDeleteFont;
  final Future<String?> Function(String? fontId)? onPreviewFont;

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late ReaderPreferences _draft = widget.preferences;
  late List<ReaderFontAsset> _importedFonts = [...widget.importedFonts];
  String? _fontCandidateId;
  bool _fontCandidateActive = false;
  String? _fontPreviewFamily;
  bool _fontPreviewLoading = false;
  String? _fontPreviewError;
  late ReaderMode _mode = widget.mode;
  _ReaderSettingsCategory _category = _ReaderSettingsCategory.typography;
  final ScrollController _categoryScrollController = ScrollController();
  double _categoryDragStart = 0;
  double _categoryScrollStart = 0;
  late final TextEditingController _lightTextColorController =
      TextEditingController(text: _hexColor(_draft.lightTextColorArgb));
  late final TextEditingController _lightBackgroundColorController =
      TextEditingController(text: _hexColor(_draft.lightBackgroundColorArgb));
  late final TextEditingController _darkTextColorController =
      TextEditingController(text: _hexColor(_draft.darkTextColorArgb));
  late final TextEditingController _darkBackgroundColorController =
      TextEditingController(text: _hexColor(_draft.darkBackgroundColorArgb));
  Brightness _editingBrightness = Brightness.light;
  bool _brightnessInitialized = false;
  String? _textColorError;
  String? _backgroundColorError;

  void _commit(ReaderPreferences value) {
    setState(() => _draft = value);
    widget.onPreferencesCommitted(value);
  }

  @override
  void didUpdateWidget(covariant ReaderSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      setState(() => _draft = widget.preferences);
      _syncBrightnessControllers();
    }
  }

  String? get _selectedFontId =>
      _fontCandidateActive ? _fontCandidateId : _draft.fontId;

  bool get _fontCandidateChanged =>
      _fontCandidateActive && _fontCandidateId != _draft.fontId;

  Future<void> _selectFontCandidate(String? fontId) async {
    setState(() {
      _fontCandidateId = fontId;
      _fontCandidateActive = true;
      _fontPreviewFamily = null;
      _fontPreviewError = null;
      _fontPreviewLoading = true;
    });
    try {
      final family = await widget.onPreviewFont?.call(fontId);
      if (!mounted) return;
      setState(() {
        _fontPreviewFamily = family;
        _fontPreviewLoading = false;
        _fontPreviewError = family == null && fontId != null
            ? '此字体无法加载，将回退为系统默认。'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fontPreviewLoading = false;
        _fontPreviewError = '此字体无法加载，将回退为系统默认。';
      });
    }
  }

  void _cancelFontCandidate() {
    setState(() {
      _fontCandidateId = null;
      _fontCandidateActive = false;
      _fontPreviewFamily = null;
      _fontPreviewError = null;
      _fontPreviewLoading = false;
    });
  }

  void _applyFontCandidate() {
    if (!_fontCandidateChanged ||
        _fontPreviewLoading ||
        _fontPreviewError != null) {
      return;
    }
    final next = _draft.copyWith(fontId: _fontCandidateId);
    _commit(next);
    setState(() {
      _fontCandidateId = null;
      _fontCandidateActive = false;
      _fontPreviewFamily = null;
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    _lightTextColorController.dispose();
    _lightBackgroundColorController.dispose();
    _darkTextColorController.dispose();
    _darkBackgroundColorController.dispose();
    super.dispose();
  }

  TextEditingController get _textColorController =>
      _editingBrightness == Brightness.light
      ? _lightTextColorController
      : _darkTextColorController;

  TextEditingController get _backgroundColorController =>
      _editingBrightness == Brightness.light
      ? _lightBackgroundColorController
      : _darkBackgroundColorController;

  int? _textColorFor(Brightness brightness) => brightness == Brightness.light
      ? _draft.lightTextColorArgb
      : _draft.darkTextColorArgb;

  int? _backgroundColorFor(Brightness brightness) =>
      brightness == Brightness.light
      ? _draft.lightBackgroundColorArgb
      : _draft.darkBackgroundColorArgb;

  Brightness _effectiveBrightness(BuildContext context, ReaderThemeMode mode) =>
      switch (mode) {
        ReaderThemeMode.light => Brightness.light,
        ReaderThemeMode.dark => Brightness.dark,
        ReaderThemeMode.system => MediaQuery.platformBrightnessOf(context),
      };

  void _syncBrightnessControllers() {
    _textColorController.text = _hexColor(_textColorFor(_editingBrightness));
    _backgroundColorController.text = _hexColor(
      _backgroundColorFor(_editingBrightness),
    );
    _textColorError = null;
    _backgroundColorError = null;
  }

  void _previewColor({required bool text, required String value}) {
    final parsed = _parseColor(value);
    final light = _editingBrightness == Brightness.light;
    if (value.trim().isEmpty) {
      final next = text
          ? (light
                ? _draft.copyWith(
                    paletteId: ReaderPaletteId.custom,
                    lightTextColorArgb: null,
                  )
                : _draft.copyWith(
                    paletteId: ReaderPaletteId.custom,
                    darkTextColorArgb: null,
                  ))
          : (light
                ? _draft.copyWith(
                    paletteId: ReaderPaletteId.custom,
                    lightBackgroundColorArgb: null,
                  )
                : _draft.copyWith(
                    paletteId: ReaderPaletteId.custom,
                    darkBackgroundColorArgb: null,
                  ));
      setState(() {
        _draft = next;
        if (text) {
          _textColorError = null;
        } else {
          _backgroundColorError = null;
        }
      });
      widget.onPreferencesCommitted(next);
      return;
    }
    setState(() {
      if (text) {
        _textColorError = value.trim().isEmpty || parsed != null
            ? null
            : '请输入 #RRGGBB 或 rgb(r,g,b)';
        if (parsed != null) {
          _draft = light
              ? _draft.copyWith(
                  paletteId: ReaderPaletteId.custom,
                  lightTextColorArgb: parsed,
                )
              : _draft.copyWith(
                  paletteId: ReaderPaletteId.custom,
                  darkTextColorArgb: parsed,
                );
        }
      } else {
        _backgroundColorError = value.trim().isEmpty || parsed != null
            ? null
            : '请输入 #RRGGBB 或 rgb(r,g,b)';
        if (parsed != null) {
          _draft = light
              ? _draft.copyWith(
                  paletteId: ReaderPaletteId.custom,
                  lightBackgroundColorArgb: parsed,
                )
              : _draft.copyWith(
                  paletteId: ReaderPaletteId.custom,
                  darkBackgroundColorArgb: parsed,
                );
        }
      }
    });
    if (parsed != null) {
      widget.onPreferencesCommitted(_draft);
    }
  }

  static String _hexColor(int? value) => value == null
      ? ''
      : '#${(value & 0xffffff).toRadixString(16).padLeft(6, '0')}';

  static int? _parseColor(String raw) {
    final value = raw.trim();
    final hex = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value);
    if (hex != null) return int.parse('ff${hex.group(1)}', radix: 16);
    final rgb = RegExp(
      r'^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (rgb == null) return null;
    final channels = [
      int.parse(rgb.group(1)!),
      int.parse(rgb.group(2)!),
      int.parse(rgb.group(3)!),
    ];
    if (channels.any((channel) => channel > 255)) return null;
    return 0xff000000 | (channels[0] << 16) | (channels[1] << 8) | channels[2];
  }

  Widget _buildFontSection(BuildContext context) {
    final descriptors = <ReaderFontDescriptor>[
      const ReaderSystemFontChoice(
        id: 'systemDefault',
        familyName: '系统默认',
        displayName: '系统默认',
      ),
      ...widget.systemFonts.where((font) => font.id != 'systemDefault'),
      ..._importedFonts,
    ];
    final selected = _selectedFontId;
    final previewFamily =
        _fontPreviewFamily ??
        descriptors
            .where((font) => font.fontId == selected)
            .map(
              (font) => font.source == ReaderFontSource.imported
                  ? (font as ReaderFontAsset).runtimeFamily
                  : font.familyName,
            )
            .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('字体', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(
          '当前字体：${descriptors.where((font) => font.fontId == selected).map((font) => font.displayName).firstOrNull ?? '系统默认'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          key: const ValueKey('reader-font-list'),
          tilePadding: EdgeInsets.zero,
          title: const Text('选择字体'),
          subtitle: const Text('点击后仅预览，确认应用才会重新排版'),
          children: [
            SizedBox(
              height: 190,
              child: ListView(
                children: [
                  RadioGroup<String?>(
                    groupValue: selected,
                    onChanged: (value) =>
                        unawaited(_selectFontCandidate(value)),
                    child: Column(
                      children: descriptors.map((font) {
                        final value = font.fontId == 'systemDefault'
                            ? null
                            : font.fontId;
                        return ListTile(
                          dense: true,
                          leading: Radio<String?>(value: value),
                          title: Text(font.displayName),
                          subtitle: font.source == ReaderFontSource.imported
                              ? Text(
                                  '已导入 · ${(font as ReaderFontAsset).format.name.toUpperCase()}',
                                )
                              : null,
                          onTap: () => unawaited(_selectFontCandidate(value)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            key: const ValueKey('reader-font-preview-card'),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('中文阅读效果预览'),
                    const SizedBox(height: 4),
                    Text(
                      'XAOCEN Reader  1234567890',
                      style: TextStyle(fontFamily: previewFamily, fontSize: 16),
                    ),
                    if (_fontPreviewLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (_fontPreviewError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _fontPreviewError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: widget.onImportFont == null
                  ? null
                  : () async {
                      final asset = await widget.onImportFont!.call();
                      if (!mounted || asset == null) return;
                      setState(
                        () => _importedFonts = [
                          ..._importedFonts.where(
                            (font) => font.fontId != asset.fontId,
                          ),
                          asset,
                        ],
                      );
                      await _selectFontCandidate(asset.fontId);
                    },
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('导入 TTF / OTF'),
            ),
            if (_importedFonts.any((font) => font.fontId == selected))
              OutlinedButton.icon(
                onPressed: widget.onDeleteFont == null || selected == null
                    ? null
                    : () async {
                        final id = selected;
                        await widget.onDeleteFont!.call(id);
                        if (mounted) {
                          _cancelFontCandidate();
                          if (_draft.fontId == id) {
                            _commit(_draft.copyWith(fontId: null));
                          }
                        }
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除字体'),
              ),
            if (_fontCandidateChanged) ...[
              OutlinedButton(
                onPressed: _cancelFontCandidate,
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: _applyFontCandidate,
                child: const Text('应用字体'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTypographyPanel(BuildContext context) {
    final isDesktop = defaultTargetPlatform == TargetPlatform.windows;
    final leftPadding = _PreferenceSlider(
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
      onCommitted: (value) => _commit(_draft.copyWith(paddingLeft: value)),
    );
    final rightPadding = _PreferenceSlider(
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
      onCommitted: (value) => _commit(_draft.copyWith(paddingRight: value)),
    );
    final topPadding = _PreferenceSlider(
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
      onCommitted: (value) => _commit(_draft.copyWith(paddingTop: value)),
    );
    final bottomPadding = _PreferenceSlider(
      key: readerPaddingBottomSliderKey,
      label: '下边距',
      value: _draft.paddingBottom,
      min: ReaderPreferences.minVerticalPadding,
      max: ReaderPreferences.maxVerticalPadding,
      divisions: 12,
      step: ReaderPreferences.paddingStep,
      valueLabel: _draft.paddingBottom.toStringAsFixed(0),
      onDraftChanged: (value) =>
          setState(() => _draft = _draft.copyWith(paddingBottom: value)),
      onCommitted: (value) => _commit(_draft.copyWith(paddingBottom: value)),
    );
    final paddingControls = isDesktop
        ? Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftPadding),
                  const SizedBox(width: 16),
                  Expanded(child: rightPadding),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: topPadding),
                  const SizedBox(width: 16),
                  Expanded(child: bottomPadding),
                ],
              ),
            ],
          )
        : Column(
            children: [leftPadding, rightPadding, topPadding, bottomPadding],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('排版布局', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: _aaSectionGap),
        _buildFontSection(context),
        const SizedBox(height: _aaSectionGap),
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
          onDraftChanged: (value) =>
              setState(() => _draft = _draft.copyWith(letterSpacing: value)),
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
          onCommitted: (value) => _commit(_draft.copyWith(lineHeight: value)),
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
          onDraftChanged: (value) =>
              setState(() => _draft = _draft.copyWith(paragraphSpacing: value)),
          onCommitted: (value) =>
              _commit(_draft.copyWith(paragraphSpacing: value)),
        ),
        _PreferenceSlider(
          key: readerFirstLineIndentSliderKey,
          label: '首行缩进（字宽）',
          value: _draft.firstLineIndent,
          min: ReaderPreferences.minFirstLineIndent,
          max: ReaderPreferences.maxFirstLineIndent,
          divisions: 12,
          step: ReaderPreferences.firstLineIndentStep,
          valueLabel: _draft.firstLineIndent.toStringAsFixed(1),
          onDraftChanged: (value) =>
              setState(() => _draft = _draft.copyWith(firstLineIndent: value)),
          onCommitted: (value) =>
              _commit(_draft.copyWith(firstLineIndent: value)),
        ),
        const SizedBox(height: _aaSectionGap),
        Text('正文边距', style: Theme.of(context).textTheme.titleSmall),
        paddingControls,
      ],
    );
  }

  Widget _buildAppearancePanel(BuildContext context) {
    final activeBrightness = _effectiveBrightness(context, _draft.themeMode);
    final resolvedPalette = ReaderPaletteResolver.resolve(
      paletteId: _draft.paletteId,
      dark: activeBrightness == Brightness.dark,
      lightTextArgb: _draft.lightTextColorArgb,
      lightBackgroundArgb: _draft.lightBackgroundColorArgb,
      darkTextArgb: _draft.darkTextColorArgb,
      darkBackgroundArgb: _draft.darkBackgroundColorArgb,
    );
    final resolvedTextColor = Color(resolvedPalette.textArgb);
    final resolvedBackgroundColor = Color(resolvedPalette.backgroundArgb);
    final textColor = _textColorFor(_editingBrightness) == null
        ? null
        : Color(_textColorFor(_editingBrightness)!);
    final backgroundColor = _backgroundColorFor(_editingBrightness) == null
        ? null
        : Color(_backgroundColorFor(_editingBrightness)!);
    final contrastWarning = !isReadable(
      resolvedTextColor,
      resolvedBackgroundColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('阅读色彩模式', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ReaderThemeMode>(
          key: readerThemeControlKey,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size(0, _aaControlHeight),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_aaControlRadius),
              ),
            ),
          ),
          segments: const [
            ButtonSegment(value: ReaderThemeMode.system, label: Text('跟随系统')),
            ButtonSegment(value: ReaderThemeMode.light, label: Text('浅色')),
            ButtonSegment(value: ReaderThemeMode.dark, label: Text('深色')),
          ],
          selected: {_draft.themeMode},
          onSelectionChanged: (selection) {
            final nextMode = selection.single;
            setState(() {
              _editingBrightness = _effectiveBrightness(context, nextMode);
              _syncBrightnessControllers();
            });
            _commit(_draft.copyWith(themeMode: nextMode));
          },
        ),
        const SizedBox(height: 6),
        Text('决定当前使用浅色方案或深色方案', style: Theme.of(context).textTheme.bodySmall),
        if (_draft.themeMode == ReaderThemeMode.system) ...[
          const SizedBox(height: 4),
          Text(
            '当前：${_effectiveBrightness(context, _draft.themeMode) == Brightness.dark ? '深色' : '浅色'}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '当前编辑：${_editingBrightness == Brightness.dark ? '深色' : '浅色'}方案',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(
          '当前实际生效：${_draft.paletteId == ReaderPaletteId.custom ? '自定义' : '预设'} · ${activeBrightness == Brightness.dark ? '深色' : '浅色'}亮度',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        _ReaderPalettePresetGrid(
          key: readerPaletteControlKey,
          selected: _draft.paletteId,
          onSelected: (palette) => _commit(
            // Keep custom light/dark values for a future return to custom;
            // selecting a preset changes the sole active paint source.
            _draft.copyWith(paletteId: palette),
          ),
        ),
        const SizedBox(height: 14),
        Text('自定义配色', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<Brightness>(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size(0, _aaControlHeight),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_aaControlRadius),
              ),
            ),
          ),
          segments: const [
            ButtonSegment(value: Brightness.light, label: Text('浅色方案')),
            ButtonSegment(value: Brightness.dark, label: Text('深色方案')),
          ],
          selected: {_editingBrightness},
          onSelectionChanged: (selection) => setState(() {
            _editingBrightness = selection.single;
            _syncBrightnessControllers();
          }),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '当前使用',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              activeBrightness == Brightness.dark ? '深色方案' : '浅色方案',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ReaderAppearancePreviewCard(
          paletteId: _draft.paletteId,
          dark: activeBrightness == Brightness.dark,
          lightTextArgb: _draft.lightTextColorArgb,
          lightBackgroundArgb: _draft.lightBackgroundColorArgb,
          darkTextArgb: _draft.darkTextColorArgb,
          darkBackgroundArgb: _draft.darkBackgroundColorArgb,
        ),
        const SizedBox(height: 8),
        _ColorInput(
          key: readerTextColorControlKey,
          controller: _textColorController,
          label: '字体颜色',
          preview: textColor,
          errorText: _textColorError,
          onChanged: (value) => _previewColor(text: true, value: value),
          onSubmitted: (value) => _previewColor(text: true, value: value),
          onPick: () async {
            final result = await _showReaderColorPicker(
              context,
              initial: textColor ?? resolvedTextColor,
              defaultColor: Color(
                ReaderPaletteResolver.resolve(
                  paletteId: _draft.paletteId == ReaderPaletteId.custom
                      ? ReaderPreferences.defaultPaletteId
                      : _draft.paletteId,
                  dark: _editingBrightness == Brightness.dark,
                ).textArgb,
              ),
            );
            if (result == null) return;
            _commit(
              _draft.copyWith(
                paletteId: ReaderPaletteId.custom,
                lightTextColorArgb: _editingBrightness == Brightness.light
                    ? result
                    : _draft.lightTextColorArgb,
                darkTextColorArgb: _editingBrightness == Brightness.dark
                    ? result
                    : _draft.darkTextColorArgb,
              ),
            );
          },
        ),
        if (contrastWarning)
          Text(
            '当前字体与背景对比度较低，仍将按你的选择显示。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        const SizedBox(height: 14),
        _ColorInput(
          key: readerBackgroundColorControlKey,
          controller: _backgroundColorController,
          label: '阅读背景颜色',
          preview: backgroundColor,
          errorText: _backgroundColorError,
          onChanged: (value) => _previewColor(text: false, value: value),
          onSubmitted: (value) => _previewColor(text: false, value: value),
          onPick: () async {
            final result = await _showReaderColorPicker(
              context,
              initial: backgroundColor ?? resolvedBackgroundColor,
              defaultColor: Color(
                ReaderPaletteResolver.resolve(
                  paletteId: _draft.paletteId == ReaderPaletteId.custom
                      ? ReaderPreferences.defaultPaletteId
                      : _draft.paletteId,
                  dark: _editingBrightness == Brightness.dark,
                ).backgroundArgb,
              ),
            );
            if (result == null) return;
            _commit(
              _draft.copyWith(
                paletteId: ReaderPaletteId.custom,
                lightBackgroundColorArgb: _editingBrightness == Brightness.light
                    ? result
                    : _draft.lightBackgroundColorArgb,
                darkBackgroundColorArgb: _editingBrightness == Brightness.dark
                    ? result
                    : _draft.darkBackgroundColorArgb,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
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
                        await widget.onDeleteBackgroundImage?.call(previous);
                      }
                    },
              icon: const Icon(Icons.image_outlined),
              label: Text(_draft.backgroundImagePath == null ? '导入图片' : '更换图片'),
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
            valueLabel: '${(_draft.backgroundOverlayOpacity * 100).round()}%',
            onDraftChanged: (value) => setState(
              () => _draft = _draft.copyWith(backgroundOverlayOpacity: value),
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
            _lightTextColorController.clear();
            _lightBackgroundColorController.clear();
            _darkTextColorController.clear();
            _darkBackgroundColorController.clear();
            _commit(
              _draft.copyWith(
                paletteId: ReaderPreferences.defaultPaletteId,
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
      ],
    );
  }

  Widget _buildPagingPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('阅读行为', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ReaderMode>(
          key: readerSettingsModeControlKey,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size(0, _aaControlHeight),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_aaControlRadius),
              ),
            ),
          ),
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
        const SizedBox(height: 16),
        Text(
          '阅读方式按本书保存；页面布局和翻页效果将在后续版本提供。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text('阅读信息', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        SwitchListTile.adaptive(
          key: readerShowTopInfoKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('顶部阅读信息'),
          subtitle: const Text('菜单隐藏时显示章节标题和本章进度'),
          value: _draft.showTopInfoBar,
          onChanged: (value) => _commit(_draft.copyWith(showTopInfoBar: value)),
        ),
        SwitchListTile.adaptive(
          key: readerShowBottomInfoKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('底部阅读信息'),
          subtitle: const Text('菜单隐藏时显示时间和全书进度'),
          value: _draft.showBottomInfoBar,
          onChanged: (value) =>
              _commit(_draft.copyWith(showBottomInfoBar: value)),
        ),
        SwitchListTile.adaptive(
          key: readerShowAutoReadMinimalInfoKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('自动阅读时显示极简信息'),
          subtitle: const Text('自动隐藏菜单后保留章节、时间和进度信息'),
          value: _draft.showAutoReadMinimalInfo,
          onChanged: (value) =>
              _commit(_draft.copyWith(showAutoReadMinimalInfo: value)),
        ),
        SwitchListTile.adaptive(
          key: readerShowProgressInfoKey,
          contentPadding: EdgeInsets.zero,
          title: const Text('显示章节与全书进度'),
          value: _draft.showProgressInfo,
          onChanged: (value) => _commit(
            _draft.copyWith(
              showProgressInfo: value,
              showChapterProgressInfo: value,
              showWholeBookProgressInfo: value,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('信息项目与槽位', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        _buildInfoItemRow(
          context,
          label: '章节',
          value: _draft.showChapterInfo,
          slot: _draft.chapterInfoSlot,
          onValueChanged: (value) =>
              _commit(_draft.copyWith(showChapterInfo: value)),
          onSlotChanged: (slot) =>
              _commit(_draft.copyWith(chapterInfoSlot: slot)),
        ),
        _buildInfoItemRow(
          context,
          label: '本章进度',
          value: _draft.showChapterProgressInfo,
          slot: _draft.chapterProgressInfoSlot,
          onValueChanged: (value) => _commit(
            _draft.copyWith(
              showChapterProgressInfo: value,
              showProgressInfo: value && _draft.showWholeBookProgressInfo,
            ),
          ),
          onSlotChanged: (slot) =>
              _commit(_draft.copyWith(chapterProgressInfoSlot: slot)),
        ),
        _buildInfoItemRow(
          context,
          label: '时间',
          value: _draft.showClockInfo,
          slot: _draft.clockInfoSlot,
          onValueChanged: (value) =>
              _commit(_draft.copyWith(showClockInfo: value)),
          onSlotChanged: (slot) =>
              _commit(_draft.copyWith(clockInfoSlot: slot)),
        ),
        _buildInfoItemRow(
          context,
          label: '设备电量',
          value: _draft.showBatteryInfo,
          slot: _draft.batteryInfoSlot,
          onValueChanged: (value) =>
              _commit(_draft.copyWith(showBatteryInfo: value)),
          onSlotChanged: (slot) =>
              _commit(_draft.copyWith(batteryInfoSlot: slot)),
        ),
        _buildInfoItemRow(
          context,
          label: '全书进度',
          value: _draft.showWholeBookProgressInfo,
          slot: _draft.wholeBookProgressInfoSlot,
          onValueChanged: (value) => _commit(
            _draft.copyWith(
              showWholeBookProgressInfo: value,
              showProgressInfo: value && _draft.showChapterProgressInfo,
            ),
          ),
          onSlotChanged: (slot) =>
              _commit(_draft.copyWith(wholeBookProgressInfoSlot: slot)),
        ),
        /* Legacy divider rows were replaced by fixed divider toggles below.
        _buildInfoItemRow(
          context,
          label: '分隔线',
          value: _draft.showTopInfoDivider,
          onChanged: (value) =>
              _commit(_draft.copyWith(showTopInfoDivider: value)),
        ),
        SwitchListTile.adaptive(
          context,
          label: '\u5e95\u90e8\u4fe1\u606f\u5206\u9694\u7ebf',
          value: _draft.showBottomInfoDivider,
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('顶部信息分隔线'),
          value: _draft.showTopInfoDivider,
          onChanged: (value) =>
              _commit(_draft.copyWith(showTopInfoDivider: value)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('底部信息分隔线'),
          value: _draft.showBottomInfoDivider,
          onChanged: (value) =>
              _commit(_draft.copyWith(showBottomInfoDivider: value)),
        ),
        */
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('顶部信息分隔线'),
          value: _draft.showTopInfoDivider,
          onChanged: (value) =>
              _commit(_draft.copyWith(showTopInfoDivider: value)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('底部信息分隔线'),
          value: _draft.showBottomInfoDivider,
          onChanged: (value) =>
              _commit(_draft.copyWith(showBottomInfoDivider: value)),
        ),
        if (defaultTargetPlatform == TargetPlatform.android) ...[
          const SizedBox(height: 8),
          Text('系统状态栏', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          SwitchListTile.adaptive(
            key: readerStatusBarModeKey,
            contentPadding: EdgeInsets.zero,
            title: const Text('显示系统状态栏'),
            subtitle: const Text('仅控制 Android 系统状态栏，不影响阅读信息'),
            value: _draft.showSystemStatusBar,
            onChanged: (value) =>
                _commit(_draft.copyWith(showSystemStatusBar: value)),
          ),
          SwitchListTile.adaptive(
            key: readerHideNavigationBarKey,
            contentPadding: EdgeInsets.zero,
            title: const Text('\u9690\u85cf\u7cfb\u7edf\u5bfc\u822a\u680f'),
            subtitle: const Text(
              '\u4fdd\u7559\u7cfb\u7edf\u8fb9\u7f18\u624b\u52bf\u53ef\u4e34\u65f6\u5524\u56de',
            ),
            value: _draft.hideNavigationBar,
            onChanged: (value) =>
                _commit(_draft.copyWith(hideNavigationBar: value)),
          ),
          SwitchListTile.adaptive(
            key: readerExtendIntoDisplayCutoutKey,
            contentPadding: EdgeInsets.zero,
            title: const Text('\u6269\u5c55\u5230\u5218\u6d77\u533a\u57df'),
            subtitle: Text(
              _draft.showSystemStatusBar
                  ? '\u9690\u85cf\u7cfb\u7edf\u72b6\u6001\u680f\u540e\u53ef\u7528'
                  : '\u5141\u8bb8 Reader \u4f7f\u7528\u5218\u6d77\u533a\u57df',
            ),
            value: _draft.extendIntoDisplayCutout,
            onChanged: _draft.showSystemStatusBar
                ? null
                : (value) =>
                      _commit(_draft.copyWith(extendIntoDisplayCutout: value)),
          ),
          const SizedBox(height: 8),
          Text(
            '\u5c4f\u5e55\u65b9\u5411',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          SegmentedButton<ReaderScreenOrientation>(
            key: readerScreenOrientationKey,
            segments: const [
              ButtonSegment(
                value: ReaderScreenOrientation.system,
                label: Text('\u8ddf\u968f\u7cfb\u7edf'),
              ),
              ButtonSegment(
                value: ReaderScreenOrientation.autoRotate,
                label: Text('\u81ea\u52a8\u65cb\u8f6c'),
              ),
              ButtonSegment(
                value: ReaderScreenOrientation.portrait,
                label: Text('\u9501\u5b9a\u7ad6\u5c4f'),
              ),
              ButtonSegment(
                value: ReaderScreenOrientation.landscape,
                label: Text('\u9501\u5b9a\u6a2a\u5c4f'),
              ),
            ],
            selected: {_draft.screenOrientation},
            onSelectionChanged: (selection) =>
                _commit(_draft.copyWith(screenOrientation: selection.single)),
          ),
        ],
        const SizedBox(height: 12),
        Text('时间显示方式', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SegmentedButton<ReaderTimeDisplayMode>(
          key: readerTimeDisplayModeKey,
          segments: const [
            ButtonSegment(
              value: ReaderTimeDisplayMode.twentyFourHour,
              label: Text('24 小时'),
            ),
            ButtonSegment(
              value: ReaderTimeDisplayMode.twelveHour,
              label: Text('12 小时'),
            ),
            ButtonSegment(
              value: ReaderTimeDisplayMode.hidden,
              label: Text('不显示'),
            ),
          ],
          selected: {_draft.timeDisplayMode},
          onSelectionChanged: (selection) =>
              _commit(_draft.copyWith(timeDisplayMode: selection.single)),
        ),
        const SizedBox(height: 6),
        Text(
          '时间会按所选 12/24 小时格式显示在固定槽位；关闭“时间”即可隐藏。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInfoItemRow(
    BuildContext context, {
    required String label,
    required bool value,
    bool showSlot = true,
    required ReaderInfoSlot slot,
    required ValueChanged<bool> onValueChanged,
    required ValueChanged<ReaderInfoSlot> onSlotChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      leading: Switch.adaptive(value: value, onChanged: onValueChanged),
      trailing: showSlot
          ? DropdownButton<ReaderInfoSlot>(
              value: slot,
              isDense: true,
              underline: const SizedBox.shrink(),
              onChanged: (next) {
                if (next != null) onSlotChanged(next);
              },
              items: [
                for (final item in ReaderInfoSlot.values)
                  DropdownMenuItem(value: item, child: Text(_slotLabel(item))),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  String _slotLabel(ReaderInfoSlot slot) => switch (slot) {
    ReaderInfoSlot.topLeft => '顶部左',
    ReaderInfoSlot.topCenter => '顶部中',
    ReaderInfoSlot.topRight => '顶部右',
    ReaderInfoSlot.bottomLeft => '底部左',
    ReaderInfoSlot.bottomCenter => '底部中',
    ReaderInfoSlot.bottomRight => '底部右',
  };

  Widget _buildAdvancedPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('高级设置', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          '设置变化会保留当前 ReaderLocator；外观颜色属于即时预览，不会触发重新分页。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: readerResetPreferencesKey,
          onPressed: () {
            _lightTextColorController.clear();
            _lightBackgroundColorController.clear();
            _darkTextColorController.clear();
            _darkBackgroundColorController.clear();
            setState(() => _draft = ReaderPreferences.defaults);
            widget.onResetPreferences();
          },
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('恢复全部阅读设置'),
        ),
      ],
    );
  }

  Widget _buildCategoryPanel(BuildContext context) => switch (_category) {
    _ReaderSettingsCategory.typography => _buildTypographyPanel(context),
    _ReaderSettingsCategory.appearance => _buildAppearancePanel(context),
    _ReaderSettingsCategory.paging => _buildPagingPanel(context),
    _ReaderSettingsCategory.advanced => _buildAdvancedPanel(context),
  };

  @override
  Widget build(BuildContext context) {
    if (!_brightnessInitialized) {
      _editingBrightness = _effectiveBrightness(context, _draft.themeMode);
      _syncBrightnessControllers();
      _brightnessInitialized = true;
    }
    final availableWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = defaultTargetPlatform == TargetPlatform.windows
        ? math.min(960.0, availableWidth)
        : availableWidth;
    final useLabelRail = panelWidth >= 840;
    final useIconRail = panelWidth >= 600 && panelWidth < 840;
    final categories = [
      (_ReaderSettingsCategory.typography, '排版布局', Icons.text_fields_rounded),
      (_ReaderSettingsCategory.appearance, '阅读外观', Icons.palette_outlined),
      (_ReaderSettingsCategory.paging, '阅读行为', Icons.menu_book_outlined),
      (_ReaderSettingsCategory.advanced, '高级设置', Icons.tune_rounded),
    ];
    final content = _buildCategoryPanel(context);
    final navigation = useLabelRail
        ? SizedBox(
            width: 180,
            child: Column(
              children: [
                for (final item in categories)
                  ListTile(
                    key: ValueKey('reader-settings-category-${item.$1.name}'),
                    dense: true,
                    selected: _category == item.$1,
                    leading: Icon(item.$3),
                    title: Text(item.$2),
                    onTap: () => setState(() => _category = item.$1),
                  ),
              ],
            ),
          )
        : useIconRail
        ? SizedBox(
            width: 64,
            child: Column(
              children: [
                for (final item in categories)
                  Tooltip(
                    message: item.$2,
                    child: IconButton(
                      key: ValueKey('reader-settings-category-${item.$1.name}'),
                      isSelected: _category == item.$1,
                      selectedIcon: Icon(item.$3),
                      icon: Icon(item.$3),
                      onPressed: () => setState(() => _category = item.$1),
                    ),
                  ),
              ],
            ),
          )
        : Listener(
            onPointerDown: (event) {
              _categoryDragStart = event.position.dx;
              _categoryScrollStart = _categoryScrollController.hasClients
                  ? _categoryScrollController.offset
                  : 0;
            },
            onPointerMove: (event) {
              if (!_categoryScrollController.hasClients) return;
              final next =
                  (_categoryScrollStart +
                          (_categoryDragStart - event.position.dx))
                      .clamp(
                        0.0,
                        _categoryScrollController.position.maxScrollExtent,
                      )
                      .toDouble();
              _categoryScrollController.jumpTo(next);
            },
            onPointerSignal: (event) {
              if (event is PointerScrollEvent &&
                  _categoryScrollController.hasClients) {
                final next =
                    (_categoryScrollController.offset + event.scrollDelta.dy)
                        .clamp(
                          0.0,
                          _categoryScrollController.position.maxScrollExtent,
                        )
                        .toDouble();
                _categoryScrollController.jumpTo(next);
              }
            },
            child: SingleChildScrollView(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in categories) ...[
                    ChoiceChip(
                      key: ValueKey('reader-settings-category-${item.$1.name}'),
                      selected: _category == item.$1,
                      label: Text(item.$2),
                      avatar: Icon(item.$3, size: 17),
                      onSelected: (_) => setState(() => _category = item.$1),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          );
    final panel = (useLabelRail || useIconRail)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              navigation,
              const SizedBox(width: 24),
              const VerticalDivider(width: 1),
              const SizedBox(width: 24),
              Expanded(child: SingleChildScrollView(child: content)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              navigation,
              const SizedBox(height: 18),
              Expanded(child: SingleChildScrollView(child: content)),
            ],
          );
    return SafeArea(
      child: SizedBox(
        width: panelWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: Padding(
            key: readerSettingsSheetKey,
            padding: EdgeInsets.fromLTRB(
              useLabelRail ? 28 : 20,
              0,
              useLabelRail ? 28 : 20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('阅读设置', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(child: panel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ReaderSettingsCategory { typography, appearance, paging, advanced }

class _ColorInput extends StatelessWidget {
  const _ColorInput({
    super.key,
    required this.controller,
    required this.label,
    required this.preview,
    required this.errorText,
    required this.onChanged,
    required this.onSubmitted,
    this.onPick,
  });

  final TextEditingController controller;
  final String label;
  final Color? preview;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: '#RRGGBB 或 rgb(255,255,255)',
                errorText: errorText,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: preview ?? Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: const SizedBox(width: 18, height: 18),
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.colorize),
            label: const Text('\u53d6\u8272'),
          ),
        ],
      ),
    );
  }
}

Future<int?> _showReaderColorPicker(
  BuildContext context, {
  required Color initial,
  required Color defaultColor,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) =>
        _ReaderColorPickerDialog(initial: initial, defaultColor: defaultColor),
  );
}

class _ReaderColorPickerDialog extends StatefulWidget {
  const _ReaderColorPickerDialog({
    required this.initial,
    required this.defaultColor,
  });

  final Color initial;
  final Color defaultColor;

  @override
  State<_ReaderColorPickerDialog> createState() =>
      _ReaderColorPickerDialogState();
}

class _ReaderColorPickerDialogState extends State<_ReaderColorPickerDialog> {
  late Color _color = widget.initial;
  late final TextEditingController _hex = TextEditingController(
    text: '#${widget.initial.toARGB32().toRadixString(16).substring(2)}',
  );
  String? _error;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _setColor(Color color) {
    setState(() {
      _color = color.withAlpha(255);
      _hex.text =
          '#${(_color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
      _error = null;
    });
  }

  void _parseHex(String raw) {
    final parsed = ReaderSettingsSheetStateColorParser.parse(raw);
    if (parsed == null) {
      setState(() => _error = '\u8bf7\u8f93\u5165 #RRGGBB \u6216 rgb(r,g,b)');
      return;
    }
    _setColor(Color(parsed));
  }

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(_color);
    return AlertDialog(
      title: const Text('\u9009\u62e9\u989c\u8272'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 64, color: _color),
            const SizedBox(height: 12),
            TextField(
              controller: _hex,
              decoration: InputDecoration(
                labelText: 'HEX / RGB',
                errorText: _error,
              ),
              onSubmitted: _parseHex,
            ),
            const SizedBox(height: 8),
            Slider(
              min: 0,
              max: 360,
              value: hsv.hue,
              onChanged: (value) => _setColor(hsv.withHue(value).toColor()),
            ),
            Slider(
              min: 0,
              max: 1,
              value: hsv.saturation,
              onChanged: (value) =>
                  _setColor(hsv.withSaturation(value).toColor()),
            ),
            Slider(
              min: 0,
              max: 1,
              value: hsv.value,
              onChanged: (value) => _setColor(hsv.withValue(value).toColor()),
            ),
            TextButton.icon(
              onPressed: () => _setColor(widget.defaultColor),
              icon: const Icon(Icons.restore),
              label: const Text('\u6062\u590d\u65b9\u6848\u9ed8\u8ba4\u8272'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('\u53d6\u6d88'),
        ),
        FilledButton(
          onPressed: _error == null
              ? () => Navigator.pop(context, _color.toARGB32())
              : null,
          child: const Text('\u786e\u8ba4'),
        ),
      ],
    );
  }
}

/// Kept local to the appearance UI so parsing remains identical to the
/// existing #RRGGBB/rgb(r,g,b) contract without adding a second persistence
/// format.
final class ReaderSettingsSheetStateColorParser {
  static int? parse(String raw) {
    final value = raw.trim();
    final hex = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value);
    if (hex != null) return int.parse('ff${hex.group(1)}', radix: 16);
    final rgb = RegExp(
      r'^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (rgb == null) return null;
    final channels = [
      int.parse(rgb.group(1)!),
      int.parse(rgb.group(2)!),
      int.parse(rgb.group(3)!),
    ];
    if (channels.any((channel) => channel > 255)) return null;
    return 0xff000000 | (channels[0] << 16) | (channels[1] << 8) | channels[2];
  }
}

class _ReaderPalettePresetGrid extends StatelessWidget {
  const _ReaderPalettePresetGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ReaderPaletteId selected;
  final ValueChanged<ReaderPaletteId> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('阅读配色方案', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('自定义'),
              selected: selected == ReaderPaletteId.custom,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_aaControlRadius),
              ),
              onSelected: (_) => onSelected(ReaderPaletteId.custom),
            ),
            for (final palette in ReaderPalette.presets)
              Tooltip(
                message: '${palette.label} · 浅色/深色方案',
                child: ChoiceChip(
                  label: Text(palette.label),
                  selected: palette.id == selected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_aaControlRadius),
                  ),
                  avatar: _DualPaletteSwatch(palette: palette),
                  onSelected: (_) => onSelected(palette.id),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DualPaletteSwatch extends StatelessWidget {
  const _DualPaletteSwatch({required this.palette});

  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 20,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: ColoredBox(
              color: Color(palette.light.backgroundArgb),
              child: Center(
                child: Text(
                  'A',
                  style: ReaderTypography.paletteSwatch(
                    color: Color(palette.light.textArgb),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: Color(palette.dark.backgroundArgb),
              child: Center(
                child: Text(
                  'A',
                  style: ReaderTypography.paletteSwatch(
                    color: Color(palette.dark.textArgb),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderAppearancePreviewCard extends StatelessWidget {
  const _ReaderAppearancePreviewCard({
    required this.paletteId,
    required this.dark,
    required this.lightTextArgb,
    required this.lightBackgroundArgb,
    required this.darkTextArgb,
    required this.darkBackgroundArgb,
  });

  final ReaderPaletteId paletteId;
  final bool dark;
  final int? lightTextArgb;
  final int? lightBackgroundArgb;
  final int? darkTextArgb;
  final int? darkBackgroundArgb;

  @override
  Widget build(BuildContext context) {
    final colors = ReaderPaletteResolver.resolve(
      paletteId: paletteId,
      dark: dark,
      lightTextArgb: lightTextArgb,
      lightBackgroundArgb: lightBackgroundArgb,
      darkTextArgb: darkTextArgb,
      darkBackgroundArgb: darkBackgroundArgb,
    );
    final background = Color(colors.backgroundArgb);
    final text = Color(colors.textArgb);
    return Container(
      key: const ValueKey('reader-appearance-preview'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(_aaControlRadius),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: text),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前方案预览',
              style: ReaderTypography.previewLabel(
                color: text.withValues(alpha: .72),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Aa 读书正文示例 · 正文色 / 背景色',
              style: ReaderTypography.previewBody(color: text),
            ),
          ],
        ),
      ),
    );
  }
}

/* legacy inline Aa layout retained in history; category panels above replace it.
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
               divisions: 12,
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
*/

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
              // Keep search hits readable in both custom palettes. The
              // highlight is a translucent accent wash; text remains the
              // normal foreground rather than reusing the accent itself.
              color: style.color ?? Theme.of(context).colorScheme.onSurface,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .20),
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
