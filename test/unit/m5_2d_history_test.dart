import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reading_history_repository.dart';
import 'package:xaocen_reader/data/repositories/reading_session_repository.dart';

void main() {
  test(
    'history aggregate derives duration/count and recent excludes detached books',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final now = DateTime(2026, 8, 9, 10);
      await db
          .into(db.contentSources)
          .insert(
            ContentSourcesCompanion.insert(
              id: 'source',
              type: 'localTxt',
              displayName: 'Book',
              contentHash: 'hash',
              managedSourcePath: 'managed/source.txt',
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
              id: 'book',
              sourceId: 'source',
              title: 'Book',
              itemCount: 0,
              normalizedCharacterLength: 100,
              importedAt: now,
              updatedAt: now,
            ),
          );
      final history = ReadingHistoryRepository(db: db);
      final sessions = ReadingSessionRepository(db: db);
      final entry = await history.ensureForCollection(
        collectionId: 'book',
        bookTitleSnapshot: 'Book',
        now: now,
      );
      final session = await sessions.start(
        historyEntryId: entry.id,
        startedAt: now,
      );
      await sessions.addEffectiveSeconds(session.id, 125);
      await history.recordRead(
        historyEntryId: entry.id,
        at: now.add(const Duration(minutes: 2)),
        chapterTitleSnapshot: 'Chapter 1',
        progressSnapshot: '12.5%',
      );
      expect((await sessions.aggregate(entry.id)).totalReadingSeconds, 125);
      expect((await sessions.aggregate(entry.id)).sessionCount, 1);
      expect(await history.loadRecentInLibrary(), hasLength(1));

      await (db.delete(
        db.contentCollections,
      )..where((t) => t.id.equals('book'))).go();
      expect((await history.loadById(entry.id))!.collectionId, isNull);
      expect(await history.loadRecentInLibrary(), isEmpty);
      expect((await sessions.aggregate(entry.id)).sessionCount, 1);
      await history.delete(entry.id);
      expect(await sessions.loadForHistory(entry.id), isEmpty);
    },
  );
}
