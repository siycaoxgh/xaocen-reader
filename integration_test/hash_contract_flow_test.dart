import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xaocen_reader/app/library_page.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/reader_page.dart';
import 'package:xaocen_reader/reader/reader_text_block.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_data.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_loader.dart';

/// M3.1 hash 合同集成测试（任务书 §十一）。
///
/// 核心链路：导入大 fixture（含 CRLF）→ 完全关闭 Repository/Database →
/// 重新打开 → NormalizedDocumentLoader → Reader 首屏成功。
/// 断言 normalizedHash 三处一致（manifest / Drift / 落盘字节）。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory libRoot;
  late Directory fixtureDir;

  setUp(() {
    fixtureDir = Directory.systemTemp.createTempSync('xaocen_m31_fixture');
    // 生成大 fixture：~1.2MB，CRLF 行尾，少量章节（贴近真实文件）
    final sb = StringBuffer();
    var i = 0;
    while (sb.length < 1200 * 1024) {
      sb.write('第$i章 大文件内容\r\n');
      while (sb.length < 40 * 1024 * (i + 1) && sb.length < 1200 * 1024) {
        sb.write('正文内容段落${i}_$i，汉字混排𠀀𠀀𠀀。\r\n');
      }
      i++;
    }
    File(
      '${fixtureDir.path}${Platform.pathSeparator}big_crlf.txt',
    ).writeAsBytesSync(utf8.encode(sb.toString()));
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
    // 等一小段让文件句柄释放
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      if (await libRoot.exists()) await libRoot.delete(recursive: true);
    } catch (_) {}
    try {
      if (await fixtureDir.exists()) await fixtureDir.delete(recursive: true);
    } catch (_) {}
  });

  /// 数据库文件（跨会话持久化验证用）。
  late File dbFile;

  /// 用文件数据库构建作用域（模拟真实应用持久化，支持跨会话重开）。
  Future<ProviderContainer> buildScope() async {
    libRoot = Directory.systemTemp.createTempSync('xaocen_m31_lib');
    dbFile = File('${libRoot.path}/library.sqlite');
    db = AppDatabase(NativeDatabase(dbFile));
    final fm = LibraryFileManager(libraryRoot: libRoot);
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        fileManagerProvider.overrideWithValue(fm),
        encodingIndexProvider.overrideWithValue(_indexProvider()),
      ],
    );
  }

  testWidgets('大 fixture 导入→关闭→重开→Loader→Reader 首屏', (tester) async {
    // ---- 第一次启动：导入 ----
    final container = await buildScope();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: const LibraryPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('书库为空，点击“导入书籍”开始'), findsOneWidget);

    final repo = container.read(libraryRepositoryProvider);
    final r1 = await repo.importTxt(
      ImportTxtRequest(
        externalFile: File(
          '${fixtureDir.path}${Platform.pathSeparator}big_crlf.txt',
        ),
        confirmLargeFile: true,
      ),
    );
    expect(r1.alreadyImported, isFalse);
    final collectionId = r1.collection.id;

    // 断言：Drift content_hash == manifest normalizedHash == 落盘字节 hash
    final hash = collectionId.replaceFirst('local-txt:', '');
    final normBytes = await File(
      '${libRoot.path}/local_txt/$hash/normalized.txt',
    ).readAsBytes();
    final normSha = sha256.convert(normBytes).toString();
    final docs = await repo.getDocuments(collectionId);
    expect(docs, isNotEmpty);
    for (final d in docs) {
      expect(d.contentHash, normSha, reason: 'Drift 必须存 normalizedHash');
    }
    final manifest = await File(
      '${libRoot.path}/local_txt/$hash/manifest.json',
    ).readAsString();
    expect(manifest, contains(normSha));

    // ---- 完全关闭 Repository/Database（§十一 要求跨会话）----
    await db.close();
    container.dispose();

    // ---- 同一文件数据库重开 ----
    final db2 = AppDatabase(NativeDatabase(dbFile));
    final fm2 = LibraryFileManager(libraryRoot: libRoot);
    final repo2 = LocalLibraryRepository(
      database: db2,
      fileManager: fm2,
      encodingIndexProvider: _indexProvider(),
    );

    // ---- 重新打开：Loader 加载成功 ----
    final loader2 = NormalizedDocumentLoader(fileManager: fm2);
    final docs2 = await repo2.getDocuments(collectionId);
    expect(docs2, isNotEmpty);
    final doc = await loader2.load(
      storagePath: docs2.first.storagePath,
      expectedLength: r1.collection.normalizedCharacterLength,
    );
    expect(doc.text.length, r1.collection.normalizedCharacterLength);
    expect(doc.text.contains('第0章 大文件内容'), isTrue);

    // ---- Reader 首屏成功 ----
    final toc = await repo2.getToc(collectionId);
    final container2 = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db2),
        fileManagerProvider.overrideWithValue(fm2),
        encodingIndexProvider.overrideWithValue(_indexProvider()),
      ],
    );
    addTearDown(container2.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container2,
        child: MaterialApp(
          home: ReaderPage(
            launch: ReaderLaunchContext(
              collection: r1.collection,
              documents: docs2,
              toc: toc,
              normalizedCharacterLength:
                  r1.collection.normalizedCharacterLength,
              documentLoader: loader2,
              progressRepository: ReadingProgressRepository(db: db2),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    // 首屏应渲染正文块（非 loading / 非 failed）
    expect(
      find.byType(ReaderTextBlock),
      findsWidgets,
      reason: 'Reader 首屏应渲染正文块',
    );
    expect(find.textContaining('加载失败'), findsNothing);
    expect(find.textContaining('书籍文件需要修复'), findsNothing);

    await db2.close();
    // 让 tearDown 的 db.close() 幂等（db 已 close，再次 close 安全）
  });
}

class _IndexDataLoader {
  const _IndexDataLoader();
  Gb18030IndexData loadFromAsset() {
    final f = File('assets/encoding/gb18030_index.bin');
    return const Gb18030IndexLoader().parse(f.readAsBytesSync());
  }
}

EncodingIndexProvider _indexProvider() =>
    MemoryEncodingIndexProvider(const _IndexDataLoader().loadFromAsset());
