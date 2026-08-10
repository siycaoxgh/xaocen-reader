import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/reader/chapter_page_metrics.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/paged_reader_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const corpusPath = String.fromEnvironment(
    'XAOCEN_REAL_TXT_DIR',
    defaultValue: r'C:\Users\TOM\Desktop\测试',
  );

  test(
    'M5.3.2 paged chapter metrics: all real TXT, bounded current chapter only',
    () async {
      final corpus = Directory(corpusPath);
      expect(await corpus.exists(), isTrue);
      final files =
          corpus
              .listSync()
              .whereType<File>()
              .where((file) => file.path.toLowerCase().endsWith('.txt'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      expect(files, hasLength(4));

      final root = await Directory.systemTemp.createTemp('m532_metrics');
      final db = AppDatabase.forTesting();
      try {
        final manager = LibraryFileManager(libraryRoot: root);
        final library = LocalLibraryRepository(
          database: db,
          fileManager: manager,
          encodingIndexProvider: FlutterAssetEncodingIndexProvider(),
        );
        final loader = NormalizedDocumentLoader(fileManager: manager);
        final progress = ReadingProgressRepository(db: db);
        final resolver = ChapterPageMetricsResolver();

        for (final file in files) {
          final imported = await library.importTxt(
            ImportTxtRequest(externalFile: file, confirmLargeFile: true),
          );
          final documentRow = (await library.getDocuments(
            imported.collection.id,
          )).first;
          final document = await loader.load(
            storagePath: documentRow.storagePath,
          );
          final toc = await library.getToc(imported.collection.id);
          final chapters = toc
              .where((entry) => entry.kind == 'chapter')
              .toList();
          final starts = chapters
              .map((entry) => entry.startCharacterOffset)
              .toList();
          final blockIndex = ReaderBlockIndex.build(
            text: document.text,
            targetBlockSize: 6144,
          );
          final samples = <int>[];
          if (chapters.isEmpty) {
            samples.add(document.text.length ~/ 2);
          } else {
            final selected = <LibraryTocEntry>{
              chapters.first,
              chapters[chapters.length ~/ 2],
              chapters.last,
            };
            for (final chapter in selected) {
              samples.add(chapter.startCharacterOffset);
              final nextStart = chapters
                  .map((entry) => entry.startCharacterOffset)
                  .where((offset) => offset > chapter.startCharacterOffset)
                  .fold<int>(
                    document.text.length,
                    (value, offset) => value < offset ? value : offset,
                  );
              if (nextStart - chapter.startCharacterOffset > 2) {
                samples.add(
                  chapter.startCharacterOffset +
                      (nextStart - chapter.startCharacterOffset) ~/ 2,
                );
              }
            }
          }

          if (chapters.isEmpty) {
            final controller = PagedReaderController(
              collectionId: imported.collection.id,
              document: document,
              progressRepository: progress,
              blockIndex: blockIndex,
              style: const TextStyle(fontSize: 17, height: 1.7),
              width: 400,
              height: 600,
            );
            final metrics = await resolver.resolve(
              engine: controller.engine,
              locator: ReaderLocator(
                collectionId: imported.collection.id,
                absoluteCharacterOffset: samples.single,
              ),
              toc: toc,
              normalizedLength: document.text.length,
              collectionId: imported.collection.id,
              normalizedHash: document.normalizedHash,
              isCurrent: () => true,
            );
            expect(
              metrics,
              isNull,
              reason: 'no-chapter must not derive chapter pages',
            );
            controller.dispose();
          } else {
            for (final offset in samples) {
              final controller = PagedReaderController(
                collectionId: imported.collection.id,
                document: document,
                progressRepository: progress,
                blockIndex: blockIndex,
                style: const TextStyle(fontSize: 17, height: 1.7),
                width: 400,
                height: 600,
                chapterStartOffsets: starts,
              );
              final locator = ReaderLocator(
                collectionId: imported.collection.id,
                absoluteCharacterOffset: offset,
              );
              controller.open(locator);
              final metrics = await resolver.resolve(
                engine: controller.engine,
                locator: locator,
                toc: toc,
                normalizedLength: document.text.length,
                collectionId: imported.collection.id,
                normalizedHash: document.normalizedHash,
                isCurrent: () => true,
              );
              expect(metrics, isNotNull);
              expect(metrics!.currentPage.contains(offset), isTrue);
              expect(
                metrics.currentPageNumber,
                inInclusiveRange(1, metrics.totalPageCount),
              );
              expect(metrics.totalPageCount, greaterThan(0));
              if (offset == metrics.boundary.startOffset) {
                expect(metrics.currentPageNumber, 1);
                expect(metrics.currentPage.startCharacterOffset, offset);
              }
              // ignore: avoid_print
              print(
                'M5.3.2 file=${file.uri.pathSegments.last} '
                'chapter=${metrics.boundary.chapter.displayTitle} '
                'page=${metrics.currentPageNumber}/${metrics.totalPageCount} '
                'elapsedMs=${metrics.elapsed.inMilliseconds} cache=${metrics.fromCache}',
              );
              controller.dispose();
            }
          }
        }
      } finally {
        await db.close();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
