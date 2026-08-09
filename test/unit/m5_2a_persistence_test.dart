import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reader_bookmark_repository.dart';
import 'package:xaocen_reader/data/repositories/reading_history_repository.dart';
import 'package:xaocen_reader/data/repositories/reading_session_repository.dart';
import 'package:xaocen_reader/domain/library/current_chapter_resolver.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/reader/reader_bookmark.dart' as domain;

void main() {
  const collectionId = 'local-txt:m52a';
  const sourceId = 'local-txt-source:m52a';

  Future<void> seedCollection(AppDatabase db) async {
    final now = DateTime(2026, 8, 9);
    await db.into(db.contentSources).insert(
      ContentSourcesCompanion.insert(
        id: sourceId,
        type: 'localTxt',
        displayName: 'M5.2a',
        contentHash: 'm52a-hash',
        managedSourcePath: 'managed/m52a/source.txt',
        sourceSize: 10,
        detectedEncoding: 'utf8',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.into(db.contentCollections).insert(
      ContentCollectionsCompanion.insert(
        id: collectionId,
        sourceId: sourceId,
        title: 'M5.2a Book',
        itemCount: 2,
        normalizedCharacterLength: 1000,
        importedAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<List<Map<String, Object?>>> pragmaRows(
    AppDatabase db,
    String table,
  ) async {
    final rows = await db.customSelect('PRAGMA foreign_key_list($table)').get();
    return rows.map((row) => row.data).toList(growable: false);
  }

  group('M5.2a schema 6 foreign keys', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting();
      await seedCollection(db);
    });

    tearDown(() => db.close());

    test('schema version and PRAGMA foreign keys are active', () async {
      expect(db.schemaVersion, 6);
      final enabled = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(enabled.data['foreign_keys'], 1);

      final historyFks = await pragmaRows(db, 'reading_history');
      final bookmarkFks = await pragmaRows(db, 'reader_bookmarks');
      final sessionFks = await pragmaRows(db, 'reading_sessions');
      expect(
        historyFks.any(
          (row) =>
              row['table'] == 'content_collections' &&
              row['from'] == 'collection_id' &&
              row['on_delete'] == 'SET NULL',
        ),
        isTrue,
      );
      expect(
        bookmarkFks.any(
          (row) =>
              row['table'] == 'content_collections' &&
              row['from'] == 'collection_id' &&
              row['on_delete'] == 'SET NULL',
        ),
        isTrue,
      );
      expect(
        sessionFks.any(
          (row) =>
              row['table'] == 'reading_history' &&
              row['from'] == 'history_entry_id' &&
              row['on_delete'] == 'CASCADE',
        ),
        isTrue,
      );
    });

    test('collection delete preserves history/bookmark as detached rows', () async {
      final history = ReadingHistoryRepository(db: db);
      final bookmarks = ReaderBookmarkRepository(db: db);
      final sessions = ReadingSessionRepository(db: db);
      final now = DateTime(2026, 8, 9, 10);
      final entry = await history.ensureForCollection(
        collectionId: collectionId,
        bookTitleSnapshot: 'M5.2a Book',
        normalizedHashSnapshot: 'normalized-hash',
        now: now,
      );
      final bookmark = await bookmarks.create(
        collectionId: collectionId,
        absoluteCharacterOffset: 321,
        normalizedHashAtCreation: 'normalized-hash',
        bookTitleSnapshot: 'M5.2a Book',
        now: now,
      );
      await sessions.start(historyEntryId: entry.id, startedAt: now);

      await (db.delete(db.contentCollections)
            ..where((t) => t.id.equals(collectionId)))
          .go();

      final detachedHistory = await history.loadById(entry.id);
      final detachedBookmark = await bookmarks.get(bookmark.id);
      expect(detachedHistory, isNotNull);
      expect(detachedHistory!.collectionId, isNull);
      expect(detachedBookmark, isNotNull);
      expect(detachedBookmark!.collectionId, isNull);
      expect((await sessions.loadForHistory(entry.id)), hasLength(1));
      expect(
        domain.deriveReaderBookmarkStatus(
          detachedBookmark,
          currentNormalizedHash: null,
          normalizedCharacterLength: null,
        ).reason,
        domain.ReaderBookmarkOrphanReason.collectionRemoved,
      );
    });

    test('deleting history cascades sessions but not the book', () async {
      final history = ReadingHistoryRepository(db: db);
      final sessions = ReadingSessionRepository(db: db);
      final entry = await history.ensureForCollection(
        collectionId: collectionId,
        bookTitleSnapshot: 'M5.2a Book',
      );
      await sessions.start(historyEntryId: entry.id);
      await history.delete(entry.id);

      expect(await history.loadById(entry.id), isNull);
      expect(await sessions.loadForHistory(entry.id), isEmpty);
      expect(
        await (db.select(db.contentCollections)
              ..where((t) => t.id.equals(collectionId)))
            .getSingleOrNull(),
        isNotNull,
      );
    });

    test('schema 5 to 6 migration preserves progress and creates real FKs', () async {
      final temp = await Directory.systemTemp.createTemp('xaocen-m52a-');
      final file = File('${temp.path}\\migration.sqlite');
      final oldDb = AppDatabase(NativeDatabase(file));
      await seedCollection(oldDb);
      await oldDb.into(oldDb.readingProgress).insert(
        ReadingProgressCompanion.insert(
          collectionId: collectionId,
          absoluteCharacterOffset: 777,
          readingMode: const drift.Value('paged'),
          itemIdHint: const drift.Value(null),
          updatedAt: DateTime(2026, 8, 9, 13),
          locatorVersion: 1,
          normalizationVersion: 'v1',
        ),
      );
      // Simulate a real schema-5 file by removing only the schema-6 tables
      // before reopening the same SQLite file with AppDatabase.
      await oldDb.customStatement('DROP TABLE reading_sessions');
      await oldDb.customStatement('DROP TABLE reader_bookmarks');
      await oldDb.customStatement('DROP TABLE reading_history');
      await oldDb.customStatement('PRAGMA user_version = 5');
      await oldDb.close();

      final migrated = AppDatabase(NativeDatabase(file));
      final progress = await (migrated.select(migrated.readingProgress)
            ..where((t) => t.collectionId.equals(collectionId)))
          .getSingle();
      expect(progress.absoluteCharacterOffset, 777);
      expect(progress.readingMode, 'paged');
      expect(
        (await migrated.customSelect('PRAGMA user_version').getSingle())
            .data['user_version'],
        6,
      );
      expect((await pragmaRows(migrated, 'reading_history')).length, 1);
      expect((await pragmaRows(migrated, 'reader_bookmarks')).length, 1);
      expect((await pragmaRows(migrated, 'reading_sessions')).length, 1);
      await migrated.close();
      await temp.delete(recursive: true);
    });
  });

  group('M5.2a repositories and lifecycle', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting();
      await seedCollection(db);
    });

    tearDown(() => db.close());

    test('session duration and count derive from reading_sessions', () async {
      final history = ReadingHistoryRepository(db: db);
      final sessions = ReadingSessionRepository(db: db);
      final start = DateTime(2026, 8, 9, 12);
      final entry = await history.ensureForCollection(
        collectionId: collectionId,
        bookTitleSnapshot: 'M5.2a Book',
        now: start,
      );
      var now = start;
      final lifecycle = ReadingSessionLifecycle(
        repository: sessions,
        historyEntryId: entry.id,
        clock: () => now,
      );

      await lifecycle.startAfterVisibleConfirm();
      now = start.add(const Duration(seconds: 65));
      await lifecycle.pause();
      now = start.add(const Duration(seconds: 100));
      await lifecycle.resume();
      now = start.add(const Duration(seconds: 130));
      await lifecycle.end();

      final aggregate = await sessions.aggregate(entry.id);
      expect(aggregate.totalReadingSeconds, 95);
      expect(aggregate.sessionCount, 1);
      expect((await sessions.loadForHistory(entry.id)).single.endedAt, now);
    });

    test('bookmark orphan reason is derived without persisted flag', () async {
      final bookmark = domain.ReaderBookmark(
        id: 'b',
        collectionId: collectionId,
        absoluteCharacterOffset: 100,
        normalizedHashAtCreation: 'old',
        bookTitleSnapshot: 'Book',
        note: null,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(
        domain.deriveReaderBookmarkStatus(
          bookmark,
          currentNormalizedHash: 'new',
          normalizedCharacterLength: 1000,
        ).reason,
        domain.ReaderBookmarkOrphanReason.normalizedHashMismatch,
      );
      expect(
        domain.deriveReaderBookmarkStatus(
          bookmark,
          currentNormalizedHash: 'old',
          normalizedCharacterLength: 50,
        ).reason,
        domain.ReaderBookmarkOrphanReason.offsetOutOfBounds,
      );
    });
  });

  test('CurrentChapterResolver ignores volumes and returns null for no chapters', () {
    const toc = [
      LibraryTocEntry(
        id: 'v1',
        collectionId: collectionId,
        itemId: null,
        parentId: null,
        kind: 'volume',
        level: 1,
        title: 'Volume 1',
        orderIndex: 0,
        startCharacterOffset: 0,
        endCharacterOffset: 500,
      ),
      LibraryTocEntry(
        id: 'c1',
        collectionId: collectionId,
        itemId: 'item-c1',
        parentId: 'v1',
        kind: 'chapter',
        level: 2,
        title: 'Chapter 1',
        orderIndex: 1,
        startCharacterOffset: 100,
        endCharacterOffset: 500,
      ),
    ];
    expect(CurrentChapterResolver.resolve(50, toc), isNull);
    expect(CurrentChapterResolver.resolve(100, toc)?.id, 'c1');
    expect(CurrentChapterResolver.resolve(500, const []), isNull);
  });
}
