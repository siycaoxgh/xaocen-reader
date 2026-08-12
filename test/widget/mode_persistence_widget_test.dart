// M4 P1 Widget 层：退出只 flush active 模式 + 重开恢复「模式 + Locator」。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/domain/reader/reader_progress_state.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/paged_reader_view.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_page.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

// 多页 fixture：够大以支持翻页（分页模式）。
final String _bookText = _buildBookText();

String _buildBookText() {
  final buf = StringBuffer();
  for (var i = 1; i <= 20; i++) {
    buf.writeln('第$i章 测试章节标题$i');
    for (var p = 0; p < 6; p++) {
      buf.writeln(
        '这是第$i章第$p段的正文内容，'
        '用于分页与模式切换测试。'
        '重复占位：abcdefghijklmnopqrstuvwxyz0123456789。',
      );
    }
  }
  return buf.toString();
}

void main() {
  late AppDatabase db;
  late ReadingProgressRepository repo;
  late ReaderLaunchContext ctx;

  setUp(() async {
    db = AppDatabase.forTesting();
    repo = ReadingProgressRepository(db: db);
    final now = DateTime.now();
    await db
        .into(db.contentSources)
        .insert(
          ContentSourcesCompanion.insert(
            id: 'local-txt-source:abc',
            type: 'localTxt',
            displayName: 'T',
            contentHash: 'abc',
            managedSourcePath: 'p',
            sourceSize: 1,
            detectedEncoding: 'utf8',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.contentCollections)
        .insert(
          ContentCollectionsCompanion.insert(
            id: 'local-txt:abc',
            sourceId: 'local-txt-source:abc',
            title: '测试书籍',
            itemCount: 4,
            normalizedCharacterLength: _bookText.length,
            importedAt: now,
            updatedAt: now,
          ),
        );
    ctx = ReaderLaunchContext(
      collection: LibraryCollection(
        id: 'local-txt:abc',
        sourceId: 'local-txt-source:abc',
        title: '测试书籍',
        subtitle: null,
        itemCount: 4,
        normalizedCharacterLength: _bookText.length,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 1,
        importedAt: DateTime.now(),
      ),
      documents: const [],
      normalizedCharacterLength: _bookText.length,
      toc: const [],
      documentLoader: NormalizedDocumentLoader(
        fileManager: LibraryFileManager(
          libraryRoot: Directory.systemTemp.createTempSync('m41_widget'),
        ),
      ),
      progressRepository: repo,
    );
  });

  tearDown(() async => db.close());

  Future<void> pumpReader(
    WidgetTester tester, {
    ReaderProgressState? initialState,
    ReaderLocator? progress,
    ValueChanged<ReaderModeRestoreReport>? onModeRestore,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPage(
          launch: ctx,
          documentOverride: NormalizedDocument(
            text: _bookText,
            normalizedHash: '',
            normalizationVersion: 'v1',
            parserVersion: '1',
            indexFormatVersion: '1',
            sourceFileName: 'test.txt',
          ),
          initialStateOverride: initialState,
          progressOverride: progress,
          onModeRestore: onModeRestore,
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> selectMode(WidgetTester tester, ReaderMode mode) async {
    await tester.tap(find.byKey(readerAppearanceActionKey));
    await tester.pumpAndSettle();
    // The responsive Aa sheet uses an icon rail at the 600–839 px tier, so
    // the category label is intentionally not rendered at the test surface
    // width. Select the stable category key instead of relying on desktop
    // text being present.
    await tester.tap(
      find.byKey(const ValueKey('reader-settings-category-paging')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(mode == ReaderMode.paged ? '分页' : '滚动').last);
    await tester.pump();
    Navigator.of(tester.element(find.byKey(readerSettingsSheetKey))).pop();
    await tester.pumpAndSettle();
  }

  // Exercise the same ReaderPage mode callback without waiting between
  // transitions; this keeps the generation/cancellation regression test
  // genuinely rapid while the user-facing entry remains Aa → 阅读行为.
  void selectModeImmediately(WidgetTester tester, ReaderMode mode) {
    tester.widget<ReaderChrome>(find.byType(ReaderChrome)).onModeSelected(mode);
  }

  testWidgets('P1 regression: non-zero v -> p -> v confirms exact locator', (
    tester,
  ) async {
    const x = 1000;
    ReaderModeRestoreReport? report;
    await pumpReader(
      tester,
      initialState: const ReaderProgressState(
        collectionId: 'local-txt:abc',
        absoluteCharacterOffset: x,
        readingMode: ReadingMode.vertical,
      ),
      onModeRestore: (value) => report = value,
    );

    await selectMode(tester, ReaderMode.paged);
    await tester.pump();
    await selectMode(tester, ReaderMode.vertical);
    for (var i = 0; i < 20 && report == null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(report, isNotNull);
    expect(report!.target.absoluteCharacterOffset, x);
    expect(report!.confirmed.absoluteCharacterOffset, x);
    expect(report!.visibleRange.contains(x), isTrue);
  });

  testWidgets('P1 regression: rapid v -> p -> v keeps latest generation', (
    tester,
  ) async {
    const x = 1200;
    final reports = <ReaderModeRestoreReport>[];
    await pumpReader(
      tester,
      initialState: const ReaderProgressState(
        collectionId: 'local-txt:abc',
        absoluteCharacterOffset: x,
        readingMode: ReadingMode.vertical,
      ),
      onModeRestore: reports.add,
    );

    selectModeImmediately(tester, ReaderMode.paged);
    selectModeImmediately(tester, ReaderMode.vertical);
    selectModeImmediately(tester, ReaderMode.paged);
    selectModeImmediately(tester, ReaderMode.vertical);
    for (var i = 0; i < 30 && reports.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(reports, hasLength(1));
    expect(reports.single.confirmed.absoluteCharacterOffset, x);
  });

  testWidgets('P1 regression: non-zero p -> v -> p keeps exact locator', (
    tester,
  ) async {
    const x = 1400;
    final reports = <ReaderModeRestoreReport>[];
    await pumpReader(
      tester,
      initialState: const ReaderProgressState(
        collectionId: 'local-txt:abc',
        absoluteCharacterOffset: x,
        readingMode: ReadingMode.paged,
      ),
      onModeRestore: reports.add,
    );
    await tester.pumpAndSettle();

    await selectMode(tester, ReaderMode.vertical);
    for (var i = 0; i < 20 && reports.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await selectMode(tester, ReaderMode.paged);
    await selectMode(tester, ReaderMode.vertical);
    for (var i = 0; i < 20 && reports.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(reports, hasLength(2));
    expect(
      reports.every((r) => r.confirmed.absoluteCharacterOffset == x),
      isTrue,
    );
    expect(reports.every((r) => r.visibleRange.contains(x)), isTrue);
  });

  testWidgets('P1-1: 分页模式 dispose 只 flush active（不被纵向覆盖）', (tester) async {
    // 纵向初始位置 A=0，注入
    await pumpReader(
      tester,
      initialState: const ReaderProgressState(
        collectionId: 'local-txt:abc',
        absoluteCharacterOffset: 0,
        readingMode: ReadingMode.vertical,
      ),
    );

    // 切分页（菜单 → 分页）
    await selectMode(tester, ReaderMode.paged);
    await tester.pumpAndSettle();
    expect(find.byType(PagedReaderView), findsOneWidget, reason: '已切分页');

    // 翻一页（fling 左滑 = 下一页）→ onPageSettled 防抖保存 paged+B
    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    // dispose（替换 widget 树）
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    // 验证 DB：mode=paged 且位置 > 0（B），不被纵向 A=0 覆盖
    final p = await repo.getProgress('local-txt:abc');
    expect(p, isNotNull);
    expect(
      p!.readingMode,
      ReadingMode.paged,
      reason: '退出后保留 paged 模式（不被 inactive 纵向覆盖）',
    );
    expect(p.absoluteCharacterOffset, greaterThan(0), reason: '翻页后的 B 位置被保留');
  });

  testWidgets('P1-2: 重开自动恢复 paged 模式 + 位置', (tester) async {
    // 预存 paged + B（上次退出状态）
    await repo.saveProgress(
      const ReaderProgressState(
        collectionId: 'local-txt:abc',
        absoluteCharacterOffset: 30,
        readingMode: ReadingMode.paged,
      ),
    );

    // 重开：initialStateOverride 模拟从 DB 读到的 paged+B
    await pumpReader(
      tester,
      initialState: const ReaderProgressState(
        collectionId: 'local-txt:abc',
        absoluteCharacterOffset: 30,
        readingMode: ReadingMode.paged,
      ),
    );

    // 等 postFrame 自动切 paged
    await tester.pumpAndSettle();
    expect(find.byType(PagedReaderView), findsOneWidget, reason: '重开自动恢复分页模式');
  });

  testWidgets('P1-3: 纵向模式 dispose 正常保存 vertical', (tester) async {
    await pumpReader(
      tester,
      initialState: const ReaderProgressState(
        collectionId: 'local-txt:abc',
        absoluteCharacterOffset: 5,
        readingMode: ReadingMode.vertical,
      ),
    );
    // 纵向滚动一下（触发上报）
    await tester.drag(find.byType(ReaderPage), const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 500));
    // dispose
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    final p = await repo.getProgress('local-txt:abc');
    expect(p!.readingMode, ReadingMode.vertical);
  });
}
