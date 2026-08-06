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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 内存测试库。
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

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
}
