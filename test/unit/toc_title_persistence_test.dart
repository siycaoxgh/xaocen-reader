import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/collection_repair_service.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/data/repositories/managed_collection_health.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_data.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_loader.dart';

/// M3.2 数据持久化测试（任务书 §十三 数据测试）。
///
/// 核心：index 完整标题写入 Drift；ContentItem 与 TocEntry 标题一致；
/// 旧短标题数据可修复；修复不改变 collectionId/offset/reading_progress。
void main() {
  late AppDatabase db;
  late Directory libRoot;
  late LocalLibraryRepository repo;
  late EncodingIndexProvider encProvider;

  setUp(() async {
    db = AppDatabase.forTesting();
    libRoot = Directory.systemTemp.createTempSync('xaocen_toc_title_test');
    encProvider = MemoryEncodingIndexProvider(
      const _IndexDataLoader().loadFromAsset(),
    );
    repo = LocalLibraryRepository(
      database: db,
      fileManager: LibraryFileManager(libraryRoot: libRoot),
      encodingIndexProvider: encProvider,
    );
  });

  tearDown(() async {
    await db.close();
    if (await libRoot.exists()) await libRoot.delete(recursive: true);
  });

  Future<ImportTxtResult> importBytes(
    List<int> bytes, {
    String name = 'test.txt',
  }) async {
    final f = File('${libRoot.path}/in_$name');
    await f.writeAsBytes(bytes);
    return repo.importTxt(
      ImportTxtRequest(externalFile: f, confirmLargeFile: true),
    );
  }

  group('M3.2 数据持久化', () {
    test('1. index 完整标题写入 Drift（toc_entries + content_items）', () async {
      final content = '第六卷 人间风雨\n第1章 百世书\n正文内容\n第2章 剥皮\n正文\n';
      final r = await importBytes(utf8.encode(content));

      final toc = await repo.getToc(r.collection.id);
      final chapters = toc.where((e) => e.kind == 'chapter').toList();
      expect(chapters.length, 2);
      expect(chapters[0].displayTitle, '第1章 百世书');
      expect(chapters[0].title, '第1章 百世书');

      final volumes = toc.where((e) => e.kind == 'volume').toList();
      expect(volumes.length, 1);
      expect(volumes[0].displayTitle, '第六卷 人间风雨');

      // content_items 标题一致
      final items = await repo.getItems(r.collection.id);
      final itemTitles = items.map((i) => i.title).toList();
      expect(itemTitles, contains('第1章 百世书'));
      expect(itemTitles, contains('第2章 剥皮'));
    });

    test('2. ContentItem 与 TocEntry 标题一致', () async {
      final content = '第1章 开端\n正文\n第2章 发展\n正文\n';
      final r = await importBytes(utf8.encode(content));
      final toc = await repo.getToc(r.collection.id);
      final items = await repo.getItems(r.collection.id);
      final tocByOffset = {
        for (final e in toc)
          if (e.kind == 'chapter') e.startCharacterOffset: e.displayTitle,
      };
      for (final it in items) {
        final expectTitle = tocByOffset[it.startCharacterOffset];
        if (expectTitle != null) {
          expect(it.title, expectTitle);
        }
      }
    });

    test('3. 旧短标题数据可修复（repair 后标题完整）', () async {
      final content = '第1章 开端\n正文内容\n第2章 发展\n正文\n';
      final r = await importBytes(utf8.encode(content));
      final collectionId = r.collection.id;

      // 模拟旧数据：index.json parserVersion 降为 1.0.0（旧导入特征）
      // + 把 toc_entries / content_items 标题改成短标题
      final hash = collectionId.replaceFirst('local-txt:', '');
      final indexFile = File('${libRoot.path}/local_txt/$hash/index.json');
      final idx =
          jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
      idx['parserVersion'] = '1.0.0';
      await indexFile.writeAsString(jsonEncode(idx));
      await db.transaction(() async {
        final tocRows = await (db.select(
          db.tocEntries,
        )..where((t) => t.collectionId.equals(collectionId))).get();
        for (final row in tocRows) {
          if (row.kind == 'chapter') {
            await (db.update(db.tocEntries)..where((t) => t.id.equals(row.id)))
                .write(TocEntriesCompanion(title: Value('第1章')));
          }
        }
        final itemRows = await (db.select(
          db.contentItems,
        )..where((t) => t.collectionId.equals(collectionId))).get();
        for (final row in itemRows) {
          await (db.update(db.contentItems)..where((t) => t.id.equals(row.id)))
              .write(ContentItemsCompanion(title: Value('第1章')));
        }
      });

      // 健康检查应报告标题不完整
      final health = await ManagedCollectionHealthCheck(
        database: db,
        fileManager: LibraryFileManager(libraryRoot: libRoot),
      ).check(collectionId);
      expect(health.ok, isFalse);
      expect(
        health.problems.any((p) => p.contains('标题不完整')),
        isTrue,
        reason: '短标题应被健康检查识别',
      );

      // repair 修复
      final repair = CollectionRepairService(
        database: db,
        fileManager: LibraryFileManager(libraryRoot: libRoot),
        encodingIndexProvider: encProvider,
      );
      final result = await repair.repair(collectionId);
      expect(result.repaired, isTrue);

      // 修复后标题完整
      final toc2 = await repo.getToc(collectionId);
      final chapters2 = toc2.where((e) => e.kind == 'chapter').toList();
      expect(chapters2[0].displayTitle, '第1章 开端');
      expect(chapters2[1].displayTitle, '第2章 发展');

      // 健康检查通过
      final health2 = await ManagedCollectionHealthCheck(
        database: db,
        fileManager: LibraryFileManager(libraryRoot: libRoot),
      ).check(collectionId);
      expect(health2.ok, isTrue);
    });

    test('4. 修复不改变 collectionId', () async {
      final content = '第1章 开端\n正文\n';
      final r = await importBytes(utf8.encode(content));
      final collectionId = r.collection.id;

      final repair = CollectionRepairService(
        database: db,
        fileManager: LibraryFileManager(libraryRoot: libRoot),
        encodingIndexProvider: encProvider,
      );
      await repair.repair(collectionId);

      final collections = await repo.listCollections();
      expect(collections.map((c) => c.id), contains(collectionId));
    });

    test('5. 修复不改变 offset', () async {
      final content = '第1章 开端\n正文内容\n第2章 发展\n正文\n';
      final r = await importBytes(utf8.encode(content));
      final collectionId = r.collection.id;
      final tocBefore = await repo.getToc(collectionId);
      final offsetsBefore = tocBefore
          .map((e) => e.startCharacterOffset)
          .toList();

      final repair = CollectionRepairService(
        database: db,
        fileManager: LibraryFileManager(libraryRoot: libRoot),
        encodingIndexProvider: encProvider,
      );
      await repair.repair(collectionId);

      final tocAfter = await repo.getToc(collectionId);
      expect(
        tocAfter.map((e) => e.startCharacterOffset).toList(),
        offsetsBefore,
        reason: 'repair 不得改变章节 offset',
      );
    });

    test('6. 修复不清除 reading_progress', () async {
      final content = '第1章 开端\n正文内容\n第2章 发展\n正文\n';
      final r = await importBytes(utf8.encode(content));
      final collectionId = r.collection.id;

      // 写进度
      await db
          .into(db.readingProgress)
          .insert(
            ReadingProgressCompanion.insert(
              collectionId: collectionId,
              absoluteCharacterOffset: 5,
              itemIdHint: const Value(null),
              updatedAt: DateTime.now(),
              locatorVersion: 1,
              normalizationVersion: '1.0.0',
            ),
          );

      final repair = CollectionRepairService(
        database: db,
        fileManager: LibraryFileManager(libraryRoot: libRoot),
        encodingIndexProvider: encProvider,
      );
      await repair.repair(collectionId);

      final progress = await (db.select(
        db.readingProgress,
      )..where((t) => t.collectionId.equals(collectionId))).getSingleOrNull();
      expect(progress, isNotNull, reason: 'repair 不得清除阅读进度');
      expect(progress!.absoluteCharacterOffset, 5);
    });
  });
}

class _IndexDataLoader {
  const _IndexDataLoader();
  Gb18030IndexData loadFromAsset() {
    final f = File('assets/encoding/gb18030_index.bin');
    return const Gb18030IndexLoader().parse(f.readAsBytesSync());
  }
}
