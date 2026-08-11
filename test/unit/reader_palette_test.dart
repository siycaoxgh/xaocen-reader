import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/design/theme/app_theme.dart';
import 'package:xaocen_reader/domain/reader/reader_palette.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/reader/reader_appearance.dart';

void main() {
  test('all bundled palettes provide readable light and dark pairs', () {
    expect(ReaderPalette.presets, hasLength(6));
    for (final palette in ReaderPalette.presets) {
      expect(
        isReadable(
          Color(palette.light.textArgb),
          Color(palette.light.backgroundArgb),
        ),
        isTrue,
      );
      expect(
        isReadable(
          Color(palette.dark.textArgb),
          Color(palette.dark.backgroundArgb),
        ),
        isTrue,
      );
    }
  });

  test('preset backgrounds remain visibly distinct in both brightnesses', () {
    final lightBackgrounds = ReaderPalette.presets
        .map((palette) => palette.light.backgroundArgb)
        .toSet();
    final darkBackgrounds = ReaderPalette.presets
        .map((palette) => palette.dark.backgroundArgb)
        .toSet();
    expect(lightBackgrounds, hasLength(6));
    expect(darkBackgrounds, hasLength(6));
    expect(ReaderPalette.inkBlack.light.backgroundArgb, 0xff000000);
    expect(ReaderPalette.inkBlack.dark.backgroundArgb, 0xff000000);
  });

  test('resolver uses custom override only for the selected brightness', () {
    final light = ReaderPaletteResolver.resolve(
      paletteId: ReaderPaletteId.custom,
      dark: false,
      lightTextArgb: 0xff123456,
      darkTextArgb: 0xffabcdef,
    );
    final dark = ReaderPaletteResolver.resolve(
      paletteId: ReaderPaletteId.custom,
      dark: true,
      lightTextArgb: 0xff123456,
      darkTextArgb: 0xffabcdef,
    );
    expect(light.textArgb, 0xff123456);
    expect(dark.textArgb, 0xffabcdef);
  });

  test('preset selection cannot be masked by retained custom overrides', () {
    final colors = ReaderPaletteResolver.resolve(
      paletteId: ReaderPaletteId.inkBlack,
      dark: true,
      darkTextArgb: 0xff123456,
      darkBackgroundArgb: 0xffabcdef,
    );
    expect(colors.textArgb, ReaderPalette.inkBlack.dark.textArgb);
    expect(colors.backgroundArgb, ReaderPalette.inkBlack.dark.backgroundArgb);
  });

  test('custom mode can retain independent light and dark overrides', () {
    final light = ReaderPaletteResolver.resolve(
      paletteId: ReaderPaletteId.custom,
      dark: false,
      lightTextArgb: 0xff123456,
      lightBackgroundArgb: 0xffabcdef,
    );
    final dark = ReaderPaletteResolver.resolve(
      paletteId: ReaderPaletteId.custom,
      dark: true,
      lightTextArgb: 0xff123456,
      lightBackgroundArgb: 0xffabcdef,
    );
    expect(light.textArgb, 0xff123456);
    expect(light.backgroundArgb, 0xffabcdef);
    expect(dark.textArgb, ReaderPalette.paperWhite.dark.textArgb);
    expect(dark.backgroundArgb, ReaderPalette.paperWhite.dark.backgroundArgb);
  });

  test('浅灰 is the neutral light-gray preset label', () {
    expect(ReaderPalette.night.label, '浅灰');
  });

  testWidgets('appearance resolver honors the effective Reader theme', (
    tester,
  ) async {
    ReaderResolvedAppearance? appearance;
    final prefs = ReaderPreferences.defaults.copyWith(
      lightTextColorArgb: 0xff123456,
      darkTextColorArgb: 0xffabcdef,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            appearance = resolveReaderAppearance(
              context,
              theme: AppTheme.dark(),
              preferences: prefs,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(appearance!.textColor.toARGB32(), 0xffabcdef);
  });

  testWidgets('appearance resolver paints the selected preset variant', (
    tester,
  ) async {
    ReaderResolvedAppearance? lightInk;
    ReaderResolvedAppearance? darkGray;
    final ink = ReaderPreferences.defaults.copyWith(
      paletteId: ReaderPaletteId.inkBlack,
    );
    final gray = ReaderPreferences.defaults.copyWith(
      paletteId: ReaderPaletteId.night,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            lightInk = resolveReaderAppearance(
              context,
              theme: AppTheme.light(),
              preferences: ink,
            );
            darkGray = resolveReaderAppearance(
              context,
              theme: AppTheme.dark(),
              preferences: gray,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(lightInk!.backgroundColor.toARGB32(), 0xff000000);
    expect(lightInk!.textColor.toARGB32(), 0xfff2f2f2);
    expect(darkGray!.backgroundColor.toARGB32(), 0xff4a4a4a);
  });
}
