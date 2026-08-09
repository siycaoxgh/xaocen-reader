import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/app.dart';

void main() {
  test(
    'App shell follows system; per-book theme is resolved inside Reader',
    () {
      expect(XaocenApp.appThemeMode, ThemeMode.system);
    },
  );
}
