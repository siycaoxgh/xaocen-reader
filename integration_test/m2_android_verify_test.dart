import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xaocen_reader/app/library_page.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/sources/local_txt/txt_cancellation.dart';

/// Android 真机专项验证（M2）：
/// 1) 真实 AssetBundle 加载 GB18030 索引（FlutterAssetEncodingIndexProvider）
/// 2) 唯一名文件（UUID 风格文件名）导入 + 重复导入 alreadyImported
/// 3) 取消导入不留半成品（importing/ 目录与 DB 记录清理）
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory libRoot;
  late Directory fixtureDir;
  late ProviderContainer container;

  setUp(() {
    fixtureDir = Directory.systemTemp.createTempSync('xaocen_android_fx');
    // 唯一名（UUID 风格）UTF-8 fixture
    File(
      '${fixtureDir.path}${Platform.pathSeparator}9f8e7d6c-5b4a-3c2d-1e0f-uuid-name.txt',
    ).writeAsString('第一章 开端\n正文第一行。\n\n第二章 后续\n正文第二行。\n');
    // 取消测试用大一点的文件（写入 1MB 重复行，让导入有时间被取消）
    final big = StringBuffer();
    for (var i = 0; i < 40000; i++) {
      big.writeln('第${i + 1}章 内容段落$i');
      big.writeln('这是正文行$i，用于取消测试的中间状态。');
    }
    File(
      '${fixtureDir.path}${Platform.pathSeparator}big_cancel.txt',
    ).writeAsString(big.toString());
  });

  tearDown(() async {
    await db.close();
    container.dispose();
    if (await libRoot.exists()) await libRoot.delete(recursive: true);
    if (await fixtureDir.exists()) await fixtureDir.delete(recursive: true);
  });

  Future<void> buildScope() async {
    db = AppDatabase.forTesting();
    libRoot = Directory.systemTemp.createTempSync('xaocen_android_lib');
    final fm = LibraryFileManager(libraryRoot: libRoot);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        fileManagerProvider.overrideWithValue(fm),
        encodingIndexProvider.overrideWithValue(_indexProvider()),
      ],
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: const LibraryPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('AssetBundle 加载 + UUID 名导入 + alreadyImported', (tester) async {
    await buildScope();
    await pump(tester);

    // 1) AssetBundle 加载：直接调用 FlutterAssetEncodingIndexProvider
    final assetProvider = FlutterAssetEncodingIndexProvider();
    final index = await assetProvider.load();
    expect(index.entryCount, 23940);
    expect(index.anchorCount, 209);
    // 并发去重
    final results = await Future.wait([
      assetProvider.load(),
      assetProvider.load(),
      assetProvider.load(),
    ]);
    expect(results, hasLength(3));
    expect(results.every((r) => identical(r, index)), isTrue);

    // 2) UUID 风格名导入
    final repo = container.read(libraryRepositoryProvider);
    final r1 = await repo.importTxt(
      ImportTxtRequest(
        externalFile: File(
          '${fixtureDir.path}${Platform.pathSeparator}9f8e7d6c-5b4a-3c2d-1e0f-uuid-name.txt',
        ),
        confirmLargeFile: true,
      ),
    );
    expect(r1.alreadyImported, isFalse);
    expect(r1.collection.title, '9f8e7d6c-5b4a-3c2d-1e0f-uuid-name');

    // 重复导入 → alreadyImported
    final r2 = await repo.importTxt(
      ImportTxtRequest(
        externalFile: File(
          '${fixtureDir.path}${Platform.pathSeparator}9f8e7d6c-5b4a-3c2d-1e0f-uuid-name.txt',
        ),
        confirmLargeFile: true,
      ),
    );
    expect(r2.alreadyImported, isTrue);
    expect(r2.collection.id, r1.collection.id);

    // 书架显示
    container.invalidate(collectionsProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('uuid-name'), findsWidgets);
  });

  testWidgets('取消导入不留半成品', (tester) async {
    await buildScope();
    await pump(tester);

    final repo = container.read(libraryRepositoryProvider);
    // 立即取消：token 先取消再导入，导入应立刻抛 ImportCancelledException
    final token = TxtImportCancellationToken();
    token.cancel();
    await expectLater(
      repo.importTxt(
        ImportTxtRequest(
          externalFile: File(
            '${fixtureDir.path}${Platform.pathSeparator}big_cancel.txt',
          ),
          confirmLargeFile: true,
        ),
        token: token,
      ),
      throwsA(isA<ImportCancelledException>()),
    );
    // 取消后应无半成品：书库为空、importing 目录无残留
    expect(await repo.listCollections(), isEmpty);
    final importingDir = Directory(
      '${libRoot.path}${Platform.pathSeparator}importing',
    );
    if (await importingDir.exists()) {
      final leftover = await importingDir.list().toList();
      expect(leftover, isEmpty, reason: '取消后 importing 目录应为空');
    }
    // UI 不应显示新书
    container.invalidate(collectionsProvider);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('big_cancel'), findsNothing);
  });
}

/// 跨平台加载：Windows 用文件路径；Android 用 AssetBundle。
EncodingIndexProvider _indexProvider() {
  return FlutterAssetEncodingIndexProvider();
}
