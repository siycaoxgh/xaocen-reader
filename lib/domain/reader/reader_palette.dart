/// Bundled Reader palettes and their light/dark color pairs.
///
/// A palette is a paint-only base. Per-book custom colors are applied by the
/// resolver and never participate in text metrics or Locator persistence.
library;

enum ReaderPaletteId {
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
      backgroundArgb: 0xffffffff,
    ),
    dark: ReaderPaletteColors(textArgb: 0xfff4f1ea, backgroundArgb: 0xff242424),
  );
  static const warmYellow = ReaderPalette(
    id: ReaderPaletteId.warmYellow,
    label: '暖黄',
    light: ReaderPaletteColors(
      textArgb: 0xff4b3425,
      backgroundArgb: 0xfffff8e7,
    ),
    dark: ReaderPaletteColors(textArgb: 0xfff5e8c8, backgroundArgb: 0xff2b251b),
  );
  static const tealGreen = ReaderPalette(
    id: ReaderPaletteId.tealGreen,
    label: '青绿',
    light: ReaderPaletteColors(
      textArgb: 0xff19342a,
      backgroundArgb: 0xffe8f2ec,
    ),
    dark: ReaderPaletteColors(textArgb: 0xffd8f0e3, backgroundArgb: 0xff182823),
  );
  static const cyanBlue = ReaderPalette(
    id: ReaderPaletteId.cyanBlue,
    label: '青蓝',
    light: ReaderPaletteColors(
      textArgb: 0xff17313a,
      backgroundArgb: 0xffe9f3f8,
    ),
    dark: ReaderPaletteColors(textArgb: 0xffd8eef5, backgroundArgb: 0xff17262c),
  );
  static const night = ReaderPalette(
    id: ReaderPaletteId.night,
    label: '夜间',
    light: ReaderPaletteColors(
      textArgb: 0xff303238,
      backgroundArgb: 0xfff1f1f1,
    ),
    dark: ReaderPaletteColors(textArgb: 0xffe6e6e6, backgroundArgb: 0xff202124),
  );
  static const inkBlack = ReaderPalette(
    id: ReaderPaletteId.inkBlack,
    label: '墨黑',
    light: ReaderPaletteColors(
      textArgb: 0xff101010,
      backgroundArgb: 0xfff5f5f5,
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
    final palette = ReaderPalette.fromId(paletteId);
    final base = dark ? palette.dark : palette.light;
    return ReaderPaletteColors(
      textArgb: dark
          ? darkTextArgb ?? base.textArgb
          : lightTextArgb ?? base.textArgb,
      backgroundArgb: dark
          ? darkBackgroundArgb ?? base.backgroundArgb
          : lightBackgroundArgb ?? base.backgroundArgb,
    );
  }
}
