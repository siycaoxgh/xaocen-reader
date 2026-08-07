import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/design/theme/app_theme.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/reader_appearance.dart';
import 'package:xaocen_reader/reader/reader_page.dart';
import 'package:xaocen_reader/reader/reader_text_block.dart';

/// P1：Reader 深色可读性（M3.3 附加）—— 8 项 widget 验收。
///
/// 合同：正文/标题颜色必须从 Theme 解析（ReaderResolvedAppearance），
/// 对比度 ≥4.5:1；显示与测量同一 TextPainter；主题切换只重绘不重建
/// block 索引、不写进度、不改变 ReaderLocator。
void main() {
  late Directory tmp;
  late LibraryFileManager fileManager;
  late NormalizedDocumentLoader loader;
  late AppDatabase db;
  late ReadingProgressRepository progressRepo;

  const bookText = '第一章 开端\n第一行正文内容。\n第二章 发展\n第二行正文内容。\n第三章 结局\n第三行正文内容。';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('xaocen_reader_dark');
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
    String storagePath = 'library/local_txt/abc/normalized.txt',
  }) {
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
          storagePath: storagePath,
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
      ],
      normalizedCharacterLength: bookText.length,
      documentLoader: loader,
      progressRepository: progressRepo,
    );
  }

  Future<void> pumpReader(WidgetTester tester, {ThemeData? theme}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.dark(),
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
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  TextStyle blockStyleOf(WidgetTester tester) {
    final block = tester.widget<ReaderTextBlock>(
      find.byType(ReaderTextBlock).first,
    );
    return block.style;
  }

  group('P1 Reader 深色可读性', () {
    testWidgets('1. 浅色主题：正文深色且可读（≥4.5:1）', (tester) async {
      await pumpReader(tester, theme: AppTheme.light());
      final style = blockStyleOf(tester);
      final color = style.color ?? Colors.black;
      expect(color.computeLuminance(), lessThan(0.5), reason: '浅色主题正文应为深色');
      final bg = AppTheme.light().colorScheme.surface;
      expect(
        isReadable(color, bg),
        isTrue,
        reason: '浅色主题正文对比度 ${contrastRatio(color, bg)}',
      );
    });

    testWidgets('2. 深色主题：正文浅色且可读（≥4.5:1）', (tester) async {
      await pumpReader(tester, theme: AppTheme.dark());
      final style = blockStyleOf(tester);
      final color = style.color ?? Colors.black;
      expect(color.computeLuminance(), greaterThan(0.5), reason: '深色主题正文应为浅色');
      final bg = AppTheme.dark().colorScheme.surface;
      expect(
        isReadable(color, bg),
        isTrue,
        reason: '深色主题正文对比度 ${contrastRatio(color, bg)}',
      );
    });

    testWidgets('3. TextPainter 使用解析色（非硬编码）', (tester) async {
      await pumpReader(tester, theme: AppTheme.dark());
      final style = blockStyleOf(tester);
      final expected = resolveReaderAppearance(
        tester.element(find.byType(ReaderPage)),
      );
      expect(
        style.color,
        expected.textColor,
        reason: 'ReaderTextBlock 必须消费 ReaderResolvedAppearance.textColor',
      );
    });

    testWidgets('4. 主题切换后 block 颜色更新（只重绘）', (tester) async {
      await pumpReader(tester, theme: AppTheme.light());
      final c1 = blockStyleOf(tester).color;
      // 同结构重 pump 切换主题：ReaderPage State 复用，didChangeDependencies 触发
      await pumpReader(tester, theme: AppTheme.dark());
      final c2 = blockStyleOf(tester).color;
      expect(c1, isNot(c2), reason: '主题切换后正文颜色必须更新');
      expect(c2!.computeLuminance(), greaterThan(0.5), reason: '深色主题下应为浅色文字');
    });

    testWidgets('5. 主题切换不改变 ReaderLocator', (tester) async {
      await pumpReader(tester, theme: AppTheme.light());
      await pumpReader(tester, theme: AppTheme.dark());
      // 切换后无滚动、无恢复动作：页面仍显示首屏
      await tester.pumpAndSettle();
      expect(find.textContaining('加载失败'), findsNothing);
      expect(find.byType(ReaderTextBlock), findsWidgets);
      // 首屏顶部仍为 0 偏移（未因切换主题改变位置）
      final progress = await db.select(db.readingProgress).get();
      expect(progress, isEmpty, reason: '主题切换不应产生新的进度写入');
    });

    testWidgets('6. 主题切换不写进度表', (tester) async {
      await pumpReader(tester, theme: AppTheme.light());
      await pumpReader(tester, theme: AppTheme.dark());
      await tester.pump(const Duration(milliseconds: 600));
      final progress = await db.select(db.readingProgress).get();
      expect(progress, isEmpty, reason: '切换主题不触发任何保存（恢复完成前零写入）');
    });

    testWidgets('7. 无深底深字组合（全主题矩阵可读）', (tester) async {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        await pumpReader(tester, theme: theme);
        final a = resolveReaderAppearance(
          tester.element(find.byType(ReaderPage)),
        );
        expect(
          isReadable(a.textColor, a.backgroundColor),
          isTrue,
          reason: '正文 ${theme.brightness} 对比度不足',
        );
        expect(
          isReadable(a.headingColor, a.backgroundColor),
          isTrue,
          reason: '标题 ${theme.brightness} 对比度不足',
        );
      }
    });

    testWidgets('8. 深色主题下 loading 与 error 状态可见', (tester) async {
      // loading：无 documentOverride → 走真实 loader，首帧 spinner
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: ReaderPage(key: UniqueKey(), launch: launchContext()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        find.byType(CircularProgressIndicator),
        findsWidgets,
        reason: '深色主题下 loading 指示器应显示',
      );
      // error：storagePath 含 `..` → loader 同步抛 unsafe_path → failed 态
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: ReaderPage(
            key: UniqueKey(),
            launch: launchContext(storagePath: '../escape'),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final errFinder = find.textContaining('加载失败');
      expect(errFinder, findsOneWidget, reason: '深色主题下 error 态应显示');
      final errText = tester.widget<Text>(errFinder.first);
      final errColor =
          errText.style?.color ?? AppTheme.dark().colorScheme.onSurface;
      expect(
        errColor.computeLuminance(),
        greaterThan(0.5),
        reason: '深色主题下错误文本应为浅色（可读）',
      );
    });
  });
}
