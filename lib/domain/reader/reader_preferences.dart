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
    if (themeMode != previous.themeMode) {
      result.add(ReaderPreferenceChangeKind.paint);
    }
    return result;
  }

  static double _valid(double value, double min, double max, double fallback) =>
      value.isFinite && value >= min && value <= max ? value : fallback;

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
      themeMode == other.themeMode;

  @override
  int get hashCode => Object.hash(
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
  );
}
