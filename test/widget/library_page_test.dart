import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/library_page.dart';
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
    testWidgets('空书库显示提示', (tester) async {
      await pump(tester);
      expect(find.text('本地书库'), findsOneWidget);
      expect(find.text('导入 TXT'), findsOneWidget);
      expect(find.text('书库为空，点击“导入 TXT”开始'), findsOneWidget);
    });

    testWidgets('导入按钮存在', (tester) async {
      await pump(tester);
      expect(find.widgetWithText(FilledButton, '导入 TXT'), findsOneWidget);
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

    testWidgets('点击书籍显示 Reader 占位提示', (tester) async {
      final collection = LibraryCollection(
        id: 'local-txt:abc',
        sourceId: 'local-txt-source:abc',
        title: '测试书籍',
        subtitle: null,
        itemCount: 1,
        normalizedCharacterLength: 10,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: 100,
        importedAt: DateTime(2026, 8, 6),
      );
      container = ProviderContainer(
        overrides: [
          collectionsProvider.overrideWith((ref) async => [collection]),
        ],
      );
      addTearDown(container.dispose);
      await pump(tester);
      await tester.tap(find.text('测试书籍'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Reader 将在 M3 实现'), findsOneWidget);
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
