/// Strong per-collection ReaderPreferences persistence boundary.
library;

// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';

import '../../domain/reader/reader_preferences.dart';
import '../../domain/reader/reader_palette.dart';
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
      fontId: preferences.fontId,
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
      paletteId: preferences.paletteId,
      lightTextColorArgb: preferences.lightTextColorArgb,
      lightBackgroundColorArgb: preferences.lightBackgroundColorArgb,
      darkTextColorArgb: preferences.darkTextColorArgb,
      darkBackgroundColorArgb: preferences.darkBackgroundColorArgb,
      backgroundImagePath: preferences.backgroundImagePath,
      backgroundImageOpacity: preferences.backgroundImageOpacity,
      backgroundOverlayOpacity: preferences.backgroundOverlayOpacity,
      showTopInfoBar: preferences.showTopInfoBar,
      showBottomInfoBar: preferences.showBottomInfoBar,
      showProgressInfo: preferences.showProgressInfo,
      statusBarMode: preferences.statusBarMode,
      timeDisplayMode: preferences.timeDisplayMode,
      showChapterInfo: preferences.showChapterInfo,
      showChapterProgressInfo: preferences.showChapterProgressInfo,
      showClockInfo: preferences.showClockInfo,
      showWholeBookProgressInfo: preferences.showWholeBookProgressInfo,
      showTopInfoDivider: preferences.showTopInfoDivider,
      showBottomInfoDivider: preferences.showBottomInfoDivider,
      showAutoReadMinimalInfo: preferences.showAutoReadMinimalInfo,
      chapterInfoSlot: preferences.chapterInfoSlot,
      chapterProgressInfoSlot: preferences.chapterProgressInfoSlot,
      clockInfoSlot: preferences.clockInfoSlot,
      wholeBookProgressInfoSlot: preferences.wholeBookProgressInfoSlot,
      infoDividerSlot: preferences.infoDividerSlot,
    );
    await _db
        .into(_db.readerPreferencesRows)
        .insertOnConflictUpdate(
          ReaderPreferencesRowsCompanion(
            collectionId: Value(collectionId),
            fontId: Value(safe.fontId),
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
            paletteId: Value(safe.paletteId.name),
            // Keep schema-7 columns synchronized for downgrade-safe reads and
            // existing diagnostics; canonical values are brightness-specific.
            textColorArgb: Value(safe.lightTextColorArgb),
            backgroundColorArgb: Value(safe.lightBackgroundColorArgb),
            lightTextColorArgb: Value(safe.lightTextColorArgb),
            lightBackgroundColorArgb: Value(safe.lightBackgroundColorArgb),
            darkTextColorArgb: Value(safe.darkTextColorArgb),
            darkBackgroundColorArgb: Value(safe.darkBackgroundColorArgb),
            backgroundImagePath: Value(safe.backgroundImagePath),
            backgroundImageOpacity: Value(safe.backgroundImageOpacity),
            backgroundOverlayOpacity: Value(safe.backgroundOverlayOpacity),
            showTopInfoBar: Value(safe.showTopInfoBar),
            showBottomInfoBar: Value(safe.showBottomInfoBar),
            showProgressInfo: Value(safe.showProgressInfo),
            statusBarMode: Value(safe.statusBarMode.name),
            timeDisplayMode: Value(safe.timeDisplayMode.name),
            showChapterInfo: Value(safe.showChapterInfo),
            showChapterProgressInfo: Value(safe.showChapterProgressInfo),
            showClockInfo: Value(safe.showClockInfo),
            showWholeBookProgressInfo: Value(safe.showWholeBookProgressInfo),
            showInfoDivider: Value(safe.showInfoDivider),
            showTopInfoDivider: Value(safe.showTopInfoDivider),
            showBottomInfoDivider: Value(safe.showBottomInfoDivider),
            showAutoReadMinimalInfo: Value(safe.showAutoReadMinimalInfo),
            chapterInfoSlot: Value(safe.chapterInfoSlot.name),
            chapterProgressInfoSlot: Value(safe.chapterProgressInfoSlot.name),
            clockInfoSlot: Value(safe.clockInfoSlot.name),
            wholeBookProgressInfoSlot: Value(
              safe.wholeBookProgressInfoSlot.name,
            ),
            infoDividerSlot: Value(safe.infoDividerSlot.name),
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
      fontId: row.fontId,
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
      paletteId:
          ReaderPaletteId.values
              .where((value) => value.name == row.paletteId)
              .firstOrNull ??
          ReaderPreferences.defaultPaletteId,
      lightTextColorArgb: row.lightTextColorArgb ?? row.textColorArgb,
      lightBackgroundColorArgb:
          row.lightBackgroundColorArgb ?? row.backgroundColorArgb,
      darkTextColorArgb: row.darkTextColorArgb ?? row.textColorArgb,
      darkBackgroundColorArgb:
          row.darkBackgroundColorArgb ?? row.backgroundColorArgb,
      backgroundImagePath: row.backgroundImagePath,
      backgroundImageOpacity: row.backgroundImageOpacity,
      backgroundOverlayOpacity: row.backgroundOverlayOpacity,
      showTopInfoBar: row.showTopInfoBar,
      showBottomInfoBar: row.showBottomInfoBar,
      showProgressInfo: row.showProgressInfo,
      statusBarMode:
          ReaderStatusBarMode.values
              .where((value) => value.name == row.statusBarMode)
              .firstOrNull ??
          ReaderPreferences.defaultStatusBarMode,
      timeDisplayMode:
          ReaderTimeDisplayMode.values
              .where((value) => value.name == row.timeDisplayMode)
              .firstOrNull ??
          ReaderPreferences.defaultTimeDisplayMode,
      showChapterInfo: row.showChapterInfo,
      showChapterProgressInfo: row.showChapterProgressInfo,
      showClockInfo: row.showClockInfo,
      showWholeBookProgressInfo: row.showWholeBookProgressInfo,
      showTopInfoDivider: row.showTopInfoDivider,
      showBottomInfoDivider: row.showBottomInfoDivider,
      showAutoReadMinimalInfo: row.showAutoReadMinimalInfo,
      chapterInfoSlot: _decodeSlot(
        row.chapterInfoSlot,
        ReaderPreferences.defaultChapterInfoSlot,
      ),
      chapterProgressInfoSlot: _decodeSlot(
        row.chapterProgressInfoSlot,
        ReaderPreferences.defaultChapterProgressInfoSlot,
      ),
      clockInfoSlot: _decodeSlot(
        row.clockInfoSlot,
        ReaderPreferences.defaultClockInfoSlot,
      ),
      wholeBookProgressInfoSlot: _decodeSlot(
        row.wholeBookProgressInfoSlot,
        ReaderPreferences.defaultWholeBookProgressInfoSlot,
      ),
      infoDividerSlot: _decodeSlot(
        row.infoDividerSlot,
        ReaderPreferences.defaultInfoDividerSlot,
      ),
    );
  }

  ReaderInfoSlot _decodeSlot(String value, ReaderInfoSlot fallback) =>
      ReaderInfoSlot.values.firstWhere(
        (slot) => slot.name == value,
        orElse: () => fallback,
      );
}
