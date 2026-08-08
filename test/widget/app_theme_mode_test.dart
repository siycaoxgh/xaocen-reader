import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/app.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reader_preferences_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';

void main() {
  late AppDatabase db;
  late Directory libraryRoot;
  late ProviderContainer container;
  late ReaderPreferencesRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting();
    libraryRoot = await Directory.systemTemp.createTemp('m51c_app_theme');
    repository = ReaderPreferencesRepository(db: db);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        fileManagerProvider.overrideWithValue(
          LibraryFileManager(libraryRoot: libraryRoot),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (await libraryRoot.exists()) await libraryRoot.delete(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const XaocenApp()),
    );
    await tester.pump();
    await tester.pump();
  }

  ThemeMode currentMode(WidgetTester tester) {
    return tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
  }

  Future<void> pumpThemeChange(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('system → light → dark → system 实时生效', (tester) async {
    await pumpApp(tester);
    expect(currentMode(tester), ThemeMode.system);

    await repository.update(
      ReaderPreferences.defaults.copyWith(themeMode: ReaderThemeMode.light),
    );
    await pumpThemeChange(tester);
    expect(currentMode(tester), ThemeMode.light);

    await repository.update(
      ReaderPreferences.defaults.copyWith(themeMode: ReaderThemeMode.dark),
    );
    await pumpThemeChange(tester);
    expect(currentMode(tester), ThemeMode.dark);
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);

    await repository.update(ReaderPreferences.defaults);
    await pumpThemeChange(tester);
    expect(currentMode(tester), ThemeMode.system);
  });

  testWidgets('App 重建后持久化主题仍生效', (tester) async {
    await repository.update(
      ReaderPreferences.defaults.copyWith(themeMode: ReaderThemeMode.dark),
    );
    await pumpApp(tester);
    expect(currentMode(tester), ThemeMode.dark);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpApp(tester);
    expect(currentMode(tester), ThemeMode.dark);
  });
}
