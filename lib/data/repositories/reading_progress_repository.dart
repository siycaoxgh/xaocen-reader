/// ReadingProgressRepository —— 阅读进度持久化。
///
/// UI 和 Reader Controller 不得直接访问 Drift；一律经此 Repository。
/// 每个 collection 一条当前阅读进度；删除 collection 时级联删除。
/// 不保存页面 / 像素 / blockIndex / 正文。
library;

import 'package:drift/drift.dart';

import '../../domain/reader/reader_locator.dart';
import '../database/app_database.dart';

/// 阅读进度仓库。
class ReadingProgressRepository {
  // ignore: prefer_initializing_formals
  ReadingProgressRepository({required AppDatabase db}) : _db = db;
  final AppDatabase _db;

  /// locator 版本（与 [ReaderLocator] 语义对齐，M3=1）。
  static const int locatorVersion = 1;

  /// 读取指定 collection 的进度；无进度返回 null。
  Future<ReaderLocator?> getProgress(String collectionId) async {
    final row = await (_db.select(
      _db.readingProgress,
    )..where((t) => t.collectionId.equals(collectionId))).getSingleOrNull();
    if (row == null) return null;
    return ReaderLocator(
      collectionId: row.collectionId,
      absoluteCharacterOffset: row.absoluteCharacterOffset,
      itemIdHint: row.itemIdHint,
    );
  }

  /// 保存进度（upsert）。
  Future<void> saveProgress(ReaderLocator locator) async {
    await _db
        .into(_db.readingProgress)
        .insertOnConflictUpdate(
          ReadingProgressCompanion.insert(
            collectionId: locator.collectionId,
            absoluteCharacterOffset: locator.absoluteCharacterOffset,
            itemIdHint: Value(locator.itemIdHint),
            updatedAt: DateTime.now(),
            locatorVersion: locatorVersion,
            normalizationVersion: 'v1',
          ),
        );
  }

  /// 清空进度（删除行）。
  Future<void> clearProgress(String collectionId) async {
    await (_db.delete(
      _db.readingProgress,
    )..where((t) => t.collectionId.equals(collectionId))).go();
  }
}
