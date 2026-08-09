import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reader_bookmark_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_bookmark.dart' as domain;

void main() {
  late AppDatabase db;
  late ReaderBookmarkRepository repository;
  final now = DateTime(2026, 8, 9, 12);

  Future<void> seedCollection(String id, String title) async {
    final sourceId = '$id-source';
    await db
        .into(db.contentSources)
        .insert(
          ContentSourcesCompanion.insert(
            id: sourceId,
            type: 'localTxt',
            displayName: title,
            contentHash: id,
            managedSourcePath: 'library/local_txt/$id/source.txt',
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
            id: id,
            sourceId: sourceId,
            title: title,
            itemCount: 1,
            normalizedCharacterLength: 1000,
            importedAt: now,
            updatedAt: now,
          ),
        );
  }

  setUp(() async {
    db = AppDatabase.forTesting();
    repository = ReaderBookmarkRepository(db: db);
    await seedCollection('book-a', 'Book A');
    await seedCollection('book-b', 'Book B');
  });

  tearDown(() => db.close());

  test('duplicate offset is idempotent and books remain isolated', () async {
    final first = await repository.create(
      collectionId: 'book-a',
      absoluteCharacterOffset: 120,
      normalizedHashAtCreation: 'hash-a',
      bookTitleSnapshot: 'Book A',
      now: now,
    );
    final duplicate = await repository.create(
      collectionId: 'book-a',
      absoluteCharacterOffset: 120,
      normalizedHashAtCreation: 'hash-a',
      bookTitleSnapshot: 'Book A',
      now: now.add(const Duration(seconds: 1)),
    );
    final otherBook = await repository.create(
      collectionId: 'book-b',
      absoluteCharacterOffset: 120,
      normalizedHashAtCreation: 'hash-b',
      bookTitleSnapshot: 'Book B',
      now: now,
    );

    expect(duplicate.id, first.id);
    expect(await repository.loadForCollection('book-a'), hasLength(1));
    expect(
      (await repository.loadForCollection('book-b')).single.id,
      otherBook.id,
    );
  });

  test('deleting a bookmark does not change reading progress', () async {
    await db
        .into(db.readingProgress)
        .insert(
          ReadingProgressCompanion.insert(
            collectionId: 'book-a',
            absoluteCharacterOffset: 456,
            readingMode: const drift.Value('vertical'),
            itemIdHint: const drift.Value(null),
            updatedAt: now,
            locatorVersion: 1,
            normalizationVersion: 'v1',
          ),
        );
    final bookmark = await repository.create(
      collectionId: 'book-a',
      absoluteCharacterOffset: 456,
      normalizedHashAtCreation: 'hash-a',
      bookTitleSnapshot: 'Book A',
      note: 'keep this note',
      now: now,
    );
    await repository.delete(bookmark.id);

    expect(await repository.loadForCollection('book-a'), isEmpty);
    final progress = await (db.select(
      db.readingProgress,
    )..where((row) => row.collectionId.equals('book-a'))).getSingle();
    expect(progress.absoluteCharacterOffset, 456);
    expect(bookmark.note, 'keep this note');
  });

  test('orphan status is dynamic and remains deletable', () async {
    final bookmark = domain.ReaderBookmark(
      id: 'orphan',
      collectionId: 'book-a',
      absoluteCharacterOffset: 1001,
      normalizedHashAtCreation: 'hash-a',
      bookTitleSnapshot: 'Book A',
      note: 'orphan note',
      createdAt: now,
      updatedAt: now,
    );
    final status = domain.deriveReaderBookmarkStatus(
      bookmark,
      currentNormalizedHash: 'hash-a',
      normalizedCharacterLength: 1000,
    );
    expect(status.isOrphan, isTrue);
    expect(status.reason, domain.ReaderBookmarkOrphanReason.offsetOutOfBounds);
  });
}
