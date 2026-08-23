import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/data_root.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/domain/reader/content_transform.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_data.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/web_book_runtime.dart';

void main() {
  late DataRoot root;
  late AppDatabase database;
  late LibraryFileManager files;
  late LocalLibraryRepository repository;
  late RemoteHttpTransport transport;
  late WebBookSource source;
  late WebBookDetail detail;

  setUp(() async {
    final temp = await Directory.systemTemp.createTemp(
      'xaocen-webbook-update-',
    );
    root = await DataRoot.forDirectory(temp, profileId: 'test');
    database = AppDatabase.forTesting();
    files = LibraryFileManager(libraryRoot: root.booksDirectory);
    repository = LocalLibraryRepository(
      database: database,
      fileManager: files,
      encodingIndexProvider: MemoryEncodingIndexProvider(
        Gb18030IndexData(entries: Uint16List(0), anchors: Uint32List(0)),
      ),
    );
    transport = RemoteHttpTransport();
    source = WebBookSource(
      id: RemoteSourceId('fixture-source'),
      endpoint: Uri.parse('https://fixture.example/book'),
      bookKey: 'book-1',
      ruleSetId: 'fixture-source-v1',
    );
    detail = WebBookDetail(
      bookKey: 'book-1',
      title: '青山',
      detailUri: source.endpoint,
      author: '测试作者',
    );
  });

  tearDown(() async {
    transport.close();
    await database.close();
    await root.rootDirectory.delete(recursive: true);
  });

  WebBookChapter chapter(String key, int order, String text) {
    return WebBookChapter(
      bookKey: detail.bookKey,
      entry: WebBookTocEntry(
        chapterKey: key,
        title: '第$order章',
        orderIndex: order,
        chapterUri: Uri.parse('https://fixture.example/chapter/$key'),
      ),
      body: WebSourceBody(
        canonical: CanonicalContent(
          contentId: '$key-content',
          sourceRevision: '$key-revision',
          text: text,
        ),
      ),
      ruleSet: const WebRuleSetRef(id: 'fixture-source-v1', version: 1),
    );
  }

  WebBookTableOfContents toc(List<WebBookChapter> chapters) {
    return WebBookTableOfContents(
      bookKey: detail.bookKey,
      entries: chapters.map((chapter) => chapter.entry).toList(),
      sourceRevision: chapters
          .map((chapter) => chapter.entry.chapterKey)
          .join(','),
    );
  }

  Future<LibraryCollection> importInitial() async {
    final runtime = WebBookHttpRuntime(transport: transport);
    final chapters = [chapter('c1', 0, '第一章正文。'), chapter('c2', 1, '第二章正文。')];
    final projection = runtime.toReaderContent(
      source: source,
      detail: detail,
      chapters: chapters,
    );
    final result = await repository.importWebBook(
      ImportWebBookRequest(
        source: source,
        detail: detail,
        projection: projection,
      ),
    );
    return result.collection;
  }

  test('appends only new chapters and preserves locator/progress', () async {
    final collection = await importInitial();
    final beforeDocuments = await repository.getDocuments(collection.id);
    final beforeOffset = beforeDocuments.first.startCharacterOffset;
    await database
        .into(database.readingProgress)
        .insert(
          ReadingProgressCompanion.insert(
            collectionId: collection.id,
            absoluteCharacterOffset: 4,
            readingMode: const drift.Value('vertical'),
            itemIdHint: const drift.Value(null),
            updatedAt: DateTime(2026, 8, 18),
            locatorVersion: 1,
            normalizationVersion: 'v1',
          ),
        );

    final c1 = chapter('c1', 0, '第一章正文。');
    final c2 = chapter('c2', 1, '第二章正文。');
    final c3 = chapter('c3', 2, '第三章新正文。');
    final newToc = toc([c1, c2, c3]);
    final plan = await repository.planWebBookUpdate(
      collectionId: collection.id,
      toc: newToc,
    );
    expect(plan.status, WebBookUpdateStatus.updated);
    expect(plan.newEntries.map((entry) => entry.chapterKey), ['c3']);

    final result = await repository.updateWebBook(
      plan: plan,
      chapters: [c3],
      toc: newToc,
    );
    expect(result.status, WebBookUpdateStatus.updated);
    expect(result.addedChapterCount, 1);
    expect(result.collection.itemCount, 3);
    expect(
      result.collection.normalizedCharacterLength,
      greaterThan(collection.normalizedCharacterLength),
    );
    expect(
      (await repository.getDocuments(collection.id)).first.startCharacterOffset,
      beforeOffset,
    );
    expect(
      (await database.select(database.readingProgress).get())
          .single
          .absoluteCharacterOffset,
      4,
    );
    expect(
      (await repository.getToc(collection.id)).map((entry) => entry.title),
      ['第0章', '第1章', '第2章'],
    );

    final noChanges = await repository.planWebBookUpdate(
      collectionId: collection.id,
      toc: newToc,
    );
    expect(noChanges.status, WebBookUpdateStatus.noChanges);
    final noChangeResult = await repository.updateWebBook(
      plan: noChanges,
      chapters: const [],
      toc: newToc,
    );
    expect(noChangeResult.status, WebBookUpdateStatus.noChanges);
    expect(noChangeResult.addedChapterCount, 0);
  });

  test('does not rewrite a snapshot when source order changes', () async {
    final collection = await importInitial();
    final c1 = chapter('c1', 1, '第一章正文。');
    final c2 = chapter('c2', 0, '第二章正文。');
    final c3 = chapter('c3', 2, '第三章新正文。');
    final plan = await repository.planWebBookUpdate(
      collectionId: collection.id,
      toc: toc([c2, c1, c3]),
    );
    expect(plan.status, WebBookUpdateStatus.failed);
    expect(plan.newEntries, isEmpty);
    expect((await repository.getCollection(collection.id))!.itemCount, 2);
    expect(
      (await repository.getToc(collection.id)).map((entry) => entry.title),
      ['第0章', '第1章'],
    );
  });
}
