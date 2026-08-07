import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/reader_page.dart';

/// M3.3 目录打开时定位当前章节（§十 Widget）。
///
/// fixture：3 卷 × 每卷 200 章 = 600 章，总文本足够大让目录可滚动。
void main() {
  late Directory tmp;
  late LibraryFileManager fileManager;
  late NormalizedDocumentLoader loader;
  late AppDatabase db;
  late ReadingProgressRepository progressRepo;

  const volumeCount = 3;
  const chaptersPerVolume = 200;
  const totalChapters = volumeCount * chaptersPerVolume;

  // 每章标题 + 两行正文；总长 ~30k 字符
  late final String bookText;
  late final List<LibraryTocEntry> tocEntries;
  late final Map<int, int> chapterOffsetOf; // chapterNo -> start offset

  setUpAll(() {
    db = AppDatabase.forTesting();
    final sb = StringBuffer();
    final toc = <LibraryTocEntry>[];
    final offsets = <int, int>{};
    var offset = 0;
    var order = 0;
    for (var v = 1; v <= volumeCount; v++) {
      final vid = 'v$v';
      final vStart = offset;
      final vTitle = '第$v卷 卷$v 标题';
      sb.write('$vTitle\n');
      toc.add(
        LibraryTocEntry(
          id: vid,
          collectionId: 'local-txt:abc',
          itemId: null,
          parentId: null,
          kind: 'volume',
          level: 1,
          title: vTitle,
          displayTitle: vTitle,
          orderIndex: v,
          startCharacterOffset: vStart,
          endCharacterOffset: 0,
        ),
      );
      offset += '$vTitle\n'.length;
      for (var c = 1; c <= chaptersPerVolume; c++) {
        final no = (v - 1) * chaptersPerVolume + c;
        final title = '第$no章 章节$no';
        offsets[no] = offset;
        sb.write('$title\n');
        sb.write('这是第$no章的正文内容，包含一些汉字和标点符号。\n');
        sb.write('第二行正文，保证块内多行。\n');
        final end = offset + title.length + 1 + 30 + 1 + 12 + 1;
        toc.add(
          LibraryTocEntry(
            id: 'c$no',
            collectionId: 'local-txt:abc',
            itemId: 'local-txt:abc:chapter:$no',
            parentId: vid,
            kind: 'chapter',
            level: 2,
            title: title,
            displayTitle: title,
            orderIndex: ++order,
            startCharacterOffset: offset,
            endCharacterOffset: end,
          ),
        );
        offset = end;
      }
    }
    bookText = sb.toString();
    tocEntries = toc;
    chapterOffsetOf = offsets;
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('xaocen_toc_scroll');
    fileManager = LibraryFileManager(libraryRoot: tmp);
    loader = NormalizedDocumentLoader(fileManager: fileManager);
    progressRepo = ReadingProgressRepository(db: db);
    final now = DateTime.now();
    await db
        .into(db.contentSources)
        .insertOnConflictUpdate(
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
        .insertOnConflictUpdate(
          ContentCollectionsCompanion.insert(
            id: 'local-txt:abc',
            sourceId: 'local-txt-source:abc',
            title: '测试书籍',
            itemCount: totalChapters,
            normalizedCharacterLength: bookText.length,
            importedAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  tearDownAll(() async {
    await db.close();
  });

  ReaderLaunchContext launchContext({int progressOffset = 0}) {
    return ReaderLaunchContext(
      collection: LibraryCollection(
        id: 'local-txt:abc',
        sourceId: 'local-txt-source:abc',
        title: '测试书籍',
        subtitle: null,
        itemCount: totalChapters,
        normalizedCharacterLength: bookText.length,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 2048,
        importedAt: DateTime.now(),
      ),
      documents: [
        LibraryDocument(
          id: 'local-txt:abc:document:0',
          itemId: 'local-txt:abc:chapter:1',
          storagePath: 'library/local_txt/abc/normalized.txt',
          mediaType: 'text/plain',
          startCharacterOffset: 0,
          endCharacterOffset: bookText.length,
          contentHash: '',
          normalizationVersion: 'v1',
        ),
      ],
      toc: tocEntries,
      normalizedCharacterLength: bookText.length,
      documentLoader: loader,
      progressRepository: progressRepo,
    );
  }

  /// 打开 Reader 并恢复到指定章节。
  Future<void> pumpReader(WidgetTester tester, int chapterNo) async {
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
          progressOverride: ReaderLocator(
            collectionId: 'local-txt:abc',
            absoluteCharacterOffset: chapterOffsetOf[chapterNo]!,
          ),
        ),
      ),
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // 跑完两阶段恢复对齐链（post-frame 链）
    await tester.pumpAndSettle();
  }

  Future<void> openToc(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.list));
    await tester.pumpAndSettle();
    // 等两阶段定位完成（post-frame × 2）
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  void closeToc(WidgetTester tester) {
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  }

  /// 目标章节 tile 是否在目录视口内。
  bool tileVisible(WidgetTester tester, String title) {
    final finder = find.text(title);
    if (finder.evaluate().isEmpty) return false;
    final box = tester.renderObject<RenderBox>(finder.first);
    final topLeft = box.localToGlobal(Offset.zero);
    final bottomRight = box.localToGlobal(
      Offset(box.size.width, box.size.height),
    );
    final screenH = tester.getSize(find.byType(MaterialApp)).height;
    final sheetTop = screenH * 0.4;
    return bottomRight.dy > sheetTop && topLeft.dy < screenH;
  }

  /// 目标行顶部在目录视口中的相对位置（0~1，期望 ~0.35）。
  double tileAlignmentInViewport(WidgetTester tester, String title) {
    final finder = find.text(title);
    final box = tester.renderObject<RenderBox>(finder.first);
    final top = box.localToGlobal(Offset.zero).dy;
    final screenH = tester.getSize(find.byType(MaterialApp)).height;
    final sheetTop = screenH * 0.4;
    return (top - sheetTop) / (screenH - sheetTop);
  }

  group('M3.3 目录自动定位', () {
    testWidgets('1. 阅读第1章打开目录：第1章可见且高亮', (tester) async {
      await pumpReader(tester, 1);
      await openToc(tester);
      expect(find.text('第1章 章节1'), findsOneWidget, reason: '第1章应在目录中');
      expect(tileVisible(tester, '第1章 章节1'), isTrue, reason: '第1章应可见');
      final tile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('第1章 章节1'),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.selected, isTrue, reason: '第1章应高亮');
    });

    testWidgets('2. 阅读第258章打开目录：自动滚到第258章', (tester) async {
      await pumpReader(tester, 258);
      await openToc(tester);
      expect(find.text('第258章 章节258'), findsOneWidget);
      expect(
        tileVisible(tester, '第258章 章节258'),
        isTrue,
        reason: '打开目录后当前章节应立即可见，无需手动滚动',
      );
    });

    testWidgets('3. 阅读第473章打开目录：自动滚到第473章', (tester) async {
      await pumpReader(tester, 473);
      await openToc(tester);
      expect(tileVisible(tester, '第473章 章节473'), isTrue);
    });

    testWidgets('4. 当前章节属于折叠卷时父卷自动展开', (tester) async {
      await pumpReader(tester, 450); // 第3卷
      await openToc(tester);
      expect(find.text('第450章 章节450'), findsOneWidget);
      expect(tileVisible(tester, '第450章 章节450'), isTrue);
      // 定位在 450 章（第3卷）时卷3标题在视口上方，先用户滚动到卷3标题
      await tester.drag(find.byType(ListView).last, const Offset(0, 2551));
      await tester.pumpAndSettle();
      expect(find.text('第3卷 卷3 标题'), findsOneWidget);
      // 折叠第3卷后其章节消失
      await tester.tap(find.text('第3卷 卷3 标题'));
      await tester.pumpAndSettle();
      expect(find.text('第450章 章节450'), findsNothing);
      // 点击「定位当前章节」→ 父卷重新展开 + 定位
      await tester.tap(find.text('定位当前章节'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('第450章 章节450'), findsOneWidget);
    });

    testWidgets('5. 打开后高亮项可见（自动定位生效）', (tester) async {
      await pumpReader(tester, 400);
      await openToc(tester);
      expect(tileVisible(tester, '第400章 章节400'), isTrue);
    });

    testWidgets('6. 高亮项位于视口约 30%~40% 区域', (tester) async {
      await pumpReader(tester, 300);
      await openToc(tester);
      final alignment = tileAlignmentInViewport(tester, '第300章 章节300');
      expect(
        alignment,
        inInclusiveRange(0.20, 0.55),
        reason: '高亮项应在视口上部 30~40% 附近，实际 $alignment',
      );
    });

    testWidgets('7. 用户手动滚动目录后不被自动拉回', (tester) async {
      await pumpReader(tester, 300);
      await openToc(tester);
      expect(tileVisible(tester, '第300章 章节300'), isTrue);
      // 用户向上滚动目录到前段（大距离确保到顶）
      await tester.drag(find.byType(ListView).last, const Offset(0, 30000));
      await tester.pumpAndSettle();
      // 记录滚动后的位置：第1章可见
      expect(find.text('第1章 章节1'), findsOneWidget, reason: '滚动后第1章应在视口');
      // 再等一会：不得自动拉回第300章
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('第1章 章节1'), findsOneWidget, reason: '未被自动拉回');
      expect(tileVisible(tester, '第1章 章节1'), isTrue);
    });

    testWidgets('8. 关闭再打开时重新定位当前章节', (tester) async {
      await pumpReader(tester, 300);
      await openToc(tester);
      expect(tileVisible(tester, '第300章 章节300'), isTrue);
      closeToc(tester);
      await tester.pumpAndSettle();
      // 重新打开 → 再次定位
      await openToc(tester);
      expect(tileVisible(tester, '第300章 章节300'), isTrue);
    });

    testWidgets('9. 正文滚动到新章节后再次打开定位新章节', (tester) async {
      await pumpReader(tester, 100);
      await openToc(tester);
      expect(tileVisible(tester, '第100章 章节100'), isTrue);
      closeToc(tester);
      await tester.pumpAndSettle();
      // 正文滚到后面（drag 正文 SuperListView：~200 章处）
      await tester.drag(find.byType(SuperListView), const Offset(0, -11500));
      await tester.pumpAndSettle();
      await openToc(tester);
      // 新当前章节（drag 后）应被高亮且可见
      final selectedFinder = find.byWidgetPredicate(
        (w) => w is ListTile && w.selected == true,
      );
      expect(selectedFinder, findsWidgets, reason: '应有高亮当前章节');
      final selTile = tester.widget<ListTile>(selectedFinder.first);
      final titleText = (selTile.title as Text?)?.data ?? '';
      expect(titleText, isNotEmpty);
      expect(titleText != '第100章 章节100', isTrue, reason: '正文滚动后当前章节应已变化');
      expect(
        tileVisible(tester, titleText),
        isTrue,
        reason: '高亮当前章节应可见（自动定位生效）',
      );
    });

    testWidgets('10. 无章节显示并定位「全文」', (tester) async {
      const noChaptersText = '无章节正文，只有一段话。\n第二段。\n';
      await tester.pumpWidget(
        MaterialApp(
          home: ReaderPage(
            launch: ReaderLaunchContext(
              collection: LibraryCollection(
                id: 'local-txt:abc',
                sourceId: 'local-txt-source:abc',
                title: '测试书籍',
                subtitle: null,
                itemCount: 0,
                normalizedCharacterLength: noChaptersText.length,
                detectedEncoding: TextEncoding.utf8,
                sourceSize: 2048,
                importedAt: DateTime.now(),
              ),
              documents: [
                LibraryDocument(
                  id: 'local-txt:abc:document:0',
                  itemId: 'local-txt:abc:whole',
                  storagePath: 'library/local_txt/abc/normalized.txt',
                  mediaType: 'text/plain',
                  startCharacterOffset: 0,
                  endCharacterOffset: noChaptersText.length,
                  contentHash: '',
                  normalizationVersion: 'v1',
                ),
              ],
              toc: [
                LibraryTocEntry(
                  id: 'whole',
                  collectionId: 'local-txt:abc',
                  itemId: null,
                  parentId: null,
                  kind: 'chapter',
                  level: 1,
                  title: '全文',
                  displayTitle: '全文',
                  orderIndex: 0,
                  startCharacterOffset: 0,
                  endCharacterOffset: noChaptersText.length,
                ),
              ],
              normalizedCharacterLength: noChaptersText.length,
              documentLoader: loader,
              progressRepository: progressRepo,
            ),
            documentOverride: NormalizedDocument(
              text: noChaptersText,
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
      await openToc(tester);
      expect(find.text('全文'), findsWidgets);
      expect(find.textContaining('第1章'), findsNothing);
    });

    testWidgets('11. dispose 后无残留 callback', (tester) async {
      await pumpReader(tester, 300);
      await openToc(tester);
      closeToc(tester);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. 快速开关目录没有异常', (tester) async {
      await pumpReader(tester, 300);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byIcon(Icons.list));
        await tester.pump(const Duration(milliseconds: 80));
        if (find.byType(Navigator).evaluate().isNotEmpty) {
          tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        }
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
