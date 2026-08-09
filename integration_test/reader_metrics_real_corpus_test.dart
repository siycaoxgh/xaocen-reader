import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/domain/reader/reader_progress_state.dart';
import 'package:xaocen_reader/domain/reader/reading_mode.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/paged_reader_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const corpusPath = String.fromEnvironment(
    'XAOCEN_REAL_TXT_DIR',
    defaultValue: r'C:\Users\TOM\Desktop\测试',
  );

  test(
    'M5.1e.1 real corpus typography relayout: all TXT, logical error 0',
    () async {
      final corpus = Directory(corpusPath);
      expect(await corpus.exists(), isTrue, reason: '真实语料目录必须存在: $corpusPath');
      final files =
          corpus
              .listSync()
              .whereType<File>()
              .where((file) => file.path.toLowerCase().endsWith('.txt'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      expect(files, isNotEmpty);

      final libraryRoot = await Directory.systemTemp.createTemp('m51b_corpus');
      final db = AppDatabase.forTesting();
      try {
        final manager = LibraryFileManager(libraryRoot: libraryRoot);
        final repository = LocalLibraryRepository(
          database: db,
          fileManager: manager,
          encodingIndexProvider: FlutterAssetEncodingIndexProvider(),
        );
        final progress = ReadingProgressRepository(db: db);
        final loader = NormalizedDocumentLoader(fileManager: manager);
        final corpusStates = <ReaderProgressState>[];

        for (final file in files) {
          final imported = await repository.importTxt(
            ImportTxtRequest(externalFile: file, confirmLargeFile: true),
          );
          final documents = await repository.getDocuments(
            imported.collection.id,
          );
          final document = await loader.load(
            storagePath: documents.first.storagePath,
          );
          final blockIndex = ReaderBlockIndex.build(
            text: document.text,
            targetBlockSize: 6144,
          );
          final offsets = <int>{
            0,
            document.text.length ~/ 2,
            document.text.isEmpty ? 0 : document.text.length - 1,
          };

          for (final offset in offsets) {
            final controller = PagedReaderController(
              collectionId: imported.collection.id,
              document: document,
              progressRepository: progress,
              blockIndex: blockIndex,
              style: const TextStyle(fontSize: 17, height: 1.7),
              width: 400,
              height: 600,
              paddingTop: 8,
              paddingBottom: 10,
              paddingLeft: 16,
              paddingRight: 18,
            );
            final locator = ReaderLocator(
              collectionId: imported.collection.id,
              absoluteCharacterOffset: offset,
            );
            controller.open(locator);
            final before = controller.currentPage!;
            final beforeSignature = controller.lastSignature;

            controller.freezeWrites();
            controller.relayout(
              width: 400,
              height: 600,
              style: const TextStyle(
                fontSize: 22,
                height: 1.9,
                letterSpacing: .3,
              ),
              paragraphSpacing: 6,
              firstLineIndent: 2,
              paddingTop: 14,
              paddingBottom: 20,
              paddingLeft: 26,
              paddingRight: 34,
            );
            final after = controller.currentPage!;
            final afterLocator = controller.confirmedLocator!;
            final logicalError = (afterLocator.absoluteCharacterOffset - offset)
                .abs();

            expect(controller.lastSignature, isNot(beforeSignature));
            expect(after.contains(offset), isTrue);
            expect(afterLocator, locator);
            expect(logicalError, 0);
            expect(controller.window.pageCount, lessThanOrEqualTo(6));
            // ignore: avoid_print
            print(
              'M5.1e.1 corpus=${file.uri.pathSegments.last} '
              'locator=$offset->$afterLocator before=$before after=$after '
              'logicalError=$logicalError',
            );
            controller.unfreezeWrites();
            controller.dispose();
          }

          if (file.path.contains('1-500')) {
            expect(imported.collection.itemCount, 473);
          }
          if (file.lengthSync() > 7 * 1024 * 1024) {
            expect(imported.collection.itemCount, 1);
          }
          final state = ReaderProgressState(
            collectionId: imported.collection.id,
            absoluteCharacterOffset: document.text.length ~/ 2,
            readingMode: corpusStates.length.isEven
                ? ReadingMode.paged
                : ReadingMode.vertical,
          );
          await progress.saveProgress(state);
          corpusStates.add(state);
        }

        expect(corpusStates, hasLength(files.length));
        expect(corpusStates.length, greaterThanOrEqualTo(2));
        for (var round = 0; round < 4; round++) {
          for (final expected in corpusStates.reversed) {
            expect(await progress.getProgress(expected.collectionId), expected);
          }
        }
      } finally {
        await db.close();
        if (await libraryRoot.exists()) {
          await libraryRoot.delete(recursive: true);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
