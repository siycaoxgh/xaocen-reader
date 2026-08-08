/// ReaderPreferences —— 全局阅读外观设置的强类型合同（M5.1a）。
///
/// 本模型不包含 readingMode；滚动/分页模式仍按书保存在
/// ReaderProgressState 中。它也不包含任何位置字段：ReaderLocator 的
/// normalized.txt UTF-16 code-unit offset 仍是唯一阅读位置真源。
library;

/// Reader 主题模式。
enum ReaderThemeMode { system, light, dark }

/// 设置变化对渲染管线的影响类别。
enum ReaderPreferenceChangeKind {
  /// 会改变文本度量、可用正文区域或分页边界。
  metrics,

  /// 仅改变颜色绘制；不应触发布局或分页。
  paint,
}

/// 全局 Reader 设置。
final class ReaderPreferences {
  const ReaderPreferences._({
    required this.fontSize,
    required this.lineHeight,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.themeMode,
  });

  static const double defaultFontSize = 17;
  static const double minFontSize = 12;
  static const double maxFontSize = 32;

  static const double defaultLineHeight = 1.7;
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.4;

  static const double defaultHorizontalPadding = 16;
  static const double minHorizontalPadding = 0;
  static const double maxHorizontalPadding = 64;

  static const double defaultVerticalPadding = 8;
  static const double minVerticalPadding = 0;
  static const double maxVerticalPadding = 48;

  static const ReaderThemeMode defaultThemeMode = ReaderThemeMode.system;

  static const ReaderPreferences defaults = ReaderPreferences._(
    fontSize: defaultFontSize,
    lineHeight: defaultLineHeight,
    horizontalPadding: defaultHorizontalPadding,
    verticalPadding: defaultVerticalPadding,
    themeMode: defaultThemeMode,
  );

  /// 建立合法设置；每个非法字段独立回退默认值。
  factory ReaderPreferences({
    double fontSize = defaultFontSize,
    double lineHeight = defaultLineHeight,
    double horizontalPadding = defaultHorizontalPadding,
    double verticalPadding = defaultVerticalPadding,
    ReaderThemeMode themeMode = defaultThemeMode,
  }) {
    return ReaderPreferences._(
      fontSize: _validDouble(
        fontSize,
        min: minFontSize,
        max: maxFontSize,
        fallback: defaultFontSize,
      ),
      lineHeight: _validDouble(
        lineHeight,
        min: minLineHeight,
        max: maxLineHeight,
        fallback: defaultLineHeight,
      ),
      horizontalPadding: _validDouble(
        horizontalPadding,
        min: minHorizontalPadding,
        max: maxHorizontalPadding,
        fallback: defaultHorizontalPadding,
      ),
      verticalPadding: _validDouble(
        verticalPadding,
        min: minVerticalPadding,
        max: maxVerticalPadding,
        fallback: defaultVerticalPadding,
      ),
      themeMode: themeMode,
    );
  }

  final double fontSize;
  final double lineHeight;
  final double horizontalPadding;
  final double verticalPadding;
  final ReaderThemeMode themeMode;

  ReaderPreferences copyWith({
    double? fontSize,
    double? lineHeight,
    double? horizontalPadding,
    double? verticalPadding,
    ReaderThemeMode? themeMode,
  }) {
    return ReaderPreferences(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      verticalPadding: verticalPadding ?? this.verticalPadding,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  /// 与旧值相比需要执行的渲染工作。
  Set<ReaderPreferenceChangeKind> changesFrom(ReaderPreferences previous) {
    final changes = <ReaderPreferenceChangeKind>{};
    if (fontSize != previous.fontSize ||
        lineHeight != previous.lineHeight ||
        horizontalPadding != previous.horizontalPadding ||
        verticalPadding != previous.verticalPadding) {
      changes.add(ReaderPreferenceChangeKind.metrics);
    }
    if (themeMode != previous.themeMode) {
      changes.add(ReaderPreferenceChangeKind.paint);
    }
    return changes;
  }

  static double _validDouble(
    double value, {
    required double min,
    required double max,
    required double fallback,
  }) {
    if (!value.isFinite || value < min || value > max) return fallback;
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderPreferences &&
          fontSize == other.fontSize &&
          lineHeight == other.lineHeight &&
          horizontalPadding == other.horizontalPadding &&
          verticalPadding == other.verticalPadding &&
          themeMode == other.themeMode;

  @override
  int get hashCode => Object.hash(
    fontSize,
    lineHeight,
    horizontalPadding,
    verticalPadding,
    themeMode,
  );
}
