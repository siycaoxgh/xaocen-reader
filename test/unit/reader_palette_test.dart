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

  test('resolver uses custom override only for the selected brightness', () {
    final light = ReaderPaletteResolver.resolve(
      paletteId: ReaderPaletteId.paperWhite,
      dark: false,
      lightTextArgb: 0xff123456,
      darkTextArgb: 0xffabcdef,
    );
    final dark = ReaderPaletteResolver.resolve(
      paletteId: ReaderPaletteId.paperWhite,
      dark: true,
      lightTextArgb: 0xff123456,
      darkTextArgb: 0xffabcdef,
    );
    expect(light.textArgb, 0xff123456);
    expect(dark.textArgb, 0xffabcdef);
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
}
