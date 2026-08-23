import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/app.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/domain/app_theme_mode.dart';

void main() {
  testWidgets('App Settings theme switches the shell live and persists', (
    tester,
  ) async {
    final database = AppDatabase.forTesting();
    final libraryRoot = Directory.systemTemp.createTempSync('xaocen_theme_');
    addTearDown(() {
      database.close();
      libraryRoot.deleteSync(recursive: true);
    });
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        fileManagerProvider.overrideWithValue(
          LibraryFileManager(libraryRoot: libraryRoot),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const XaocenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await container.read(appThemeModeProvider.notifier).setMode(
      AppThemeMode.dark,
    );
    await tester.pumpAndSettle();
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark);

    await container.read(appThemeModeProvider.notifier).setMode(
      AppThemeMode.light,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    expect(await container.read(appThemePreferencesRepositoryProvider).load(),
        AppThemeMode.light);
  });
}
