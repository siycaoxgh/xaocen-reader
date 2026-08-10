import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/app_shell_page.dart';
import 'package:xaocen_reader/app/providers.dart';

void main() {
  Future<ProviderContainer> createContainer() async {
    final container = ProviderContainer(
      overrides: [
        collectionsProvider.overrideWith((ref) async => const []),
        recentReadingProvider.overrideWith((ref) async => const []),
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
    await tester.tap(find.text('我的').last);
    await tester.pump();
    expect(find.text('阅读历史'), findsOneWidget);
    expect(find.text('阅读设置'), findsOneWidget);
  });
}
