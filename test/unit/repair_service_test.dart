import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/collection_repair_service.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/data/repositories/managed_collection_health.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_data.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_loader.dart';

/// M3.1 修复服务 + alreadyImported 逻辑测试（任务书 §八/§九/§十一）。
void main() {
  late AppDatabase db;
  late Directory libRoot;
  late LocalLibraryRepository repo;
  late CollectionRepairService repair;
  late ManagedCollectionHealthCheck healthCheck;
  late EncodingIndexProvider encProvider;

  setUp(() async {
    db = AppDatabase.forTesting();
    libRoot = Directory.systemTemp.createTempSync('xaocen_repair_test');
    encProvider = MemoryEncodingIndexProvider(
      const _IndexDataLoader().loadFromAsset(),
    );
    final fm = LibraryFileManager(libraryRoot: libRoot);
    repo = LocalLibraryRepository(
      database: db,
      fileManager: fm,
      encodingIndexProvider: encProvider,
    );
    repair = CollectionRepairService(
      database: db,
      fileManager: fm,
      encodingIndexProvider: encProvider,
    );
    healthCheck = ManagedCollectionHealthCheck(database: db, fileManager: fm);
  });

  tearDown(() async {
    await db.close();
    if (await libRoot.exists()) {
      await libRoot.delete(recursive: true);
    }
  });

  String sha256Of(List<int> b) => sha256.convert(b).toString();

  Future<ImportTxtResult> importText(
    String text, {
    String name = 't.txt',
  }) async {
    final f = File('${libRoot.path}/ext_$name');
    await f.writeAsBytes(utf8.encode(text));
    return repo.importTxt(
      ImportTxtRequest(externalFile: f, confirmLargeFile: true),
    );
  }

  String contentDirOf(String collectionId) =>
      collectionId.replaceFirst('local-txt:', '');

  group('ManagedCollectionHealth（§八）', () {
    test('健康 collection → ok', () async {
      final r = await importText('第1章 开端\r\n正文\r\n第2章 结尾\r\n');
      final h = await healthCheck.check(r.collection.id);
      expect(h.ok, isTrue);
      expect(h.problems, isEmpty);
      expect(h.sourceOk, isTrue);
      expect(h.normalizedOk, isTrue);
      expect(h.dbConsistent, isTrue);
    });

    test('source.txt 损坏 → sourceOk=false', () async {
      final r = await importText('第1章 开端\r\n正文\r\n');
      final hash = contentDirOf(r.collection.id);
      final sf = File('${libRoot.path}/local_txt/$hash/source.txt');
      final bytes = await sf.readAsBytes();
      bytes[0] = bytes[0] == 0x41 ? 0x42 : 0x41;
      await sf.writeAsBytes(bytes);
      final h = await healthCheck.check(r.collection.id);
      expect(h.sourceOk, isFalse);
      expect(h.ok, isFalse);
    });

    test('Drift hash 错误（旧 bug 模拟）→ dbConsistent=false', () async {
      final r = await importText('第1章 开端\r\n正文\r\n');
      // 模拟 M3 旧 bug：content_hash 存 sourceHash（全表更新）
      final allDocs = await db.select(db.contentDocuments).get();
      for (final d in allDocs) {
        await (db.update(
          db.contentDocuments,
        )..where((t) => t.id.equals(d.id))).write(
          ContentDocumentsCompanion(
            contentHash: Value(r.collection.id.replaceFirst('local-txt:', '')),
          ),
        );
      }
      final h = await healthCheck.check(r.collection.id);
      expect(h.dbConsistent, isFalse);
      expect(h.sourceOk, isTrue);
      expect(h.normalizedOk, isTrue);
      expect(h.ok, isFalse);
    });
  });

  group('CollectionRepairService（§八）', () {
    test('9. source 正确、normalized 损坏 → 自动 repair 成功', () async {
      final r = await importText('第1章 开端\r\n正文内容\r\n第2章 发展\r\n');
      final hash = contentDirOf(r.collection.id);
      // 破坏 normalized.txt（截断）
      final nf = File('${libRoot.path}/local_txt/$hash/normalized.txt');
      final bytes = await nf.readAsBytes();
      await nf.writeAsBytes(bytes.sublist(0, bytes.length ~/ 2));

      final result = await repair.repair(r.collection.id);
      expect(result.success, isTrue, reason: result.error);
      expect(result.repaired, isTrue);
      // 修复后 health ok
      final h = await healthCheck.check(r.collection.id);
      expect(h.ok, isTrue);
      // 修复产物 = 从 source 重跑结果
      final normBytes = await File(
        '${libRoot.path}/local_txt/$hash/normalized.txt',
      ).readAsBytes();
      expect(sha256Of(normBytes), result.normalizedHash);
      expect(utf8.decode(normBytes).contains('第2章 发展'), isTrue);
    });

    test('10. source.txt 也损坏 → 拒绝 repair', () async {
      final r = await importText('第1章 开端\r\n正文\r\n');
      final hash = contentDirOf(r.collection.id);
      final sf = File('${libRoot.path}/local_txt/$hash/source.txt');
      final bytes = await sf.readAsBytes();
      await sf.writeAsBytes(bytes.sublist(0, bytes.length ~/ 2)); // 截断 source
      final result = await repair.repair(r.collection.id);
      expect(result.success, isFalse);
      expect(result.repaired, isFalse);
      expect(result.error, contains('source.txt'));
    });

    test('11. repair 不改变外部 TXT', () async {
      final extFile = File('${libRoot.path}/ext_keep.txt');
      final text = '第1章 开端\r\n正文内容\r\n第2章 结尾\r\n';
      await extFile.writeAsBytes(utf8.encode(text));
      final before = sha256Of(utf8.encode(text));
      final r = await repo.importTxt(
        ImportTxtRequest(externalFile: extFile, confirmLargeFile: true),
      );
      final hash = contentDirOf(r.collection.id);
      // 破坏 normalized 后 repair
      final nf = File('${libRoot.path}/local_txt/$hash/normalized.txt');
      await nf.writeAsBytes(
        (await nf.readAsBytes()).sublist(
          0,
          (await nf.readAsBytes()).length ~/ 2,
        ),
      );
      await repair.repair(r.collection.id);
      // 外部文件不变
      expect(sha256Of(await extFile.readAsBytes()), before);
      expect(await extFile.readAsString(), text);
    });

    test('12. repair 失败不覆盖旧文件', () async {
      final r = await importText('第1章 开端\r\n正文\r\n');
      final hash = contentDirOf(r.collection.id);
      final dir = '${libRoot.path}/local_txt/$hash';
      // 破坏 source（repair 会在前置拒绝，不触碰派生文件）
      final sf = File('$dir/source.txt');
      final srcBytes = await sf.readAsBytes();
      await sf.writeAsBytes(srcBytes.sublist(0, srcBytes.length ~/ 2));
      final normBefore = await File('$dir/normalized.txt').readAsBytes();
      final manifestBefore = await File('$dir/manifest.json').readAsString();

      final result = await repair.repair(r.collection.id);
      expect(result.success, isFalse);
      // 旧文件未被覆盖/删除
      expect(await File('$dir/normalized.txt').exists(), isTrue);
      expect(await File('$dir/manifest.json').exists(), isTrue);
      expect(await File('$dir/normalized.txt').readAsBytes(), normBefore);
      expect(await File('$dir/manifest.json').readAsString(), manifestBefore);
      // 无 .bak 残留
      expect(await File('$dir/normalized.txt.bak').exists(), isFalse);
      expect(await File('$dir/manifest.json.repair-bak').exists(), isFalse);
    });

    test('19. repaired collection 可打开 Reader（Loader 通过）', () async {
      final r = await importText('第1章 开端\r\n正文\r\n第2章 结尾\r\n');
      final hash = contentDirOf(r.collection.id);
      final nf = File('${libRoot.path}/local_txt/$hash/normalized.txt');
      await nf.writeAsBytes(
        (await nf.readAsBytes()).sublist(
          0,
          (await nf.readAsBytes()).length ~/ 2,
        ),
      );
      final result = await repair.repair(r.collection.id);
      expect(result.success, isTrue);

      final loader = NormalizedDocumentLoader(
        fileManager: LibraryFileManager(libraryRoot: libRoot),
      );
      final docs = await repo.getDocuments(r.collection.id);
      final doc = await loader.load(
        storagePath: docs.first.storagePath,
        expectedLength: r.collection.normalizedCharacterLength,
      );
      expect(doc.text.contains('第1章 开端'), isTrue);
      expect(doc.text.length, r.collection.normalizedCharacterLength);
    });

    test('20. repair 后原 reading_progress 保留且可 clamp', () async {
      final r = await importText('第1章 开端\r\n正文\r\n第2章 结尾\r\n');
      // 先写入进度
      await db
          .into(db.readingProgress)
          .insert(
            ReadingProgressCompanion.insert(
              collectionId: r.collection.id,
              absoluteCharacterOffset: 5,
              updatedAt: DateTime.now(),
              locatorVersion: 1,
              normalizationVersion: '1.0.0',
            ),
          );
      final hash = contentDirOf(r.collection.id);
      final nf = File('${libRoot.path}/local_txt/$hash/normalized.txt');
      await nf.writeAsBytes(
        (await nf.readAsBytes()).sublist(
          0,
          (await nf.readAsBytes()).length ~/ 2,
        ),
      );
      final result = await repair.repair(r.collection.id);
      expect(result.success, isTrue);
      // 进度保留
      final progress = await (db.select(
        db.readingProgress,
      )..where((t) => t.collectionId.equals(r.collection.id))).getSingle();
      expect(progress, isNotNull);
      expect(progress.absoluteCharacterOffset, 5);
    });
  });

  group('alreadyImported 逻辑（§九）', () {
    test('健康重复导入 → alreadyImported', () async {
      final f = File('${libRoot.path}/ext_dup.txt');
      await f.writeAsBytes(utf8.encode('第1章 开端\r\n正文\r\n'));
      final r1 = await repo.importTxt(
        ImportTxtRequest(externalFile: f, confirmLargeFile: true),
      );
      final r2 = await repo.importTxt(
        ImportTxtRequest(externalFile: f, confirmLargeFile: true),
      );
      expect(r1.alreadyImported, isFalse);
      expect(r1.outcome, ImportOutcome.imported);
      expect(r2.alreadyImported, isTrue);
      expect(r2.outcome, ImportOutcome.alreadyImported);
      expect(r2.collection.id, r1.collection.id);
    });

    test('重复导入但 normalized 损坏 → 自动 repair 并返回 repairedExisting', () async {
      final f = File('${libRoot.path}/ext_repair.txt');
      final text = '第1章 开端\r\n正文内容\r\n第2章 发展\r\n';
      await f.writeAsBytes(utf8.encode(text));
      await repo.importTxt(
        ImportTxtRequest(externalFile: f, confirmLargeFile: true),
      );
      // 破坏 managed normalized.txt
      final hash = sha256Of(utf8.encode(text));
      final nf = File('${libRoot.path}/local_txt/$hash/normalized.txt');
      await nf.writeAsBytes(
        (await nf.readAsBytes()).sublist(
          0,
          (await nf.readAsBytes()).length ~/ 2,
        ),
      );

      final r2 = await repo.importTxt(
        ImportTxtRequest(externalFile: f, confirmLargeFile: true),
      );
      expect(r2.alreadyImported, isTrue);
      expect(r2.outcome, ImportOutcome.repairedExisting);
      // 修复后健康
      final h = await healthCheck.check(r2.collection.id);
      expect(h.ok, isTrue);
    });

    test('source 也损坏 → corruptedManagedCopy（不自动 repair）', () async {
      final f = File('${libRoot.path}/ext_corrupt.txt');
      final text = '第1章 开端\r\n正文\r\n';
      await f.writeAsBytes(utf8.encode(text));
      await repo.importTxt(
        ImportTxtRequest(externalFile: f, confirmLargeFile: true),
      );
      final hash = sha256Of(utf8.encode(text));
      final sf = File('${libRoot.path}/local_txt/$hash/source.txt');
      await sf.writeAsBytes(
        (await sf.readAsBytes()).sublist(
          0,
          (await sf.readAsBytes()).length ~/ 2,
        ),
      );

      final r2 = await repo.importTxt(
        ImportTxtRequest(externalFile: f, confirmLargeFile: true),
      );
      expect(r2.alreadyImported, isTrue);
      expect(r2.outcome, ImportOutcome.corruptedManagedCopy);
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
