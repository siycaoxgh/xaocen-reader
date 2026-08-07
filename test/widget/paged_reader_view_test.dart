/// PagedReaderView Widget 测试（M4 §四十二-1~5、15~18、20）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/paged_reader_controller.dart';
import 'package:xaocen_reader/reader/paged_reader_view.dart';
import 'package:xaocen_reader/reader/reader_appearance.dart';
import 'package:xaocen_reader/reader/reader_text_block.dart';

const _style = TextStyle(fontSize: 10, height: 1.0);

/// Ahem 字体：fontSize 10、宽 400（content 368）→ 每行 36 字符；
/// 高 600（content 584）→ 58 行 → 约 2088 字符/页。文本 40000 → ~20 页。
final _text = 'a' * 40000;

void main() {
  late AppDatabase db;
  late ReadingProgressRepository progressRepo;

  setUp(() async {
    db = AppDatabase.forTesting();
    progressRepo = ReadingProgressRepository(db: db);
    final now = DateTime.now();
    await db
        .into(db.contentSources)
        .insert(
          ContentSourcesCompanion.insert(
            id: 'local-txt-source:c1',
            type: 'localTxt',
            displayName: 'Test',
            contentHash: 'c1',
            managedSourcePath: 'library/local_txt/c1/source.txt',
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
            id: 'c1',
            sourceId: 'local-txt-source:c1',
            title: 'Test',
            itemCount: 1,
            normalizedCharacterLength: _text.length,
            importedAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  PagedReaderController makeController() {
    final doc = NormalizedDocument(
      text: _text,
      normalizedHash: '',
      normalizationVersion: 'v1',
      parserVersion: '1',
      indexFormatVersion: '1',
      sourceFileName: 't.txt',
    );
    final bi = ReaderBlockIndex.build(text: _text, targetBlockSize: 6144);
    return PagedReaderController(
      collectionId: 'c1',
      document: doc,
      progressRepository: progressRepo,
      blockIndex: bi,
      style: _style,
      width: 400,
      height: 600,
    );
  }

  ReaderResolvedAppearance appearance({bool dark = false}) {
    return ReaderResolvedAppearance(
      backgroundColor: dark ? const Color(0xFF111111) : Colors.white,
      textColor: dark ? Colors.white : Colors.black,
      secondaryTextColor: Colors.grey,
      headingColor: dark ? Colors.white : Colors.black,
      selectionColor: const Color(0xFFCCE8E8),
      baseTextStyle: _style.copyWith(color: dark ? Colors.white : Colors.black),
    );
  }

  testWidgets('1. paged first open：PageView + 正文渲染', (tester) async {
    final c = makeController();
    c.open(const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: PagedReaderView(controller: c, appearance: appearance()),
        ),
      ),
    );
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(ReaderTextBlock), findsWidgets);
    expect(c.currentPage, isNotNull);
    c.dispose();
  });

  testWidgets('2. next：左滑翻到下一页并更新 confirmed', (tester) async {
    final c = makeController();
    c.open(const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0));
    final first = c.currentPage!;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: PagedReaderView(controller: c, appearance: appearance()),
        ),
      ),
    );
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1200);
    await tester.pumpAndSettle();
    expect(
      c.currentPage!.startCharacterOffset,
      isNot(first.startCharacterOffset),
    );
    expect(
      c.confirmedLocator!.absoluteCharacterOffset,
      c.currentPage!.startCharacterOffset,
      reason: '用户翻页后 confirmed = 新页 start',
    );
    c.dispose();
  });

  testWidgets('3. previous：右滑翻回上一页', (tester) async {
    final c = makeController();
    c.open(const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: PagedReaderView(controller: c, appearance: appearance()),
        ),
      ),
    );
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1200);
    await tester.pumpAndSettle();
    final p2 = c.currentPage!;
    await tester.fling(find.byType(PageView), const Offset(500, 0), 1200);
    await tester.pumpAndSettle();
    expect(c.currentPage!.startCharacterOffset, isNot(p2.startCharacterOffset));
    expect(c.currentPage!.startCharacterOffset, 0);
    c.dispose();
  });

  testWidgets('4. final page：末页 endReached 不越界', (tester) async {
    final c = makeController();
    c.open(const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: PagedReaderView(controller: c, appearance: appearance()),
        ),
      ),
    );
    var guard = 0;
    while (!c.window.atDocumentEnd && guard < 60) {
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1200);
      await tester.pumpAndSettle();
      guard++;
    }
    expect(c.window.atDocumentEnd, isTrue);
    expect(
      c.currentPage!.endCharacterOffset,
      _text.length,
      reason: '末页 end = document length（§27）',
    );
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1200);
    await tester.pumpAndSettle();
    expect(c.window.atDocumentEnd, isTrue);
    c.dispose();
  });

  testWidgets('5. first page：首页 startReached 不回退', (tester) async {
    final c = makeController();
    c.open(const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: PagedReaderView(controller: c, appearance: appearance()),
        ),
      ),
    );
    expect(c.window.atDocumentStart, isTrue);
    await tester.fling(find.byType(PageView), const Offset(500, 0), 1200);
    await tester.pumpAndSettle();
    expect(c.currentPage!.startCharacterOffset, 0);
    c.dispose();
  });

  testWidgets('15/16. dark / light 背景正确', (tester) async {
    final c = makeController();
    c.open(const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: PagedReaderView(
            controller: c,
            appearance: appearance(dark: true),
          ),
        ),
      ),
    );
    final boxes = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((b) => b.color == const Color(0xFF111111));
    expect(boxes, isNotEmpty, reason: '深色背景应生效');
    c.dispose();
  });

  testWidgets('17. resize：relayout 后页面覆盖原位置且 confirmed 保持', (tester) async {
    final c = makeController();
    c.open(
      const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 5000),
    );
    final anchor = c.confirmedLocator!;
    final changed = c.relayout(width: 800, height: 600, style: _style);
    expect(changed, isTrue);
    expect(c.confirmedLocator, anchor, reason: 'resize 不改 confirmed（§31）');
    expect(c.currentPage!.contains(5000), isTrue);
    c.dispose();
  });

  testWidgets('18. rapid flip：快速连续翻页 0 crash 0 assertion', (tester) async {
    final c = makeController();
    c.open(const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: PagedReaderView(controller: c, appearance: appearance()),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1200);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(c.window.pageCount, lessThanOrEqualTo(10));
    c.dispose();
  });

  testWidgets('20. dispose 无异常', (tester) async {
    final c = makeController();
    c.open(const ReaderLocator(collectionId: 'c1', absoluteCharacterOffset: 0));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: PagedReaderView(controller: c, appearance: appearance()),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
    c.dispose();
  });
}
