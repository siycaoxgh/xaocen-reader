/// Per-book Reader appearance contract (M5.1e.1).
library;

import 'reader_palette.dart';

enum ReaderThemeMode { system, light, dark }

/// Android system-bar presentation for the Reader route.  The preference is
/// display-only: it never participates in metrics or Locator persistence.
enum ReaderStatusBarMode { system, readerInfo, hidden }

/// Reader-specific Android screen orientation policy.  The value is stored as
/// a semantic preference; the platform adapter maps it to native orientation
/// requests without becoming part of the ReaderLocator contract.
enum ReaderScreenOrientation { system, autoRotate, portrait, landscape }

/// Clock presentation used by the optional Reader information layer.
enum ReaderTimeDisplayMode { twentyFourHour, twelveHour, hidden }

/// Fixed semantic slots for the minimal Reader information layer.  Slots are
/// intentionally named rather than pixel coordinates so the layer remains
/// safe across cutouts, window resizes and future responsive layouts.
enum ReaderInfoSlot {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

enum ReaderPreferenceChangeKind { metrics, paint, display }

final class ReaderPreferences {
  const ReaderPreferences._({
    required this.fontId,
    required this.fontSize,
    required this.letterSpacing,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.firstLineIndent,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingLeft,
    required this.paddingRight,
    required this.themeMode,
    required this.paletteId,
    required this.lightTextColorArgb,
    required this.lightBackgroundColorArgb,
    required this.darkTextColorArgb,
    required this.darkBackgroundColorArgb,
    required this.backgroundImagePath,
    required this.backgroundImageOpacity,
    required this.backgroundOverlayOpacity,
    required this.showTopInfoBar,
    required this.showBottomInfoBar,
    required this.showProgressInfo,
    required this.showSystemStatusBar,
    required this.hideNavigationBar,
    required this.extendIntoDisplayCutout,
    required this.screenOrientation,
    required this.statusBarMode,
    required this.timeDisplayMode,
    required this.showChapterInfo,
    required this.showChapterProgressInfo,
    required this.showClockInfo,
    required this.showWholeBookProgressInfo,
    required this.showTopInfoDivider,
    required this.showBottomInfoDivider,
    required this.showAutoReadMinimalInfo,
    required this.chapterInfoSlot,
    required this.chapterProgressInfoSlot,
    required this.clockInfoSlot,
    required this.wholeBookProgressInfoSlot,
    required this.infoDividerSlot,
  });

  static const double defaultFontSize = 17;
  static const String? defaultFontId = null;
  static const double minFontSize = 12;
  static const double maxFontSize = 32;
  static const double fontSizeStep = 1;

  static const double defaultLetterSpacing = 0;
  static const double minLetterSpacing = -0.5;
  static const double maxLetterSpacing = 1;
  static const double letterSpacingStep = 0.05;

  static const double defaultLineHeight = 1.7;
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.4;
  static const double lineHeightStep = 0.1;

  static const double defaultParagraphSpacing = 0;
  static const double minParagraphSpacing = 0;
  static const double maxParagraphSpacing = 32;
  static const double paragraphSpacingStep = 1;

  /// Em units; visual placeholder only, never inserted into normalized text.
  static const double defaultFirstLineIndent = 0;
  static const double minFirstLineIndent = -2;
  static const double maxFirstLineIndent = 4;
  static const double firstLineIndentStep = 0.5;

  static const double defaultPaddingTop = 8;
  static const double defaultPaddingBottom = 8;
  static const double defaultPaddingLeft = 16;
  static const double defaultPaddingRight = 16;
  static const double minVerticalPadding = 0;
  static const double maxVerticalPadding = 48;
  static const double minHorizontalPadding = 0;
  static const double maxHorizontalPadding = 64;
  static const double paddingStep = 2;

  static const ReaderThemeMode defaultThemeMode = ReaderThemeMode.system;
  static const ReaderPaletteId defaultPaletteId = ReaderPaletteId.paperWhite;
  static const double defaultBackgroundImageOpacity = 1;
  static const double defaultBackgroundOverlayOpacity = 0.45;
  static const double minAppearanceOpacity = 0;
  static const double maxAppearanceOpacity = 1;

  static const bool defaultShowTopInfoBar = true;
  static const bool defaultShowBottomInfoBar = true;
  static const bool defaultShowProgressInfo = true;
  static const bool defaultShowSystemStatusBar = true;
  static const bool defaultHideNavigationBar = false;
  static const bool defaultExtendIntoDisplayCutout = false;
  static const ReaderScreenOrientation defaultScreenOrientation =
      ReaderScreenOrientation.system;
  static const ReaderStatusBarMode defaultStatusBarMode =
      ReaderStatusBarMode.system;
  static const ReaderTimeDisplayMode defaultTimeDisplayMode =
      ReaderTimeDisplayMode.twentyFourHour;
  static const bool defaultShowChapterInfo = true;
  static const bool defaultShowChapterProgressInfo = true;
  static const bool defaultShowClockInfo = true;
  static const bool defaultShowWholeBookProgressInfo = true;
  static const bool defaultShowInfoDivider = false;
  static const bool defaultShowAutoReadMinimalInfo = true;
  static const ReaderInfoSlot defaultChapterInfoSlot = ReaderInfoSlot.topLeft;
  static const ReaderInfoSlot defaultChapterProgressInfoSlot =
      ReaderInfoSlot.topRight;
  static const ReaderInfoSlot defaultClockInfoSlot = ReaderInfoSlot.bottomLeft;
  static const ReaderInfoSlot defaultWholeBookProgressInfoSlot =
      ReaderInfoSlot.bottomRight;
  static const ReaderInfoSlot defaultInfoDividerSlot = ReaderInfoSlot.topCenter;

  static const ReaderPreferences defaults = ReaderPreferences._(
    fontId: defaultFontId,
    fontSize: defaultFontSize,
    letterSpacing: defaultLetterSpacing,
    lineHeight: defaultLineHeight,
    paragraphSpacing: defaultParagraphSpacing,
    firstLineIndent: defaultFirstLineIndent,
    paddingTop: defaultPaddingTop,
    paddingBottom: defaultPaddingBottom,
    paddingLeft: defaultPaddingLeft,
    paddingRight: defaultPaddingRight,
    themeMode: defaultThemeMode,
    paletteId: defaultPaletteId,
    lightTextColorArgb: null,
    lightBackgroundColorArgb: null,
    darkTextColorArgb: null,
    darkBackgroundColorArgb: null,
    backgroundImagePath: null,
    backgroundImageOpacity: defaultBackgroundImageOpacity,
    backgroundOverlayOpacity: defaultBackgroundOverlayOpacity,
    showTopInfoBar: defaultShowTopInfoBar,
    showBottomInfoBar: defaultShowBottomInfoBar,
    showProgressInfo: defaultShowProgressInfo,
    showSystemStatusBar: defaultShowSystemStatusBar,
    hideNavigationBar: defaultHideNavigationBar,
    extendIntoDisplayCutout: defaultExtendIntoDisplayCutout,
    screenOrientation: defaultScreenOrientation,
    statusBarMode: defaultStatusBarMode,
    timeDisplayMode: defaultTimeDisplayMode,
    showChapterInfo: defaultShowChapterInfo,
    showChapterProgressInfo: defaultShowChapterProgressInfo,
    showClockInfo: defaultShowClockInfo,
    showWholeBookProgressInfo: defaultShowWholeBookProgressInfo,
    showTopInfoDivider: defaultShowInfoDivider,
    showBottomInfoDivider: defaultShowInfoDivider,
    showAutoReadMinimalInfo: defaultShowAutoReadMinimalInfo,
    chapterInfoSlot: defaultChapterInfoSlot,
    chapterProgressInfoSlot: defaultChapterProgressInfoSlot,
    clockInfoSlot: defaultClockInfoSlot,
    wholeBookProgressInfoSlot: defaultWholeBookProgressInfoSlot,
    infoDividerSlot: defaultInfoDividerSlot,
  );

  factory ReaderPreferences({
    String? fontId = defaultFontId,
    double fontSize = defaultFontSize,
    double letterSpacing = defaultLetterSpacing,
    double lineHeight = defaultLineHeight,
    double paragraphSpacing = defaultParagraphSpacing,
    double firstLineIndent = defaultFirstLineIndent,
    double paddingTop = defaultPaddingTop,
    double paddingBottom = defaultPaddingBottom,
    double paddingLeft = defaultPaddingLeft,
    double paddingRight = defaultPaddingRight,
    ReaderThemeMode themeMode = defaultThemeMode,
    ReaderPaletteId? paletteId,
    int? textColorArgb,
    int? backgroundColorArgb,
    int? lightTextColorArgb,
    int? lightBackgroundColorArgb,
    int? darkTextColorArgb,
    int? darkBackgroundColorArgb,
    String? backgroundImagePath,
    double backgroundImageOpacity = defaultBackgroundImageOpacity,
    double backgroundOverlayOpacity = defaultBackgroundOverlayOpacity,
    bool showTopInfoBar = defaultShowTopInfoBar,
    bool showBottomInfoBar = defaultShowBottomInfoBar,
    bool showProgressInfo = defaultShowProgressInfo,
    bool? showSystemStatusBar,
    bool hideNavigationBar = defaultHideNavigationBar,
    bool extendIntoDisplayCutout = defaultExtendIntoDisplayCutout,
    ReaderScreenOrientation screenOrientation = defaultScreenOrientation,
    ReaderStatusBarMode statusBarMode = defaultStatusBarMode,
    ReaderTimeDisplayMode timeDisplayMode = defaultTimeDisplayMode,
    bool? showChapterInfo,
    bool? showChapterProgressInfo,
    bool? showClockInfo,
    bool? showWholeBookProgressInfo,
    bool? showInfoDivider,
    bool? showTopInfoDivider,
    bool? showBottomInfoDivider,
    bool showAutoReadMinimalInfo = defaultShowAutoReadMinimalInfo,
    ReaderInfoSlot chapterInfoSlot = defaultChapterInfoSlot,
    ReaderInfoSlot chapterProgressInfoSlot = defaultChapterProgressInfoSlot,
    ReaderInfoSlot clockInfoSlot = defaultClockInfoSlot,
    ReaderInfoSlot wholeBookProgressInfoSlot = defaultWholeBookProgressInfoSlot,
    ReaderInfoSlot infoDividerSlot = defaultInfoDividerSlot,
  }) => ReaderPreferences._(
    fontId: _validFontId(fontId),
    fontSize: _valid(fontSize, minFontSize, maxFontSize, defaultFontSize),
    letterSpacing: _valid(
      letterSpacing,
      minLetterSpacing,
      maxLetterSpacing,
      defaultLetterSpacing,
    ),
    lineHeight: _valid(
      lineHeight,
      minLineHeight,
      maxLineHeight,
      defaultLineHeight,
    ),
    paragraphSpacing: _valid(
      paragraphSpacing,
      minParagraphSpacing,
      maxParagraphSpacing,
      defaultParagraphSpacing,
    ),
    firstLineIndent: _valid(
      firstLineIndent,
      minFirstLineIndent,
      maxFirstLineIndent,
      defaultFirstLineIndent,
    ),
    paddingTop: _valid(
      paddingTop,
      minVerticalPadding,
      maxVerticalPadding,
      defaultPaddingTop,
    ),
    paddingBottom: _valid(
      paddingBottom,
      minVerticalPadding,
      maxVerticalPadding,
      defaultPaddingBottom,
    ),
    paddingLeft: _valid(
      paddingLeft,
      minHorizontalPadding,
      maxHorizontalPadding,
      defaultPaddingLeft,
    ),
    paddingRight: _valid(
      paddingRight,
      minHorizontalPadding,
      maxHorizontalPadding,
      defaultPaddingRight,
    ),
    themeMode: themeMode,
    // Legacy callers that provide the old single color pair are explicitly
    // entering custom mode. A caller that wants a preset can still pass its
    // palette id, which keeps preset/custom selection unambiguous.
    paletteId:
        paletteId ??
        ((textColorArgb != null || backgroundColorArgb != null)
            ? ReaderPaletteId.custom
            : defaultPaletteId),
    lightTextColorArgb: _validArgb(lightTextColorArgb ?? textColorArgb),
    lightBackgroundColorArgb: _validArgb(
      lightBackgroundColorArgb ?? backgroundColorArgb,
    ),
    darkTextColorArgb: _validArgb(darkTextColorArgb ?? textColorArgb),
    darkBackgroundColorArgb: _validArgb(
      darkBackgroundColorArgb ?? backgroundColorArgb,
    ),
    backgroundImagePath: _validManagedPath(backgroundImagePath),
    backgroundImageOpacity: _valid(
      backgroundImageOpacity,
      minAppearanceOpacity,
      maxAppearanceOpacity,
      defaultBackgroundImageOpacity,
    ),
    backgroundOverlayOpacity: _valid(
      backgroundOverlayOpacity,
      minAppearanceOpacity,
      maxAppearanceOpacity,
      defaultBackgroundOverlayOpacity,
    ),
    showTopInfoBar: showTopInfoBar,
    showBottomInfoBar: showBottomInfoBar,
    showProgressInfo:
        (showChapterProgressInfo ?? showProgressInfo) &&
        (showWholeBookProgressInfo ?? showProgressInfo),
    showSystemStatusBar:
        showSystemStatusBar ?? statusBarMode == ReaderStatusBarMode.system,
    hideNavigationBar: hideNavigationBar,
    extendIntoDisplayCutout:
        extendIntoDisplayCutout &&
        !(showSystemStatusBar ?? statusBarMode == ReaderStatusBarMode.system),
    screenOrientation: screenOrientation,
    statusBarMode: statusBarMode,
    timeDisplayMode: timeDisplayMode,
    showChapterInfo: showChapterInfo ?? defaultShowChapterInfo,
    showChapterProgressInfo: showChapterProgressInfo ?? showProgressInfo,
    showClockInfo: showClockInfo ?? defaultShowClockInfo,
    showWholeBookProgressInfo: showWholeBookProgressInfo ?? showProgressInfo,
    showTopInfoDivider:
        showTopInfoDivider ?? showInfoDivider ?? defaultShowInfoDivider,
    showBottomInfoDivider:
        showBottomInfoDivider ?? showInfoDivider ?? defaultShowInfoDivider,
    showAutoReadMinimalInfo: showAutoReadMinimalInfo,
    chapterInfoSlot: chapterInfoSlot,
    chapterProgressInfoSlot: chapterProgressInfoSlot,
    clockInfoSlot: clockInfoSlot,
    wholeBookProgressInfoSlot: wholeBookProgressInfoSlot,
    infoDividerSlot: infoDividerSlot,
  );

  final String? fontId;
  final double fontSize;
  final double letterSpacing;
  final double lineHeight;
  final double paragraphSpacing;
  final double firstLineIndent;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final ReaderThemeMode themeMode;
  final ReaderPaletteId paletteId;
  final int? lightTextColorArgb;
  final int? lightBackgroundColorArgb;
  final int? darkTextColorArgb;
  final int? darkBackgroundColorArgb;
  final String? backgroundImagePath;
  final double backgroundImageOpacity;
  final double backgroundOverlayOpacity;
  final bool showTopInfoBar;
  final bool showBottomInfoBar;
  final bool showProgressInfo;

  /// Android-only OS status-bar visibility. Reader information regions are
  /// independent and are controlled by [showTopInfoBar]/[showBottomInfoBar].
  final bool showSystemStatusBar;

  /// Android-only immersive navigation-bar visibility.
  final bool hideNavigationBar;

  /// Android-only cutout policy.  It is effective only while the system
  /// status bar is hidden; the settings UI enforces that dependency.
  final bool extendIntoDisplayCutout;
  final ReaderScreenOrientation screenOrientation;
  @Deprecated('Use showSystemStatusBar; retained for legacy persistence/API.')
  final ReaderStatusBarMode statusBarMode;
  final ReaderTimeDisplayMode timeDisplayMode;
  final bool showChapterInfo;
  final bool showChapterProgressInfo;
  final bool showClockInfo;
  final bool showWholeBookProgressInfo;
  final bool showTopInfoDivider;
  final bool showBottomInfoDivider;

  /// Legacy aggregate retained for source compatibility. New UI and storage
  /// use the independent top/bottom flags.
  bool get showInfoDivider => showTopInfoDivider || showBottomInfoDivider;
  final bool showAutoReadMinimalInfo;
  final ReaderInfoSlot chapterInfoSlot;
  final ReaderInfoSlot chapterProgressInfoSlot;
  final ReaderInfoSlot clockInfoSlot;
  final ReaderInfoSlot wholeBookProgressInfoSlot;
  final ReaderInfoSlot infoDividerSlot;

  /// Legacy aliases retained for callers from schema 7. They represent the
  /// light override; canonical storage keeps separate light/dark values.
  int? get textColorArgb => lightTextColorArgb;
  int? get backgroundColorArgb => lightBackgroundColorArgb;

  bool get hasCustomAppearance =>
      lightTextColorArgb != null ||
      lightBackgroundColorArgb != null ||
      darkTextColorArgb != null ||
      darkBackgroundColorArgb != null ||
      backgroundImagePath != null;

  static const Object _unset = Object();

  ReaderPreferences copyWith({
    Object? fontId = _unset,
    double? fontSize,
    double? letterSpacing,
    double? lineHeight,
    double? paragraphSpacing,
    double? firstLineIndent,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
    ReaderThemeMode? themeMode,
    ReaderPaletteId? paletteId,
    Object? textColorArgb = _unset,
    Object? backgroundColorArgb = _unset,
    Object? lightTextColorArgb = _unset,
    Object? lightBackgroundColorArgb = _unset,
    Object? darkTextColorArgb = _unset,
    Object? darkBackgroundColorArgb = _unset,
    Object? backgroundImagePath = _unset,
    double? backgroundImageOpacity,
    double? backgroundOverlayOpacity,
    bool? showTopInfoBar,
    bool? showBottomInfoBar,
    bool? showProgressInfo,
    bool? showSystemStatusBar,
    bool? hideNavigationBar,
    bool? extendIntoDisplayCutout,
    ReaderScreenOrientation? screenOrientation,
    ReaderStatusBarMode? statusBarMode,
    ReaderTimeDisplayMode? timeDisplayMode,
    bool? showChapterInfo,
    bool? showChapterProgressInfo,
    bool? showClockInfo,
    bool? showWholeBookProgressInfo,
    bool? showInfoDivider,
    bool? showTopInfoDivider,
    bool? showBottomInfoDivider,
    bool? showAutoReadMinimalInfo,
    ReaderInfoSlot? chapterInfoSlot,
    ReaderInfoSlot? chapterProgressInfoSlot,
    ReaderInfoSlot? clockInfoSlot,
    ReaderInfoSlot? wholeBookProgressInfoSlot,
    ReaderInfoSlot? infoDividerSlot,
  }) {
    final legacyText = identical(textColorArgb, _unset)
        ? null
        : textColorArgb as int?;
    final legacyBackground = identical(backgroundColorArgb, _unset)
        ? null
        : backgroundColorArgb as int?;
    final nextLightText =
        legacyText != null || !identical(textColorArgb, _unset)
        ? legacyText
        : identical(lightTextColorArgb, _unset)
        ? this.lightTextColorArgb
        : lightTextColorArgb as int?;
    final nextDarkText = legacyText != null || !identical(textColorArgb, _unset)
        ? legacyText
        : identical(darkTextColorArgb, _unset)
        ? this.darkTextColorArgb
        : darkTextColorArgb as int?;
    final nextLightBackground =
        legacyBackground != null || !identical(backgroundColorArgb, _unset)
        ? legacyBackground
        : identical(lightBackgroundColorArgb, _unset)
        ? this.lightBackgroundColorArgb
        : lightBackgroundColorArgb as int?;
    final nextDarkBackground =
        legacyBackground != null || !identical(backgroundColorArgb, _unset)
        ? legacyBackground
        : identical(darkBackgroundColorArgb, _unset)
        ? this.darkBackgroundColorArgb
        : darkBackgroundColorArgb as int?;
    final overrideWasEdited =
        !identical(textColorArgb, _unset) ||
        !identical(backgroundColorArgb, _unset) ||
        !identical(lightTextColorArgb, _unset) ||
        !identical(lightBackgroundColorArgb, _unset) ||
        !identical(darkTextColorArgb, _unset) ||
        !identical(darkBackgroundColorArgb, _unset);
    final nextPaletteId =
        paletteId ??
        (overrideWasEdited ? ReaderPaletteId.custom : this.paletteId);
    final nextChapterInfo = showChapterInfo ?? this.showChapterInfo;
    final nextChapterProgress =
        showChapterProgressInfo ??
        showProgressInfo ??
        this.showChapterProgressInfo;
    final nextWholeBookProgress =
        showWholeBookProgressInfo ??
        showProgressInfo ??
        this.showWholeBookProgressInfo;
    final nextShowSystemStatusBar =
        showSystemStatusBar ??
        (statusBarMode == null
            ? this.showSystemStatusBar
            : statusBarMode == ReaderStatusBarMode.system);
    return ReaderPreferences(
      fontId: identical(fontId, _unset) ? this.fontId : fontId as String?,
      fontSize: fontSize ?? this.fontSize,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      firstLineIndent: firstLineIndent ?? this.firstLineIndent,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
      themeMode: themeMode ?? this.themeMode,
      paletteId: nextPaletteId,
      lightTextColorArgb: nextLightText,
      lightBackgroundColorArgb: nextLightBackground,
      darkTextColorArgb: nextDarkText,
      darkBackgroundColorArgb: nextDarkBackground,
      backgroundImagePath: identical(backgroundImagePath, _unset)
          ? this.backgroundImagePath
          : backgroundImagePath as String?,
      backgroundImageOpacity:
          backgroundImageOpacity ?? this.backgroundImageOpacity,
      backgroundOverlayOpacity:
          backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
      showTopInfoBar: showTopInfoBar ?? this.showTopInfoBar,
      showBottomInfoBar: showBottomInfoBar ?? this.showBottomInfoBar,
      showProgressInfo: nextChapterProgress && nextWholeBookProgress,
      showSystemStatusBar: nextShowSystemStatusBar,
      hideNavigationBar: hideNavigationBar ?? this.hideNavigationBar,
      extendIntoDisplayCutout:
          (extendIntoDisplayCutout ?? this.extendIntoDisplayCutout) &&
          !nextShowSystemStatusBar,
      screenOrientation: screenOrientation ?? this.screenOrientation,
      statusBarMode: statusBarMode ?? this.statusBarMode,
      timeDisplayMode: timeDisplayMode ?? this.timeDisplayMode,
      showChapterInfo: nextChapterInfo,
      showChapterProgressInfo: nextChapterProgress,
      showClockInfo: showClockInfo ?? this.showClockInfo,
      showWholeBookProgressInfo: nextWholeBookProgress,
      showTopInfoDivider:
          showTopInfoDivider ?? showInfoDivider ?? this.showTopInfoDivider,
      showBottomInfoDivider:
          showBottomInfoDivider ??
          showInfoDivider ??
          this.showBottomInfoDivider,
      showAutoReadMinimalInfo:
          showAutoReadMinimalInfo ?? this.showAutoReadMinimalInfo,
      chapterInfoSlot: chapterInfoSlot ?? this.chapterInfoSlot,
      chapterProgressInfoSlot:
          chapterProgressInfoSlot ?? this.chapterProgressInfoSlot,
      clockInfoSlot: clockInfoSlot ?? this.clockInfoSlot,
      wholeBookProgressInfoSlot:
          wholeBookProgressInfoSlot ?? this.wholeBookProgressInfoSlot,
      infoDividerSlot: infoDividerSlot ?? this.infoDividerSlot,
    );
  }

  Set<ReaderPreferenceChangeKind> changesFrom(ReaderPreferences previous) {
    final result = <ReaderPreferenceChangeKind>{};
    if (fontId != previous.fontId ||
        fontSize != previous.fontSize ||
        letterSpacing != previous.letterSpacing ||
        lineHeight != previous.lineHeight ||
        paragraphSpacing != previous.paragraphSpacing ||
        firstLineIndent != previous.firstLineIndent ||
        paddingTop != previous.paddingTop ||
        paddingBottom != previous.paddingBottom ||
        paddingLeft != previous.paddingLeft ||
        paddingRight != previous.paddingRight) {
      result.add(ReaderPreferenceChangeKind.metrics);
    }
    if (themeMode != previous.themeMode ||
        paletteId != previous.paletteId ||
        lightTextColorArgb != previous.lightTextColorArgb ||
        lightBackgroundColorArgb != previous.lightBackgroundColorArgb ||
        darkTextColorArgb != previous.darkTextColorArgb ||
        darkBackgroundColorArgb != previous.darkBackgroundColorArgb ||
        backgroundImagePath != previous.backgroundImagePath ||
        backgroundImageOpacity != previous.backgroundImageOpacity ||
        backgroundOverlayOpacity != previous.backgroundOverlayOpacity) {
      result.add(ReaderPreferenceChangeKind.paint);
    }
    if (showTopInfoBar != previous.showTopInfoBar ||
        showBottomInfoBar != previous.showBottomInfoBar ||
        showProgressInfo != previous.showProgressInfo ||
        showSystemStatusBar != previous.showSystemStatusBar ||
        hideNavigationBar != previous.hideNavigationBar ||
        extendIntoDisplayCutout != previous.extendIntoDisplayCutout ||
        screenOrientation != previous.screenOrientation ||
        statusBarMode != previous.statusBarMode ||
        timeDisplayMode != previous.timeDisplayMode ||
        showChapterInfo != previous.showChapterInfo ||
        showChapterProgressInfo != previous.showChapterProgressInfo ||
        showClockInfo != previous.showClockInfo ||
        showWholeBookProgressInfo != previous.showWholeBookProgressInfo ||
        showTopInfoDivider != previous.showTopInfoDivider ||
        showBottomInfoDivider != previous.showBottomInfoDivider ||
        showAutoReadMinimalInfo != previous.showAutoReadMinimalInfo ||
        chapterInfoSlot != previous.chapterInfoSlot ||
        chapterProgressInfoSlot != previous.chapterProgressInfoSlot ||
        clockInfoSlot != previous.clockInfoSlot ||
        wholeBookProgressInfoSlot != previous.wholeBookProgressInfoSlot ||
        infoDividerSlot != previous.infoDividerSlot) {
      result.add(ReaderPreferenceChangeKind.display);
    }
    return result;
  }

  static double _valid(double value, double min, double max, double fallback) =>
      value.isFinite && value >= min && value <= max ? value : fallback;

  static int? _validArgb(int? value) =>
      value != null && value >= 0 && value <= 0xffffffff ? value : null;

  static String? _validManagedPath(String? value) {
    final path = value?.trim();
    if (path == null || path.isEmpty || path.contains('..')) return null;
    return path;
  }

  static String? _validFontId(String? value) {
    final id = value?.trim();
    if (id == null || id.isEmpty) return null;
    // Imported fonts use their SHA-256 id; platform/system fonts use a
    // stable namespaced id.  Neither may contain path separators or traversal.
    final valid = RegExp(r'^[A-Za-z0-9._:-]{1,160}$').hasMatch(id);
    return valid && !id.contains('..') ? id : null;
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderPreferences &&
      fontId == other.fontId &&
      fontSize == other.fontSize &&
      letterSpacing == other.letterSpacing &&
      lineHeight == other.lineHeight &&
      paragraphSpacing == other.paragraphSpacing &&
      firstLineIndent == other.firstLineIndent &&
      paddingTop == other.paddingTop &&
      paddingBottom == other.paddingBottom &&
      paddingLeft == other.paddingLeft &&
      paddingRight == other.paddingRight &&
      themeMode == other.themeMode &&
      paletteId == other.paletteId &&
      lightTextColorArgb == other.lightTextColorArgb &&
      lightBackgroundColorArgb == other.lightBackgroundColorArgb &&
      darkTextColorArgb == other.darkTextColorArgb &&
      darkBackgroundColorArgb == other.darkBackgroundColorArgb &&
      backgroundImagePath == other.backgroundImagePath &&
      backgroundImageOpacity == other.backgroundImageOpacity &&
      backgroundOverlayOpacity == other.backgroundOverlayOpacity &&
      showTopInfoBar == other.showTopInfoBar &&
      showBottomInfoBar == other.showBottomInfoBar &&
      showProgressInfo == other.showProgressInfo &&
      showSystemStatusBar == other.showSystemStatusBar &&
      hideNavigationBar == other.hideNavigationBar &&
      extendIntoDisplayCutout == other.extendIntoDisplayCutout &&
      screenOrientation == other.screenOrientation &&
      statusBarMode == other.statusBarMode &&
      timeDisplayMode == other.timeDisplayMode &&
      showChapterInfo == other.showChapterInfo &&
      showChapterProgressInfo == other.showChapterProgressInfo &&
      showClockInfo == other.showClockInfo &&
      showWholeBookProgressInfo == other.showWholeBookProgressInfo &&
      showTopInfoDivider == other.showTopInfoDivider &&
      showBottomInfoDivider == other.showBottomInfoDivider &&
      showAutoReadMinimalInfo == other.showAutoReadMinimalInfo &&
      chapterInfoSlot == other.chapterInfoSlot &&
      chapterProgressInfoSlot == other.chapterProgressInfoSlot &&
      clockInfoSlot == other.clockInfoSlot &&
      wholeBookProgressInfoSlot == other.wholeBookProgressInfoSlot &&
      infoDividerSlot == other.infoDividerSlot;

  @override
  int get hashCode => Object.hashAll([
    fontId,
    fontSize,
    letterSpacing,
    lineHeight,
    paragraphSpacing,
    firstLineIndent,
    paddingTop,
    paddingBottom,
    paddingLeft,
    paddingRight,
    themeMode,
    paletteId,
    lightTextColorArgb,
    lightBackgroundColorArgb,
    darkTextColorArgb,
    darkBackgroundColorArgb,
    backgroundImagePath,
    backgroundImageOpacity,
    backgroundOverlayOpacity,
    showTopInfoBar,
    showBottomInfoBar,
    showProgressInfo,
    showSystemStatusBar,
    hideNavigationBar,
    extendIntoDisplayCutout,
    screenOrientation,
    statusBarMode,
    timeDisplayMode,
    showChapterInfo,
    showChapterProgressInfo,
    showClockInfo,
    showWholeBookProgressInfo,
    showTopInfoDivider,
    showBottomInfoDivider,
    showAutoReadMinimalInfo,
    chapterInfoSlot,
    chapterProgressInfoSlot,
    clockInfoSlot,
    wholeBookProgressInfoSlot,
    infoDividerSlot,
  ]);
}
