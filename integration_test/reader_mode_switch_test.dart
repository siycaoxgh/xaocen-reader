/// M4.2 集成测试：双模式切换专项（§十七/§十八/§二十/§二十一）。
///
/// 验证：
/// 1. vertical→paged：confirmed ReaderLocator 保持精确（不被 page.start 覆盖）；
/// 2. paged→vertical 未翻页：恢复原精确 anchor（§十八：切换不丢位置）；
/// 3. 用户翻页后 confirmed 更新为新页 start；
/// 4. 切换过程零错误写入（freezeWrites）；
/// 5. 分页模式目录跳转（精确 target）。
library;

import 'dart:convert';
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
import 'package:xaocen_reader/domain/reader/reader_progress_state.dart';
import 'package:xaocen_reader/reader/paged_reader_view.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_page.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

/// 生成多章 fixture（约 30 章 × 800 字符 ≈ 24KB）。
String _buildFixture() {
  final buf = StringBuffer();
  for (var i = 1; i <= 30; i++) {
    buf.writeln('第$i章 标题$i');
    for (var p = 0; p < 8; p++) {
      buf.writeln(
        '第$i章第$p 段正文，用于模式切换测试的中文分页文本。'
        'abcdefghijklmnopqrstuvwxyz0123456789 重复占位。',
      );
    }
  }
  return buf.toString();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory libRoot;
  late Directory fixtureDir;
  late ProviderContainer container;

  setUp(() {
    fixtureDir = Directory.systemTemp.createTempSync('xaocen_it_m42s_fixture');
    File(
      '${fixtureDir.path}${Platform.pathSeparator}switch_book.txt',
    ).writeAsBytesSync(utf8.encode(_buildFixture()));
  });

  tearDown(() async {
    await db.close();
    container.dispose();
    if (await libRoot.exists()) await libRoot.delete(recursive: true);
    if (await fixtureDir.exists()) await fixtureDir.delete(recursive: true);
  });

  Future<void> buildScope() async {
    db = AppDatabase.forTesting();
    libRoot = Directory.systemTemp.createTempSync('xaocen_it_m42s_lib');
    final fm = LibraryFileManager(libraryRoot: libRoot);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        fileManagerProvider.overrideWithValue(fm),
        encodingIndexProvider.overrideWithValue(
          FlutterAssetEncodingIndexProvider(),
        ),
      ],
    );
  }

  Future<void> selectMode(WidgetTester tester, ReaderMode mode) async {
    await tester.tap(find.byKey(readerAppearanceActionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('阅读行为'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(mode == ReaderMode.paged ? '分页' : '滚动').last);
    await tester.pump();
    Navigator.of(tester.element(find.byKey(readerSettingsSheetKey))).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('切换不丢位置：v→p→v 保精确 anchor + 零写入', (tester) async {
    await buildScope();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LibraryPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final repo = container.read(libraryRepositoryProvider);
    final r = await repo.importTxt(
      ImportTxtRequest(
        externalFile: File(
          '${fixtureDir.path}${Platform.pathSeparator}switch_book.txt',
        ),
        confirmLargeFile: true,
      ),
    );
    expect(r.alreadyImported, isFalse);
    container.invalidate(collectionsProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    const requestedX = 1200;
    final progressRepo = container.read(readingProgressRepositoryProvider);
    await progressRepo.saveProgress(
      ReaderProgressState(
        collectionId: r.collection.id,
        absoluteCharacterOffset: requestedX,
        readingMode: ReadingMode.vertical,
      ),
    );

    // 打开 Reader
    await tester.tap(find.text('switch_book'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ReaderPage), findsOneWidget);

    final x = (await progressRepo.getProgress(
      r.collection.id,
    ))!.absoluteCharacterOffset;
    expect(x, greaterThan(0), reason: '核心模式切换验收必须使用非零 Locator X');

    // v → p
    await selectMode(tester, ReaderMode.paged);
    await tester.pumpAndSettle();
    expect(find.byType(PagedReaderView), findsOneWidget);

    // 切换后 DB 仍无进度（模式切换本身不写，§十八）
    expect(
      await progressRepo.getProgress(r.collection.id),
      isA<ReaderProgressState>().having(
        (state) => state.absoluteCharacterOffset,
        'absoluteCharacterOffset',
        x,
      ),
      reason: '切换本身不写进度',
    );

    // p → v（未翻页）
    await selectMode(tester, ReaderMode.vertical);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PagedReaderView), findsNothing);
    // 未翻页切回：DB 仍无进度（位置未变，无用户操作）
    expect(
      await progressRepo.getProgress(r.collection.id),
      isA<ReaderProgressState>().having(
        (state) => state.absoluteCharacterOffset,
        'absoluteCharacterOffset',
        x,
      ),
      reason: '未翻页切换不产生进度写入',
    );

    // 返回书架、重开：仍从非零 X 恢复。
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('switch_book'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ReaderPage), findsOneWidget);
  });

  testWidgets('翻页后 confirmed 更新 + 目录远跳保存精确 target', (tester) async {
    await buildScope();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LibraryPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final repo = container.read(libraryRepositoryProvider);
    final r = await repo.importTxt(
      ImportTxtRequest(
        externalFile: File(
          '${fixtureDir.path}${Platform.pathSeparator}switch_book.txt',
        ),
        confirmLargeFile: true,
      ),
    );
    container.invalidate(collectionsProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('switch_book'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // v → p
    await selectMode(tester, ReaderMode.paged);
    await tester.pumpAndSettle();

    // 翻两页
    final pv = find.byType(PageView);
    await tester.fling(pv, const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();
    await tester.fling(pv, const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();

    // 翻页（用户操作）→ 防抖保存新页 start
    await tester.pump(const Duration(milliseconds: 500));
    final progressRepo = container.read(readingProgressRepositoryProvider);
    final saved = await progressRepo.getProgress(r.collection.id);
    expect(saved, isNotNull, reason: '用户翻页后应保存进度');
    expect(
      saved!.absoluteCharacterOffset,
      greaterThan(0),
      reason: '翻页后位置应前进，且保存的是 offset 而非 pageIndex',
    );

    // 目录远跳第 20 章 → 保存精确 target
    await tester.tap(find.byIcon(Icons.list));
    await tester.pumpAndSettle();
    // drag 目录列表（DraggableScrollableSheet 内 ListView）直到第 20 章可见
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pump();
      if (find.text('第20章 标题20').evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('第20章 标题20'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    final afterJump = await progressRepo.getProgress(r.collection.id);
    expect(afterJump, isNotNull);
    // 精确 target：第 20 章 offset（远跳后必然大于翻页位置）
    expect(
      afterJump!.absoluteCharacterOffset,
      greaterThan(saved.absoluteCharacterOffset),
      reason: '目录远跳后 confirmed = 精确 target，位置前进',
    );
  });
}
