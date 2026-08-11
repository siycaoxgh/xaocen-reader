/// Per-book Reader appearance contract (M5.1e.1).
library;

enum ReaderThemeMode { system, light, dark }

enum ReaderPreferenceChangeKind { metrics, paint }

final class ReaderPreferences {
  const ReaderPreferences._({
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
    required this.textColorArgb,
    required this.backgroundColorArgb,
    required this.backgroundImagePath,
    required this.backgroundImageOpacity,
    required this.backgroundOverlayOpacity,
  });

  static const double defaultFontSize = 17;
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
  static const double minFirstLineIndent = 0;
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
  static const double defaultBackgroundImageOpacity = 1;
  static const double defaultBackgroundOverlayOpacity = 0.45;
  static const double minAppearanceOpacity = 0;
  static const double maxAppearanceOpacity = 1;

  static const ReaderPreferences defaults = ReaderPreferences._(
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
    textColorArgb: null,
    backgroundColorArgb: null,
    backgroundImagePath: null,
    backgroundImageOpacity: defaultBackgroundImageOpacity,
    backgroundOverlayOpacity: defaultBackgroundOverlayOpacity,
  );

  factory ReaderPreferences({
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
    int? textColorArgb,
    int? backgroundColorArgb,
    String? backgroundImagePath,
    double backgroundImageOpacity = defaultBackgroundImageOpacity,
    double backgroundOverlayOpacity = defaultBackgroundOverlayOpacity,
  }) => ReaderPreferences._(
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
    textColorArgb: _validArgb(textColorArgb),
    backgroundColorArgb: _validArgb(backgroundColorArgb),
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
  );

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
  final int? textColorArgb;
  final int? backgroundColorArgb;
  final String? backgroundImagePath;
  final double backgroundImageOpacity;
  final double backgroundOverlayOpacity;

  bool get hasCustomAppearance =>
      textColorArgb != null ||
      backgroundColorArgb != null ||
      backgroundImagePath != null;

  static const Object _unset = Object();

  ReaderPreferences copyWith({
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
    Object? textColorArgb = _unset,
    Object? backgroundColorArgb = _unset,
    Object? backgroundImagePath = _unset,
    double? backgroundImageOpacity,
    double? backgroundOverlayOpacity,
  }) => ReaderPreferences(
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
    textColorArgb: identical(textColorArgb, _unset)
        ? this.textColorArgb
        : textColorArgb as int?,
    backgroundColorArgb: identical(backgroundColorArgb, _unset)
        ? this.backgroundColorArgb
        : backgroundColorArgb as int?,
    backgroundImagePath: identical(backgroundImagePath, _unset)
        ? this.backgroundImagePath
        : backgroundImagePath as String?,
    backgroundImageOpacity:
        backgroundImageOpacity ?? this.backgroundImageOpacity,
    backgroundOverlayOpacity:
        backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
  );

  Set<ReaderPreferenceChangeKind> changesFrom(ReaderPreferences previous) {
    final result = <ReaderPreferenceChangeKind>{};
    if (fontSize != previous.fontSize ||
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
        textColorArgb != previous.textColorArgb ||
        backgroundColorArgb != previous.backgroundColorArgb ||
        backgroundImagePath != previous.backgroundImagePath ||
        backgroundImageOpacity != previous.backgroundImageOpacity ||
        backgroundOverlayOpacity != previous.backgroundOverlayOpacity) {
      result.add(ReaderPreferenceChangeKind.paint);
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

  @override
  bool operator ==(Object other) =>
      other is ReaderPreferences &&
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
      textColorArgb == other.textColorArgb &&
      backgroundColorArgb == other.backgroundColorArgb &&
      backgroundImagePath == other.backgroundImagePath &&
      backgroundImageOpacity == other.backgroundImageOpacity &&
      backgroundOverlayOpacity == other.backgroundOverlayOpacity;

  @override
  int get hashCode => Object.hashAll([
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
    textColorArgb,
    backgroundColorArgb,
    backgroundImagePath,
    backgroundImageOpacity,
    backgroundOverlayOpacity,
  ]);
}
