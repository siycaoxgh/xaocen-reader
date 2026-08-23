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
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_data.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/web_book_chapter_cache_service.dart';
import 'package:xaocen_reader/sources/remote/web_book_runtime.dart';
import 'package:xaocen_reader/sources/remote/xaocen_web_book_source_definition.dart';

void main() {
  final enabled =
      const String.fromEnvironment('XAOCEN_SUDUGU_ON_DEMAND') == '1';

  test(
    'Sudugu uncached chapter is fetched once and reopened from cache',
    () async {
      final endpoint = const String.fromEnvironment('XAOCEN_LIVE_SOURCE_URL');
      if (endpoint.isEmpty) {
        fail('Set XAOCEN_LIVE_SOURCE_URL locally for live network acceptance');
      }
      final detailUri = Uri.parse(endpoint);
      final definition = XaocenWebBookSourceDefinition.fromJson({
        'schema': XaocenWebBookSourceDefinition.schema,
        'version': XaocenWebBookSourceDefinition.schemaVersion,
        'sourceId': 'manual-sudugu-on-demand',
        'name': '速读谷 · 青山（按需验收）',
        'endpoint': detailUri.toString(),
        'searchEndpoint': null,
        'bookKey': '5',
        'ruleVersion': 1,
        'rules': <String, Object?>{
          'search': <String, Object?>{
            'itemSelector': '#unused-search-result',
            'title': <String, Object?>{},
          },
          'detail': <String, Object?>{
            'selector': '.container',
            'title': <String, Object?>{'selector': 'h1 a'},
            'author': <String, Object?>{
              'selector': 'a[href*="/zuozhe/"]',
              'removePrefix': '作者：',
            },
            'description': <String, Object?>{'selector': '.des'},
          },
          'toc': <String, Object?>{
            'entrySelector': r'#list.dir a[href$=".html"]',
          },
          'chapter': <String, Object?>{'bodySelector': '.con'},
        },
      });
      final transport = RemoteHttpTransport();
      final temp = await DataRoot.forDirectory(
        await Directory.systemTemp.createTemp('xaocen-sudugu-on-demand-'),
        profileId: 'manual',
      );
      final database = AppDatabase.forTesting();
      final files = LibraryFileManager(libraryRoot: temp.booksDirectory);
      final repository = LocalLibraryRepository(
        database: database,
        fileManager: files,
        encodingIndexProvider: MemoryEncodingIndexProvider(
          Gb18030IndexData(entries: Uint16List(0), anchors: Uint32List(0)),
        ),
      );
      addTearDown(() async {
        await transport.close();
        await database.close();
        await temp.rootDirectory.delete(recursive: true);
      });
      final registry = WebBookSourceRegistry(temp);
      await registry.importDefinition(definition);
      final source = definition.toSource();
      final runtime = WebBookHttpRuntime(
        transport: transport,
        rules: definition.toExtractionRules(),
      );
      final detail = await runtime.openDetail(
        source: source,
        result: WebBookSearchResult(
          bookKey: '5',
          title: '青山',
          detailUri: detailUri,
        ),
      );
      final toc = await runtime.loadTableOfContents(
        source: source,
        detail: detail,
      );
      final firstThree = [
        for (final entry in toc.entries.take(3))
          await runtime.openChapter(
            source: source,
            detail: detail,
            entry: entry,
          ),
      ];
      final projection = runtime.toReaderContent(
        source: source,
        detail: detail,
        chapters: firstThree,
        contentId: LocalLibraryRepository.webBookCollectionIdFor(
          source.id.value,
          detail.bookKey,
        ),
      );
      final imported = await repository.importWebBook(
        ImportWebBookRequest(
          source: source,
          detail: detail,
          projection: projection,
          sourceName: '速读谷',
          catalogEntries: toc.entries,
        ),
      );
      final service = WebBookChapterCacheService(
        repository: repository,
        registry: registry,
        transport: transport,
      );
      final target = toc.entries[3];
      final fetched = await service.ensureChapter(
        collectionId: imported.collection.id,
        chapterKey: target.chapterKey,
      );
      expect(fetched.status, WebBookUpdateStatus.updated);
      final cachedToc = await repository.getToc(imported.collection.id);
      final cachedTarget = cachedToc.firstWhere(
        (entry) => entry.orderIndex == target.orderIndex,
      );
      expect(cachedTarget.itemId, isNotNull);
      expect(cachedTarget.startCharacterOffset, greaterThan(0));

      final reopened = await service.ensureChapter(
        collectionId: imported.collection.id,
        chapterKey: target.chapterKey,
      );
      expect(reopened.status, WebBookUpdateStatus.noChanges);
      expect(
        (await repository.getDocuments(imported.collection.id)),
        hasLength(4),
      );
    },
    skip: !enabled
        ? 'Set XAOCEN_SUDUGU_ON_DEMAND=1 for live network acceptance'
        : false,
  );
}
