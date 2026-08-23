import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/data_root.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/data/repositories/web_book_source_registry.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/domain/reader/reader_content.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_data.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/web_book_runtime.dart';
import 'package:xaocen_reader/sources/remote/web_book_chapter_cache_service.dart';
import 'package:xaocen_reader/sources/remote/xaocen_web_book_source_definition.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';

void main() {
  late HttpServer server;
  late Uri base;
  late DataRoot root;
  late AppDatabase database;
  late LibraryFileManager files;
  late LocalLibraryRepository repository;
  var chapter3Requests = 0;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://${server.address.host}:${server.port}');
    server.listen((request) async {
      final path = request.uri.path;
      if (path == '/chapter/3') chapter3Requests++;
      final html = switch (path) {
        '/search' =>
          '''
          <article class="book" data-book-key="book-1">
            <a class="title" href="/book">青山</a>
            <span class="author">作者：会说话的肘子</span>
          </article>
        ''',
        '/book' =>
          '''
          <div class="detail" data-book-key="book-1">
            <h1>青山</h1>
            <span class="author">作者：会说话的肘子</span>
            <p class="description">一本测试小说</p>
            <nav class="toc">
              <a data-chapter-key="c1" href="/chapter/1">第一章</a>
              <a data-chapter-key="c2" href="/chapter/2">第二章</a>
            </nav>
          </div>
        ''',
        '/chapter/1' => '<article class="chapter"><p>第一章正文。</p></article>',
        '/chapter/2' => '<article class="chapter"><p>第二章正文。</p></article>',
        '/chapter/3' => '<article class="chapter"><p>第三章按需正文。</p></article>',
        _ => '<p>not found</p>',
      };
      request.response
        ..statusCode =
            path.startsWith('/chapter') || path == '/book' || path == '/search'
            ? HttpStatus.ok
            : HttpStatus.notFound
        ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
        ..write(html);
      await request.response.close();
    });

    final temp = await Directory.systemTemp.createTemp(
      'xaocen-webbook-library-',
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
  });

  tearDown(() async {
    await server.close(force: true);
    await database.close();
    await root.rootDirectory.delete(recursive: true);
  });

  test(
    'adds an ordered WebBook snapshot and reopens it without duplication',
    () async {
      final definition = XaocenWebBookSourceDefinition.fromJson({
        'schema': XaocenWebBookSourceDefinition.schema,
        'version': XaocenWebBookSourceDefinition.schemaVersion,
        'sourceId': 'fixture-source',
        'name': 'Fixture',
        'endpoint': base.resolve('/book').toString(),
        'searchEndpoint': base.resolve('/search').toString(),
        'bookKey': 'book-1',
        'ruleVersion': 1,
        'rules': <String, Object?>{
          'search': <String, Object?>{
            'itemSelector': 'article.book',
            'title': <String, Object?>{'selector': '.title'},
            'author': <String, Object?>{
              'selector': '.author',
              'removePrefix': '作者：',
            },
            'linkSelector': '.title',
            'keyAttribute': 'data-book-key',
          },
          'detail': <String, Object?>{
            'selector': '.detail',
            'title': <String, Object?>{'selector': 'h1'},
            'author': <String, Object?>{
              'selector': '.author',
              'removePrefix': '作者：',
            },
            'description': <String, Object?>{'selector': '.description'},
            'keyAttribute': 'data-book-key',
          },
          'toc': <String, Object?>{
            'entrySelector': '.toc a',
            'title': <String, Object?>{},
            'keyAttribute': 'data-chapter-key',
            'hrefAttribute': 'href',
          },
          'chapter': <String, Object?>{'bodySelector': 'article.chapter'},
        },
      });
      final registry = WebBookSourceRegistry(root);
      await registry.importDefinition(definition);
      final transport = RemoteHttpTransport();
      addTearDown(transport.close);
      final runtime = WebBookHttpRuntime(
        transport: transport,
        rules: definition.toExtractionRules(),
      );
      final search = await runtime.search(
        source: definition.toSource(),
        request: const WebBookSearchRequest(query: '青山'),
      );
      final detail = await runtime.openDetail(
        source: definition.toSource(),
        result: search.single,
      );
      final toc = await runtime.loadTableOfContents(
        source: definition.toSource(),
        detail: detail,
      );
      final chapters = <WebBookChapter>[
        for (final entry in toc.entries)
          await runtime.openChapter(
            source: definition.toSource(),
            detail: detail,
            entry: entry,
          ),
      ];
      final projection = runtime.toReaderContent(
        source: definition.toSource(),
        detail: detail,
        chapters: chapters,
        contentId: LocalLibraryRepository.webBookCollectionIdFor(
          definition.sourceId,
          detail.bookKey,
        ),
      );

      final first = await repository.importWebBook(
        ImportWebBookRequest(
          source: definition.toSource(),
          detail: detail,
          projection: projection,
          sourceName: 'Fixture 书源',
          catalogEntries: [
            ...toc.entries,
            WebBookTocEntry(
              chapterKey: 'c3',
              title: '第三章（按需）',
              orderIndex: 2,
              chapterUri: base.resolve('/chapter/3'),
            ),
          ],
        ),
      );
      expect(first.alreadyImported, isFalse);
      expect(first.collection.sourceId, startsWith('web-book-source:'));
      expect((await repository.listCollections()).map((e) => e.id), [
        first.collection.id,
      ]);

      final documents = await repository.getDocuments(first.collection.id);
      final tocRows = await repository.getToc(first.collection.id);
      expect(tocRows.map((e) => e.title), ['第一章', '第二章', '第三章（按需）']);
      expect(tocRows.last.itemId, isNull);
      expect(documents, hasLength(2));
      final snapshot = await repository.getWebBookSnapshotMetadata(
        first.collection.id,
      );
      expect(snapshot.sourceName, 'Fixture 书源');
      expect(snapshot.cacheMode, 'chapterCache');
      expect(snapshot.totalChapterCount, 3);
      final loaded = await NormalizedDocumentLoader(fileManager: files).load(
        storagePath: documents.first.storagePath,
        expectedHash: documents.first.contentHash,
        expectedLength: first.collection.normalizedCharacterLength,
      );
      expect(loaded.text, contains('第一章正文。'));
      expect(loaded.text, contains('第二章正文。'));
      expect(
        ReaderContentAdapterRegistry.defaultInstance
            .resolve(
              collection: first.collection,
              documents: documents,
              navigation: tocRows,
            )
            .identity
            .sourceKind,
        ReaderContentSourceKinds.online,
      );

      final cacheService = WebBookChapterCacheService(
        repository: repository,
        registry: registry,
        transport: transport,
      );
      final fetched = await cacheService.ensureChapter(
        collectionId: first.collection.id,
        chapterKey: 'c3',
      );
      expect(fetched.status, WebBookUpdateStatus.updated);
      expect(fetched.addedChapterCount, 1);
      expect(chapter3Requests, 1);
      final afterFetch = await repository.getToc(first.collection.id);
      expect(afterFetch.last.itemId, isNotNull);
      expect(
        (await repository.getDocuments(first.collection.id)),
        hasLength(3),
      );
      final loadedAfterFetch =
          await NormalizedDocumentLoader(fileManager: files).load(
            storagePath: documents.first.storagePath,
            expectedLength: fetched.collection.normalizedCharacterLength,
          );
      expect(loadedAfterFetch.text, contains('第三章按需正文。'));

      final cached = await cacheService.ensureChapter(
        collectionId: first.collection.id,
        chapterKey: 'c3',
      );
      expect(cached.status, WebBookUpdateStatus.noChanges);
      expect(chapter3Requests, 1);

      final duplicate = await repository.importWebBook(
        ImportWebBookRequest(
          source: definition.toSource(),
          detail: detail,
          projection: projection,
        ),
      );
      expect(duplicate.alreadyImported, isTrue);
      expect((await repository.listCollections()).length, 1);

      await repository.removeCollection(first.collection.id);
      expect(await repository.listCollections(), isEmpty);
      expect(await registry.find(definition.sourceId), isNotNull);
      expect(
        await files
            .webBookContentDir(
              LocalLibraryRepository.webBookStorageKeyFor(first.collection.id),
            )
            .exists(),
        isFalse,
      );
    },
  );
}
