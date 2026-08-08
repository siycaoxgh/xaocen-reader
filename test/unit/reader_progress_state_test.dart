// M4 P1 专项：模式 + Locator 持久化闭环。
//
// 核心合同：
// 1. 只有「当前激活的 Reader 模式」允许提交阅读位置；
//    inactive/disposed 的 VerticalReader/PagedReader 不得覆盖。
// 2. ReaderProgressState = collectionId + absoluteCharacterOffset + readingMode
//    + updatedAt；absoluteCharacterOffset 是唯一位置真源。
// 3. 重开 = 上次的阅读模式 + 最后 confirmed Locator。
import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_progress_state.dart';
import 'package:xaocen_reader/domain/reader/reading_mode.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';

void main() {
  group('ReaderProgressState 合同', () {
    test('state 组合：locator + mode + updatedAt', () {
      final state = ReaderProgressState(
        collectionId: 'c1',
        absoluteCharacterOffset: 100,
        readingMode: ReadingMode.paged,
        itemIdHint: 'hint',
        updatedAt: DateTime(2026, 8, 8),
      );
      expect(state.absoluteCharacterOffset, 100);
      expect(state.readingMode, ReadingMode.paged);
      expect(state.itemIdHint, 'hint');
      final loc = state.toLocator();
      expect(loc, isA<ReaderLocator>());
      expect(loc.absoluteCharacterOffset, 100);
      expect(loc.itemIdHint, 'hint');
    });

    test('copyWith 保留 mode 与 offset', () {
      const state = ReaderProgressState(
        collectionId: 'c1',
        absoluteCharacterOffset: 100,
        readingMode: ReadingMode.paged,
      );
      final s2 = state.copyWith(absoluteCharacterOffset: 200);
      expect(s2.readingMode, ReadingMode.paged);
      expect(s2.absoluteCharacterOffset, 200);
    });

    test('ReadingMode 序列化/反序列化', () {
      expect(ReadingMode.vertical.storageName, 'vertical');
      expect(ReadingMode.paged.storageName, 'paged');
      expect(ReadingMode.fromStorage('paged'), ReadingMode.paged);
      expect(ReadingMode.fromStorage('vertical'), ReadingMode.vertical);
      expect(ReadingMode.fromStorage(null), ReadingMode.vertical);
      expect(ReadingMode.fromStorage('unknown'), ReadingMode.vertical);
    });
  });

  group('Repository mode 持久化', () {
    late AppDatabase db;
    late ReadingProgressRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = ReadingProgressRepository(db: db);
      final now = DateTime.now();
      await db
          .into(db.contentSources)
          .insert(
            ContentSourcesCompanion.insert(
              id: 'local-txt-source:abc',
              type: 'localTxt',
              displayName: 'T',
              contentHash: 'abc',
              managedSourcePath: 'p',
              sourceSize: 1,
              detectedEncoding: 'utf8',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.contentCollections)
          .insert(
            ContentCollectionsCompanion.insert(
              id: 'local-txt:abc',
              sourceId: 'local-txt-source:abc',
              title: 'T',
              itemCount: 1,
              normalizedCharacterLength: 100,
              importedAt: now,
              updatedAt: now,
            ),
          );
    });

    tearDown(() async => db.close());

    test('保存/读取 readingMode', () async {
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 123,
          readingMode: ReadingMode.paged,
        ),
      );
      final p = await repo.getProgress('local-txt:abc');
      expect(p, isNotNull);
      expect(p!.absoluteCharacterOffset, 123);
      expect(p.readingMode, ReadingMode.paged);
    });

    test('垂直模式保存后重开读取 vertical', () async {
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 50,
          readingMode: ReadingMode.vertical,
        ),
      );
      final p = await repo.getProgress('local-txt:abc');
      expect(p!.readingMode, ReadingMode.vertical);
    });

    test('paged 覆盖 vertical（最后一次提交为准）', () async {
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 50,
          readingMode: ReadingMode.vertical,
        ),
      );
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 90,
          readingMode: ReadingMode.paged,
        ),
      );
      final p = await repo.getProgress('local-txt:abc');
      expect(p!.absoluteCharacterOffset, 90);
      expect(p.readingMode, ReadingMode.paged);
    });
  });

  group('schema 迁移 2→3（旧数据默认 vertical）', () {
    test('旧 schema 无 readingMode 列，迁移后默认 vertical', () async {
      // 用文件库模拟 schema 2 旧库：
      // PRAGMA user_version = 2 + schema 2 结构的 reading_progress 表（无 reading_mode 列）
      final dir = await Directory.systemTemp.createTemp('m41_mig');
      final file = File('${dir.path}${Platform.pathSeparator}mig.sqlite');
      // 用 sqlite3 直接创建 schema 2 旧库（user_version=2）
      final raw = sqlite3.open(file.path);
      raw.execute('PRAGMA user_version = 2');
      raw.execute('''
        CREATE TABLE reading_progress (
          collection_id TEXT NOT NULL PRIMARY KEY,
          absolute_character_offset INTEGER NOT NULL,
          item_id_hint TEXT NULL,
          updated_at INTEGER NOT NULL,
          locator_version INTEGER NOT NULL,
          normalization_version TEXT NOT NULL
        )
      ''');
      raw.execute(
        'INSERT INTO reading_progress (collection_id, absolute_character_offset, item_id_hint, updated_at, locator_version, normalization_version) '
        "VALUES ('c_old', 42, NULL, 0, 1, 'v1')",
      );
      raw.dispose();

      // 用 AppDatabase（schemaVersion=3）打开 → 触发 onUpgrade 2→3
      // → addColumn readingMode（默认 vertical）
      final db = AppDatabase(NativeDatabase(file));
      final repo = ReadingProgressRepository(db: db);
      final p = await repo.getProgress('c_old');
      expect(p, isNotNull);
      expect(p!.absoluteCharacterOffset, 42);
      expect(
        p.readingMode,
        ReadingMode.vertical,
        reason: '旧数据无 readingMode 列 → 默认 vertical',
      );
      await db.close();
      await dir.delete(recursive: true);
    });
  });
}
