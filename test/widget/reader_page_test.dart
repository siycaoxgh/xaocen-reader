import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/reader_page.dart';
import 'package:xaocen_reader/reader/reader_text_block.dart';

/// M3 Reader Widget 测试 —— 最小 UI 行为。
void main() {
  late Directory tmp;
  late LibraryFileManager fileManager;
  late NormalizedDocumentLoader loader;
  late AppDatabase db;
  late ReadingProgressRepository progressRepo;

  const bookText = '第一章 开端\n第一行正文内容。\n第二章 发展\n第二行正文内容。\n第三章 结局\n第三行正文内容。';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('xaocen_reader_widget');
    fileManager = LibraryFileManager(libraryRoot: tmp);
    loader = NormalizedDocumentLoader(fileManager: fileManager);
    db = AppDatabase.forTesting();
    progressRepo = ReadingProgressRepository(db: db);
    // seed collection（reading_progress 外键依赖）
    final now = DateTime.now();
    await db
        .into(db.contentSources)
        .insert(
          ContentSourcesCompanion.insert(
            id: 'local-txt-source:abc',
            type: 'localTxt',
            displayName: '测试书籍',
            contentHash: 'abc',
            managedSourcePath: 'library/local_txt/abc/source.txt',
            sourceSize: 2048,
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
            itemCount: 3,
            normalizedCharacterLength: bookText.length,
            importedAt: now,
            updatedAt: now,
          ),
        );
    // 写 normalized.txt + manifest
    final contentDir = Directory('${tmp.path}/library/local_txt/abc');
    await contentDir.create(recursive: true);
    await File(
      '${contentDir.path}/normalized.txt',
    ).writeAsString(bookText, flush: true);
  });

  tearDown(() async {
    await db.close();
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  ReaderLaunchContext launchContext() {
    return ReaderLaunchContext(
      collection: LibraryCollection(
        id: 'local-txt:abc',
        sourceId: 'local-txt-source:abc',
        title: '测试书籍',
        subtitle: null,
        itemCount: 3,
        normalizedCharacterLength: bookText.length,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 2048,
        importedAt: DateTime.now(),
      ),
      documents: [
        LibraryDocument(
          id: 'local-txt:abc:document:0',
          itemId: 'local-txt:abc:chapter:0',
          storagePath: 'library/local_txt/abc/normalized.txt',
          mediaType: 'text/plain',
          startCharacterOffset: 0,
          endCharacterOffset: bookText.length,
          contentHash: '',
          normalizationVersion: 'v1',
        ),
      ],
      toc: [
        LibraryTocEntry(
          id: 't1',
          collectionId: 'local-txt:abc',
          itemId: 'local-txt:abc:chapter:0',
          parentId: null,
          kind: 'chapter',
          level: 1,
          title: '第一章 开端',
          orderIndex: 0,
          startCharacterOffset: 0,
          endCharacterOffset: 8,
        ),
        LibraryTocEntry(
          id: 't2',
          collectionId: 'local-txt:abc',
          itemId: 'local-txt:abc:chapter:1',
          parentId: null,
          kind: 'chapter',
          level: 1,
          title: '第二章 发展',
          orderIndex: 1,
          startCharacterOffset: 9,
          endCharacterOffset: 18,
        ),
      ],
      normalizedCharacterLength: bookText.length,
      documentLoader: loader,
      progressRepository: progressRepo,
    );
  }

  Future<void> pumpReader(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPage(
          launch: launchContext(),
          documentOverride: NormalizedDocument(
            text: bookText,
            normalizedHash: '',
            normalizationVersion: 'v1',
            parserVersion: '1',
            indexFormatVersion: '1',
            sourceFileName: 'test.txt',
          ),
          progressOverride: const ReaderLocator(
            collectionId: 'local-txt:abc',
            absoluteCharacterOffset: 0,
          ),
        ),
      ),
    );
    // open() 是异步：多次 pump 推进微任务与帧
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('ReaderPage Widget', () {
    testWidgets('打开后显示书名与正文', (tester) async {
      await pumpReader(tester);
      expect(find.text('测试书籍'), findsWidgets); // AppBar 标题
      // 正文以 RenderObject 渲染（ReaderTextBlock），验证 block widget 存在
      expect(find.byType(ReaderTextBlock), findsWidgets);
      // 至少一个 block 已布局完成
      final ro = tester.renderObjectList<RenderReaderTextBlock>(
        find.byType(ReaderTextBlock),
      );
      expect(ro, isNotEmpty);
    });

    testWidgets('恢复完成前零写入（打开后 DB 无进度）', (tester) async {
      await pumpReader(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        await progressRepo.getProgress('local-txt:abc'),
        isNull,
        reason: '恢复完成前不应写进度',
      );
    });

    testWidgets('返回按钮 pop', (tester) async {
      await pumpReader(tester);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      // pop 后页面消失（Navigator 栈空）
      expect(find.byType(ReaderPage), findsNothing);
    });

    testWidgets('目录按钮打开目录抽屉', (tester) async {
      await pumpReader(tester);
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      // 目录抽屉出现章节
      expect(find.text('目录 — 测试书籍'), findsOneWidget);
      expect(find.text('第二章 发展'), findsWidgets);
    });

    testWidgets('目录跳转：点击第二章后滚动', (tester) async {
      await pumpReader(tester);
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('第二章 发展'));
      await tester.pumpAndSettle();
      // 跳转后保存（finishTocJump）
      await tester.pump(const Duration(milliseconds: 200));
      final p = await progressRepo.getProgress('local-txt:abc');
      expect(p, isNotNull, reason: '目录跳转确认后保存');
    });

    testWidgets('dispose 无异常', (tester) async {
      await pumpReader(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
