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

/// M3.2 目录展示测试（§十三）：完整标题 / 卷显示 / 当前章节高亮 / 无章节全文。
void main() {
  late Directory tmp;
  late LibraryFileManager fileManager;
  late NormalizedDocumentLoader loader;
  late AppDatabase db;
  late ReadingProgressRepository progressRepo;

  // 有卷有章的文本（多行，标题行是完整标题）
  const bookText =
      '第六卷 人间风雨\n第1章 百世书\n正文第一行内容。\n'
      '第2章 剥皮\n正文第二行内容。\n第3章 归途\n正文第三行内容。\n';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('xaocen_toc_display');
    fileManager = LibraryFileManager(libraryRoot: tmp);
    loader = NormalizedDocumentLoader(fileManager: fileManager);
    db = AppDatabase.forTesting();
    progressRepo = ReadingProgressRepository(db: db);
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
  });

  tearDown(() async {
    await db.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  ReaderLaunchContext launchContext({
    List<LibraryTocEntry>? toc,
    String? text,
  }) {
    final t = text ?? bookText;
    final tocEntries =
        toc ??
        [
          LibraryTocEntry(
            id: 'v1',
            collectionId: 'local-txt:abc',
            itemId: null,
            parentId: null,
            kind: 'volume',
            level: 1,
            title: '第六卷 人间风雨',
            displayTitle: '第六卷 人间风雨',
            orderIndex: 1,
            startCharacterOffset: 0,
            endCharacterOffset: t.length,
          ),
          LibraryTocEntry(
            id: 'c1',
            collectionId: 'local-txt:abc',
            itemId: 'local-txt:abc:chapter:0',
            parentId: 'v1',
            kind: 'chapter',
            level: 2,
            title: '第1章 百世书',
            displayTitle: '第1章 百世书',
            orderIndex: 1,
            startCharacterOffset: 7,
            endCharacterOffset: 20,
          ),
          LibraryTocEntry(
            id: 'c2',
            collectionId: 'local-txt:abc',
            itemId: 'local-txt:abc:chapter:1',
            parentId: 'v1',
            kind: 'chapter',
            level: 2,
            title: '第2章 剥皮',
            displayTitle: '第2章 剥皮',
            orderIndex: 2,
            startCharacterOffset: 20,
            endCharacterOffset: 33,
          ),
          LibraryTocEntry(
            id: 'c3',
            collectionId: 'local-txt:abc',
            itemId: 'local-txt:abc:chapter:2',
            parentId: 'v1',
            kind: 'chapter',
            level: 2,
            title: '第3章 归途',
            displayTitle: '第3章 归途',
            orderIndex: 3,
            startCharacterOffset: 33,
            endCharacterOffset: t.length,
          ),
        ];
    return ReaderLaunchContext(
      collection: LibraryCollection(
        id: 'local-txt:abc',
        sourceId: 'local-txt-source:abc',
        title: '测试书籍',
        subtitle: null,
        itemCount: 3,
        normalizedCharacterLength: t.length,
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
          endCharacterOffset: t.length,
          contentHash: '',
          normalizationVersion: 'v1',
        ),
      ],
      toc: tocEntries,
      normalizedCharacterLength: t.length,
      documentLoader: loader,
      progressRepository: progressRepo,
    );
  }

  Future<void> pumpReader(
    WidgetTester tester, {
    List<LibraryTocEntry>? toc,
    String? text,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPage(
          launch: launchContext(toc: toc, text: text),
          documentOverride: NormalizedDocument(
            text: text ?? bookText,
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
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('M3.2 目录展示', () {
    testWidgets('1. 目录显示完整标题（含具体名称）', (tester) async {
      await pumpReader(tester);
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      // 完整标题而非「第1章」短标题
      expect(find.text('第1章 百世书'), findsOneWidget);
      expect(find.text('第2章 剥皮'), findsOneWidget);
      expect(find.text('第3章 归途'), findsOneWidget);
      expect(find.text('第1章'), findsNothing, reason: '不得显示短标题');
    });

    testWidgets('2. 卷标题完整显示', (tester) async {
      await pumpReader(tester);
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      expect(find.text('第六卷 人间风雨'), findsOneWidget);
      expect(find.text('第六卷'), findsNothing, reason: '卷标题必须完整');
    });

    testWidgets('3. 无章节文件目录只显示「全文」', (tester) async {
      const noChaptersText = '这是一段没有章节的正文内容，只有一段话。\n第二段。\n';
      await pumpReader(
        tester,
        toc: [
          LibraryTocEntry(
            id: 'whole',
            collectionId: 'local-txt:abc',
            itemId: null,
            parentId: null,
            kind: 'whole',
            level: 1,
            title: '全文',
            displayTitle: '全文',
            orderIndex: 0,
            startCharacterOffset: 0,
            endCharacterOffset: noChaptersText.length,
          ),
        ],
        text: noChaptersText,
      );
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      expect(find.text('全文'), findsWidgets);
      expect(find.textContaining('第1章'), findsNothing, reason: '不得伪造章节');
    });

    testWidgets('4. 点击目录章节后保存进度', (tester) async {
      await pumpReader(tester);
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('第2章 剥皮'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      final p = await progressRepo.getProgress('local-txt:abc');
      expect(p, isNotNull, reason: '目录跳转确认后应保存');
    });
  });
}
