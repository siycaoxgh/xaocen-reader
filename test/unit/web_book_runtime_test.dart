import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/content_transform.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/web_book_runtime.dart';
import 'package:xaocen_reader/sources/remote/web_book_rule_engine.dart';

void main() {
  late HttpServer server;
  late Uri base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://${server.address.host}:${server.port}');
  });

  tearDown(() => server.close(force: true));

  WebBookSource source() => WebBookSource(
    id: RemoteSourceId('fixture-book-source'),
    endpoint: base.resolve('/search'),
    bookKey: 'book-001',
    ruleSetId: 'generic-book-html-v1',
    requestCapabilities: const RemoteRequestCapabilities(
      timeout: Duration(seconds: 2),
    ),
  );

  test('runs search → detail → TOC → chapter → ReaderContent', () async {
    server.listen((request) async {
      switch (request.uri.path) {
        case '/search':
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType(
              'text',
              'html',
              charset: 'utf-8',
            )
            ..write('''
              <a data-book-key="book-001" data-author="作者甲" href="/book/001">测试小说</a>
              <a data-book-key="book-002" href="/book/002">另一部小说</a>
            ''');
        case '/book/001':
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType(
              'text',
              'html',
              charset: 'utf-8',
            )
            ..write('''
              <article data-book-key="book-001" data-title="测试小说">
                <h1>测试小说</h1>
                <meta name="author" content="作者甲">
                <meta name="description" content="一本用于验证的小说">
                <p class="description">简介补充。</p>
                <nav>
                  <a data-chapter-key="chapter-002" href="/book/001/ch2">第二章</a>
                  <a data-chapter-key="chapter-001" href="/book/001/ch1">第一章</a>
                </nav>
              </article>
            ''');
        case '/book/001/ch1':
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType(
              'text',
              'html',
              charset: 'utf-8',
            )
            ..write('''
              <article class="chapter-content">
                <h1>第一章</h1><p>第一章正文 &amp; 其他内容。</p>
                <script>不应进入正文</script>
              </article>
            ''');
        case '/book/001/ch2':
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType(
              'text',
              'html',
              charset: 'utf-8',
            )
            ..write('''
              <article class="chapter-content">
                <h1>第二章</h1><p>第二章正文。</p>
              </article>
            ''');
        default:
          request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);
    final runtime = WebBookHttpRuntime(transport: transport);
    final bookSource = source();

    final results = await runtime.search(
      source: bookSource,
      request: const WebBookSearchRequest(query: '测试小说'),
    );
    final detail = await runtime.openDetail(
      source: bookSource,
      result: results.first,
    );
    final toc = await runtime.loadTableOfContents(
      source: bookSource,
      detail: detail,
    );
    final chapters = <WebBookChapter>[
      for (final entry in toc.entries)
        await runtime.openChapter(
          source: bookSource,
          detail: detail,
          entry: entry,
        ),
    ];
    final projection = runtime.toReaderContent(
      source: bookSource,
      detail: detail,
      chapters: chapters,
    );

    expect(results.map((result) => result.bookKey), ['book-001', 'book-002']);
    expect(detail.bookKey, 'book-001');
    expect(detail.title, '测试小说');
    expect(detail.author, '作者甲');
    expect(detail.description, '一本用于验证的小说');
    expect(toc.entries.map((entry) => entry.chapterKey), [
      'chapter-002',
      'chapter-001',
    ]);
    expect(toc.entries.map((entry) => entry.orderIndex), [0, 1]);
    expect(chapters.first.body.canonical.text, contains('第二章正文。'));
    expect(chapters.last.body.canonical.text, contains('第一章正文 & 其他内容。'));
    expect(chapters.last.body.canonical.text, isNot(contains('<script>')));
    expect(projection.content.identity.sourceKind, 'online');
    expect(projection.content.metadata.title, '测试小说');
    expect(projection.content.navigation.map((entry) => entry.title), [
      '第二章',
      '第一章',
    ]);
    expect(projection.content.documents.first.startCharacterOffset, 0);
    expect(
      projection.content.documents.last.endCharacterOffset,
      projection.content.normalizedCharacterLength,
    );
    expect(projection.documentTextById, hasLength(2));
    expect(
      chapters.first.body
          .derive(const IdentityContentTransform())
          .canPersistCanonicalLocator,
      isTrue,
    );
  });

  test('safe search result reports HTTP failures without throwing', () async {
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write('temporarily unavailable');
      await request.response.close();
    });
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);
    final outcome = await WebBookHttpRuntime(transport: transport).trySearch(
      source: source(),
      request: const WebBookSearchRequest(query: '任何书'),
    );

    expect(outcome.isSuccess, isFalse);
    expect(outcome.failure!.kind, WebBookFailureKind.http);
    expect(outcome.failure!.statusCode, HttpStatus.serviceUnavailable);
  });

  test('safe chapter result distinguishes an empty chapter body', () async {
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
        ..write(
          '<article class="chapter-content"><script>only js</script></article>',
        );
      await request.response.close();
    });
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);
    final bookSource = source();
    final detail = WebBookDetail(
      bookKey: bookSource.bookKey,
      title: '测试小说',
      detailUri: bookSource.endpoint,
    );
    final entry = WebBookTocEntry(
      chapterKey: 'chapter-empty',
      title: '空章节',
      orderIndex: 0,
      chapterUri: bookSource.endpoint,
    );
    final outcome = await WebBookHttpRuntime(
      transport: transport,
    ).tryOpenChapter(source: bookSource, detail: detail, entry: entry);

    expect(outcome.isSuccess, isFalse);
    expect(outcome.failure!.kind, WebBookFailureKind.emptyChapter);
    expect(outcome.failure!.message, '章节未提供可读正文');
  });

  test(
    'maps configured search query parameter and rejects empty query',
    () async {
      final queries = <Map<String, String>>[];
      server.listen((request) async {
        queries.add(request.uri.queryParameters);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
          ..write(
            '<a data-book-key="1" href="/book">${request.uri.queryParameters.values.first}</a>',
          );
        await request.response.close();
      });
      final transport = RemoteHttpTransport();
      addTearDown(transport.close);
      final configured = WebBookSource(
        id: RemoteSourceId('sudugu-fixture'),
        endpoint: base.resolve('/book'),
        searchEndpoint: base.resolve('/search?key=固定值'),
        searchQueryParameter: 'key',
        bookKey: '1',
        ruleSetId: 'fixture',
      );
      final runtime = WebBookHttpRuntime(transport: transport);
      await runtime.search(
        source: configured,
        request: const WebBookSearchRequest(query: '青山'),
      );
      await runtime.search(
        source: configured,
        request: const WebBookSearchRequest(query: '其他关键词'),
      );
      expect(queries, [
        {'key': '青山'},
        {'key': '其他关键词'},
      ]);
      final empty = await runtime.trySearch(
        source: configured,
        request: const WebBookSearchRequest(query: '  '),
      );
      expect(empty.isSuccess, isFalse);
      expect(empty.failure!.kind, WebBookFailureKind.emptySearch);
      expect(queries, hasLength(2));
    },
  );

  test('merges same-chapter pages with bounds and origin checks', () async {
    final requested = <String>[];
    server.listen((request) async {
      requested.add(request.uri.path);
      final html = switch (request.uri.path) {
        '/chapter/20.html' =>
          '<div id="body">第一页</div><a class="next-page" href="20-2.html">下一页</a><a class="next-chapter" href="/chapter/21.html">下一章</a>',
        '/chapter/20-2.html' =>
          '<div id="body">第二页</div><a class="next-page" href="20-3.html">下一页</a>',
        '/chapter/20-3.html' => '<div id="body">第三页</div>',
        _ => '<div id="body">下一章正文</div>',
      };
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
        ..write(html);
      await request.response.close();
    });
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);
    final sourceWithPages = WebBookSource(
      id: RemoteSourceId('paged-fixture'),
      endpoint: base.resolve('/book'),
      bookKey: 'book',
      ruleSetId: 'paged',
    );
    final runtime = WebBookHttpRuntime(
      transport: transport,
      rules: WebBookExtractionRules(
        id: 'paged',
        cssRuleSet: const WebBookCssRuleSet(
          id: 'paged',
          searchItemSelector: 'a',
          searchTitle: WebBookFieldSelector.text(),
          detailSelector: 'body',
          detailTitle: WebBookFieldSelector.text(),
          tocEntrySelector: 'a',
          tocTitle: WebBookFieldSelector.text(),
          chapterBodySelector: '#body',
          chapterNextPageSelector: 'a.next-page',
        ),
      ),
    );
    final detail = WebBookDetail(
      bookKey: 'book',
      title: '分页章节',
      detailUri: sourceWithPages.endpoint,
    );
    final chapter = await runtime.openChapter(
      source: sourceWithPages,
      detail: detail,
      entry: WebBookTocEntry(
        chapterKey: '20',
        title: '第二十章',
        orderIndex: 0,
        chapterUri: base.resolve('/chapter/20.html'),
      ),
    );
    expect(chapter.body.canonical.text, '第一页\n\n第二页\n\n第三页');
    expect(requested, [
      '/chapter/20.html',
      '/chapter/20-2.html',
      '/chapter/20-3.html',
    ]);
    expect(requested, isNot(contains('/chapter/21.html')));

    final bounded = WebBookHttpRuntime(
      transport: transport,
      rules: WebBookExtractionRules(
        id: 'paged-bounded',
        maxChapterPages: 2,
        cssRuleSet: const WebBookCssRuleSet(
          id: 'paged-bounded',
          searchItemSelector: 'a',
          searchTitle: WebBookFieldSelector.text(),
          detailSelector: 'body',
          detailTitle: WebBookFieldSelector.text(),
          tocEntrySelector: 'a',
          tocTitle: WebBookFieldSelector.text(),
          chapterBodySelector: '#body',
          chapterNextPageSelector: 'a.next-page',
        ),
      ),
    );
    final boundedOutcome = await bounded.tryOpenChapter(
      source: sourceWithPages,
      detail: detail,
      entry: WebBookTocEntry(
        chapterKey: '20',
        title: '第二十章',
        orderIndex: 0,
        chapterUri: base.resolve('/chapter/20.html'),
      ),
    );
    expect(boundedOutcome.isSuccess, isFalse);
    expect(boundedOutcome.failure!.message, contains('最大页数'));
  });
}
