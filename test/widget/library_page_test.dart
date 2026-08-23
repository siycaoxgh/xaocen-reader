import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/library_page.dart';
import 'package:xaocen_reader/app/metadata_edit_page.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';

/// M2 最小书架 Widget 测试 —— 纯 UI 状态机测试。
///
/// 注意：flutter_test 的 FakeAsync 环境不推进真实 IO（Drift/SQLite 查询
/// 会挂起），因此本测试用 provider override 注入数据，不触发真实导入；
/// 真实全链路由 integration_test 覆盖（真实 async 环境）。
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        // 空书库（默认）
        collectionsProvider.overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: const LibraryPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('书架 Widget', () {
    test('本地与在线书源标签及删除提示区分', () {
      final local = LibraryCollection(
        id: 'local-txt:label',
        sourceId: 'local-txt-source:label',
        title: '本地书',
        subtitle: null,
        itemCount: 1,
        normalizedCharacterLength: 1,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 1,
        importedAt: DateTime(2026, 8, 6),
      );
      final online = LibraryCollection(
        id: 'web-book:label',
        sourceId: 'web-book-source:fixture',
        title: '在线书',
        subtitle: null,
        itemCount: 1,
        normalizedCharacterLength: 1,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 1,
        importedAt: DateTime(2026, 8, 6),
      );
      expect(collectionSourceLabel(local), '本地书籍');
      expect(collectionSourceLabel(online), '在线书源');
      expect(collectionDeleteMessage(local), contains('不影响外部原文件'));
      expect(collectionDeleteMessage(online), '将移除书架记录和本地缓存，不影响在线书源及网站原文。');
    });

    testWidgets('空书库显示提示', (tester) async {
      await pump(tester);
      expect(find.text('本地书库'), findsOneWidget);
      expect(find.text('导入书籍'), findsOneWidget);
      expect(find.text('书库为空，点击“导入书籍”开始'), findsOneWidget);
    });

    testWidgets('导入按钮存在', (tester) async {
      await pump(tester);
      expect(find.widgetWithText(FilledButton, '导入书籍'), findsOneWidget);
    });

    testWidgets('书架大面积主体使用 App Shell surface', (tester) async {
      await pump(tester);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final surface = Theme.of(
        tester.element(find.byType(Scaffold)),
      ).colorScheme.surface;
      expect(scaffold.backgroundColor, surface);
    });

    testWidgets('有书时显示卡片（标题/章数/编码）', (tester) async {
      final collection = LibraryCollection(
        id: 'local-txt:abc',
        sourceId: 'local-txt-source:abc',
        title: '测试书籍',
        subtitle: null,
        itemCount: 3,
        normalizedCharacterLength: 100,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 2048,
        importedAt: DateTime(2026, 8, 6),
      );
      container = ProviderContainer(
        overrides: [
          collectionsProvider.overrideWith((ref) async => [collection]),
        ],
      );
      addTearDown(container.dispose);
      await pump(tester);
      expect(find.text('测试书籍'), findsOneWidget);
      expect(find.textContaining('3 章'), findsOneWidget);
      expect(find.textContaining('utf8'), findsOneWidget);
    });

    testWidgets('书籍卡片使用 metadata、作者回退和稳定封面占位', (tester) async {
      final collection = LibraryCollection(
        id: 'local-txt:metadata-card',
        sourceId: 'local-txt-source:metadata-card',
        title: '正式书名',
        subtitle: null,
        author: '测试作者',
        itemCount: 8,
        normalizedCharacterLength: 1000,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 1024,
        importedAt: DateTime(2026, 8, 6),
      );
      container = ProviderContainer(
        overrides: [
          collectionsProvider.overrideWith((ref) async => [collection]),
        ],
      );
      addTearDown(container.dispose);
      await pump(tester);
      expect(find.byType(BookCoverPlaceholder), findsOneWidget);
      expect(find.text('正式书名'), findsOneWidget);
      expect(find.text('作者：测试作者'), findsOneWidget);

      final withoutAuthor = LibraryCollection(
        id: 'local-txt:metadata-card-no-author',
        sourceId: 'local-txt-source:metadata-card-no-author',
        title: '无作者书',
        subtitle: null,
        itemCount: 1,
        normalizedCharacterLength: 10,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 10,
        importedAt: DateTime(2026, 8, 6),
      );
      container = ProviderContainer(
        overrides: [
          collectionsProvider.overrideWith((ref) async => [withoutAuthor]),
        ],
      );
      addTearDown(container.dispose);
      await pump(tester);
      expect(find.text('作者未知'), findsOneWidget);
    });

    testWidgets('书籍卡片显示本地/在线来源标签', (tester) async {
      final local = LibraryCollection(
        id: 'local-txt:source-label',
        sourceId: 'local-txt-source:source-label',
        title: '本地来源书',
        subtitle: null,
        itemCount: 1,
        normalizedCharacterLength: 10,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 10,
        importedAt: DateTime(2026, 8, 6),
      );
      final online = LibraryCollection(
        id: 'web-book:source-label',
        sourceId: 'web-book-source:source-label',
        title: '在线来源书',
        subtitle: null,
        itemCount: 1,
        normalizedCharacterLength: 10,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 10,
        importedAt: DateTime(2026, 8, 6),
      );
      container = ProviderContainer(
        overrides: [
          collectionsProvider.overrideWith((ref) async => [local, online]),
        ],
      );
      addTearDown(container.dispose);
      await pump(tester);
      expect(find.text('本地书籍'), findsOneWidget);
      expect(find.text('在线书源'), findsOneWidget);
    });

    testWidgets('书籍卡片菜单打开 metadata 编辑页', (tester) async {
      final collection = LibraryCollection(
        id: 'local-txt:edit',
        sourceId: 'source:edit',
        title: '可编辑书',
        subtitle: null,
        itemCount: 1,
        normalizedCharacterLength: 10,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 10,
        importedAt: DateTime(2026, 8, 6),
      );
      container = ProviderContainer(
        overrides: [
          collectionsProvider.overrideWith((ref) async => [collection]),
        ],
      );
      addTearDown(container.dispose);
      await pump(tester);
      await tester.tap(find.byTooltip('书籍操作'));
      await tester.pumpAndSettle();
      expect(find.text('编辑书籍信息'), findsOneWidget);
      await tester.tap(find.text('编辑书籍信息'));
      await tester.pumpAndSettle();
      expect(find.byType(MetadataEditPage), findsOneWidget);
      expect(find.text('原文件名'), findsOneWidget);
      expect(find.text('来源'), findsOneWidget);
    });

    testWidgets('超过 50MB 拒绝文案', (tester) async {
      await pump(tester);
      container
          .read(importProgressProvider.notifier)
          .setError('文件超过 50MB，不支持导入（52428801 字节）');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('不支持导入'), findsOneWidget);
    });

    testWidgets('大文件确认条显示', (tester) async {
      await pump(tester);
      container
          .read(importProgressProvider.notifier)
          .setError('large_file_confirmation_required');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('超过 20MB'), findsOneWidget);
      expect(find.text('确认导入'), findsOneWidget);
    });

    testWidgets('错误状态显示', (tester) async {
      await pump(tester);
      container.read(importProgressProvider.notifier).setError('导入失败: 测试错误');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('导入失败'), findsOneWidget);
    });

    testWidgets('进度面板显示 + 取消按钮', (tester) async {
      await pump(tester);
      final notifier = container.read(importProgressProvider.notifier);
      // 直接构造 running 状态（不触发真实导入）
      notifier.forceRunning();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      // 点取消按钮（触发 token cancel，不崩溃）
      await tester.tap(find.text('取消'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(notifier.debugTokenCancelled, isTrue);
    });
  });
}
