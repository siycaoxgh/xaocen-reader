import 'package:drift/drift.dart';

import '../../domain/reader/reader_bookmark.dart' as domain;
import '../database/app_database.dart';

class ReaderBookmarkRepository {
  // ignore: prefer_initializing_formals
  ReaderBookmarkRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  Future<List<domain.ReaderBookmark>> loadForCollection(String collectionId) async {
    final rows = await (_db.select(_db.readerBookmarks)
          ..where((t) => t.collectionId.equals(collectionId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    return rows.map(_map).toList(growable: false);
  }

  Future<List<domain.ReaderBookmark>> loadAll() async {
    final rows = await (_db.select(_db.readerBookmarks)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
    return rows.map(_map).toList(growable: false);
  }

  Stream<List<domain.ReaderBookmark>> watchForCollection(String collectionId) =>
      (_db.select(_db.readerBookmarks)
            ..where((t) => t.collectionId.equals(collectionId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch()
          .map((rows) => rows.map(_map).toList(growable: false));

  Future<domain.ReaderBookmark> create({
    required String collectionId,
    required int absoluteCharacterOffset,
    String? normalizedHashAtCreation,
    required String bookTitleSnapshot,
    String? note,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final id = 'bookmark-${timestamp.microsecondsSinceEpoch}';
    await _db.into(_db.readerBookmarks).insert(
      ReaderBookmarksCompanion.insert(
        id: id,
        collectionId: Value(collectionId),
        absoluteCharacterOffset: absoluteCharacterOffset,
        normalizedHashAtCreation: Value(normalizedHashAtCreation),
        bookTitleSnapshot: bookTitleSnapshot,
        note: Value(note),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    return _map(
      await (_db.select(_db.readerBookmarks)
            ..where((t) => t.id.equals(id)))
          .getSingle(),
    );
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.readerBookmarks)..where((t) => t.id.equals(id))).go();
  }

  Future<domain.ReaderBookmark?> get(String id) async {
    final row = await (_db.select(_db.readerBookmarks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  domain.ReaderBookmark _map(ReaderBookmark row) => domain.ReaderBookmark(
    id: row.id,
    collectionId: row.collectionId,
    absoluteCharacterOffset: row.absoluteCharacterOffset,
    normalizedHashAtCreation: row.normalizedHashAtCreation,
    bookTitleSnapshot: row.bookTitleSnapshot,
    note: row.note,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
