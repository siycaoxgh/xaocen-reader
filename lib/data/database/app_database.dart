import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    ReaderBookmarks,
    ReadingHistory,
    ReadingSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 内存测试库。
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 8;

  /// 打开应用数据库（support 目录下）。
  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'xaocen_v4_local.sqlite'));
    return AppDatabase(NativeDatabase(file));
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes(customStatement);
      await _createM52Indexes(customStatement);
    },
    onUpgrade: (m, from, to) async {
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
}
