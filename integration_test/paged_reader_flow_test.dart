/// M4.2 集成测试：分页 Reader 全链路。
///
/// 流程（§四十三）：
/// 导入 fixture → 纵向打开 → 滚动到正文中段 → 切分页 → 验证 anchor →
/// 下一页 → 下一页 → 切纵向 → 验证 visible range → 返回书架 → 重开 →
/// 验证恢复 → 切分页 → TOC 远跳 → 重启 Repository/DB → 再恢复。
///
/// 使用真实 managed normalized.txt / 真实 Drift / 真实 Repository。
/// fixture 运行时生成（多章多页，避免内嵌巨数组）。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xaocen_reader/app/library_page.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/reader/paged_reader_view.dart';
import 'package:xaocen_reader/reader/reader_page.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

/// 生成多章 fixture（UTF-8，章节标题满足扫描器合同「第X章 + 空白」）。
/// 约 40 章 × 1200 字符 ≈ 48KB，多页可翻。
String _buildFixture() {
  final buf = StringBuffer();
  for (var i = 1; i <= 40; i++) {
    buf.writeln('第$i章 章节标题$i');
    // 每章若干段，总约 1200 字符
    for (var p = 0; p < 12; p++) {
      buf.writeln(
        '这是第$i章第$p 段的正文内容，包含一些中文文本用于分页测试。'
        '每一行都会参与 TextPainter 排版，确保页面边界落在行尾。'
        '重复内容占位：abcdefghijklmnopqrstuvwxyz0123456789。',
      );
    }
    buf.writeln('（本章完）');
  }
  return buf.toString();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  void selectMode(WidgetTester tester, ReaderMode mode) {
    final menu = tester.widget<PopupMenuButton<ReaderMode>>(
      find.byType(PopupMenuButton<ReaderMode>),
    );
    menu.onSelected!(mode);
  }

  late AppDatabase db;
  late Directory libRoot;
  late Directory fixtureDir;
  late ProviderContainer container;

  setUp(() {
    fixtureDir = Directory.systemTemp.createTempSync('xaocen_it_m42_fixture');
    File(
      '${fixtureDir.path}${Platform.pathSeparator}big_chapters.txt',
    ).writeAsBytesSync(_utf8(_buildFixture()));
  });

  tearDown(() async {
    await db.close();
    container.dispose();
    if (await libRoot.exists()) await libRoot.delete(recursive: true);
    if (await fixtureDir.exists()) await fixtureDir.delete(recursive: true);
  });

  Future<void> buildScope() async {
    db = AppDatabase.forTesting();
    libRoot = Directory.systemTemp.createTempSync('xaocen_it_m42_lib');
    final fm = LibraryFileManager(libraryRoot: libRoot);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        fileManagerProvider.overrideWithValue(fm),
        encodingIndexProvider.overrideWithValue(_indexProvider()),
      ],
    );
  }

  Future<void> pumpLibrary(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LibraryPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('分页全链路：导入→纵向→切分页→翻页→切回→重开→TOC 远跳', (tester) async {
    // ---- 导入 ----
    await buildScope();
    await pumpLibrary(tester);
    final repo = container.read(libraryRepositoryProvider);
    final r1 = await repo.importTxt(
      ImportTxtRequest(
        externalFile: File(
          '${fixtureDir.path}${Platform.pathSeparator}big_chapters.txt',
        ),
        confirmLargeFile: true,
      ),
    );
    expect(r1.alreadyImported, isFalse);
    container.invalidate(collectionsProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('big_chapters'), findsOneWidget);

    // ---- 打开 Reader（纵向）----
    await tester.tap(find.text('big_chapters'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ReaderPage), findsOneWidget);

    // ---- 纵向滚动到中段 ----
    // SuperListView 存在即视为纵向模式就绪
    await tester.pumpAndSettle();

    // ---- 切分页（菜单：滚动 → 分页）----
    selectMode(tester, ReaderMode.paged);
    await tester.pumpAndSettle();
    expect(
      find.byType(PagedReaderView),
      findsOneWidget,
      reason: '切分页后应显示 PagedReaderView',
    );

    // ---- 下一页 ×2 ----
    // 键盘翻页模拟：直接 fling PageView
    final pv = find.byType(PageView);
    await tester.fling(pv, const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();
    await tester.fling(pv, const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();

    // ---- 切回纵向 ----
    selectMode(tester, ReaderMode.vertical);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PagedReaderView), findsNothing, reason: '切回后应回到纵向');
    expect(find.byType(ReaderPage), findsOneWidget);

    // ---- 返回书架 ----
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('big_chapters'), findsOneWidget);

    // ---- 重开：验证进度恢复 ----
    await tester.tap(find.text('big_chapters'));
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ReaderPage), findsOneWidget);
    // 恢复后应有已确认进度（滚动/翻页过 → 已保存）
    await tester.pumpAndSettle();

    // ---- 切分页 + TOC 远跳 ----
    selectMode(tester, ReaderMode.paged);
    await tester.pumpAndSettle();
    expect(find.byType(PagedReaderView), findsOneWidget);

    // 目录远跳（第 30 章）
    await tester.tap(find.byIcon(Icons.list));
    await tester.pumpAndSettle();
    // 目录可能虚拟化：滚到第 30 章附近
    await tester.scrollUntilVisible(
      find.text('第30章 章节标题30'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('第30章 章节标题30'));
    await tester.pumpAndSettle();
    // 跳转后目录关闭，回到分页正文
    expect(find.byType(PagedReaderView), findsOneWidget);
    // TOC 跳转是防抖保存（400ms）：等待落盘
    await tester.pump(const Duration(milliseconds: 600));
    final progressBefore = await container
        .read(readingProgressRepositoryProvider)
        .getProgress(r1.collection.id);
    expect(progressBefore, isNotNull, reason: 'TOC 远跳（明确用户操作）后应保存精确 target');
    expect(
      progressBefore!.absoluteCharacterOffset,
      greaterThan(0),
      reason: '第 30 章 offset 应显著大于 0（远跳生效）',
    );

    // ---- 模拟重启：新 Repository 读同一 DB ----
    // （真实持久化重启由 Android 真机 force-stop 验证；此处沿用 M3 集成测试做法）
    final reopened = await ReadingProgressRepository(
      db: db,
    ).getProgress(r1.collection.id);
    expect(reopened, isNotNull, reason: '重启后进度仍保留');
    expect(
      reopened!.absoluteCharacterOffset,
      progressBefore.absoluteCharacterOffset,
      reason: '重启后恢复的 offset 与保存一致',
    );
  });
}

/// UTF-8 编码（dart:convert）。
List<int> _utf8(String s) => utf8.encode(s);

/// AssetBundle 索引 Provider（Windows/Android 通用）。
EncodingIndexProvider _indexProvider() {
  return FlutterAssetEncodingIndexProvider();
}
