/// PagedReaderController 单元测试（M4 §四十一-20~25 等）。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/domain/reader/reader_search.dart';
import 'package:xaocen_reader/domain/reader/reader_visible_range.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/paged_reader_controller.dart';
import 'package:xaocen_reader/reader/reader_controller.dart';

const _style = TextStyle(fontSize: 10, height: 1.0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late AppDatabase db;
  late ReadingProgressRepository progressRepo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('xaocen_paged_ctrl');
    db = AppDatabase.forTesting();
    progressRepo = ReadingProgressRepository(db: db);
    await _seedCollection(db, 'c1');
  });

  tearDown(() async {
    await db.close();
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  /// 构造分页控制器。Ahem：fontSize 10、宽 100、无 padding →
  /// 每行 10 字符、每页 10 行 = 100 字符。
  PagedReaderController makeController({
    String? text,
    double width = 100,
    double height = 100,
  }) {
    final t = text ?? 'a' * 1000;
    final doc = NormalizedDocument(
      text: t,
      normalizedHash: '',
      normalizationVersion: 'v1',
      parserVersion: '1',
      indexFormatVersion: '1',
      sourceFileName: 'test.txt',
    );
    final bi = ReaderBlockIndex.build(text: t, targetBlockSize: 6144);
    return PagedReaderController(
      collectionId: 'c1',
      document: doc,
      progressRepository: progressRepo,
      blockIndex: bi,
      style: _style,
      width: width,
      height: height,
      horizontalPadding: 0,
      verticalPadding: 0,
    );
  }

  group('PagedReaderController', () {
    test(
      'M5.2c search result jumps to containing page without replacing offset',
      () {
        final controller = makeController(text: 'searchable ' * 2000);
        controller.open(
          const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
        );
        const result = ReaderSearchResult(
          startOffset: 1234,
          endOffset: 1240,
          contextStartOffset: 1200,
          contextEndOffset: 1300,
          snippet: 'searchable',
          derivedChapterTitle: '全文',
        );
        final page = controller.jumpToOffset(result.startOffset);
        expect(page.contains(result.startOffset), isTrue);
        expect(controller.confirmedLocator?.absoluteCharacterOffset, 1234);
        controller.dispose();
      },
    );

    test(
      'metrics relayout invalidates window/signature and preserves exact locator',
      () {
        final c = makeController(text: 'a' * 20000, width: 400, height: 600);
        const anchor = ReaderLocator(
          collectionId: 'c1',
          absoluteCharacterOffset: 9876,
        );
        c.open(anchor);
        final oldGeneration = c.generation;
        final oldSignature = c.lastSignature;
        final oldWindow = c.window.current;

        c.freezeWrites();
        final changed = c.relayout(
          width: 400,
          height: 600,
          style: const TextStyle(fontSize: 22, height: 1.8),
          horizontalPadding: 36,
          verticalPadding: 24,
        );

        expect(changed, isTrue);
        expect(c.generation, greaterThan(oldGeneration));
        expect(c.lastSignature, isNot(oldSignature));
        expect(c.window.current, isNot(oldWindow));
        expect(
          c.window.current!.contains(anchor.absoluteCharacterOffset),
          isTrue,
        );
        expect(c.confirmedLocator, anchor);
        expect(c.window.pageCount, lessThanOrEqualTo(6), reason: '不得全文预分页');
        c.unfreezeWrites();
        c.dispose();
      },
    );

    test('rapid metrics generations leave only final metrics active', () {
      final c = makeController(text: 'a' * 20000, width: 400, height: 600);
      const anchor = ReaderLocator(
        collectionId: 'c1',
        absoluteCharacterOffset: 9876,
      );
      c.open(anchor);
      for (final size in <double>[18, 20, 24, 22]) {
        c.relayout(
          width: 400,
          height: 600,
          style: TextStyle(fontSize: size, height: 1.7),
        );
      }
      expect(c.lastSignature.styleMetricsKey, contains('22'));
      expect(c.currentPage!.contains(anchor.absoluteCharacterOffset), isTrue);
      expect(c.confirmedLocator, anchor);
      c.dispose();
    });

    test(
      'metrics freeze blocks paged lifecycle/dispose progress writes',
      () async {
        final c = makeController(text: 'a' * 20000, width: 400, height: 600);
        const anchor = ReaderLocator(
          collectionId: 'c1',
          absoluteCharacterOffset: 5000,
        );
        c.open(anchor);
        c.freezeWrites();
        await c.flush();
        expect(await progressRepo.getProgress('c1'), isNull);
        c.dispose();
        expect(await progressRepo.getProgress('c1'), isNull);
      },
    );

    test('open(anchor)：页面覆盖 anchor，confirmed=精确 anchor（§17）', () {
      final c = makeController();
      final page = c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 250),
      );
      expect(page.contains(250), isTrue);
      expect(
        c.confirmedLocator!.absoluteCharacterOffset,
        250,
        reason: '打开时 confirmed 必须保持精确 anchor，不被 page.start 覆盖',
      );
      // 窗口预填前后相邻页（§九）：有限窗口，与全文页数无关。
      expect(c.window.pageCount, greaterThanOrEqualTo(1));
      expect(c.window.pageCount, lessThanOrEqualTo(2 + 1 + 3));
      expect(c.window.current!.contains(250), isTrue);
      c.dispose();
    });

    test('page 开头可以早于 anchor（§17）', () {
      final c = makeController();
      final page = c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 250),
      );
      expect(page.startCharacterOffset <= 250, isTrue);
      expect(page.endCharacterOffset > 250, isTrue);
      c.dispose();
    });

    test('nextPage：窗口扩展 + confirmed=新页 start + 防抖保存（§19）', () async {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      final r = c.nextPage();
      expect(r, PageTurnResult.ok);
      expect(c.currentPage!.startCharacterOffset, 100);
      expect(
        c.confirmedLocator!.absoluteCharacterOffset,
        100,
        reason: '用户翻页后 confirmed = 新页 page.start',
      );
      // 防抖 400ms 后落库
      await Future.delayed(const Duration(milliseconds: 450));
      final p = await progressRepo.getProgress('c1');
      expect(p!.absoluteCharacterOffset, 100);
      c.dispose();
    });

    test('previousPage：窗口向前扩展', () {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 500),
      );
      c.nextPage(); // 500→600
      c.nextPage(); // 600→700
      final r = c.previousPage(); // 700→600
      expect(r, PageTurnResult.ok);
      expect(c.currentPage!.startCharacterOffset, 600);
      expect(c.confirmedLocator!.absoluteCharacterOffset, 600);
      c.dispose();
    });

    test('document start/end：startReached / endReached（§27/§28）', () {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      expect(c.previousPage(), PageTurnResult.startReached);
      // 翻到最后一页
      var guard = 0;
      while (c.nextPage() == PageTurnResult.ok && guard < 20) {
        guard++;
      }
      expect(c.window.atDocumentEnd, isTrue);
      expect(c.nextPage(), PageTurnResult.endReached);
      expect(
        c.currentPage!.endCharacterOffset,
        1000,
        reason: '末页 end = document length（§27）',
      );
      c.dispose();
    });

    test('jumpToOffset：confirmed=精确 target，不被 page.start 覆盖（§24）', () async {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      final page = c.jumpToOffset(255, itemIdHint: 'ch2');
      expect(page.contains(255), isTrue);
      expect(page.startCharacterOffset <= 255, isTrue);
      expect(
        c.confirmedLocator!.absoluteCharacterOffset,
        255,
        reason: '目录跳转后 confirmed 保持精确 target',
      );
      // 明确用户操作：立即防抖保存
      await Future.delayed(const Duration(milliseconds: 450));
      final p = await progressRepo.getProgress('c1');
      expect(p!.absoluteCharacterOffset, 255);
      expect(p.itemIdHint, 'ch2');
      c.dispose();
    });

    test('只切模式不翻页：confirmed 保持 anchor（§18）', () {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 250),
      );
      // 模拟「立即切回」：未翻页时 confirmed 仍是 250 而非 page.start
      expect(c.confirmedLocator!.absoluteCharacterOffset, 250);
      expect(c.userTurnedPage, isFalse);
      c.dispose();
    });

    test('partial swipe 不保存（§19：只拖动一半不保存）', () async {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      // 不调用 onPageSettled / nextPage：无保存
      await Future.delayed(const Duration(milliseconds: 450));
      expect(await progressRepo.getProgress('c1'), isNull);
      c.dispose();
    });

    test('stale generation：过期防抖结果被拒绝（§21）', () async {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      c.nextPage(); // 防抖 Timer 挂起（gen=1）
      c.jumpToOffset(500); // generation++（gen=2），旧 Timer 应失效
      await Future.delayed(const Duration(milliseconds: 450));
      final p = await progressRepo.getProgress('c1');
      expect(
        p!.absoluteCharacterOffset,
        500,
        reason: '过期代（nextPage 的 100）不得覆盖新代位置',
      );
      c.dispose();
    });

    test('relayout：resize 后 confirmed 保持（§31）', () {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 250),
      );
      final before = c.confirmedLocator!;
      final changed = c.relayout(width: 200, height: 100, style: _style);
      expect(changed, isTrue);
      expect(
        c.confirmedLocator,
        before,
        reason: 'resize 是程序化重建，confirmed 保持不变',
      );
      // 新尺寸下页面仍覆盖原位置
      expect(c.currentPage!.contains(250), isTrue);
      c.dispose();
    });

    test('relayout：同尺寸同样式不重建', () {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      final gen = c.window.windowGeneration;
      final changed = c.relayout(width: 100, height: 100, style: _style);
      expect(changed, isFalse);
      expect(c.window.windowGeneration, gen);
      c.dispose();
    });

    test('纯颜色变化不重分页（§32：签名不变）', () {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      final pageBefore = c.currentPage!;
      // 颜色变化：同一 metrics key
      final colorStyle = const TextStyle(
        fontSize: 10,
        height: 1.0,
        color: Colors.red,
      );
      final changed = c.relayout(width: 100, height: 100, style: colorStyle);
      expect(changed, isTrue, reason: '颜色变化不改变签名 → 不重分页');
      expect(c.currentPage, pageBefore, reason: '颜色变化不改变页面划分（同一 metrics）');
      c.dispose();
    });

    test('no pageIndex persistence：保存的是 offset 而非页号', () async {
      final c = makeController();
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      c.nextPage(); // 第 2 页
      await Future.delayed(const Duration(milliseconds: 450));
      final p = await progressRepo.getProgress('c1');
      expect(p!.absoluteCharacterOffset, 100);
      expect(
        p.absoluteCharacterOffset,
        isNot(1),
        reason: '不得把 pageIndex 当位置保存',
      );
      c.dispose();
    });

    test('empty document：打开不 crash、单空页、confirmed 合法（§29）', () {
      final c = makeController(text: '');
      final page = c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      expect(page.length, 0);
      expect(c.window.atDocumentEnd, isTrue);
      expect(c.nextPage(), PageTurnResult.endReached);
      expect(c.previousPage(), PageTurnResult.startReached);
      expect(c.confirmedLocator!.absoluteCharacterOffset, 0);
      c.dispose();
    });

    test('window 保持有限：连续翻 50 页窗口数不增长（§14）', () {
      final c = makeController(text: 'a' * 10000);
      c.open(
        const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0),
      );
      for (var i = 0; i < 50; i++) {
        c.nextPage();
      }
      expect(c.window.pageCount, lessThanOrEqualTo(6));
      expect(c.window.maxObserved, lessThanOrEqualTo(7));
      c.dispose();
    });

    test('rapid mode switch（§41-24）：连续 open/relayout 不崩溃', () {
      final c = makeController();
      for (var i = 0; i < 5; i++) {
        c.open(
          ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: i * 100),
        );
        c.relayout(width: 100 + i * 10, height: 100, style: _style);
      }
      expect(c.confirmedLocator, isNotNull);
      expect(c.currentPage, isNotNull);
      c.dispose();
    });
  });

  group('ReaderController write freeze（§21）', () {
    test('freezeWrites 期间 flush 零写入；解冻后写入', () async {
      final rc = ReaderController(
        collectionId: 'c1',
        documentLoader: NormalizedDocumentLoader(
          fileManager: LibraryFileManager(libraryRoot: tmp),
        ),
        progressRepository: progressRepo,
      );
      rc.injectDocument(
        NormalizedDocument(
          text: '第一章\n正文\n',
          normalizedHash: '',
          normalizationVersion: 'v1',
          parserVersion: '1',
          indexFormatVersion: '1',
          sourceFileName: 't.txt',
        ),
      );
      rc.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 5,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await rc.open();
      await rc.finishRestore(); // 解冻用户写入
      rc.reportUserScroll(topVisibleCharacterOffset: 2);

      rc.freezeWrites();
      await rc.flush(); // 冻结中：不落库
      expect(
        await progressRepo.getProgress('c1'),
        isNull,
        reason: '切换期间写入必须冻结',
      );
      rc.unfreezeWrites();
      await rc.flush();
      expect(
        (await progressRepo.getProgress('c1'))!.absoluteCharacterOffset,
        2,
      );
      rc.dispose();
    });
  });
}

/// 准备一个 collection（reading_progress 外键依赖）。
Future<void> _seedCollection(AppDatabase db, String id) async {
  final now = DateTime.now();
  final hash = id.replaceFirst('local-txt:', '');
  await db
      .into(db.contentSources)
      .insert(
        ContentSourcesCompanion.insert(
          id: 'local-txt-source:$hash',
          type: 'localTxt',
          displayName: 'Test',
          contentHash: hash,
          managedSourcePath: 'library/local_txt/$hash/source.txt',
          sourceSize: 100,
          detectedEncoding: 'utf8',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db
      .into(db.contentCollections)
      .insert(
        ContentCollectionsCompanion.insert(
          id: id,
          sourceId: 'local-txt-source:$hash',
          title: 'Test',
          itemCount: 1,
          normalizedCharacterLength: 100,
          importedAt: now,
          updatedAt: now,
        ),
      );
}
