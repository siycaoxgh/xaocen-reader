import 'package:drift/drift.dart';

import '../../domain/reader/reading_history.dart';
import '../database/app_database.dart';

class ReadingHistoryRepository {
  // ignore: prefer_initializing_formals
  ReadingHistoryRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  Future<ReadingHistoryEntry?> loadById(String id) async {
    final row = await (_db.select(
      _db.readingHistory,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<ReadingHistoryEntry?> loadForCollection(String collectionId) async {
    final row = await (_db.select(
      _db.readingHistory,
    )..where((t) => t.collectionId.equals(collectionId))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  /// Ensures the one aggregate history row associated with a collection.
  Future<ReadingHistoryEntry> ensureForCollection({
    required String collectionId,
    required String bookTitleSnapshot,
    String? authorSnapshot,
    String? normalizedHashSnapshot,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final id = 'history:$collectionId';
    final existing = await loadById(id);
    if (existing == null) {
      await _db
          .into(_db.readingHistory)
          .insert(
            ReadingHistoryCompanion.insert(
              id: id,
              collectionId: Value(collectionId),
              bookTitleSnapshot: bookTitleSnapshot,
              authorSnapshot: Value(authorSnapshot),
              normalizedHashSnapshot: Value(normalizedHashSnapshot),
              firstReadAt: timestamp,
              lastReadAt: timestamp,
              lastChapterTitleSnapshot: const Value.absent(),
              lastProgressSnapshot: const Value.absent(),
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );
    } else {
      await (_db.update(
        _db.readingHistory,
      )..where((t) => t.id.equals(id))).write(
        ReadingHistoryCompanion(
          collectionId: Value(collectionId),
          bookTitleSnapshot: Value(bookTitleSnapshot),
          authorSnapshot: Value(authorSnapshot),
          normalizedHashSnapshot: Value(normalizedHashSnapshot),
          lastReadAt: Value(timestamp),
          updatedAt: Value(timestamp),
        ),
      );
    }
    return (await loadById(id))!;
  }

  Future<void> recordRead({
    required String historyEntryId,
    required DateTime at,
    String? chapterTitleSnapshot,
    String? progressSnapshot,
  }) async {
    await (_db.update(
      _db.readingHistory,
    )..where((t) => t.id.equals(historyEntryId))).write(
      ReadingHistoryCompanion(
        lastReadAt: Value(at),
        lastChapterTitleSnapshot: Value(chapterTitleSnapshot),
        lastProgressSnapshot: Value(progressSnapshot),
        updatedAt: Value(at),
      ),
    );
  }

  Future<List<ReadingHistoryEntry>> loadRecentInLibrary({int limit = 2}) async {
    if (limit <= 0) return const [];
    final rows =
        await (_db.select(_db.readingHistory)
              ..where((t) => t.collectionId.isNotNull())
              ..orderBy([(t) => OrderingTerm.desc(t.lastReadAt)]))
            .get();
    final result = <ReadingHistoryEntry>[];
    for (final row in rows) {
      final collectionId = row.collectionId;
      if (collectionId == null) continue;
      final collection = await (_db.select(
        _db.contentCollections,
      )..where((t) => t.id.equals(collectionId))).getSingleOrNull();
      if (collection != null) {
        final hasSession =
            await (_db.select(_db.readingSessions)
                  ..where((t) => t.historyEntryId.equals(row.id))
                  ..limit(1))
                .getSingleOrNull();
        if (hasSession != null) {
          result.add(_map(row));
          if (result.length >= limit) break;
        }
      }
    }
    return result;
  }

  Future<List<ReadingHistoryEntry>> loadAll() async {
    final rows = await (_db.select(
      _db.readingHistory,
    )..orderBy([(t) => OrderingTerm.desc(t.lastReadAt)])).get();
    return rows.map(_map).toList(growable: false);
  }

  Future<void> delete(String historyEntryId) async {
    await (_db.delete(
      _db.readingHistory,
    )..where((t) => t.id.equals(historyEntryId))).go();
  }

  ReadingHistoryEntry _map(ReadingHistoryData row) => ReadingHistoryEntry(
    id: row.id,
    collectionId: row.collectionId,
    bookTitleSnapshot: row.bookTitleSnapshot,
    authorSnapshot: row.authorSnapshot,
    normalizedHashSnapshot: row.normalizedHashSnapshot,
    firstReadAt: row.firstReadAt,
    lastReadAt: row.lastReadAt,
    lastChapterTitleSnapshot: row.lastChapterTitleSnapshot,
    lastProgressSnapshot: row.lastProgressSnapshot,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
