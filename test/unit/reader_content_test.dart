import 'package:flutter_test/flutter_test.dart';

import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/domain/reader/reader_content.dart';

void main() {
  final collection = LibraryCollection(
    id: 'collection-1',
    sourceId: 'local-txt-source:source-hash',
    title: '测试书',
    subtitle: null,
    itemCount: 2,
    normalizedCharacterLength: 120,
    detectedEncoding: TextEncoding.utf8,
    sourceSize: 140,
    importedAt: DateTime(2026, 1, 1),
    author: '作者',
    description: '简介',
    metadataSource: 'autoDetected',
    titleSource: 'autoDetected',
    authorSource: 'autoDetected',
  );

  final documents = <LibraryDocument>[
    const LibraryDocument(
      id: 'document-1',
      itemId: 'item-1',
      storagePath: 'collections/collection-1/normalized.txt',
      mediaType: 'text/plain',
      startCharacterOffset: 0,
      endCharacterOffset: 120,
      contentHash: 'normalized-hash',
      normalizationVersion: 'v1',
    ),
  ];

  final navigation = <LibraryTocEntry>[
    const LibraryTocEntry(
      id: 'chapter-1',
      collectionId: 'collection-1',
      itemId: 'item-1',
      parentId: null,
      kind: 'chapter',
      level: 0,
      title: '第一章',
      orderIndex: 0,
      startCharacterOffset: 0,
      endCharacterOffset: 60,
    ),
    const LibraryTocEntry(
      id: 'chapter-2',
      collectionId: 'collection-1',
      itemId: 'item-2',
      parentId: null,
      kind: 'chapter',
      level: 0,
      title: '第二章',
      orderIndex: 1,
      startCharacterOffset: 60,
      endCharacterOffset: 120,
    ),
  ];

  test('TXT adapter maps identity, metadata and source projections', () {
    final content = const TxtReaderContentAdapter().adapt(
      collection: collection,
      documents: documents,
      navigation: navigation,
    );

    expect(content.identity.contentId, 'collection-1');
    expect(content.identity.sourceId, 'local-txt-source:source-hash');
    expect(content.identity.sourceKind, ReaderContentSourceKinds.localTxt);
    expect(content.identity.sourceRevision, 'normalized-hash');
    expect(content.metadata.title, '测试书');
    expect(content.metadata.author, '作者');
    expect(content.metadata.metadataSource, 'autoDetected');
    expect(content.primaryDocument?.storagePath, documents.single.storagePath);
    expect(content.navigation.map((entry) => entry.title), ['第一章', '第二章']);
    expect(content.normalizedCharacterLength, 120);
  });

  test('TXT adapter preserves source order and absolute UTF-16 offsets', () {
    final content = const TxtReaderContentAdapter().adapt(
      collection: collection,
      documents: documents,
      navigation: navigation,
    );

    expect(content.navigation.map((entry) => entry.orderIndex).toList(), [
      0,
      1,
    ]);
    expect(
      content.navigation
          .map(
            (entry) => (entry.startCharacterOffset, entry.endCharacterOffset),
          )
          .toList(),
      [(0, 60), (60, 120)],
    );
  });

  test('contract projections are read-only', () {
    final content = const TxtReaderContentAdapter().adapt(
      collection: collection,
      documents: documents,
      navigation: navigation,
    );

    expect(
      () => content.documents.add(documents.single),
      throwsUnsupportedError,
    );
    expect(
      () => content.navigation.add(navigation.first),
      throwsUnsupportedError,
    );
  });

  test(
    'unimplemented source kinds remain explicit and do not masquerade as TXT',
    () {
      final nonTxt = LibraryCollection(
        id: collection.id,
        sourceId: 'rss-source:feed-1',
        title: collection.title,
        subtitle: collection.subtitle,
        itemCount: collection.itemCount,
        normalizedCharacterLength: collection.normalizedCharacterLength,
        detectedEncoding: collection.detectedEncoding,
        sourceSize: collection.sourceSize,
        importedAt: collection.importedAt,
      );

      final content = ReaderContentAdapterRegistry.defaultInstance.resolve(
        collection: nonTxt,
        documents: documents,
        navigation: navigation,
      );

      expect(content.identity.sourceKind, ReaderContentSourceKinds.unknown);
      expect(content.identity.sourceId, 'rss-source:feed-1');
    },
  );
}
