import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:xaocen_reader/design/theme/app_theme.dart';
import 'package:xaocen_reader/design/theme/app_typography.dart';

void main() {
  test('AppTypography applies the shared fallback and semantic weights', () {
    final theme = AppTheme.light();
    final title = theme.textTheme.titleLarge!;
    final body = theme.textTheme.bodyMedium!;

    expect(title.fontFamilyFallback, AppTypography.fontFamilyFallback);
    expect(title.fontWeight, FontWeight.w600);
    expect(body.fontFamilyFallback, AppTypography.fontFamilyFallback);
    expect(body.fontWeight, FontWeight.w400);
  });

  test('ReaderTypography keeps the platform default as its primary face', () {
    final style = ReaderTypography.body(
      fontSize: 18,
      lineHeight: 1.7,
      letterSpacing: 0,
      color: const Color(0xff222222),
    );

    expect(style.fontFamily, isNull);
    expect(style.fontFamilyFallback, AppTypography.fontFamilyFallback);
  });
}
