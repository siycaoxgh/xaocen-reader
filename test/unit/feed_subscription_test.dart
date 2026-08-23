import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/data_root.dart';
import 'package:xaocen_reader/data/repositories/feed_subscription_repository.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/sources/remote/feed_subscription_service.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';

void main() {
  late Directory rootDirectory;
  late DataRoot root;
  late HttpServer server;
  late Uri endpoint;
  var responseBody = '';

  setUp(() async {
    rootDirectory = await Directory.systemTemp.createTemp('xaocen-feed-root-');
    root = await DataRoot.forDirectory(rootDirectory, profileId: 'feed_user');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    endpoint = Uri.parse('http://${server.address.host}:${server.port}/feed');
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType(
          'application',
          'rss+xml',
          charset: 'utf-8',
        )
        ..write(responseBody);
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await rootDirectory.delete(recursive: true);
  });

  StandardFeedSource source() => StandardFeedSource(
    id: RemoteSourceId('daily-feed'),
    endpoint: endpoint,
    format: 'rss',
    requestCapabilities: const RemoteRequestCapabilities(
      followRedirects: false,
      timeout: Duration(seconds: 2),
    ),
  );

  String rss({required String firstBody, bool includeSecond = false}) =>
      '<rss version="2.0"><channel><title>每日更新</title>'
      '<description>订阅摘要</description>'
      '<item><guid>article-1</guid><title>第一篇</title>'
      '<description>$firstBody</description></item>'
      '${includeSecond ? '<item><guid>article-2</guid><title>第二篇</title><description>新文章</description></item>' : ''}'
      '</channel></rss>';

  test('adds, persists and removes a profile-scoped subscription', () async {
    final repository = FeedSubscriptionRepository(root);
    final added = await repository.add(source());
    expect(added.sourceId, 'daily-feed');
    expect(added.articles, isEmpty);
    expect(await repository.storageFile.exists(), isTrue);

    final reopened = FeedSubscriptionRepository(
      await DataRoot.forDirectory(rootDirectory, profileId: 'feed_user'),
    );
    expect((await reopened.list()).single.endpoint, endpoint);
    expect(await reopened.remove('daily-feed'), isTrue);
    expect(await reopened.list(), isEmpty);
    expect(await reopened.remove('daily-feed'), isFalse);
  });

  test('manual refresh persists feed metadata and articles', () async {
    responseBody = rss(firstBody: '正文一');
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);
    final service = FeedSubscriptionService(
      repository: FeedSubscriptionRepository(root),
      transport: transport,
    );
    await service.addSubscription(source());

    final refreshed = await service.refresh('daily-feed');
    expect(refreshed.title, '每日更新');
    expect(refreshed.description, '订阅摘要');
    expect(refreshed.lastRefreshedAt, isNotNull);
    expect(refreshed.articles.single.title, '第一篇');
    expect(refreshed.articles.single.body, '正文一');
    expect(refreshed.articles.single.identity, contains('daily-feed'));

    final reopened = FeedSubscriptionRepository(
      await DataRoot.forDirectory(rootDirectory, profileId: 'feed_user'),
    );
    expect((await reopened.list()).single.articles.single.body, '正文一');
  });

  test(
    'refresh updates existing identity without duplicates and adds new items',
    () async {
      responseBody = rss(firstBody: '旧正文');
      final transport = RemoteHttpTransport();
      addTearDown(transport.close);
      final service = FeedSubscriptionService(
        repository: FeedSubscriptionRepository(root),
        transport: transport,
      );
      await service.addSubscription(source());
      final first = await service.refresh('daily-feed');
      final firstSeen = first.articles.single.firstSeenAt;

      responseBody = rss(firstBody: '更新正文', includeSecond: true);
      final second = await service.refresh('daily-feed');
      expect(second.articles, hasLength(2));
      expect(
        second.articles.where(
          (article) => article.identity == first.articles.single.identity,
        ),
        hasLength(1),
      );
      final updated = second.articles.first;
      expect(updated.body, '更新正文');
      expect(updated.firstSeenAt, firstSeen);
      expect(updated.updatedAt.isAfter(firstSeen), isTrue);
    },
  );

  test('subscription storage is isolated by DataRoot/profile', () async {
    final otherDirectory = await Directory.systemTemp.createTemp(
      'xaocen-feed-other-',
    );
    addTearDown(() => otherDirectory.delete(recursive: true));
    final otherRoot = await DataRoot.forDirectory(
      otherDirectory,
      profileId: 'other_user',
    );
    final firstRepository = FeedSubscriptionRepository(root);
    await firstRepository.add(source());
    final otherRepository = FeedSubscriptionRepository(otherRoot);
    await otherRepository.storageFile.parent.create(recursive: true);
    await firstRepository.storageFile.copy(otherRepository.storageFile.path);
    await expectLater(
      otherRepository.list(),
      throwsA(isA<DataRootException>()),
    );
  });
}
