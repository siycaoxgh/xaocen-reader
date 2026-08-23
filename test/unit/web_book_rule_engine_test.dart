import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/web_book_rule_engine.dart';
import 'package:xaocen_reader/sources/remote/web_book_runtime.dart';

void main() {
  late HttpServer server;
  late Uri base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://${server.address.host}:${server.port}');
  });

  tearDown(() => server.close(force: true));

  test(
    'CSS selectors drive search, detail, TOC, chapter and projection',
    () async {
      server.listen((request) async {
        switch (request.uri.path) {
          case '/search':
            expect(request.uri.queryParameters['q'], '目标书');
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType(
                'text',
                'html',
                charset: 'utf-8',
              )
              ..write('''
              <section id="results">
                <article class="book" data-book-id="book-css-1">
                  <a class="title" href="/book/1">目标书</a>
                  <span class="author">作者甲</span>
                </article>
              </section>
            ''');
          case '/book/1':
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType(
                'text',
                'html',
                charset: 'utf-8',
              )
              ..write('''
              <main id="book">
                <h1 class="name">目标书</h1>
                <p class="author">作者甲</p>
                <p class="description">一本规则引擎测试书。</p>
                <nav id="toc">
                  <a class="chapter" data-chapter="c-2" href="/book/1/2">第二章</a>
                  <a class="chapter" data-chapter="c-1" href="/book/1/1">第一章</a>
                </nav>
              </main>
            ''');
          case '/book/1/1':
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType(
                'text',
                'html',
                charset: 'utf-8',
              )
              ..write('<article id="content"><p>第一章正文。</p></article>');
          case '/book/1/2':
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType(
                'text',
                'html',
                charset: 'utf-8',
              )
              ..write('<article id="content"><p>第二章正文。</p></article>');
          default:
            request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });

      final source = WebBookSource(
        id: RemoteSourceId('css-rule-fixture'),
        endpoint: base.resolve('/book/1'),
        searchEndpoint: base.resolve('/search'),
        bookKey: 'book-css-1',
        ruleSetId: 'css-fixture-v1',
        requestCapabilities: const RemoteRequestCapabilities(
          timeout: Duration(seconds: 2),
        ),
      );
      final rules = WebBookExtractionRules(
        id: 'css-fixture-v1',
        cssRuleSet: WebBookCssRuleSet(
          id: 'css-fixture-v1',
          searchItemSelector: '#results article.book',
          searchTitle: const WebBookFieldSelector(selector: '.title'),
          searchAuthor: const WebBookFieldSelector(selector: '.author'),
          searchLinkSelector: '.title',
          searchBookKeyAttribute: 'data-book-id',
          detailSelector: '#book',
          detailTitle: const WebBookFieldSelector(selector: '.name'),
          detailAuthor: const WebBookFieldSelector(selector: '.author'),
          detailDescription: const WebBookFieldSelector(
            selector: '.description',
          ),
          tocEntrySelector: '#toc a.chapter',
          tocTitle: const WebBookFieldSelector.text(),
          chapterKeyAttribute: 'data-chapter',
          chapterBodySelector: '#content',
        ),
      );
      final transport = RemoteHttpTransport();
      addTearDown(transport.close);
      final runtime = WebBookHttpRuntime(transport: transport, rules: rules);

      final search = await runtime.search(
        source: source,
        request: const WebBookSearchRequest(query: '目标书'),
      );
      final detail = await runtime.openDetail(
        source: source,
        result: search.single,
      );
      final toc = await runtime.loadTableOfContents(
        source: source,
        detail: detail,
      );
      final chapters = [
        for (final entry in toc.entries)
          await runtime.openChapter(
            source: source,
            detail: detail,
            entry: entry,
          ),
      ];
      final projection = runtime.toReaderContent(
        source: source,
        detail: detail,
        chapters: chapters,
      );

      expect(search.single.bookKey, 'book-css-1');
      expect(search.single.detailUri, base.resolve('/book/1'));
      expect(detail.title, '目标书');
      expect(detail.author, '作者甲');
      expect(detail.description, '一本规则引擎测试书。');
      expect(toc.entries.map((entry) => entry.chapterKey), ['c-2', 'c-1']);
      expect(projection.content.navigation.map((entry) => entry.title), [
        '第二章',
        '第一章',
      ]);
      expect(projection.content.normalizedCharacterLength, greaterThan(0));
    },
  );
}
