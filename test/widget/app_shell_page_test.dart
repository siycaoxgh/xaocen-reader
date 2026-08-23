import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/app_shell_page.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/domain/reader/reading_history.dart';

void main() {
  Future<ProviderContainer> createContainer({
    List<ReadingHistoryEntry> recent = const [],
  }) async {
    final container = ProviderContainer(
      overrides: [
        collectionsProvider.overrideWith((ref) async => const []),
        recentReadingProvider.overrideWith((ref) async => recent),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('desktop shell exposes sidebar primary navigation', (
    tester,
  ) async {
    final container = await createContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AppShellPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsAtLeastNWidgets(1));
    expect(find.text('书架'), findsAtLeastNWidgets(1));
    expect(find.text('我的'), findsAtLeastNWidgets(1));
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('书架').first);
    await tester.pump();
    expect(find.text('本地书库'), findsOneWidget);
    expect(find.text('最近阅读'), findsNothing);
  });

  testWidgets('mobile shell uses bottom primary navigation', (tester) async {
    final container = await createContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: const MaterialApp(home: AppShellPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('首页'), findsAtLeastNWidgets(1));
    expect(find.text('首页'), findsNWidgets(1));
    expect(find.text('内容订阅'), findsOneWidget);
    expect(find.text('订阅'), findsNothing);
    await tester.tap(find.text('我的').last);
    await tester.pump();
    expect(find.text('我的'), findsNWidgets(1));
    expect(find.text('阅读历史'), findsOneWidget);
    expect(find.text('阅读设置'), findsOneWidget);
  });

  testWidgets(
    'home shows at most the derived recent entries and an empty state',
    (tester) async {
      final now = DateTime(2026, 8, 11);
      final recent = [
        ReadingHistoryEntry(
          id: 'history-a',
          collectionId: 'book-a',
          bookTitleSnapshot: 'Book A',
          authorSnapshot: null,
          normalizedHashSnapshot: null,
          firstReadAt: now,
          lastReadAt: now,
          lastChapterTitleSnapshot: 'Chapter 1',
          lastProgressSnapshot: '10%',
          createdAt: now,
          updatedAt: now,
        ),
        ReadingHistoryEntry(
          id: 'history-b',
          collectionId: 'book-b',
          bookTitleSnapshot: 'Book B',
          authorSnapshot: null,
          normalizedHashSnapshot: null,
          firstReadAt: now,
          lastReadAt: now.subtract(const Duration(minutes: 1)),
          lastChapterTitleSnapshot: null,
          lastProgressSnapshot: null,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final container = await createContainer(recent: recent);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AppShellPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book A'), findsOneWidget);
      expect(find.text('Book B'), findsOneWidget);
      expect(find.text('继续阅读'), findsOneWidget);
    },
  );
}
