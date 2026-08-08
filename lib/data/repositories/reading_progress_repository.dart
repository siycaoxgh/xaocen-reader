/// ReadingProgressRepository —— 阅读进度持久化。
///
/// UI 和 Reader Controller 不得直接访问 Drift；一律经此 Repository。
/// 每个 collection 一条当前阅读进度；删除 collection 时级联删除。
/// 不保存页面 / 像素 / blockIndex / 正文。
library;

import 'package:drift/drift.dart';

import '../../domain/reader/reader_locator.dart';
import '../../domain/reader/reader_progress_state.dart';
import '../../domain/reader/reading_mode.dart';
import '../database/app_database.dart';

/// 阅读进度仓库。
class ReadingProgressRepository {
  // ignore: prefer_initializing_formals
  ReadingProgressRepository({required AppDatabase db}) : _db = db;
  final AppDatabase _db;

  /// locator 版本（与 [ReaderLocator] 语义对齐，M3=1）。
  static const int locatorVersion = 1;

  /// 读取指定 collection 的进度状态；无进度返回 null。
  ///
  /// 返回 [ReaderProgressState]（含 readingMode）——
  /// 位置真源仍是 absoluteCharacterOffset，
  /// readingMode 只是表现状态。
  Future<ReaderProgressState?> getProgress(String collectionId) async {
    final row = await (_db.select(
      _db.readingProgress,
    )..where((t) => t.collectionId.equals(collectionId))).getSingleOrNull();
    if (row == null) return null;
    return ReaderProgressState(
      collectionId: row.collectionId,
      absoluteCharacterOffset: row.absoluteCharacterOffset,
      readingMode: ReadingMode.fromStorage(row.readingMode),
      itemIdHint: row.itemIdHint,
      updatedAt: row.updatedAt,
    );
  }

  /// 保存进度状态（upsert）。
  ///
  /// 只允许“当前激活的 Reader 模式”提交
  /// 位置；inactive/disposed 的 Reader 不得覆盖。
  Future<void> saveProgress(ReaderProgressState state) async {
    await _db
        .into(_db.readingProgress)
        .insertOnConflictUpdate(
          ReadingProgressCompanion.insert(
            collectionId: state.collectionId,
            absoluteCharacterOffset: state.absoluteCharacterOffset,
            readingMode: Value(state.readingMode.storageName),
            itemIdHint: Value(state.itemIdHint),
            updatedAt: DateTime.now(),
            locatorVersion: locatorVersion,
            normalizationVersion: 'v1',
          ),
        );
  }

  /// 保存位置（保留旧调用方兼容：由 Locator 构建状态）。
  ///
  /// 默认 readingMode 为 [ReadingMode.vertical]；
  /// 分页模式请使用 [saveProgress] 传入完整状态。
  Future<void> saveLocator(
    ReaderLocator locator, {
    ReadingMode mode = ReadingMode.vertical,
  }) {
    return saveProgress(
      ReaderProgressState(
        collectionId: locator.collectionId,
        absoluteCharacterOffset: locator.absoluteCharacterOffset,
        readingMode: mode,
        itemIdHint: locator.itemIdHint,
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
