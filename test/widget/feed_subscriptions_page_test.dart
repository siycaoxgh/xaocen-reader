import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/feed_article_reader_page.dart';
import 'package:xaocen_reader/app/feed_subscriptions_page.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/domain/remote/feed_subscription.dart';
import 'package:xaocen_reader/reader/reader_page.dart';

void main() {
  final now = DateTime.utc(2026, 8, 16);
  final subscription = FeedSubscription(
    sourceId: 'daily-feed',
    endpoint: Uri.parse('https://example.com/feed.xml'),
    format: 'rss',
    title: '每日更新',
    description: '测试订阅',
    subscribedAt: now,
    updatedAt: now,
    lastRefreshedAt: now,
    articles: [
      FeedArticle(
        identity: 'daily-feed:article-1',
        title: '第一篇文章',
        body: '这是文章正文。',
        summary: '文章摘要',
        publishedAt: now,
        firstSeenAt: now,
        updatedAt: now,
      ),
    ],
  );

  testWidgets('subscription list exposes feed and opens article list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedSubscriptionsProvider.overrideWith((ref) async => [subscription]),
          feedSubscriptionProvider.overrideWith(
            (ref, sourceId) async =>
                sourceId == subscription.sourceId ? subscription : null,
          ),
        ],
        child: const MaterialApp(home: FeedSubscriptionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的订阅'), findsOneWidget);
    expect(find.text('每日更新'), findsOneWidget);
    expect(find.textContaining('1 篇文章 · example.com'), findsOneWidget);

    await tester.tap(find.text('每日更新'));
    await tester.pumpAndSettle();
    expect(find.text('订阅文章'), findsNothing);
    expect(find.text('第一篇文章'), findsOneWidget);
    expect(find.textContaining('文章摘要'), findsOneWidget);
  });

  testWidgets('empty state explains how to add a feed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedSubscriptionsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: FeedSubscriptionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('还没有订阅'), findsOneWidget);
    expect(find.text('点击右上角加号，粘贴订阅地址即可。'), findsOneWidget);
  });

  testWidgets('add dialog keeps transport details out of the user flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedSubscriptionsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: FeedSubscriptionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('添加订阅'));
    await tester.pumpAndSettle();

    expect(find.text('添加订阅'), findsOneWidget);
    expect(find.text('订阅地址'), findsOneWidget);
    expect(find.text('系统会自动识别订阅格式'), findsOneWidget);
    expect(find.text('RSS 2.0'), findsNothing);
    expect(find.text('来源标识（可选）'), findsNothing);
  });

  testWidgets(
    'narrow layout keeps subscription actions visible without overflow',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedSubscriptionsProvider.overrideWith(
              (ref) async => [subscription],
            ),
          ],
          child: MediaQuery(
            data: const MediaQueryData(size: Size(320, 640)),
            child: const MaterialApp(home: FeedSubscriptionsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('刷新'), findsOneWidget);
      expect(find.byTooltip('删除'), findsOneWidget);
    },
  );

  testWidgets('article opens the existing Reader surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RemoteFeedArticleReaderPage(
          subscription: subscription,
          article: subscription.articles.single,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    // Reader正文由自定义 RenderObject 绘制，不会在测试树中暴露为
    // Text widget；验证实际 Reader surface 和其标题已挂载即可。
    expect(find.byType(ReaderPage), findsOneWidget);
    expect(find.text('第一篇文章'), findsOneWidget);
  });
}
