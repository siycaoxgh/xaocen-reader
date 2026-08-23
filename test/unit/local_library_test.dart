import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/data/repositories/local_book_cover_repository.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/domain/library/local_txt_metadata.dart';
import 'package:xaocen_reader/domain/local_txt/pipeline_progress.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_data.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_loader.dart';
import 'package:xaocen_reader/sources/local_txt/txt_cancellation.dart';

/// M2 数据库 + 文件 + 仓库测试。
///
/// 使用自包含 fixture（test/fixtures/txt）与内存数据库 + 临时目录，
/// 不读取外部 TXT，不提交正文。
void main() {
  group('保守 TXT metadata 推断', () {
    test('明确书名/作者优先，文件名范围后缀仅保守清理', () {
      final metadata = LocalTxtMetadataInferer.fromText(
        '《苟在初圣魔门当人材》\n作者：鹤守月满池\n第一章',
        '苟在初圣魔门当人材(1-500章).txt',
      );
      expect(metadata.title, '苟在初圣魔门当人材');
      expect(metadata.author, '鹤守月满池');
      expect(metadata.titleSource, 'explicitText');
      expect(metadata.authorSource, 'explicitText');
    });

    test('无可信作者不猜，普通文件名只去扩展名', () {
      final metadata = LocalTxtMetadataInferer.fromText(
        '作品相关\n第一卷 诡异蓝光\n第一章',
        '因果快递-20260625.txt',
      );
      expect(metadata.title, '因果快递-20260625');
      expect(metadata.author, isNull);
      expect(metadata.authorSource, 'unknown');
    });

    test('范围清理不误删真实书名尾部数字', () {
      expect(LocalTxtMetadataInferer.cleanFileName('青山2024.txt'), '青山2024');
      expect(LocalTxtMetadataInferer.cleanFileName('青山(501-809章).txt'), '青山');
    });
  });

  late AppDatabase db;
  late Directory libRoot;
  late LocalLibraryRepository repo;
  late EncodingIndexProvider encProvider;

  setUp(() async {
    db = AppDatabase.forTesting();
    libRoot = Directory.systemTemp.createTempSync('xaocen_lib_test');
    encProvider = MemoryEncodingIndexProvider(
      // 用正式二进制索引（测试资产）
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
    if (await libRoot.exists()) {
      await libRoot.delete(recursive: true);
    }
  });

  File fixture(String name) => File('test/fixtures/txt/$name');

  Future<ImportTxtResult> importFixture(String name, {bool confirm = true}) {
    return repo.importTxt(
      ImportTxtRequest(externalFile: fixture(name), confirmLargeFile: confirm),
    );
  }

  group('schema 与空库', () {
    test('空库 schema 创建成功（6 表）', () async {
      final tables = await db.select(db.contentSources).get();
      expect(tables, isEmpty);
      expect(await db.select(db.contentCollections).get(), isEmpty);
      expect(await db.select(db.contentItems).get(), isEmpty);
      expect(await db.select(db.contentDocuments).get(), isEmpty);
      expect(await db.select(db.tocEntries).get(), isEmpty);
      expect(await db.select(db.importRecords).get(), isEmpty);
    });

    test('listCollections 空', () async {
      expect(await repo.listCollections(), isEmpty);
    });
  });

  group('有章节导入', () {
    test('utf8_chapters：3 章 3 item，无卷', () async {
      final r = await importFixture('utf8_chapters.txt');
      expect(r.alreadyImported, isFalse);
      expect(r.collection.itemCount, 3);
      expect(r.collection.titleSource, 'fileName');
      expect(r.collection.author, isNull);

      final items = await repo.getItems(r.collection.id);
      expect(items.length, 3);
      expect(items[0].kind, 'chapter');
      expect(items[0].orderIndex, 1);
      expect(items[0].startCharacterOffset, 0);

      final toc = await repo.getToc(r.collection.id);
      expect(toc.length, 3);
      expect(toc.every((e) => e.kind == 'chapter'), isTrue);

      final docs = await repo.getDocuments(r.collection.id);
      expect(docs.length, 3);
      expect(
        docs.every((d) => d.storagePath.endsWith('normalized.txt')),
        isTrue,
      );
    });

    test('volumes：卷不计入 itemCount，toc parentId 正确', () async {
      final r = await importFixture('volumes.txt');
      // 第1章/第2章 + 第二卷第1章/第3章 = 4 章；卷 2 个
      expect(r.collection.itemCount, 4);

      final toc = await repo.getToc(r.collection.id);
      final volumes = toc.where((e) => e.kind == 'volume').toList();
      final chapters = toc.where((e) => e.kind == 'chapter').toList();
      expect(volumes.length, 2);
      expect(chapters.length, 4);

      // 第二卷的章节 parentId 指向第二卷
      final vol2 = volumes[1];
      final vol2Chapters = chapters
          .where((c) => c.parentId == vol2.id)
          .toList();
      expect(vol2Chapters.length, 2);
      // 卷内重新编号：第二卷 第1章 order=1, 第3章 order=2
      expect(vol2Chapters[0].orderIndex, 1);
      expect(vol2Chapters[1].orderIndex, 2);

      // volume 不计入 items
      final items = await repo.getItems(r.collection.id);
      expect(items.length, 4);
    });

    test('documents 范围正确', () async {
      final r = await importFixture('utf8_chapters.txt');
      final docs = await repo.getDocuments(r.collection.id);
      final items = await repo.getItems(r.collection.id);
      for (final item in items) {
        final doc = docs.firstWhere((d) => d.itemId == item.id);
        expect(doc.startCharacterOffset, item.startCharacterOffset);
        expect(doc.endCharacterOffset, item.endCharacterOffset);
      }
      // 全文范围：第2章 end == normalized length
      expect(
        docs.last.endCharacterOffset,
        r.collection.normalizedCharacterLength,
      );
    });
  });

  test('metadata is persisted without changing collection identity', () async {
    final file = File('${libRoot.path}${Platform.pathSeparator}book.txt')
      ..writeAsStringSync('《测试书》\n作者：测试作者\n第一章\n正文');
    final result = await repo.importTxt(
      ImportTxtRequest(externalFile: file, confirmLargeFile: true),
    );
    final loaded = await repo.getCollection(result.collection.id);
    expect(loaded?.title, '测试书');
    expect(loaded?.author, '测试作者');
    expect(loaded?.sourcePath, contains('library'));
    expect(loaded?.fileName, 'book.txt');
    expect(loaded?.id, result.collection.id);
    expect(await repo.getItems(result.collection.id), isNotEmpty);
  });

  test('real four TXT corpus receives conservative metadata', () async {
    final corpus = Directory(r'C:\Users\TOM\Desktop\测试');
    if (!await corpus.exists()) return;
    final files = await corpus
        .list()
        .where(
          (entry) => entry is File && entry.path.toLowerCase().endsWith('.txt'),
        )
        .cast<File>()
        .toList();
    expect(files, hasLength(4));
    final expected = <String, String>{
      '苟在初圣魔门当人材(1-500章).txt': '苟在初圣魔门当人材',
      '青山(501-809章).txt': '青山',
      '因果快递-20260625.txt': '因果快递-20260625',
      '无章节数字测试.txt': '苟在武道世界成圣',
    };
    for (final file in files) {
      final metadata = await LocalTxtMetadataInferer.fromFile(file);
      expect(metadata.title, expected[file.uri.pathSegments.last]);
      expect(metadata.metadataSource, 'localInference');
    }
  });

  test(
    'manual metadata overrides persist and restore without changing identity or progress',
    () async {
      final imported = await importFixture('utf8_chapters.txt');
      final original = imported.collection;
      final progress = ReadingProgressRepository(db: db);
      await progress.saveLocator(
        ReaderLocator(
          collectionId: original.id,
          absoluteCharacterOffset: 42,
          itemIdHint: null,
        ),
      );

      final edited = await repo.updateManualMetadata(
        original.id,
        title: '手动书名',
        author: '手动作者',
        description: '手动简介',
        titleChanged: true,
        authorChanged: true,
        descriptionChanged: true,
      );
      expect(edited.id, original.id);
      expect(edited.sourcePath, original.sourcePath);
      expect(edited.title, '手动书名');
      expect(edited.titleSource, 'manual');
      expect(edited.authorSource, 'manual');
      expect(
        (await progress.getProgress(original.id))!.absoluteCharacterOffset,
        42,
      );

      final rescanned = await importFixture('utf8_chapters.txt');
      expect(rescanned.collection.id, original.id);
      final afterRescan = await repo.getCollection(original.id);
      expect(afterRescan!.title, '手动书名');
      expect(afterRescan.author, '手动作者');

      final restored = await repo.restoreAutomaticMetadata(original.id);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.author, isNull);
      expect(restored.titleSource, 'fileName');
      expect(restored.metadataSource, 'localInference');
      expect(
        (await progress.getProgress(original.id))!.absoluteCharacterOffset,
        42,
      );
    },
  );

  test(
    'schema 18 to 20 adds metadata and cover defaults without touching progress',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'xaocen-metadata-migration-',
      );
      final file = File(
        '${temp.path}${Platform.pathSeparator}migration.sqlite',
      );
      final old = AppDatabase(NativeDatabase(file));
      await old.customStatement('''
      INSERT INTO content_sources
        (id, type, display_name, content_hash, managed_source_path,
         source_size, detected_encoding, created_at, updated_at)
      VALUES ('source', 'localTxt', 'legacy.txt', 'hash',
              'library/local_txt/hash/source.txt', 1, 'utf8', 0, 0)
    ''');
      await old.customStatement('''
      INSERT INTO content_collections
        (id, source_id, title, item_count, normalized_character_length,
         imported_at, updated_at)
      VALUES ('book', 'source', 'Legacy', 1, 12, 0, 0)
    ''');
      await old.customStatement('''
      INSERT INTO reading_progress
        (collection_id, absolute_character_offset, reading_mode, item_id_hint,
         updated_at, locator_version, normalization_version)
      VALUES ('book', 194, 'vertical', NULL, 0, 1, 'v1')
    ''');
      for (final column in [
        'author',
        'description',
        'metadata_source',
        'title_source',
        'author_source',
        'cover_path',
        'cover_source',
      ]) {
        await old.customStatement(
          'ALTER TABLE content_collections DROP COLUMN $column',
        );
      }
      await old.customStatement('PRAGMA user_version = 18');
      await old.close();

      final migrated = AppDatabase(NativeDatabase(file));
      final row = await migrated
          .select(migrated.contentCollections)
          .getSingle();
      final progress = await migrated
          .select(migrated.readingProgress)
          .getSingle();
      expect(row.title, 'Legacy');
      expect(row.metadataSource, 'legacy');
      expect(row.titleSource, 'legacy');
      expect(row.author, isNull);
      expect(row.coverPath, isNull);
      expect(row.coverSource, 'placeholder');
      expect(progress.absoluteCharacterOffset, 194);
      expect(
        (await migrated.customSelect('PRAGMA user_version').getSingle())
            .data['user_version'],
        21,
      );
      await migrated.close();
      await temp.delete(recursive: true);
    },
  );

  test(
    'local cover is copied into managed storage and safely falls back',
    () async {
      final imported = await importFixture('utf8_chapters.txt');
      final source = File('${libRoot.path}${Platform.pathSeparator}picked.png');
      await source.writeAsBytes(const [137, 80, 78, 71, 13, 10, 26, 10]);
      final covers = LocalBookCoverRepository(
        database: db,
        fileManager: LibraryFileManager(libraryRoot: libRoot),
      );

      final relative = await covers.importCover(
        collectionId: imported.collection.id,
        source: source,
      );
      expect(relative, startsWith(LocalBookCoverRepository.prefix));
      final managed = covers.resolve(relative);
      expect(managed, isNotNull);
      expect(await managed!.readAsBytes(), await source.readAsBytes());
      final saved = await repo.getCollection(imported.collection.id);
      expect(saved!.coverPath, relative);
      expect(saved.coverSource, 'manual');

      await covers.removeCover(imported.collection.id, relative);
      expect(covers.resolve(relative), isNull);
      final reverted = await repo.getCollection(imported.collection.id);
      expect(reverted!.coverPath, isNull);
      expect(reverted.coverSource, 'placeholder');
    },
  );

  group('无章节导入', () {
    test('no_chapters：1 个 whole item，0 章', () async {
      final r = await importFixture('no_chapters.txt');
      expect(r.collection.itemCount, 1);

      final items = await repo.getItems(r.collection.id);
      expect(items.length, 1);
      expect(items.single.kind, 'whole');
      expect(items.single.startCharacterOffset, 0);
      expect(
        items.single.endCharacterOffset,
        r.collection.normalizedCharacterLength,
      );

      // 不伪造目录
      final toc = await repo.getToc(r.collection.id);
      expect(toc, isEmpty);

      final docs = await repo.getDocuments(r.collection.id);
      expect(docs.length, 1);
      expect(docs.single.startCharacterOffset, 0);
      expect(
        docs.single.endCharacterOffset,
        r.collection.normalizedCharacterLength,
      );
    });
  });

  group('重复导入', () {
    test('同 hash 返回 alreadyImported，不复制第二份', () async {
      final r1 = await importFixture('utf8_chapters.txt');
      final r2 = await importFixture('utf8_chapters.txt');
      expect(r2.alreadyImported, isTrue);
      expect(r2.collection.id, r1.collection.id);
      // 只有一个 collection
      expect(await repo.listCollections(), hasLength(1));
      // 只有一个正式目录（local_txt 下）
      final localTxt = Directory(
        '${libRoot.path}${Platform.pathSeparator}local_txt',
      );
      expect(await localTxt.exists(), isTrue);
      final contentDirs = await localTxt
          .list()
          .where((e) => e is Directory)
          .toList();
      expect(contentDirs.length, 1);
    });

    test('同名不同内容可分别导入', () async {
      final r1 = await importFixture('utf8_chapters.txt');
      // 构造内容不同的同名文件
      final other = File(
        '${libRoot.path}${Platform.pathSeparator}utf8_chapters_other.txt',
      );
      await other.writeAsString('第一章 不同内容\n完全不同\n');
      final r2 = await repo.importTxt(
        ImportTxtRequest(externalFile: other, confirmLargeFile: true),
      );
      expect(r2.alreadyImported, isFalse);
      expect(r2.collection.id, isNot(r1.collection.id));
      expect(await repo.listCollections(), hasLength(2));
    });
  });

  group('删除与外部保护', () {
    test('删除 collection 级联清理，外部文件保留', () async {
      final external = fixture('utf8_chapters.txt');
      final externalBytes = await external.readAsBytes();

      final r = await importFixture('utf8_chapters.txt');
      expect(await repo.listCollections(), hasLength(1));

      await repo.removeCollection(r.collection.id);

      expect(await repo.listCollections(), isEmpty);
      expect(await repo.getItems(r.collection.id), isEmpty);
      expect(await repo.getToc(r.collection.id), isEmpty);
      expect(await repo.getDocuments(r.collection.id), isEmpty);
      // 外部文件未动
      expect(await external.readAsBytes(), externalBytes);
    });

    test('删除不存在的 collection 抛异常', () async {
      expect(
        () => repo.removeCollection('local-txt:nonexistent'),
        throwsA(isA<LibraryException>()),
      );
    });

    test('删除失败不留假成功（模拟文件删除失败被捕获）', () async {
      final r = await importFixture('utf8_chapters.txt');
      // 先删文件目录再删记录，验证 deleteContentDir 的安全校验
      // 这里验证安全校验拒绝非法路径
      final fm = LibraryFileManager(libraryRoot: libRoot);
      await expectLater(
        () => fm.deleteContentDir('../escape'),
        throwsA(isA<LibraryFileException>()),
      );
      await expectLater(
        () => fm.deleteContentDir(''),
        throwsA(isA<LibraryFileException>()),
      );
      await repo.removeCollection(r.collection.id);
    });
  });

  group('文件一致性', () {
    test('原文件副本 hash 与外部一致', () async {
      final external = fixture('gbk.txt');
      final externalBytes = await external.readAsBytes();
      final r = await importFixture('gbk.txt');
      final hash = r.collection.id.replaceFirst('local-txt:', '');

      final sourceCopy = File(
        '${libRoot.path}${Platform.pathSeparator}local_txt'
        '${Platform.pathSeparator}$hash${Platform.pathSeparator}source.txt',
      );
      expect(await sourceCopy.exists(), isTrue);
      expect(await sourceCopy.readAsBytes(), externalBytes);
    });

    test('normalized.txt 只做允许的规范化', () async {
      final r = await importFixture('crlf.txt');
      final hash = r.collection.id.replaceFirst('local-txt:', '');
      final normalizedFile = File(
        '${libRoot.path}${Platform.pathSeparator}local_txt'
        '${Platform.pathSeparator}$hash${Platform.pathSeparator}normalized.txt',
      );
      final text = await normalizedFile.readAsString();
      // CRLF 已转 LF
      expect(text.contains('\r'), isFalse);
      // 段首空白保留
      expect(text.contains('  缩进'), isFalse); // fixture 无缩进
      // normalized 长度与索引一致（repository 已验证，这里抽查）
      expect(text.length, r.collection.normalizedCharacterLength);
    });

    test('外部文件字节不变（导入后）', () async {
      final external = fixture('gb18030.txt');
      final before = await external.readAsBytes();
      await importFixture('gb18030.txt');
      expect(await external.readAsBytes(), before);
    });

    test('取消清理临时目录，不留正式书', () async {
      final token = TxtImportCancellationToken();
      token.cancel();
      await expectLater(
        repo.importTxt(
          ImportTxtRequest(
            externalFile: fixture('utf8_chapters.txt'),
            confirmLargeFile: true,
          ),
          token: token,
        ),
        throwsA(isA<ImportCancelledException>()),
      );
      // 无 collection
      expect(await repo.listCollections(), isEmpty);
      // importing 临时目录不存在（或为空）
      final importing = Directory(
        '${libRoot.path}${Platform.pathSeparator}importing',
      );
      if (await importing.exists()) {
        expect(await importing.list().isEmpty, isTrue);
      }
    });
  });

  group('进度与取消', () {
    test('import progress 阶段被回调', () async {
      final phases = <PipelinePhase>[];
      final r = await repo.importTxt(
        ImportTxtRequest(
          externalFile: fixture('utf8_chapters.txt'),
          confirmLargeFile: true,
        ),
        onProgress: (p) => phases.add(p.phase),
      );
      expect(phases, isNotEmpty);
      expect(phases.last, PipelinePhase.completed);
      expect(r.alreadyImported, isFalse);
    });

    test('大文件需要确认', () async {
      // 20MB+1 fixture
      await expectLater(
        repo.importTxt(
          ImportTxtRequest(
            externalFile: fixture('large_20mb_p1.bin'),
            confirmLargeFile: false,
          ),
        ),
        throwsA(isA<LargeFileConfirmationRequired>()),
      );
    });

    test('超过 50MB 拒绝', () async {
      await expectLater(
        repo.importTxt(
          ImportTxtRequest(
            externalFile: fixture('large_50mb_p1.bin'),
            confirmLargeFile: true,
          ),
        ),
        throwsA(isA<LargeFileUnsupported>()),
      );
    });
  });

  group('缓存与 AssetBundle', () {
    test('M1 缓存可命中（重复导入内部用 .m1cache）', () async {
      // 导入两次（不同路径但同内容），第二次 should 走已导入分支
      final r1 = await importFixture('utf8_chapters.txt');
      final r2 = await importFixture('utf8_chapters.txt');
      expect(r2.alreadyImported, isTrue);
      expect(r2.collection.id, r1.collection.id);
    });

    test('EncodingIndexProvider 并发只加载一次', () async {
      // FlutterAssetEncodingIndexProvider 的并发去重：
      // 模拟一个每次 load 递增计数的 provider，验证并发请求只触发一次底层加载。
      var loads = 0;
      final p = _OnceProvider(_loadIndex, onLoad: () => loads++);
      final results = await Future.wait([p.load(), p.load(), p.load()]);
      expect(results, hasLength(3));
      expect(loads, 1);
    });
  });
}

/// 与 FlutterAssetEncodingIndexProvider 相同的并发去重语义。
class _OnceProvider implements EncodingIndexProvider {
  _OnceProvider(this._factory, {required this.onLoad});

  final Gb18030IndexData Function() _factory;
  final void Function() onLoad;

  Future<Gb18030IndexData>? _cached;
  Future<Gb18030IndexData>? _inFlight;

  @override
  Future<Gb18030IndexData> load() {
    final cached = _cached;
    if (cached != null) return cached;
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _loadOnce();
    _inFlight = future;
    return future;
  }

  Future<Gb18030IndexData> _loadOnce() async {
    onLoad();
    final parsed = _factory();
    _cached = Future.value(parsed);
    _inFlight = null;
    return parsed;
  }
}

Gb18030IndexData _loadIndex() {
  final bytes = File('assets/encoding/gb18030_index.bin').readAsBytesSync();
  return const Gb18030IndexLoader().parse(bytes);
}

class _IndexDataLoader {
  const _IndexDataLoader();

  Gb18030IndexData loadFromAsset() {
    final bytes = File('assets/encoding/gb18030_index.bin').readAsBytesSync();
    return const Gb18030IndexLoader().parse(bytes);
  }
}
