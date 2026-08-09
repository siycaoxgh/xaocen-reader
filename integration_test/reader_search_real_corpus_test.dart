import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/reader_search.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const paths = [
    r'C:\Users\TOM\Desktop\测试\因果快递-20260625.txt',
    r'C:\Users\TOM\Desktop\测试\无章节数字测试.txt',
    r'C:\Users\TOM\Desktop\测试\苟在初圣魔门当人材(1-500章).txt',
    r'C:\Users\TOM\Desktop\测试\青山(501-809章).txt',
  ];

  test('M5.2c all four real TXT search normalized UTF-16 anchors', () async {
    final files = paths.map(File.new).toList(growable: false);
    for (final file in files) {
      expect(await file.exists(), isTrue, reason: '真实语料存在: ${file.path}');
    }

    final root = Directory.systemTemp.createTempSync('xaocen-search-corpus');
    final db = AppDatabase.forTesting();
    try {
      final fileManager = LibraryFileManager(libraryRoot: root);
      final repository = LocalLibraryRepository(
        database: db,
        fileManager: fileManager,
        encodingIndexProvider: FlutterAssetEncodingIndexProvider(),
      );
      final loader = NormalizedDocumentLoader(fileManager: fileManager);
      final search = ReaderSearchService();

      for (final file in files) {
        final imported = await repository.importTxt(
          ImportTxtRequest(externalFile: file, confirmLargeFile: true),
        );
        final documents = await repository.getDocuments(imported.collection.id);
        final toc = await repository.getToc(imported.collection.id);
        final document = await loader.load(
          storagePath: documents.first.storagePath,
        );
        final anchors = [
          0,
          _safeAnchor(document.text, document.text.length ~/ 2),
          _safeAnchor(
            document.text,
            (document.text.length - 8).clamp(0, document.text.length),
          ),
        ];
        for (final anchor in anchors) {
          final queryEnd = _queryEnd(document.text, anchor);
          final query = document.text.substring(anchor, queryEnd);
          final results = await search.search(
            text: document.text,
            query: query,
            toc: toc,
            maxResults: 100,
          );
          final hit = results.where((result) => result.startOffset == anchor);
          expect(hit, isNotEmpty, reason: '${file.path} anchor=$anchor');
          final result = hit.first;
          expect(
            document.text.substring(result.startOffset, result.endOffset),
            query,
          );
          expect(result.contextStartOffset, lessThanOrEqualTo(anchor));
          expect(
            result.contextEndOffset,
            greaterThanOrEqualTo(result.endOffset),
          );
          expect(result.derivedChapterTitle, isNotEmpty);
        }
      }
    } finally {
      await db.close();
      if (await root.exists()) await root.delete(recursive: true);
    }
  });
}

int _queryEnd(String text, int start) {
  if (start >= text.length) return text.length;
  var end = (start + 8).clamp(0, text.length).toInt();
  if (end < text.length &&
      text.codeUnitAt(end) >= 0xDC00 &&
      text.codeUnitAt(end) <= 0xDFFF) {
    end++;
  }
  return end;
}

int _safeAnchor(String text, int offset) {
  if (offset > 0 && offset < text.length) {
    final unit = text.codeUnitAt(offset);
    if (unit >= 0xDC00 && unit <= 0xDFFF) return offset - 1;
  }
  return offset;
}
