/// Strong per-collection ReaderPreferences persistence boundary.
library;

// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';

import '../../domain/reader/reader_preferences.dart';
import '../database/app_database.dart';

final class ReaderPreferencesRepository {
  ReaderPreferencesRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  Future<ReaderPreferences> load(String collectionId) async {
    final row = await (_db.select(
      _db.readerPreferencesRows,
    )..where((t) => t.collectionId.equals(collectionId))).getSingleOrNull();
    return _decode(row);
  }

  Stream<ReaderPreferences> watch(String collectionId) =>
      (_db.select(_db.readerPreferencesRows)
            ..where((t) => t.collectionId.equals(collectionId)))
          .watchSingleOrNull()
          .map(_decode);

  Future<void> update(
    String collectionId,
    ReaderPreferences preferences,
  ) async {
    final safe = ReaderPreferences(
      fontSize: preferences.fontSize,
      letterSpacing: preferences.letterSpacing,
      lineHeight: preferences.lineHeight,
      paragraphSpacing: preferences.paragraphSpacing,
      firstLineIndent: preferences.firstLineIndent,
      paddingTop: preferences.paddingTop,
      paddingBottom: preferences.paddingBottom,
      paddingLeft: preferences.paddingLeft,
      paddingRight: preferences.paddingRight,
      themeMode: preferences.themeMode,
      textColorArgb: preferences.textColorArgb,
      backgroundColorArgb: preferences.backgroundColorArgb,
      backgroundImagePath: preferences.backgroundImagePath,
      backgroundImageOpacity: preferences.backgroundImageOpacity,
      backgroundOverlayOpacity: preferences.backgroundOverlayOpacity,
    );
    await _db
        .into(_db.readerPreferencesRows)
        .insertOnConflictUpdate(
          ReaderPreferencesRowsCompanion(
            collectionId: Value(collectionId),
            fontSize: Value(safe.fontSize),
            letterSpacing: Value(safe.letterSpacing),
            lineHeight: Value(safe.lineHeight),
            paragraphSpacing: Value(safe.paragraphSpacing),
            firstLineIndent: Value(safe.firstLineIndent),
            paddingTop: Value(safe.paddingTop),
            paddingBottom: Value(safe.paddingBottom),
            paddingLeft: Value(safe.paddingLeft),
            paddingRight: Value(safe.paddingRight),
            themeMode: Value(safe.themeMode.name),
            textColorArgb: Value(safe.textColorArgb),
            backgroundColorArgb: Value(safe.backgroundColorArgb),
            backgroundImagePath: Value(safe.backgroundImagePath),
            backgroundImageOpacity: Value(safe.backgroundImageOpacity),
            backgroundOverlayOpacity: Value(safe.backgroundOverlayOpacity),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> resetToDefaults(String collectionId) async {
    await (_db.delete(
      _db.readerPreferencesRows,
    )..where((t) => t.collectionId.equals(collectionId))).go();
  }

  ReaderPreferences _decode(ReaderPreferencesRow? row) {
    if (row == null) return ReaderPreferences.defaults;
    return ReaderPreferences(
      fontSize: row.fontSize,
      letterSpacing: row.letterSpacing,
      lineHeight: row.lineHeight,
      paragraphSpacing: row.paragraphSpacing,
      firstLineIndent: row.firstLineIndent,
      paddingTop: row.paddingTop,
      paddingBottom: row.paddingBottom,
      paddingLeft: row.paddingLeft,
      paddingRight: row.paddingRight,
      themeMode:
          ReaderThemeMode.values
              .where((value) => value.name == row.themeMode)
              .firstOrNull ??
          ReaderPreferences.defaultThemeMode,
      textColorArgb: row.textColorArgb,
      backgroundColorArgb: row.backgroundColorArgb,
      backgroundImagePath: row.backgroundImagePath,
      backgroundImageOpacity: row.backgroundImageOpacity,
      backgroundOverlayOpacity: row.backgroundOverlayOpacity,
    );
  }
}
