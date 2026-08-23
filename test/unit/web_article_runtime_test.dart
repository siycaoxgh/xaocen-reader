import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/content_transform.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/web_article_runtime.dart';

void main() {
  late HttpServer server;
  late Uri base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://${server.address.host}:${server.port}');
  });

  tearDown(() => server.close(force: true));

  WebArticleSource sourceFor(String path) {
    final articleUri = base.resolve(path);
    return WebArticleSource(
      id: RemoteSourceId('fixture-article'),
      endpoint: articleUri,
      articleUri: articleUri,
      ruleSetId: 'generic-html-v1',
      requestCapabilities: const RemoteRequestCapabilities(
        timeout: Duration(seconds: 2),
      ),
    );
  }

  WebArticleListItem itemFor(Uri uri) => WebArticleListItem(
    identity: 'fixture-article-1',
    title: '列表标题',
    uri: uri,
    summary: '摘要',
  );

  test(
    'fetches, sanitizes and projects a public-article-shaped HTML page',
    () async {
      server.listen((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
          ..write('''
          <!doctype html>
          <html><head>
            <title>真实文章 &amp; 标题</title>
            <meta name="author" content="作者甲">
            <meta name="description" content="文章摘要">
            <link rel="canonical" href="/canonical/article-1">
          </head><body>
            <article>
              <h1>真实文章 &amp; 标题</h1>
              <p>第一段 <strong>正文</strong>。</p>
              <p>第二段 <a href="https://example.com">相关链接</a>。</p>
              <img src="https://example.com/hero.jpg" alt="示意图">
              <script>不要进入正文</script>
            </article>
          </body></html>
        ''');
        await request.response.close();
      });
      final transport = RemoteHttpTransport();
      addTearDown(transport.close);
      final runtime = WebArticleHttpRuntime(transport: transport);
      final source = sourceFor('/article/1');
      final item = itemFor(source.articleUri);

      final outcome = await runtime.tryFetch(source: source, item: item);

      expect(outcome.isSuccess, isTrue);
      final document = outcome.document!;
      expect(document.item.title, '真实文章 & 标题');
      expect(document.author, '作者甲');
      expect(document.description, '文章摘要');
      expect(document.canonicalUri, base.resolve('/canonical/article-1'));
      expect(document.body.canonical.text, contains('第一段 正文。'));
      expect(
        document.body.canonical.text,
        contains('第二段 相关链接 (https://example.com)。'),
      );
      expect(document.body.canonical.text, contains('[图片：示意图]'));
      expect(document.body.canonical.text, isNot(contains('<script>')));

      final projection = runtime.toReaderContent(
        source: source,
        document: document,
      );
      expect(projection.content.identity.sourceKind, 'online');
      expect(projection.content.metadata.title, '真实文章 & 标题');
      expect(projection.content.documents, hasLength(1));
      expect(projection.content.navigation.single.title, '真实文章 & 标题');
      expect(
        projection.documentTextById.values.single,
        document.body.canonical.text,
      );
      final derived = document.body.derive(const IdentityContentTransform());
      expect(derived.canPersistCanonicalLocator, isTrue);
      expect(derived.text, document.body.canonical.text);
    },
  );

  test('surfaces HTTP failure without throwing from the safe API', () async {
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write('temporarily unavailable');
      await request.response.close();
    });
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);
    final runtime = WebArticleHttpRuntime(transport: transport);
    final source = sourceFor('/unavailable');

    final outcome = await runtime.tryFetch(
      source: source,
      item: itemFor(source.articleUri),
    );

    expect(outcome.isSuccess, isFalse);
    expect(outcome.failure!.kind, WebArticleFailureKind.http);
    expect(outcome.failure!.statusCode, HttpStatus.serviceUnavailable);
    expect(outcome.failure!.message, contains('503'));
  });

  test(
    'reports pages with no readable body as an extraction boundary',
    () async {
      server.listen((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
          ..write('<article><script>only javascript</script></article>');
        await request.response.close();
      });
      final transport = RemoteHttpTransport();
      addTearDown(transport.close);
      final runtime = WebArticleHttpRuntime(transport: transport);
      final source = sourceFor('/empty');

      final outcome = await runtime.tryFetch(
        source: source,
        item: itemFor(source.articleUri),
      );

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure!.kind, WebArticleFailureKind.emptyBody);
      expect(outcome.failure!.message, '文章未提供可读正文');
    },
  );

  test('keeps response charset handling in the shared transport', () async {
    server.listen((request) async {
      final bytes = utf8.encode('<article>中文正文</article>');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
        ..add(bytes);
      await request.response.close();
    });
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);
    final runtime = WebArticleHttpRuntime(transport: transport);
    final source = sourceFor('/charset');
    final document = await runtime.fetch(
      source: source,
      item: itemFor(source.articleUri),
    );

    expect(document.body.canonical.text, '中文正文');
  });
}
