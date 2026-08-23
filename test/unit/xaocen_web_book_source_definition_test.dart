import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/web_book_runtime.dart';
import 'package:xaocen_reader/sources/remote/xaocen_web_book_source_definition.dart';

Map<String, Object?> _suduguFixture(Uri endpoint) => <String, Object?>{
  'schema': XaocenWebBookSourceDefinition.schema,
  'version': XaocenWebBookSourceDefinition.schemaVersion,
  'sourceId': 'fixture-sudugu-qingshan',
  'name': '速读谷 · 青山',
  'endpoint': endpoint.toString(),
  'searchEndpoint': null,
  'bookKey': '5',
  'ruleVersion': 1,
  'rules': <String, Object?>{
    'search': <String, Object?>{
      'itemSelector': '#search article.book',
      'title': <String, Object?>{'selector': '.title'},
      'author': <String, Object?>{'selector': '.author', 'removePrefix': '作者：'},
      'linkSelector': '.title',
      'keyAttribute': 'data-book-key',
    },
    'detail': <String, Object?>{
      'selector': '.container',
      'title': <String, Object?>{'selector': 'h1 a'},
      'author': <String, Object?>{
        'selector': 'a[href*="/zuozhe/"]',
        'removePrefix': '作者：',
      },
      'description': <String, Object?>{'selector': '.des'},
      'keyAttribute': 'data-book-key',
    },
    'toc': <String, Object?>{
      'entrySelector': r'#list.dir a[href$=".html"]',
      'title': <String, Object?>{},
      'keyAttribute': 'data-chapter-key',
      'hrefAttribute': 'href',
    },
    'chapter': <String, Object?>{'bodySelector': '.con'},
  },
};

void main() {
  test('validates, round-trips and maps a Sudugu-shaped definition', () {
    final definition = XaocenWebBookSourceDefinition.fromJson(
      _suduguFixture(Uri.parse('https://fixture.invalid/books/qingshan/')),
    );

    expect(definition.sourceId, 'fixture-sudugu-qingshan');
    expect(definition.name, '速读谷 · 青山');
    expect(definition.ruleVersion, 1);
    expect(definition.toSource().bookKey, '5');
    expect(definition.toSource().ruleSetId, 'fixture-sudugu-qingshan-v1');
    expect(definition.toExtractionRules().version, 1);
    expect(definition.rules.detailSelector, '.container');
    expect(definition.rules.tocEntrySelector, r'#list.dir a[href$=".html"]');

    final encoded = definition.toJsonString();
    final decoded = XaocenWebBookSourceDefinition.fromJsonString(encoded);
    expect(decoded.toJson(), definition.toJson());
    expect(
      XaocenWebBookSourceDefinition.canDecode(jsonDecode(encoded)),
      isTrue,
    );
  });

  test('rejects unsupported schema, unsafe URI and XPath rules', () {
    final fixture = _suduguFixture(
      Uri.parse('https://fixture.invalid/books/qingshan/'),
    );
    expect(
      () => XaocenWebBookSourceDefinition.fromJson({
        ...fixture,
        'schema': 'legado-json',
      }),
      throwsFormatException,
    );
    expect(
      () => XaocenWebBookSourceDefinition.fromJson({
        ...fixture,
        'endpoint': 'file:///tmp/book',
      }),
      throwsFormatException,
    );
    final rules = Map<String, Object?>.from(fixture['rules']! as Map);
    final chapter = Map<String, Object?>.from(rules['chapter']! as Map);
    chapter['bodySelector'] = '//article';
    rules['chapter'] = chapter;
    expect(
      () =>
          XaocenWebBookSourceDefinition.fromJson({...fixture, 'rules': rules}),
      throwsFormatException,
    );
  });

  test('definition rules drive the existing WebBook runtime', () async {
    late HttpServer server;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final base = Uri.parse('http://${server.address.host}:${server.port}');
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
        ..write('''
          <div class="container" data-book-key="5">
            <h1><a>青山</a></h1>
            <a href="/zuozhe/1">作者：会说话的肘子</a>
            <p class="des">青山简介</p>
            <nav id="list" class="dir">
              <a data-chapter-key="c-1" href="/5/1.html">第1章</a>
              <a data-chapter-key="c-2" href="/5/2.html">第2章</a>
            </nav>
          </div>
          <article class="con"><p>第一章正文。</p></article>
        ''');
      await request.response.close();
    });
    final definition = XaocenWebBookSourceDefinition.fromJson(
      _suduguFixture(base.resolve('/5/')),
    );
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);
    final runtime = WebBookHttpRuntime(
      transport: transport,
      rules: definition.toExtractionRules(),
    );
    final detail = await runtime.openDetail(
      source: definition.toSource(),
      result: WebBookSearchResult(
        bookKey: definition.bookKey,
        title: '青山',
        detailUri: definition.endpoint,
      ),
    );
    final toc = await runtime.loadTableOfContents(
      source: definition.toSource(),
      detail: detail,
    );
    expect(detail.title, '青山');
    expect(detail.author, '会说话的肘子');
    expect(toc.entries.map((entry) => entry.chapterKey), ['c-1', 'c-2']);
  });
}
