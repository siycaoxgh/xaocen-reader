/// Bundled Reader palettes and their light/dark color pairs.
///
/// A palette is a paint-only base. Per-book custom colors are applied by the
/// resolver and never participate in text metrics or Locator persistence.
library;

enum ReaderPaletteId {
  /// Explicit custom mode. Stored light/dark overrides are authoritative
  /// only while this value is selected.
  custom,
  paperWhite,
  warmYellow,
  tealGreen,
  cyanBlue,
  night,
  inkBlack,
}

final class ReaderPaletteColors {
  const ReaderPaletteColors({
    required this.textArgb,
    required this.backgroundArgb,
  });

  final int textArgb;
  final int backgroundArgb;
}

final class ReaderPalette {
  const ReaderPalette({
    required this.id,
    required this.label,
    required this.light,
    required this.dark,
  });

  final ReaderPaletteId id;
  final String label;
  final ReaderPaletteColors light;
  final ReaderPaletteColors dark;

  static const paperWhite = ReaderPalette(
    id: ReaderPaletteId.paperWhite,
    label: '纸白',
    light: ReaderPaletteColors(
      textArgb: 0xff1c1b1f,
      backgroundArgb: 0xfffffdf8,
    ),
    dark: ReaderPaletteColors(textArgb: 0xfff4f1ea, backgroundArgb: 0xff242424),
  );
  static const warmYellow = ReaderPalette(
    id: ReaderPaletteId.warmYellow,
    label: '暖黄',
    light: ReaderPaletteColors(
      textArgb: 0xff3b2a1b,
      backgroundArgb: 0xfffff1c2,
    ),
    dark: ReaderPaletteColors(textArgb: 0xfffff1c2, backgroundArgb: 0xff3b2d18),
  );
  static const tealGreen = ReaderPalette(
    id: ReaderPaletteId.tealGreen,
    label: '青绿',
    light: ReaderPaletteColors(
      textArgb: 0xff17362a,
      backgroundArgb: 0xffcbe8d8,
    ),
    dark: ReaderPaletteColors(textArgb: 0xffcbe8d8, backgroundArgb: 0xff16372a),
  );
  static const cyanBlue = ReaderPalette(
    id: ReaderPaletteId.cyanBlue,
    label: '青蓝',
    light: ReaderPaletteColors(
      textArgb: 0xff17313a,
      backgroundArgb: 0xffc7e7f2,
    ),
    dark: ReaderPaletteColors(textArgb: 0xffc7e7f2, backgroundArgb: 0xff16323c),
  );
  static const night = ReaderPalette(
    id: ReaderPaletteId.night,
    label: '浅灰',
    light: ReaderPaletteColors(
      textArgb: 0xff303238,
      backgroundArgb: 0xffd9d9d9,
    ),
    dark: ReaderPaletteColors(textArgb: 0xfff0f0f0, backgroundArgb: 0xff4a4a4a),
  );
  static const inkBlack = ReaderPalette(
    id: ReaderPaletteId.inkBlack,
    label: '墨黑',
    light: ReaderPaletteColors(
      textArgb: 0xfff2f2f2,
      backgroundArgb: 0xff000000,
    ),
    dark: ReaderPaletteColors(textArgb: 0xfff2f2f2, backgroundArgb: 0xff000000),
  );

  static const presets = <ReaderPalette>[
    paperWhite,
    warmYellow,
    tealGreen,
    cyanBlue,
    night,
    inkBlack,
  ];

  static ReaderPalette fromId(ReaderPaletteId id) => presets.firstWhere(
    (palette) => palette.id == id,
    orElse: () => paperWhite,
  );
}

final class ReaderPaletteResolver {
  const ReaderPaletteResolver._();

  static ReaderPaletteColors resolve({
    required ReaderPaletteId paletteId,
    required bool dark,
    int? lightTextArgb,
    int? lightBackgroundArgb,
    int? darkTextArgb,
    int? darkBackgroundArgb,
  }) {
    // Presets and custom colors are mutually exclusive paint sources.
    // Custom mode falls back to the neutral paper-white pair for a brightness
    // without an explicit override.
    final palette = ReaderPalette.fromId(
      paletteId == ReaderPaletteId.custom
          ? ReaderPaletteId.paperWhite
          : paletteId,
    );
    final base = dark ? palette.dark : palette.light;
    final useCustom = paletteId == ReaderPaletteId.custom;
    return ReaderPaletteColors(
      textArgb: useCustom && dark
          ? darkTextArgb ?? base.textArgb
          : useCustom && !dark
          ? lightTextArgb ?? base.textArgb
          : base.textArgb,
      backgroundArgb: useCustom && dark
          ? darkBackgroundArgb ?? base.backgroundArgb
          : useCustom && !dark
          ? lightBackgroundArgb ?? base.backgroundArgb
          : base.backgroundArgb,
    );
  }
}
