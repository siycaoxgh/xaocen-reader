import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_book_cover_repository.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/domain/reader/reader_content.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_loader.dart';

List<int> _epubBytes() {
  final archive = Archive();
  archive.addFile(ArchiveFile.string('mimetype', 'application/epub+zip'));
  archive.addFile(
    ArchiveFile.string(
      'META-INF/container.xml',
      '''<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OPS/package.opf"/></rootfiles></container>''',
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'OPS/package.opf',
      '''<package xmlns="http://www.idpf.org/2007/opf"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>持久化 EPUB</dc:title><dc:creator>测试作者</dc:creator><meta name="cover" content="cover"/></metadata><manifest><item id="one" href="one.xhtml" media-type="application/xhtml+xml"/><item id="two" href="two.xhtml" media-type="application/xhtml+xml"/><item id="image" href="pixel.png" media-type="image/png"/><item id="cover" href="cover.png" media-type="image/png"/><item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/></manifest><spine><itemref idref="one"/><itemref idref="two"/></spine></package>''',
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'OPS/one.xhtml',
      '<html><head><style>h1{font-weight:bold}</style></head><body><h1>第一章</h1><p><em>第一段。</em></p><img src="pixel.png" alt="封面"/></body></html>',
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'OPS/two.xhtml',
      '<html><body><h1>第二章</h1><p>第二段。</p></body></html>',
    ),
  );
  archive.addFile(ArchiveFile('OPS/pixel.png', 4, [0, 0, 0, 0]));
  archive.addFile(ArchiveFile('OPS/cover.png', 4, [4, 3, 2, 1]));
  archive.addFile(
    ArchiveFile.string(
      'OPS/nav.xhtml',
      '<html xmlns:epub="http://www.idpf.org/2007/ops"><body><nav epub:type="toc"><ol><li><a href="one.xhtml">第一章</a></li><li><a href="two.xhtml">第二章</a></li></ol></nav></body></html>',
    ),
  );
  return ZipEncoder().encode(archive)!;
}

void main() {
  late AppDatabase db;
  late Directory libraryRoot;
  late LocalLibraryRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting();
    libraryRoot = await Directory.systemTemp.createTemp('xaocen_epub_import');
    final indexBytes = File(
      'assets/encoding/gb18030_index.bin',
    ).readAsBytesSync();
    repository = LocalLibraryRepository(
      database: db,
      fileManager: LibraryFileManager(libraryRoot: libraryRoot),
      encodingIndexProvider: MemoryEncodingIndexProvider(
        const Gb18030IndexLoader().parse(indexBytes),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    if (await libraryRoot.exists()) await libraryRoot.delete(recursive: true);
  });

  test(
    'EPUB import persists package, metadata, spine documents and TOC',
    () async {
      final external = File(
        '${libraryRoot.path}${Platform.pathSeparator}book.epub',
      );
      await external.writeAsBytes(_epubBytes());

      final result = await repository.importEpub(
        ImportEpubRequest(externalFile: external),
      );
      expect(result.alreadyImported, isFalse);
      expect(result.collection.sourceId, startsWith('epub-source:'));
      expect(result.collection.title, '持久化 EPUB');
      expect(result.collection.author, '测试作者');
      expect(result.collection.metadataSource, 'autoDetected');
      expect(result.collection.titleSource, 'autoDetected');
      expect(result.collection.authorSource, 'autoDetected');
      expect(result.collection.coverSource, 'autoDetected');
      expect(result.collection.coverPath, startsWith('library/epub/'));
      expect(result.collection.coverPath, endsWith('/cover.png'));
      expect(
        await repository.fileManager
            .resolveStoragePath(result.collection.coverPath!)
            .exists(),
        isTrue,
      );
      final coverRepository = LocalBookCoverRepository(
        database: db,
        fileManager: repository.fileManager,
      );
      final manualCover = File(
        '${libraryRoot.path}${Platform.pathSeparator}manual.png',
      );
      await manualCover.writeAsBytes([9, 8, 7, 6]);
      final manualPath = await coverRepository.importCover(
        collectionId: result.collection.id,
        source: manualCover,
      );
      expect(manualPath, startsWith('library/covers/'));
      final manual = await repository.getCollection(result.collection.id);
      expect(manual?.coverSource, 'manual');
      expect(coverRepository.resolve(manual?.coverPath), isNotNull);

      await coverRepository.removeCover(result.collection.id, manualPath);
      final restoredCover = await repository.getCollection(
        result.collection.id,
      );
      expect(restoredCover?.coverSource, 'autoDetected');
      expect(restoredCover?.coverPath, result.collection.coverPath);
      expect(coverRepository.resolve(restoredCover?.coverPath), isNotNull);

      final docs = await repository.getDocuments(result.collection.id);
      final toc = await repository.getToc(result.collection.id);
      expect(docs, hasLength(2));
      expect(toc.map((e) => e.title), ['第一章', '第二章']);
      final content = ReaderContentAdapterRegistry.defaultInstance.resolve(
        collection: result.collection,
        documents: docs,
        navigation: toc,
      );
      expect(content.identity.sourceKind, ReaderContentSourceKinds.epub);
      expect(content.primaryDocument?.storagePath, docs.first.storagePath);
      expect(docs.every((d) => d.storagePath.contains('/epub/')), isTrue);
      expect(
        await repository.fileManager
            .resolveStoragePath(docs.first.storagePath)
            .exists(),
        isTrue,
      );
      final loaded =
          await NormalizedDocumentLoader(
            fileManager: repository.fileManager,
          ).load(
            storagePath: docs.first.storagePath,
            expectedLength: result.collection.normalizedCharacterLength,
          );
      expect(loaded.text, contains('第一段。'));
      expect(loaded.text, contains('第二段。'));
      expect(loaded.rendering?.styleRuns, isNotEmpty);
      expect(loaded.rendering?.images, hasLength(1));
      expect(
        await repository.fileManager
            .resolveStoragePath(loaded.rendering!.images.single.storagePath)
            .exists(),
        isTrue,
      );

      final reopened = await repository.getCollection(result.collection.id);
      expect(reopened?.title, result.collection.title);
      expect(reopened?.sourcePath, contains('/epub/'));

      final duplicate = await repository.importEpub(
        ImportEpubRequest(externalFile: external),
      );
      expect(duplicate.alreadyImported, isTrue);
      expect(await repository.listCollections(), hasLength(1));
    },
  );
}
