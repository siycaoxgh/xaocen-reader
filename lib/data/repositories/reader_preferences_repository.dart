/// Strong per-collection ReaderPreferences persistence boundary.
library;

// ignore_for_file: prefer_initializing_formals

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
    );
    await _db
        .into(_db.readerPreferencesRows)
        .insertOnConflictUpdate(
          ReaderPreferencesRowsCompanion.insert(
            collectionId: collectionId,
            fontSize: safe.fontSize,
            letterSpacing: safe.letterSpacing,
            lineHeight: safe.lineHeight,
            paragraphSpacing: safe.paragraphSpacing,
            firstLineIndent: safe.firstLineIndent,
            paddingTop: safe.paddingTop,
            paddingBottom: safe.paddingBottom,
            paddingLeft: safe.paddingLeft,
            paddingRight: safe.paddingRight,
            themeMode: safe.themeMode.name,
            updatedAt: DateTime.now(),
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
    );
  }
}
