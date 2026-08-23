import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import '../data_root.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// XAOCEN v4 本地数据库 —— 最小 schemaVersion 1。
///
/// 规则：foreign_keys 开启；索引见 [AppDatabase] 构造；
/// 正文不写入 SQLite（只存路径与偏移）。
@DriftDatabase(
  tables: [
    ContentSources,
    ContentCollections,
    ContentItems,
    ContentDocuments,
    TocEntries,
    ImportRecords,
    ReadingProgress,
    AppSettings,
    ReaderPreferencesRows,
    ReaderFontAssetRows,
    ReaderBookmarks,
    ReadingHistory,
    ReadingSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {this.dataRootLease});

  final DataRootLease? dataRootLease;

  /// 内存测试库。
  AppDatabase.forTesting()
    : dataRootLease = null,
      super(NativeDatabase.memory());

  @override
  int get schemaVersion => 21;

  /// 打开应用数据库（support 目录下）。
  static Future<AppDatabase> open({DataRoot? dataRoot}) async {
    final root = dataRoot ?? await DataRoot.standard();
    final lease = await root.acquireLease();
    try {
      return AppDatabase(
        NativeDatabase(root.databaseFile),
        dataRootLease: lease,
      );
    } catch (_) {
      await lease.release();
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await super.close();
    await dataRootLease?.release();
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes(customStatement);
      await _createM52Indexes(customStatement);
      await _createFontIndexes(customStatement);
    },
    onUpgrade: (m, from, to) async {
      Future<bool> hasReaderPreferenceColumn(String name) async {
        final rows = await customSelect(
          'PRAGMA table_info(reader_preferences)',
        ).get();
        return rows.any((row) => row.data['name'] == name);
      }

      Future<bool> hasCollectionColumn(String name) async {
        final rows = await customSelect(
          'PRAGMA table_info(content_collections)',
        ).get();
        return rows.any((row) => row.data['name'] == name);
      }

      Future<bool> hasTable(String name) async {
        final rows = await customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = '$name'",
        ).get();
        return rows.isNotEmpty;
      }

      // schema 1 → 2：仅新增 reading_progress 表，不触碰 M2 既有数据。
      if (from < 2) {
        await m.createTable(readingProgress);
        await _createIndexes(customStatement);
      }
      // schema 2 → 3：reading_progress 新增 readingMode 列
      // （阅读表现状态，旧数据默认 'vertical'）。
      // 从 schema 1 直接跨级升级时，上面的 createTable 会按“当前表定义”
      // 创建 readingMode；只有真实 schema 2 旧表才需要 addColumn。
      if (from == 2) {
        await m.addColumn(readingProgress, readingProgress.readingMode);
      }
      // schema 3 → 4：仅新增 app_settings，不触碰书库、managed TXT、
      // reading_progress、readingMode 或 ReaderLocator。
      if (from < 4) {
        await m.createTable(appSettings);
      }
      if (from < 5) {
        await m.createTable(readerPreferencesRows);
        // Preserve legacy global M5.1a-e values by seeding every existing book.
        // Invalid values remain harmless: the repository validates every field.
        final hasCollectionsTable =
            await customSelect(
              "SELECT 1 FROM sqlite_master "
              "WHERE type = 'table' AND name = 'content_collections'",
            ).getSingleOrNull() !=
            null;
        if (hasCollectionsTable) {
          await customStatement('''
          INSERT INTO reader_preferences (
            collection_id, font_size, letter_spacing, line_height,
            paragraph_spacing, first_line_indent, padding_top, padding_bottom,
            padding_left, padding_right, theme_mode, updated_at
          )
          SELECT id,
            COALESCE((SELECT CAST(value AS REAL) FROM app_settings WHERE key='reader.fontSize'), 17),
            0,
            COALESCE((SELECT CAST(value AS REAL) FROM app_settings WHERE key='reader.lineHeight'), 1.7),
            0, 0,
            COALESCE((SELECT CAST(value AS REAL) FROM app_settings WHERE key='reader.verticalPadding'), 8),
            COALESCE((SELECT CAST(value AS REAL) FROM app_settings WHERE key='reader.verticalPadding'), 8),
            COALESCE((SELECT CAST(value AS REAL) FROM app_settings WHERE key='reader.horizontalPadding'), 16),
            COALESCE((SELECT CAST(value AS REAL) FROM app_settings WHERE key='reader.horizontalPadding'), 16),
            COALESCE((SELECT value FROM app_settings WHERE key='reader.themeMode'), 'system'),
            CAST(strftime('%s','now') AS INTEGER)
          FROM content_collections
        ''');
        }
      }
      if (from < 6) {
        await m.createTable(readerBookmarks);
        await m.createTable(readingHistory);
        await m.createTable(readingSessions);
        await _createM52Indexes(customStatement);
      }
      // schema <5 creates the current table definition above, so only real
      // schema 5/6 databases need the five appearance columns added.
      if (from >= 5 && from < 7) {
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.textColorArgb,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.backgroundColorArgb,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.backgroundImagePath,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.backgroundImageOpacity,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.backgroundOverlayOpacity,
        );
      }
      // schema 7 → 8: add palette identity and independent light/dark custom
      // overrides. Legacy single-pair colors are copied to both brightnesses
      // so existing books retain their exact appearance.
      if (from >= 5 && from < 8) {
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.paletteId,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.lightTextColorArgb,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.lightBackgroundColorArgb,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.darkTextColorArgb,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.darkBackgroundColorArgb,
        );
        await customStatement('''
          UPDATE reader_preferences
          SET light_text_color_argb = text_color_argb,
              light_background_color_argb = background_color_argb,
              dark_text_color_argb = text_color_argb,
              dark_background_color_argb = background_color_argb,
              palette_id = CASE
                WHEN text_color_argb IS NOT NULL
                  OR background_color_argb IS NOT NULL
                THEN 'custom'
                ELSE palette_id
              END
        ''');
      }
      // schema 8 → 9: per-book Reader display preferences.  These values are
      // transient presentation choices only; no Locator/progress columns are
      // changed and all existing books receive the explicit defaults.
      if (from >= 5 && from < 9) {
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showTopInfoBar,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showBottomInfoBar,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showProgressInfo,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.statusBarMode,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.timeDisplayMode,
        );
      }
      // schema 9 → 10: fixed-slot minimal Reader information preferences.
      // Existing showProgressInfo is copied to both progress item toggles so
      // an explicit legacy hide choice is preserved during migration.
      if (from >= 5 && from < 10) {
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showChapterInfo,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showChapterProgressInfo,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showClockInfo,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showWholeBookProgressInfo,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showInfoDivider,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.chapterInfoSlot,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.chapterProgressInfoSlot,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.clockInfoSlot,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.wholeBookProgressInfoSlot,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.infoDividerSlot,
        );
        await customStatement('''
          UPDATE reader_preferences
          SET show_chapter_progress_info = show_progress_info,
              show_whole_book_progress_info = show_progress_info
        ''');
      }
      // schema 10 → 11: per-book control for whether the transient minimal
      // information layer remains visible while AutoRead hides the chrome.
      // Existing books keep the enabled default; no position or session data
      // is touched.
      if (from >= 5 && from < 11) {
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showAutoReadMinimalInfo,
        );
      }
      // schema 11 → 12: app-managed font metadata plus a nullable per-book
      // font identity. Existing books remain on systemDefault (null).
      if (from < 12) {
        await m.createTable(readerFontAssetRows);
        await _createFontIndexes(customStatement);
      }
      if (from >= 5 && from < 12) {
        await m.addColumn(readerPreferencesRows, readerPreferencesRows.fontId);
      }
      // schema 12 -> 13: independent top and bottom Reader info dividers.
      // Existing single-divider preference is copied to both sides so no
      // user's prior visibility choice is lost.
      if (from >= 5 && from < 13) {
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showTopInfoDivider,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showBottomInfoDivider,
        );
        await customStatement('''
          UPDATE reader_preferences
          SET show_top_info_divider = show_info_divider,
              show_bottom_info_divider = show_info_divider
        ''');
      }
      // schema 13 -> 14: split Android OS status-bar visibility from the
      // legacy statusBarMode value, which also used to gate Reader info.
      // Preserve old semantics: system => visible, readerInfo/hidden => off.
      if (from >= 5 && from < 14) {
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.showSystemStatusBar,
        );
        await customStatement('''
          UPDATE reader_preferences
          SET show_system_status_bar = CASE
            WHEN status_bar_mode = 'system' THEN 1
            ELSE 0
          END,
          show_top_info_bar = CASE
            WHEN status_bar_mode = 'hidden' THEN 0
            ELSE show_top_info_bar
          END,
          show_bottom_info_bar = CASE
            WHEN status_bar_mode = 'hidden' THEN 0
            ELSE show_bottom_info_bar
          END
        ''');
      }
      // schema 14 -> 15: independent Android navigation-bar, display-cutout,
      // and screen-orientation preferences. These are per-book presentation
      // choices only; no Locator/progress data is changed.
      if (from >= 5 && from < 15) {
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.hideNavigationBar,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.extendIntoDisplayCutout,
        );
        await m.addColumn(
          readerPreferencesRows,
          readerPreferencesRows.screenOrientation,
        );
      }
      // schema 15 -> 16: optional device-battery Reader information item.
      // Existing books keep their current slots and do not gain a new visible
      // item unexpectedly; new/default preferences enable bottom-center.
      if (from >= 5 && from < 16) {
        if (!await hasReaderPreferenceColumn('show_battery_info')) {
          await m.addColumn(
            readerPreferencesRows,
            readerPreferencesRows.showBatteryInfo,
          );
        }
        if (!await hasReaderPreferenceColumn('battery_info_slot')) {
          await m.addColumn(
            readerPreferencesRows,
            readerPreferencesRows.batteryInfoSlot,
          );
        }
        if (await hasReaderPreferenceColumn('show_battery_info')) {
          await customStatement(
            'UPDATE reader_preferences SET show_battery_info = 0',
          );
        }
      }
      // schema 16 -> 17: per-book paragraph alignment. Existing books keep
      // the historical left-aligned rendering contract.
      if (from >= 5 && from < 17) {
        if (!await hasReaderPreferenceColumn('text_alignment')) {
          await m.addColumn(
            readerPreferencesRows,
            readerPreferencesRows.textAlignment,
          );
        }
      }
      // schema 17 -> 18: Reader screen-awake policy. These are per-book
      // presentation preferences only; no Locator, progress, or session data
      // is changed. Existing books receive follow-system/30-minute defaults.
      if (from >= 5 && from < 18) {
        if (!await hasReaderPreferenceColumn('screen_awake_mode')) {
          await m.addColumn(
            readerPreferencesRows,
            readerPreferencesRows.screenAwakeMode,
          );
        }
        if (!await hasReaderPreferenceColumn(
          'screen_awake_inactivity_minutes',
        )) {
          await m.addColumn(
            readerPreferencesRows,
            readerPreferencesRows.screenAwakeInactivityMinutes,
          );
        }
      }
      // schema 18 -> 19: local book metadata is separated from file/source
      // identity. Existing collections retain their title and receive legacy
      // source markers; no progress, locator, bookmark, or history rows move.
      if (from < 19 && await hasTable('content_collections')) {
        if (!await hasCollectionColumn('author')) {
          await m.addColumn(contentCollections, contentCollections.author);
        }
        if (!await hasCollectionColumn('description')) {
          await m.addColumn(contentCollections, contentCollections.description);
        }
        if (!await hasCollectionColumn('metadata_source')) {
          await m.addColumn(
            contentCollections,
            contentCollections.metadataSource,
          );
        }
        if (!await hasCollectionColumn('title_source')) {
          await m.addColumn(contentCollections, contentCollections.titleSource);
        }
        if (!await hasCollectionColumn('author_source')) {
          await m.addColumn(
            contentCollections,
            contentCollections.authorSource,
          );
        }
      }
      // schema 19 -> 20: managed local cover metadata. The path is relative
      // to DataRoot and never points at the user's original TXT directory.
      if (from < 20 && await hasTable('content_collections')) {
        if (!await hasCollectionColumn('cover_path')) {
          await m.addColumn(contentCollections, contentCollections.coverPath);
        }
        if (!await hasCollectionColumn('cover_source')) {
          await m.addColumn(contentCollections, contentCollections.coverSource);
        }
      }
      // schema 20 → 21: independent Reader background transparency. This is
      // paint-only; existing books keep the fully opaque default and no
      // locator/progress/geometry data is changed.
      if (from >= 5 && from < 21) {
        if (!await hasReaderPreferenceColumn('background_opacity')) {
          await m.addColumn(
            readerPreferencesRows,
            readerPreferencesRows.backgroundOpacity,
          );
        }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createIndexes(Future<void> Function(String) exec) async {
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_collections_source '
      'ON content_collections (source_id)',
    );
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_items_collection_order '
      'ON content_items (collection_id, order_index)',
    );
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_documents_item '
      'ON content_documents (item_id)',
    );
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_toc_collection_order '
      'ON toc_entries (collection_id, order_index)',
    );
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_imports_source '
      'ON import_records (source_hash)',
    );
  }

  Future<void> _createM52Indexes(Future<void> Function(String) exec) async {
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_reader_bookmarks_collection_offset '
      'ON reader_bookmarks (collection_id, absolute_character_offset)',
    );
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_reading_history_last_read '
      'ON reading_history (last_read_at DESC)',
    );
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_reading_sessions_history '
      'ON reading_sessions (history_entry_id)',
    );
  }

  Future<void> _createFontIndexes(Future<void> Function(String) exec) async {
    await exec(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_reader_fonts_content_hash '
      'ON reader_font_asset_rows (content_hash)',
    );
  }
}
