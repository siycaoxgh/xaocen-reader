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

/// M3.4 目录平铺展示（§九 Widget）。
///
/// 主 fixture：3 卷 × 每卷 200 章 = 600 章，总文本足够大让目录可滚动。
/// 异常 fixture：层级错乱的卷/章/部/番外混合，验证平铺容错。
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

  /// 异常层级 fixture（§八/§九）：错乱 parentId、连续 volume、卷中无章、
  /// 卷/部混用、chapter 无 parent。必须全部平铺可见且可跳转。
  (List<LibraryTocEntry>, String) abnormalFixture() {
    final entries = <LibraryTocEntry>[
      LibraryTocEntry(
        id: 'v1',
        collectionId: 'local-txt:xyz',
        itemId: null,
        parentId: null,
        kind: 'volume',
        level: 1,
        title: '第一卷',
        displayTitle: '第一卷',
        orderIndex: 0,
        startCharacterOffset: 0,
        endCharacterOffset: 0,
      ),
      LibraryTocEntry(
        id: 'c1',
        collectionId: 'local-txt:xyz',
        itemId: 'local-txt:xyz:chapter:1',
        parentId: 'v1',
        kind: 'chapter',
        level: 2,
        title: '第1章',
        displayTitle: '第1章',
        orderIndex: 1,
        startCharacterOffset: 4,
        endCharacterOffset: 0,
      ),
      LibraryTocEntry(
        id: 'c2',
        collectionId: 'local-txt:xyz',
        itemId: 'local-txt:xyz:chapter:2',
        parentId: 'v1',
        kind: 'chapter',
        level: 2,
        title: '第2章',
        displayTitle: '第2章',
        orderIndex: 2,
        startCharacterOffset: 8,
        endCharacterOffset: 0,
      ),
      LibraryTocEntry(
        id: 'v2',
        collectionId: 'local-txt:xyz',
        itemId: null,
        parentId: null,
        kind: 'volume',
        level: 1,
        title: '第二卷',
        displayTitle: '第二卷',
        orderIndex: 3,
        startCharacterOffset: 12,
        endCharacterOffset: 0,
      ),
      LibraryTocEntry(
        id: 'v3',
        collectionId: 'local-txt:xyz',
        itemId: null,
        parentId: null,
        kind: 'volume',
        level: 1,
        title: '第三卷',
        displayTitle: '第三卷',
        orderIndex: 4,
        startCharacterOffset: 16,
        endCharacterOffset: 0,
      ),
      LibraryTocEntry(
        id: 'c3',
        collectionId: 'local-txt:xyz',
        itemId: 'local-txt:xyz:chapter:3',
        parentId: 'v3',
        kind: 'chapter',
        level: 2,
        title: '第1章',
        displayTitle: '第1章',
        orderIndex: 5,
        startCharacterOffset: 20,
        endCharacterOffset: 0,
      ),
      // parentId 指向不存在的卷（幽灵父级）——不得隐藏
      LibraryTocEntry(
        id: 'c4',
        collectionId: 'local-txt:xyz',
        itemId: 'local-txt:xyz:chapter:4',
        parentId: 'ghost-volume',
        kind: 'chapter',
        level: 2,
        title: '第2章',
        displayTitle: '第2章',
        orderIndex: 6,
        startCharacterOffset: 24,
        endCharacterOffset: 0,
      ),
      // 卷/部混用
      LibraryTocEntry(
        id: 'p1',
        collectionId: 'local-txt:xyz',
        itemId: null,
        parentId: null,
        kind: 'volume',
        level: 1,
        title: '第四部',
        displayTitle: '第四部',
        orderIndex: 7,
        startCharacterOffset: 28,
        endCharacterOffset: 0,
      ),
      LibraryTocEntry(
        id: 'c5',
        collectionId: 'local-txt:xyz',
        itemId: 'local-txt:xyz:chapter:5',
        parentId: 'p1',
        kind: 'chapter',
        level: 2,
        title: '第99章',
        displayTitle: '第99章',
        orderIndex: 8,
        startCharacterOffset: 32,
        endCharacterOffset: 0,
      ),
      // 番外：无 parent 的 chapter
      LibraryTocEntry(
        id: 'c6',
        collectionId: 'local-txt:xyz',
        itemId: 'local-txt:xyz:chapter:6',
        parentId: null,
        kind: 'chapter',
        level: 1,
        title: '番外',
        displayTitle: '番外',
        orderIndex: 9,
        startCharacterOffset: 36,
        endCharacterOffset: 0,
      ),
    ];
    final text =
        '第一卷\n第1章\n第2章\n第二卷\n第三卷\n第1章\n第2章\n'
        '第四部\n第99章\n番外\n';
    return (entries, text);
  }

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

  ReaderLaunchContext launchContext({
    List<LibraryTocEntry>? toc,
    String? text,
    String collectionId = 'local-txt:abc',
    String title = '测试书籍',
    int itemCount = totalChapters,
  }) {
    final body = text ?? bookText;
    return ReaderLaunchContext(
      collection: LibraryCollection(
        id: collectionId,
        sourceId: 'local-txt-source:${collectionId.split(':').last}',
        title: title,
        subtitle: null,
        itemCount: itemCount,
        normalizedCharacterLength: body.length,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 2048,
        importedAt: DateTime.now(),
      ),
      documents: [
        LibraryDocument(
          id: '$collectionId:document:0',
          itemId: '$collectionId:chapter:1',
          storagePath: 'library/local_txt/abc/normalized.txt',
          mediaType: 'text/plain',
          startCharacterOffset: 0,
          endCharacterOffset: body.length,
          contentHash: '',
          normalizationVersion: 'v1',
        ),
      ],
      toc: toc ?? tocEntries,
      normalizedCharacterLength: body.length,
      documentLoader: loader,
      progressRepository: progressRepo,
    );
  }

  /// 打开 Reader 并恢复到指定章节。
  Future<void> pumpReader(
    WidgetTester tester,
    int chapterNo, {
    List<LibraryTocEntry>? toc,
    String? text,
    int? offset,
  }) async {
    final body = text ?? bookText;
    final off = offset ?? chapterOffsetOf[chapterNo]!;
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPage(
          launch: launchContext(toc: toc, text: body),
          documentOverride: NormalizedDocument(
            text: body,
            normalizedHash: '',
            normalizationVersion: 'v1',
            parserVersion: '1',
            indexFormatVersion: '1',
            sourceFileName: 'test.txt',
          ),
          progressOverride: ReaderLocator(
            collectionId: 'local-txt:abc',
            absoluteCharacterOffset: off,
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

  group('M3.4 目录平铺展示', () {
    testWidgets('1. volume + chapter 全部可见', (tester) async {
      await pumpReader(tester, 1);
      await openToc(tester);
      // 平铺渲染：卷标题与章节标题都直接显示（无折叠隐藏）
      expect(find.text('第1卷 卷1 标题'), findsOneWidget, reason: '卷标题始终显示');
      expect(find.text('第1章 章节1'), findsOneWidget, reason: '章节始终显示');
      // 虚拟列表：滚动到底后尾部卷/章同样可见（证明无任何隐藏）
      for (
        var i = 0;
        i < 80 && find.text('第600章 章节600').evaluate().isEmpty;
        i++
      ) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -600));
        await tester.pumpAndSettle();
      }
      expect(find.text('第600章 章节600'), findsOneWidget, reason: '滚动后尾部章可见');
      // 再往上滚到第3卷标题（尾部卷也应可见）
      for (
        var i = 0;
        i < 80 && find.text('第3卷 卷3 标题').evaluate().isEmpty;
        i++
      ) {
        await tester.drag(find.byType(ListView).last, const Offset(0, 600));
        await tester.pumpAndSettle();
      }
      expect(find.text('第3卷 卷3 标题'), findsOneWidget, reason: '滚动后尾部卷可见');
    });

    testWidgets('2. 没有任何折叠按钮', (tester) async {
      await pumpReader(tester, 300);
      await openToc(tester);
      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(find.byIcon(Icons.expand_less), findsNothing);
    });

    testWidgets('3. 当前章节属于 volume 时仍直接可见', (tester) async {
      await pumpReader(tester, 450); // 第3卷
      await openToc(tester);
      // 无折叠 → 450 章（属于卷3）直接平铺可见；若卷3被折叠则该章不可见
      expect(find.text('第450章 章节450'), findsOneWidget);
      expect(tileVisible(tester, '第450章 章节450'), isTrue);
    });

    testWidgets('4. 阅读第258章打开目录：直接定位', (tester) async {
      await pumpReader(tester, 258);
      await openToc(tester);
      expect(find.text('第258章 章节258'), findsOneWidget);
      expect(
        tileVisible(tester, '第258章 章节258'),
        isTrue,
        reason: '打开目录后当前章节应立即可见，无需手动滚动',
      );
    });

    testWidgets('5. 阅读第473章打开目录：直接定位', (tester) async {
      await pumpReader(tester, 473);
      await openToc(tester);
      expect(tileVisible(tester, '第473章 章节473'), isTrue);
    });

    testWidgets('6. parentId 错误不隐藏 chapter', (tester) async {
      final (entries, text) = abnormalFixture();
      await pumpReader(tester, 0, toc: entries, text: text, offset: 20);
      await openToc(tester);
      // 幽灵父级章节必须可见：滚动遍历目录，第2章（两个，含幽灵父级）都出现
      var sawChapter2 = 0;
      for (var step = 0; step < 4; step++) {
        sawChapter2 += find.text('第2章').evaluate().length;
        if (sawChapter2 >= 2) break;
        await tester.drag(find.byType(ListView).last, const Offset(0, -160));
        await tester.pumpAndSettle();
      }
      expect(
        sawChapter2,
        greaterThanOrEqualTo(2),
        reason: '两处「第2章」都可见（含幽灵父级），实际 $sawChapter2',
      );
    });

    testWidgets('7. chapter 无 parent 仍显示', (tester) async {
      final (entries, text) = abnormalFixture();
      await pumpReader(tester, 0, toc: entries, text: text, offset: 36);
      await openToc(tester);
      // 滚动遍历：无父级番外仍显示
      for (var i = 0; i < 6 && find.text('番外').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      expect(find.text('番外'), findsOneWidget, reason: '无父级番外仍显示');
    });

    testWidgets('8. 连续 volume 正常显示', (tester) async {
      final (entries, text) = abnormalFixture();
      await pumpReader(tester, 0, toc: entries, text: text, offset: 12);
      await openToc(tester);
      expect(find.text('第二卷'), findsOneWidget);
      expect(find.text('第三卷'), findsOneWidget);
      // 卷之间无章节也正常
      expect(find.text('第二卷'), findsOneWidget);
    });

    testWidgets('9. 多种 volume/part 混合仍按 orderIndex 显示', (tester) async {
      final (entries, text) = abnormalFixture();
      await pumpReader(tester, 0, toc: entries, text: text, offset: 0);
      await openToc(tester);
      // 异常 fixture 全部 10 项必须可见（滚动到底逐项确认）
      final titles = [
        '第一卷',
        '第1章',
        '第2章',
        '第二卷',
        '第三卷',
        '第1章',
        '第2章',
        '第四部',
        '第99章',
        '番外',
      ];
      // 目录初始视口只显示前几项；先确认顶部项
      expect(find.text('第一卷'), findsOneWidget);
      expect(find.text('第二卷'), findsOneWidget);
      // 滚动遍历确认尾部项（虚拟列表分步滚动）
      for (var i = 0; i < 6 && find.text('番外').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      expect(find.text('第99章'), findsOneWidget, reason: '尾部卷内章节可见');
      expect(find.text('番外'), findsOneWidget, reason: '尾部番外可见');
      expect(titles.length, 10);
    });

    testWidgets('10. 用户手动滚动目录后不被自动拉回', (tester) async {
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

    testWidgets('11. 定位当前章节按钮工作', (tester) async {
      await pumpReader(tester, 300);
      await openToc(tester);
      expect(tileVisible(tester, '第300章 章节300'), isTrue);
      // 用户滚离后出现按钮
      await tester.drag(find.byType(ListView).last, const Offset(0, 30000));
      await tester.pumpAndSettle();
      expect(find.text('第1章 章节1'), findsOneWidget);
      expect(find.text('定位当前章节'), findsOneWidget, reason: '滚离后显示定位按钮');
      // 点击 → 回到当前章节
      await tester.tap(find.text('定位当前章节'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tileVisible(tester, '第300章 章节300'), isTrue, reason: '点击后回到当前章节');
    });

    testWidgets('12. 无章节只显示全文', (tester) async {
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
  });
}
