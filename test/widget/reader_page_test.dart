import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/data/repositories/reader_bookmark_repository.dart';
import 'package:xaocen_reader/data/repositories/reader_preferences_repository.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/domain/reader/reader_palette.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/domain/reader/reader_progress_state.dart';
import 'package:xaocen_reader/domain/reader/reading_mode.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/reader_page.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_metrics_signature.dart';
import 'package:xaocen_reader/reader/reader_text_block.dart';

/// M3 Reader Widget 测试 —— 最小 UI 行为。
void main() {
  late Directory tmp;
  late LibraryFileManager fileManager;
  late NormalizedDocumentLoader loader;
  late AppDatabase db;
  late ReadingProgressRepository progressRepo;
  late ReaderBookmarkRepository bookmarkRepo;

  const bookText = '第一章 开端\n第一行正文内容。\n第二章 发展\n第二行正文内容。\n第三章 结局\n第三行正文内容。';

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('xaocen_reader_widget');
    fileManager = LibraryFileManager(libraryRoot: tmp);
    loader = NormalizedDocumentLoader(fileManager: fileManager);
    db = AppDatabase.forTesting();
    progressRepo = ReadingProgressRepository(db: db);
    bookmarkRepo = ReaderBookmarkRepository(db: db);
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

  ReaderLaunchContext launchContext({
    ReaderPreferencesRepository? preferencesRepository,
    ReaderBookmarkRepository? bookmarkRepository,
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
      bookmarkRepository: bookmarkRepository,
      preferencesRepository: preferencesRepository,
    );
  }

  Future<void> pumpReader(
    WidgetTester tester, {
    Stream<ReaderPreferences>? preferencesOverride,
    ValueChanged<ReaderMetricsRelayoutReport>? onMetricsRelayout,
    ReaderPreferencesRepository? preferencesRepository,
    ReaderBookmarkRepository? bookmarkRepository,
    ReaderProgressState? initialStateOverride,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPage(
          launch: launchContext(
            preferencesRepository: preferencesRepository,
            bookmarkRepository: bookmarkRepository,
          ),
          preferencesOverride: preferencesOverride,
          initialStateOverride: initialStateOverride,
          onMetricsRelayout: onMetricsRelayout,
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
    testWidgets(
      'reopen uses this book saved preferences for the first effective layout',
      (tester) async {
        final repository = ReaderPreferencesRepository(db: db);
        final saved = ReaderPreferences.defaults.copyWith(
          fontSize: 23,
          letterSpacing: .35,
          lineHeight: 2,
          paragraphSpacing: 7,
          firstLineIndent: 2,
          paddingTop: 12,
          paddingBottom: 18,
          paddingLeft: 24,
          paddingRight: 30,
          themeMode: ReaderThemeMode.dark,
        );
        await repository.update('local-txt:abc', saved);

        Future<void> expectSavedLayout() async {
          final block = tester.widget<ReaderTextBlock>(
            find.byType(ReaderTextBlock).first,
          );
          expect(block.style.fontSize, saved.fontSize);
          expect(block.style.letterSpacing, saved.letterSpacing);
          expect(block.style.height, saved.lineHeight);
          expect(block.paragraphSpacing, saved.paragraphSpacing);
          expect(block.firstLineIndent, saved.firstLineIndent);
          expect(
            block.maxWidth,
            closeTo(800 - saved.paddingLeft - saved.paddingRight, .01),
          );
        }

        await pumpReader(tester, preferencesRepository: repository);
        await expectSavedLayout();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));

        await pumpReader(tester, preferencesRepository: repository);
        await expectSavedLayout();
        expect(await repository.load('local-txt:abc'), saved);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'paint-only appearance does not restore locator or write progress',
      (tester) async {
        final changes = StreamController<ReaderPreferences>(sync: true);
        final metricsReports = <ReaderMetricsRelayoutReport>[];
        await pumpReader(
          tester,
          preferencesOverride: changes.stream,
          onMetricsRelayout: metricsReports.add,
        );
        changes.add(
          ReaderPreferences.defaults.copyWith(themeMode: ReaderThemeMode.light),
        );
        await tester.pump();
        changes.add(
          ReaderPreferences.defaults.copyWith(themeMode: ReaderThemeMode.dark),
        );
        await tester.pump();
        changes.add(ReaderPreferences.defaults);
        await tester.pump();
        changes.add(
          ReaderPreferences.defaults.copyWith(
            textColorArgb: 0xff4b3425,
            backgroundColorArgb: 0xfffff8e7,
            backgroundImagePath:
                'library/reader_backgrounds/test/background.png',
            backgroundImageOpacity: .8,
            backgroundOverlayOpacity: .55,
          ),
        );
        await tester.pump();

        expect(
          metricsReports,
          isEmpty,
          reason: 'paint-only 不进入 locator restore',
        );
        expect(await progressRepo.getProgress('local-txt:abc'), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        unawaited(changes.close());
      },
    );

    testWidgets('metrics 快速变化只应用最后一代，纵向 confirmed locator 不漂移', (tester) async {
      final changes = StreamController<ReaderPreferences>(sync: true);
      final reports = <ReaderMetricsRelayoutReport>[];
      await pumpReader(
        tester,
        preferencesOverride: changes.stream,
        onMetricsRelayout: reports.add,
      );
      changes.add(ReaderPreferences.defaults.copyWith(fontSize: 18));
      await tester.pump();
      changes.add(ReaderPreferences.defaults.copyWith(fontSize: 20));
      await tester.pump();
      changes.add(ReaderPreferences.defaults.copyWith(fontSize: 24));
      await tester.pump();
      changes.add(ReaderPreferences.defaults.copyWith(fontSize: 22));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final blocks = tester.widgetList<ReaderTextBlock>(
        find.byType(ReaderTextBlock),
      );
      expect(blocks, isNotEmpty);
      expect(blocks.every((block) => block.style.fontSize == 22), isTrue);
      expect(reports, isNotEmpty);
      expect(reports.last.signature.fontSize, 22);
      expect(reports.last.logicalError, 0);
      expect(
        reports.last.visibleAfter!.contains(
          reports.last.locatorBefore.absoluteCharacterOffset,
        ),
        isTrue,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      unawaited(changes.close());
    });

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

    testWidgets('V3 chrome overlays toggle without progress writes', (
      tester,
    ) async {
      await pumpReader(tester);
      expect(find.byKey(readerTopChromeKey), findsOneWidget);
      expect(find.byKey(readerBottomChromeKey), findsOneWidget);

      await tester.tap(find.byKey(readerChromeToggleKey));
      await tester.pump(const Duration(milliseconds: 150));
      final top = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byKey(readerTopChromeKey),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(top.opacity, 0);
      expect(await progressRepo.getProgress('local-txt:abc'), isNull);

      await tester.tap(find.byKey(readerChromeToggleKey));
      await tester.pump(const Duration(milliseconds: 150));
      expect(await progressRepo.getProgress('local-txt:abc'), isNull);
    });

    testWidgets(
      'Aa opens complete settings panel; opening and closing writes no progress',
      (tester) async {
        await pumpReader(tester);
        await tester.tap(find.byKey(readerAppearanceActionKey));
        await tester.pumpAndSettle();
        expect(find.text('阅读设置'), findsOneWidget);
        expect(find.byKey(readerFontSizeSliderKey), findsOneWidget);
        expect(find.byKey(readerLineHeightSliderKey), findsOneWidget);
        expect(find.byKey(readerHorizontalPaddingSliderKey), findsOneWidget);
        expect(find.byKey(readerVerticalPaddingSliderKey), findsOneWidget);
        await tester.tap(find.text('外观'));
        await tester.pumpAndSettle();
        expect(find.byKey(readerThemeControlKey), findsOneWidget);
        await tester.ensureVisible(find.byKey(readerTextColorControlKey));
        expect(find.byKey(readerTextColorControlKey), findsOneWidget);
        expect(find.byKey(readerBackgroundColorControlKey), findsOneWidget);
        expect(find.byKey(readerBackgroundImageActionKey), findsOneWidget);
        expect(find.byKey(readerResetAppearanceKey), findsOneWidget);
        await tester.tap(find.text('阅读行为'));
        await tester.pumpAndSettle();
        expect(find.byKey(readerSettingsModeControlKey), findsOneWidget);
        await tester.tap(find.text('高级'));
        await tester.pumpAndSettle();
        expect(find.byKey(readerResetPreferencesKey), findsOneWidget);
        expect(await progressRepo.getProgress('local-txt:abc'), isNull);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(await progressRepo.getProgress('local-txt:abc'), isNull);

        await tester.tap(find.byKey(readerMoreActionKey));
        await tester.pumpAndSettle();
        expect(find.textContaining('朗读当前未实现'), findsOneWidget);
      },
    );

    testWidgets(
      'settings metrics commit relayouts at exact Locator and persists final draft',
      (tester) async {
        final repository = ReaderPreferencesRepository(db: db);
        final reports = <ReaderMetricsRelayoutReport>[];
        await pumpReader(
          tester,
          preferencesRepository: repository,
          onMetricsRelayout: reports.add,
        );
        await tester.tap(find.byKey(readerAppearanceActionKey));
        await tester.pumpAndSettle();

        for (final key in [
          readerFontSizeSliderKey,
          readerLineHeightSliderKey,
          readerHorizontalPaddingSliderKey,
          readerVerticalPaddingSliderKey,
        ]) {
          await tester.ensureVisible(find.byKey(key));
          await tester.pump();
          await tester.drag(find.byKey(key), const Offset(48, 0));
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
        }

        expect(reports.length, greaterThanOrEqualTo(3));
        expect(reports.every((report) => report.logicalError == 0), isTrue);
        final stored = await repository.load('local-txt:abc');
        expect(stored.fontSize, isNot(ReaderPreferences.defaultFontSize));
        expect(stored.lineHeight, isNot(ReaderPreferences.defaultLineHeight));
        expect(stored.paddingLeft, isNot(ReaderPreferences.defaultPaddingLeft));
        expect(stored.paddingTop, isNot(ReaderPreferences.defaultPaddingTop));
        expect(await progressRepo.getProgress('local-txt:abc'), isNull);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets('theme is paint-only and reset restores persisted defaults', (
      tester,
    ) async {
      final repository = ReaderPreferencesRepository(db: db);
      final reports = <ReaderMetricsRelayoutReport>[];
      await pumpReader(
        tester,
        preferencesRepository: repository,
        onMetricsRelayout: reports.add,
      );
      await tester.tap(find.byKey(readerAppearanceActionKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('外观'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('墨黑'));
      await tester.pump();
      expect(
        (await repository.load('local-txt:abc')).paletteId,
        ReaderPaletteId.inkBlack,
      );
      final colorFields = find.byType(TextField);
      expect(colorFields, findsNWidgets(2));
      await tester.enterText(colorFields.at(0), 'rgb(18, 52, 86)');
      await tester.pump();
      expect(
        (await repository.load('local-txt:abc')).textColorArgb,
        0xff123456,
      );
      await tester.enterText(colorFields.at(1), 'not-a-color');
      await tester.pump();
      expect(find.text('请输入 #RRGGBB 或 rgb(r,g,b)'), findsOneWidget);
      await tester.ensureVisible(find.text('深色'));
      await tester.pump();
      await tester.tap(find.text('深色'));
      await tester.pumpAndSettle();
      expect(
        (await repository.load('local-txt:abc')).themeMode,
        ReaderThemeMode.dark,
      );
      expect(reports, isEmpty);
      expect(await progressRepo.getProgress('local-txt:abc'), isNull);

      await tester.drag(
        find.byKey(readerSettingsSheetKey),
        const Offset(0, 1000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('排版'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(readerFontSizeSliderKey));
      await tester.pump();
      await tester.drag(
        find.byKey(readerFontSizeSliderKey),
        const Offset(80, 0),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump();
      }
      await tester.drag(
        find.byKey(readerSettingsSheetKey),
        const Offset(0, 1000),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('高级'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(readerResetPreferencesKey));
      await tester.pump();
      await tester.tap(find.byKey(readerResetPreferencesKey));
      for (var i = 0; i < 12; i++) {
        await tester.pump();
      }
      expect(
        await repository.load('local-txt:abc'),
        ReaderPreferences.defaults,
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'paged settings metrics repaginate around the exact non-zero Locator',
      (tester) async {
        final repository = ReaderPreferencesRepository(db: db);
        final reports = <ReaderMetricsRelayoutReport>[];
        await pumpReader(
          tester,
          preferencesRepository: repository,
          onMetricsRelayout: reports.add,
          initialStateOverride: ReaderProgressState(
            collectionId: 'local-txt:abc',
            absoluteCharacterOffset: 12,
            readingMode: ReadingMode.paged,
            updatedAt: DateTime(2026),
          ),
        );
        await tester.tap(find.byKey(readerAppearanceActionKey));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(readerFontSizeSliderKey),
          const Offset(70, 0),
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        final report = reports.last;
        expect(report.locatorBefore.absoluteCharacterOffset, 12);
        expect(report.logicalError, 0);
        expect(report.pageAfter!.contains(12), isTrue);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'rapid slider commits persist only the final snapshot generation',
      (tester) async {
        final repository = ReaderPreferencesRepository(db: db);
        final reports = <ReaderMetricsRelayoutReport>[];
        await pumpReader(
          tester,
          preferencesRepository: repository,
          onMetricsRelayout: reports.add,
        );
        await tester.tap(find.byKey(readerAppearanceActionKey));
        await tester.pumpAndSettle();
        final slider = find.byKey(readerFontSizeSliderKey);
        await tester.drag(slider, const Offset(20, 0));
        await tester.drag(slider, const Offset(60, 0));
        await tester.drag(slider, const Offset(-30, 0));
        await tester.drag(slider, const Offset(45, 0));
        for (var i = 0; i < 20; i++) {
          await tester.pump();
        }
        final displayed = tester.widget<Slider>(
          find.descendant(of: slider, matching: find.byType(Slider)),
        );
        expect(
          (await repository.load('local-txt:abc')).fontSize,
          displayed.value,
        );
        expect(reports.last.logicalError, 0);
        expect(reports.last.signature.fontSize, displayed.value);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'Reader chrome adapts to portrait landscape and desktop resize',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(390, 844);
        await pumpReader(tester);
        expect(tester.takeException(), isNull);

        tester.view.physicalSize = const Size(844, 390);
        await tester.pump();
        expect(tester.takeException(), isNull);

        tester.view.physicalSize = const Size(1200, 800);
        await tester.pump();
        final bottomSize = tester.getSize(find.byKey(readerBottomChromeKey));
        expect(bottomSize.width, lessThanOrEqualTo(520));
        expect(tester.takeException(), isNull);
      },
    );

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

    testWidgets('M5.2b progress and chapter display use confirmed Locator', (
      tester,
    ) async {
      await pumpReader(tester);
      // The vertical chrome now labels chapter and whole-book progress
      // separately; assert the existing whole-book contract explicitly.
      expect(find.textContaining('第1章'), findsOneWidget);
      expect(find.text('本章 0%'), findsOneWidget);
      expect(find.text('全书 0%'), findsOneWidget);
      expect(await progressRepo.getProgress('local-txt:abc'), isNull);
    });

    testWidgets('M5.2b bookmark create/list/delete does not write progress', (
      tester,
    ) async {
      await pumpReader(
        tester,
        bookmarkRepository: bookmarkRepo,
        initialStateOverride: const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 12,
          readingMode: ReadingMode.vertical,
        ),
      );
      await tester.tap(find.byKey(readerBookmarksActionKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(readerBookmarkCreateKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      final bookmarks = await bookmarkRepo.loadForCollection('local-txt:abc');
      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.absoluteCharacterOffset, 12);
      expect(await progressRepo.getProgress('local-txt:abc'), isNull);

      expect(find.byKey(readerBookmarkListKey), findsOneWidget);
      expect(find.textContaining('Offset 12'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(await bookmarkRepo.loadForCollection('local-txt:abc'), isEmpty);
      expect(await progressRepo.getProgress('local-txt:abc'), isNull);
    });

    testWidgets('M5.2b vertical bookmark jump confirms exact offset', (
      tester,
    ) async {
      await bookmarkRepo.create(
        collectionId: 'local-txt:abc',
        absoluteCharacterOffset: 24,
        normalizedHashAtCreation: '',
        bookTitleSnapshot: '娴嬭瘯涔︾睄',
      );
      await pumpReader(tester, bookmarkRepository: bookmarkRepo);
      await tester.tap(find.byKey(readerBookmarksActionKey));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Offset 24'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      final progress = await progressRepo.getProgress('local-txt:abc');
      expect(progress, isNotNull);
      expect(progress!.absoluteCharacterOffset, 24);
    });

    testWidgets('dispose 无异常', (tester) async {
      await pumpReader(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
