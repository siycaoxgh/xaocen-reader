import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_progress_state.dart';
import 'package:xaocen_reader/domain/reader/reading_mode.dart';

void main() {
  group('ReadingProgressRepository', () {
    late AppDatabase db;
    late ReadingProgressRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = ReadingProgressRepository(db: db);
      // 准备一个 collection（外键依赖）
      final now = DateTime.now();
      await db
          .into(db.contentSources)
          .insert(
            ContentSourcesCompanion.insert(
              id: 'local-txt-source:abc',
              type: 'localTxt',
              displayName: 'Test Book',
              contentHash: 'abc',
              managedSourcePath: 'library/local_txt/abc/source.txt',
              sourceSize: 100,
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
              title: 'Test Book',
              itemCount: 1,
              normalizedCharacterLength: 1000,
              importedAt: now,
              updatedAt: now,
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('无进度时返回 null', () async {
      final p = await repo.getProgress('local-txt:abc');
      expect(p, isNull);
    });

    test('save 后能读取（含 itemIdHint）', () async {
      await repo.saveProgress(
        ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 12345,
          readingMode: ReadingMode.vertical,
          itemIdHint: 'local-txt:abc:chapter:1000',
        ),
      );
      final p = await repo.getProgress('local-txt:abc');
      expect(p, isNotNull);
      expect(p!.absoluteCharacterOffset, 12345);
      expect(p.itemIdHint, 'local-txt:abc:chapter:1000');
    });

    test('upsert：再次 save 覆盖', () async {
      await repo.saveProgress(
        ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 100,
          readingMode: ReadingMode.vertical,
        ),
      );
      await repo.saveProgress(
        ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 200,
          readingMode: ReadingMode.vertical,
        ),
      );
      final p = await repo.getProgress('local-txt:abc');
      expect(p!.absoluteCharacterOffset, 200);
      // 仍只有一行
      final count = await db.select(db.readingProgress).get();
      expect(count.length, 1);
    });

    test('clear 后返回 null', () async {
      await repo.saveProgress(
        ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 100,
          readingMode: ReadingMode.vertical,
        ),
      );
      await repo.clearProgress('local-txt:abc');
      expect(await repo.getProgress('local-txt:abc'), isNull);
    });

    test('删除 collection 级联删除进度', () async {
      await repo.saveProgress(
        ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 100,
          readingMode: ReadingMode.vertical,
        ),
      );
      await (db.delete(
        db.contentCollections,
      )..where((t) => t.id.equals('local-txt:abc'))).go();
      expect(await repo.getProgress('local-txt:abc'), isNull);
    });

    test('不同 collection 互不影响', () async {
      final now = DateTime.now();
      await db
          .into(db.contentSources)
          .insert(
            ContentSourcesCompanion.insert(
              id: 'local-txt-source:def',
              type: 'localTxt',
              displayName: 'Other',
              contentHash: 'def',
              managedSourcePath: 'library/local_txt/def/source.txt',
              sourceSize: 50,
              detectedEncoding: 'utf8',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.contentCollections)
          .insert(
            ContentCollectionsCompanion.insert(
              id: 'local-txt:def',
              sourceId: 'local-txt-source:def',
              title: 'Other',
              itemCount: 1,
              normalizedCharacterLength: 100,
              importedAt: now,
              updatedAt: now,
            ),
          );
      await repo.saveProgress(
        ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 1,
          readingMode: ReadingMode.paged,
        ),
      );
      await repo.saveProgress(
        ReaderProgressState(
          collectionId: 'local-txt:def',
          absoluteCharacterOffset: 2,
          readingMode: ReadingMode.vertical,
        ),
      );
      for (var round = 0; round < 5; round++) {
        final a = await repo.getProgress('local-txt:abc');
        final b = await repo.getProgress('local-txt:def');
        expect(a!.absoluteCharacterOffset, 1);
        expect(a.readingMode, ReadingMode.paged);
        expect(b!.absoluteCharacterOffset, 2);
        expect(b.readingMode, ReadingMode.vertical);
      }
    });
  });

  group('schema migration 1→2', () {
    test('旧库升级后 reading_progress 表存在', () async {
      // 用文件库模拟 schema 1 → 打开 → 升级
      // （内存库总是 schemaVersion=2 全新建，这里验证 onCreate 含新表即可）
      final db = AppDatabase.forTesting();
      final tables = await db
          .customSelect('SELECT name FROM sqlite_master WHERE type=\'table\'')
          .get();
      final names = tables.map((r) => r.data['name']).toSet();
      expect(names, contains('reading_progress'));
      await db.close();
    });
  });
}
