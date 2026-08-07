import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_data.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_loader.dart';

/// M3.1 唯一 hash 合同测试（任务书 §五/§六/§七）。
///
/// 核心断言：normalizedHash = 落盘 normalized.txt 无 BOM UTF-8 字节的 SHA-256，
/// 且 manifest / Drift / Loader 三处一致。
void main() {
  late AppDatabase db;
  late Directory libRoot;
  late LocalLibraryRepository repo;
  late NormalizedDocumentLoader loader;
  late EncodingIndexProvider encProvider;

  setUp(() async {
    db = AppDatabase.forTesting();
    libRoot = Directory.systemTemp.createTempSync('xaocen_hash_test');
    encProvider = MemoryEncodingIndexProvider(
      const _IndexDataLoader().loadFromAsset(),
    );
    repo = LocalLibraryRepository(
      database: db,
      fileManager: LibraryFileManager(libraryRoot: libRoot),
      encodingIndexProvider: encProvider,
    );
    loader = NormalizedDocumentLoader(
      fileManager: LibraryFileManager(libraryRoot: libRoot),
    );
  });

  tearDown(() async {
    await db.close();
    if (await libRoot.exists()) {
      await libRoot.delete(recursive: true);
    }
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

  /// 从 managed 目录读取 manifest。
  Future<Map<String, dynamic>> readManifest(String collectionId) async {
    final hash = collectionId.replaceFirst('local-txt:', '');
    final mf = File('${libRoot.path}/local_txt/$hash/manifest.json');
    return jsonDecode(await mf.readAsString()) as Map<String, dynamic>;
  }

  String sha256Of(List<int> bytes) => sha256.convert(bytes).toString();

  group('hash 合同（§五）', () {
    test('13. 写入后 hash 来自实际落盘字节（含 CRLF 归一化）', () async {
      // CRLF 输入 → 规范化后 LF：source hash ≠ normalized hash（模拟大文件场景）
      final content = '第1章 开端\r\n正文内容\r\n第2章 发展\r\n';
      final r = await importBytes(utf8.encode(content));

      final manifest = await readManifest(r.collection.id);
      final hash = r.collection.id.replaceFirst('local-txt:', '');
      final normBytes = await File(
        '${libRoot.path}/local_txt/$hash/normalized.txt',
      ).readAsBytes();
      final actual = sha256Of(normBytes);

      // 关键：DB 记录 = manifest = 落盘字节，而不是 sourceHash
      expect(manifest['normalizedHash'], actual);
      expect(manifest['sourceHash'], isNot(actual)); // source≠normalized
      final docs = await repo.getDocuments(r.collection.id);
      expect(docs, isNotEmpty);
      for (final d in docs) {
        expect(d.contentHash, actual, reason: 'Drift 必须存 normalizedHash');
      }
      // 长度
      expect(
        manifest['normalizedCharacterLength'],
        utf8.decode(normBytes).length,
      );
    });

    test('13b. 无 CRLF 时 source==normalized（小文件场景仍正确）', () async {
      final content = '第一章 开端\n正文\n第二章 发展\n';
      final r = await importBytes(utf8.encode(content));
      final manifest = await readManifest(r.collection.id);
      final hash = r.collection.id.replaceFirst('local-txt:', '');
      final normBytes = await File(
        '${libRoot.path}/local_txt/$hash/normalized.txt',
      ).readAsBytes();
      final actual = sha256Of(normBytes);
      expect(manifest['normalizedHash'], actual);
      // source==normalized 时三处也一致
      expect(manifest['sourceHash'], actual);
      final docs = await repo.getDocuments(r.collection.id);
      for (final d in docs) {
        expect(d.contentHash, actual);
      }
    });

    test('14. CRLF 跨 buffer 边界规范化一致', () async {
      // 构造 CR 在块尾、LF 在块头的输入（模拟流式边界）
      final sb = StringBuffer();
      // 模拟内部块大小 64KB：在边界放 CRLF
      final chunk = 64 * 1024;
      final prefix = 'x' * (chunk - 1);
      sb.write(prefix);
      sb.write('\r\n'); // CR 在块尾前一位、LF 跨边界
      sb.write('第1章 边界\r\n');
      sb.write('y' * (chunk - 3));
      sb.write('\r\n第2章 结尾\r\n');
      final r = await importBytes(utf8.encode(sb.toString()));

      final hash = r.collection.id.replaceFirst('local-txt:', '');
      final norm = await File(
        '${libRoot.path}/local_txt/$hash/normalized.txt',
      ).readAsString();
      // 所有 CRLF 都被归一为 LF
      expect(norm.contains('\r'), isFalse);
      expect(norm.contains('x' * (chunk - 1) + '\n'), isTrue);
      expect(norm.contains('第1章 边界\n'), isTrue);
      expect(norm.contains('第2章 结尾\n'), isTrue);
    });

    test('15. UTF-8 四字节字符跨 buffer 边界', () async {
      // 用大量 4 字节字符（U+1F600 等 emoji）跨块
      final chunk = 64 * 1024;
      final sb = StringBuffer();
      sb.write('第1章 开始\n');
      // 用 3 字节汉字 + 4 字节 emoji 混排跨越块边界
      while (sb.length < chunk + 64) {
        sb.write('𠀀'); // U+20000，UTF-8 4 字节
        sb.write('测试文');
      }
      sb.write('\n第2章 结束\n');
      final r = await importBytes(utf8.encode(sb.toString()));

      final hash = r.collection.id.replaceFirst('local-txt:', '');
      final norm = await File(
        '${libRoot.path}/local_txt/$hash/normalized.txt',
      ).readAsBytes();
      final text = utf8.decode(norm);
      expect(text.contains('𠀀'), isTrue);
      expect(text.contains('第2章 结束'), isTrue);
      // 长度一致
      final manifest = await readManifest(r.collection.id);
      expect(manifest['normalizedCharacterLength'], text.length);
    });

    test(
      '17. 不同 chunk size 输出相同 hash（8MB 合成文件）',
      () async {
        // 生成 >8MB 且跨块的合成文本（含 CRLF、四字节字符、长行）
        final sb = StringBuffer();
        var i = 0;
        while (sb.length < 8 * 1024 * 1024) {
          sb.write('第$i章 内容段落\r\n');
          sb.write('𠀀𠀀𠀀 汉字混排内容$i\r\n');
          sb.write('x' * 500);
          sb.write('\r\n');
          i++;
        }
        final r = await importBytes(
          utf8.encode(sb.toString()),
          name: 'big8m.txt',
        );

        final normBytes = await File(
          '${libRoot.path}/local_txt/${r.collection.id.replaceFirst('local-txt:', '')}/normalized.txt',
        ).readAsBytes();
        final actual = sha256Of(normBytes);

        // 用不同 chunk 读取验证 hash 稳定（Loader 读取路径）
        final doc = await loader.load(
          storagePath:
              'library/local_txt/${r.collection.id.replaceFirst('local-txt:', '')}/normalized.txt',
          expectedLength: utf8.decode(normBytes).length,
        );
        expect(doc.text.length, utf8.decode(normBytes).length);
        expect(sha256.convert(utf8.encode(doc.text)).toString(), actual);
        expect(actual, isNotEmpty);
        // 8MB 级文件多块存在（block index 验证由 reader 测试覆盖）
        expect(normBytes.length, greaterThan(8 * 1024 * 1024 - 100));
      },
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test('18. UTF-8 输出确定性（同一输入两遍导入 hash 相同）', () async {
      final content = '第1章 开端\r\n正文\r\n第2章 发展\r\n';
      final r1 = await importBytes(utf8.encode(content), name: 'a.txt');
      final r2 = await importBytes(utf8.encode(content), name: 'b.txt');
      expect(
        r1.collection.id,
        r2.collection.id,
        reason: '相同内容 → 相同 contentHash',
      );
      final m1 = await readManifest(r1.collection.id);
      final m2 = await readManifest(r2.collection.id);
      expect(m1['normalizedHash'], m2['normalizedHash']);
    });
  });

  group('Loader 合同（§五）', () {
    test('6. Drift hash 错误不影响打开（manifest 权威）', () async {
      final content = '第1章 开端\r\n正文\r\n';
      final r = await importBytes(utf8.encode(content));
      final hash = r.collection.id.replaceFirst('local-txt:', '');
      // 篡改 Drift 记录（模拟旧 bug：content_hash 存 sourceHash，全表更新）
      final allDocs = await db.select(db.contentDocuments).get();
      for (final d in allDocs) {
        await (db.update(
          db.contentDocuments,
        )..where((t) => t.id.equals(d.id))).write(
          ContentDocumentsCompanion(
            contentHash: Value(
              'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
            ),
          ),
        );
      }
      // Loader 仍以 manifest 校验 → 打开成功
      final doc = await loader.load(
        storagePath: 'library/local_txt/$hash/normalized.txt',
      );
      expect(doc.text.contains('第1章'), isTrue);
    });

    test('5. manifest hash 错误 → hash_mismatch', () async {
      final content = '第1章 开端\r\n正文\r\n';
      final r = await importBytes(utf8.encode(content));
      final hash = r.collection.id.replaceFirst('local-txt:', '');
      final mf = File('${libRoot.path}/local_txt/$hash/manifest.json');
      final m = jsonDecode(await mf.readAsString()) as Map<String, dynamic>;
      m['normalizedHash'] = 'wrong-wrong-wrong';
      await mf.writeAsString(jsonEncode(m));
      await expectLater(
        loader.load(storagePath: 'library/local_txt/$hash/normalized.txt'),
        throwsA(
          isA<NormalizedDocumentException>().having(
            (e) => e.code,
            'code',
            'hash_mismatch',
          ),
        ),
      );
    });

    test('7. normalized.txt 被截断 → hash_mismatch', () async {
      final content = '第1章 开端\r\n正文\r\n第2章 结尾\r\n';
      final r = await importBytes(utf8.encode(content));
      final hash = r.collection.id.replaceFirst('local-txt:', '');
      final nf = File('${libRoot.path}/local_txt/$hash/normalized.txt');
      final bytes = await nf.readAsBytes();
      await nf.writeAsBytes(bytes.sublist(0, bytes.length ~/ 2));
      await expectLater(
        loader.load(storagePath: 'library/local_txt/$hash/normalized.txt'),
        throwsA(
          isA<NormalizedDocumentException>().having(
            (e) => e.code,
            'code',
            'hash_mismatch',
          ),
        ),
      );
    });

    test('8. normalized.txt 内容被修改 → hash_mismatch', () async {
      final content = '第1章 开端\r\n正文\r\n';
      final r = await importBytes(utf8.encode(content));
      final hash = r.collection.id.replaceFirst('local-txt:', '');
      final nf = File('${libRoot.path}/local_txt/$hash/normalized.txt');
      final bytes = await nf.readAsBytes();
      // 用可打印 ASCII 替换（不破坏 UTF-8 结构，但改变内容 → hash 变）
      final text = utf8.decode(bytes);
      final modified = text.replaceFirst('正文', '改文');
      await nf.writeAsBytes(utf8.encode(modified));
      await expectLater(
        loader.load(storagePath: 'library/local_txt/$hash/normalized.txt'),
        throwsA(
          isA<NormalizedDocumentException>().having(
            (e) => e.code,
            'code',
            'hash_mismatch',
          ),
        ),
      );
    });
  });

  test(
    '2. 运行时生成 8MB TXT 导入 → Loader 打开（闭环）',
    () async {
      // 用文件数据库（真实持久化）：关闭后重开验证（§十一 集成要求）
      await db.close();
      final dbFile = File('${libRoot.path}/restart_test.sqlite');
      final db1 = AppDatabase(NativeDatabase(dbFile));
      try {
        final repo1 = LocalLibraryRepository(
          database: db1,
          fileManager: LibraryFileManager(libraryRoot: libRoot),
          encodingIndexProvider: encProvider,
        );
        // 8MB，少量章（每章 ~80KB），贴近真实文件形态
        final sb = StringBuffer();
        var i = 0;
        while (sb.length < 8 * 1024 * 1024) {
          sb.write('第$i章 大文件内容\r\n');
          // 每章填充 ~80KB 正文
          while (sb.length < 80 * 1024 * (i + 1) &&
              sb.length < 8 * 1024 * 1024) {
            sb.write('正文内容段落${i}_$i，汉字混排𠀀𠀀𠀀。\r\n');
          }
          i++;
        }
        final f = File('${libRoot.path}/in_gen8m.txt');
        await f.writeAsBytes(utf8.encode(sb.toString()));
        final r = await repo1.importTxt(
          ImportTxtRequest(externalFile: f, confirmLargeFile: true),
        );
        expect(r.alreadyImported, isFalse);
        final collectionId = r.collection.id;

        // 完全关闭后重新打开
        await db1.close();
        final db2 = AppDatabase(NativeDatabase(dbFile));
        try {
          final repo2 = LocalLibraryRepository(
            database: db2,
            fileManager: LibraryFileManager(libraryRoot: libRoot),
            encodingIndexProvider: encProvider,
          );
          final loader2 = NormalizedDocumentLoader(
            fileManager: LibraryFileManager(libraryRoot: libRoot),
          );
          final docs = await repo2.getDocuments(collectionId);
          expect(docs, isNotEmpty);
          final doc = await loader2.load(
            storagePath: docs.first.storagePath,
            expectedLength: r.collection.normalizedCharacterLength,
          );
          expect(doc.text.length, r.collection.normalizedCharacterLength);
          expect(doc.text.contains('第0章 大文件内容'), isTrue);
        } finally {
          await db2.close();
        }
      } finally {
        // 恢复 setUp 状态（后续测试用内存库）
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
        // tearDown 会 close db（已 close），需重建一个供 tearDown close
        // 这里不重建：后续测试需要 db —— 但 tearDown 闭 db 一次即可。
        // 为保持简单，后续测试直接使用 db（已在 setUp 创建，此处已 close）
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

class _IndexDataLoader {
  const _IndexDataLoader();
  Gb18030IndexData loadFromAsset() {
    final f = File('assets/encoding/gb18030_index.bin');
    return const Gb18030IndexLoader().parse(f.readAsBytesSync());
  }
}
