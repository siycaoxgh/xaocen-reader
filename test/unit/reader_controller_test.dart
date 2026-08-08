import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/domain/reader/reader_progress_state.dart';
import 'package:xaocen_reader/domain/reader/reading_mode.dart';
import 'package:xaocen_reader/domain/reader/reader_visible_range.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/reader_controller.dart';

void main() {
  late Directory tmp;
  late AppDatabase db;
  late ReadingProgressRepository progressRepo;
  late LibraryFileManager fileManager;
  late NormalizedDocumentLoader loader;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('xaocen_reader_ctrl');
    fileManager = LibraryFileManager(libraryRoot: tmp);
    loader = NormalizedDocumentLoader(fileManager: fileManager);
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

  ReaderController makeController(
    String collectionId, {
    String text = '第一章\n正文内容\n第二章\n更多内容\n',
  }) {
    final c = ReaderController(
      collectionId: collectionId,
      documentLoader: loader,
      progressRepository: progressRepo,
    );
    c.injectDocument(
      NormalizedDocument(
        text: text,
        normalizedHash: '',
        normalizationVersion: 'v1',
        parserVersion: '1',
        indexFormatVersion: '1',
        sourceFileName: 'test.txt',
      ),
    );
    return c;
  }

  group('ReaderController', () {
    test('injectDocument 后 ready', () {
      final c = makeController('c1');
      expect(c.state, ReaderState.ready);
      expect(c.blockIndex, isNotNull);
      c.dispose();
    });

    test('恢复前零写入（programmaticRestore）', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 10,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      expect(c.restoreWriteUnlocked, isFalse, reason: 'open 完成前不解冻写入');
      // 用户滚动在解冻前被忽略
      c.reportUserScroll(topVisibleCharacterOffset: 5);
      await Future.delayed(const Duration(milliseconds: 500));
      expect(
        await progressRepo.getProgress('c1'),
        isNull,
        reason: 'restore 完成前零写入',
      );
      c.dispose();
    });

    test('finishRestore 解冻并确认位置，仍零写入', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      final result = await c.finishRestore();
      expect(result, isNotNull);
      expect(c.restoreWriteUnlocked, isTrue);
      expect(c.confirmedLocator, isNotNull);
      // finishRestore 本身不写库
      expect(await progressRepo.getProgress('c1'), isNull);
      c.dispose();
    });

    test('用户滚动防抖 400ms 后保存', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      await c.finishRestore();
      // 用户滚动（解冻后）
      c.reportUserScroll(topVisibleCharacterOffset: 3);
      // 300ms 内不应写
      await Future.delayed(const Duration(milliseconds: 300));
      expect(await progressRepo.getProgress('c1'), isNull);
      // 400ms 后写
      await Future.delayed(const Duration(milliseconds: 200));
      final p = await progressRepo.getProgress('c1');
      expect(p, isNotNull);
      expect(p!.absoluteCharacterOffset, 3);
      c.dispose();
    });

    test('连续滚动只保存最后一次（防抖合并）', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      await c.finishRestore();
      c.reportUserScroll(topVisibleCharacterOffset: 1);
      await Future.delayed(const Duration(milliseconds: 100));
      c.reportUserScroll(topVisibleCharacterOffset: 2);
      await Future.delayed(const Duration(milliseconds: 100));
      c.reportUserScroll(topVisibleCharacterOffset: 5);
      await Future.delayed(const Duration(milliseconds: 500));
      final p = await progressRepo.getProgress('c1');
      expect(p!.absoluteCharacterOffset, 5);
      c.dispose();
    });

    test('flush 立即保存（scroll end / lifecycle）', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      await c.finishRestore();
      c.reportUserScroll(topVisibleCharacterOffset: 7);
      await c.flush(); // 立即 flush
      final p = await progressRepo.getProgress('c1');
      expect(p!.absoluteCharacterOffset, 7);
      c.dispose();
    });

    test('flush 在未解冻时零写入', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      await c.flush();
      expect(await progressRepo.getProgress('c1'), isNull);
      c.dispose();
    });

    test('jumpToOffset 设置 pendingTargetBlock 并保存（finishTocJump）', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 4,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      await c.finishRestore();
      await c.jumpToOffset(4, itemIdHint: 'chapter1');
      expect(c.pendingTargetBlock, isNotNull);
      expect(c.requestedLocator!.itemIdHint, 'chapter1');
      await c.finishTocJump();
      final p = await progressRepo.getProgress('c1');
      expect(p, isNotNull, reason: '目录跳转确认后立即保存');
      expect(p!.itemIdHint, 'chapter1');
      c.dispose();
    });

    test('open 带 initialLocator 时优先使用（不读库）', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await progressRepo.saveProgress(
        const ReaderProgressState(
          collectionId: 'c1',
          absoluteCharacterOffset: 9,
          readingMode: ReadingMode.vertical,
        ),
      );
      await c.open(
        initialLocator: const ReaderLocator(
          collectionId: 'c1',
          absoluteCharacterOffset: 2,
        ),
      );
      expect(c.requestedLocator!.absoluteCharacterOffset, 2);
      c.dispose();
    });

    test('open 无进度时从 0 开始', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      expect(c.requestedLocator!.absoluteCharacterOffset, 0);
      c.dispose();
    });

    test('事件边界：滚动 offset clamp 到 [0, len]', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      await c.finishRestore();
      c.reportUserScroll(topVisibleCharacterOffset: -5);
      await Future.delayed(const Duration(milliseconds: 500));
      expect(
        (await progressRepo.getProgress('c1'))!.absoluteCharacterOffset,
        0,
      );
      c.reportUserScroll(topVisibleCharacterOffset: 99999);
      await Future.delayed(const Duration(milliseconds: 500));
      // 文本 '第一章\n正文内容\n第二章\n更多内容\n' 的 UTF-16 长度 = 18
      expect(
        (await progressRepo.getProgress('c1'))!.absoluteCharacterOffset,
        18,
      );
      c.dispose();
    });

    test('dispose 取消防抖 timer 不崩溃', () async {
      final c = makeController('c1');
      c.visibleRangeProvider = () => ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 20,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
      await c.open();
      await c.finishRestore();
      c.reportUserScroll(topVisibleCharacterOffset: 3);
      c.dispose(); // 不 await，直接 dispose
      // 不抛异常即通过
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
