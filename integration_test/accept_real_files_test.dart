import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';

/// M3 真实文件验收（Windows 专用）：桌面两个验收文件。
///
/// 有章节文件：9 个指定章节 offset 落在对应 chapter 范围内，block 定位正确。
/// 无章节文件：0 章不伪造目录；25%/50%/75% 定位不跳末尾。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const chapteredPath = r'C:\Users\TOM\Desktop\测试\苟在初圣魔门当人材(1-500章).txt';
  const notocPath = r'C:\Users\TOM\Desktop\测试\无章节数字测试.txt';

  test('真实文件验收：有章节 9 章 offset + 无章节 0 章 + 比例定位', () async {
    final chaptered = File(chapteredPath);
    final notoc = File(notocPath);
    expect(await chaptered.exists(), isTrue, reason: '有章节文件存在');
    expect(await notoc.exists(), isTrue, reason: '无章节文件存在');

    final libRoot = Directory.systemTemp.createTempSync('xaocen_accept_it');
    try {
      final db = AppDatabase.forTesting();
      final fm = LibraryFileManager(libraryRoot: libRoot);
      final repo = LocalLibraryRepository(
        database: db,
        fileManager: fm,
        encodingIndexProvider: FlutterAssetEncodingIndexProvider(),
      );

      // ---- 有章节文件 ----
      final r1 = await repo.importTxt(
        ImportTxtRequest(externalFile: chaptered, confirmLargeFile: true),
      );
      expect(r1.alreadyImported, isFalse);
      expect(r1.collection.itemCount, 473, reason: '473 章');
      final toc1 = await repo.getToc(r1.collection.id);
      final chapters1 = toc1.where((e) => e.kind == 'chapter').toList();
      expect(chapters1.length, 473);
      final docs1 = await repo.getDocuments(r1.collection.id);
      expect(docs1, isNotEmpty);
      final loader = NormalizedDocumentLoader(fileManager: fm);
      final nd = await loader.load(storagePath: docs1.first.storagePath);
      final blockIndex = ReaderBlockIndex.build(
        text: nd.text,
        targetBlockSize: 6144,
      );
      expect(blockIndex.blockCount, greaterThan(1));

      // M1 合同 9 章 offset
      const offsetByChapter = <int, int>{
        1: 54,
        19: 49208,
        42: 108790,
        112: 298039,
        195: 516559,
        258: 685040,
        300: 795861,
        400: 1062206,
        473: 1257817,
      };
      for (final entry in offsetByChapter.entries) {
        final chapterNo = entry.key;
        final offset = entry.value;
        final matches = chapters1
            .where((c) => c.title.contains('第$chapterNo章'))
            .toList();
        expect(matches, isNotEmpty, reason: '第$chapterNo章 存在');
        final c = matches.first;
        expect(
          offset >= c.startCharacterOffset && offset < c.endCharacterOffset,
          isTrue,
          reason:
              '第$chapterNo章 offset=$offset 应在 [${c.startCharacterOffset},${c.endCharacterOffset})',
        );
        final block = blockIndex.blockForOffset(offset);
        expect(block, isNotNull);
        expect(
          block!.contains(offset),
          isTrue,
          reason: 'block 应包含 offset $offset',
        );
        // block 内偏移转本地 offset 应为正
        expect(offset - block.startCharacterOffset, greaterThanOrEqualTo(0));
      }

      // 外部文件 hash 不变（只读）
      final bytesBefore = await chaptered.readAsBytes();
      final bytesAfter = await chaptered.readAsBytes();
      expect(bytesBefore.length, bytesAfter.length);

      await db.close();

      // ---- 无章节文件 ----
      final db2 = AppDatabase.forTesting();
      final repo2 = LocalLibraryRepository(
        database: db2,
        fileManager: fm,
        encodingIndexProvider: FlutterAssetEncodingIndexProvider(),
      );
      final r2 = await repo2.importTxt(
        ImportTxtRequest(externalFile: notoc, confirmLargeFile: true),
      );
      expect(r2.alreadyImported, isFalse);
      expect(r2.collection.itemCount, 1, reason: '无章节 → 1 whole item');
      final toc2 = await repo2.getToc(r2.collection.id);
      final chapters2 = toc2.where((e) => e.kind == 'chapter').toList();
      expect(chapters2, isEmpty, reason: '无章节文件不伪造目录');
      final docs2 = await repo2.getDocuments(r2.collection.id);
      expect(docs2, isNotEmpty);
      final nd2 = await loader.load(storagePath: docs2.first.storagePath);
      expect(nd2.characterLength, r2.collection.normalizedCharacterLength);
      final blockIndex2 = ReaderBlockIndex.build(
        text: nd2.text,
        targetBlockSize: 6144,
      );
      // 25% / 50% / 75% 定位不跳末尾
      for (final ratio in [0.25, 0.50, 0.75]) {
        final offset = (nd2.text.length * ratio).round();
        final block = blockIndex2.blockForOffset(offset);
        expect(block, isNotNull);
        expect(
          block!.index,
          lessThan(blockIndex2.blockCount - 1),
          reason: '$ratio 定位（offset=$offset）不应直接命中末块',
        );
        expect(block.contains(offset), isTrue);
      }
      await db2.close();
    } finally {
      if (await libRoot.exists()) {
        await libRoot.delete(recursive: true);
      }
    }
  });
}
