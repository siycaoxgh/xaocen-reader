import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/sources/remote/legacy_static_text_converter.dart';
import 'package:xaocen_reader/sources/remote/legacy_source_capability_scanner.dart';
import 'package:xaocen_reader/sources/remote/web_book_rule_engine.dart';

Map<String, Object?> _record({String searchUrl = '/search?keyword={{key}}'}) =>
    <String, Object?>{
      'bookSourceName': '离线静态源',
      'bookSourceUrl': 'https://fixture.test/books/',
      'bookSourceType': 0,
      'searchUrl': searchUrl,
      'ruleSearch': <String, Object?>{
        'bookList': 'article.book',
        'name': 'a.title@text',
        'author': '.author@text',
        'bookUrl': 'a.title@href',
      },
      'ruleBookInfo': <String, Object?>{
        'name': 'h1@text',
        'author': '.author@text',
        'intro': '.intro@html',
      },
      'ruleToc': <String, Object?>{
        'chapterList': 'a.chapter',
        'chapterName': '@text',
        'chapterUrl': '@href',
      },
      'ruleContent': <String, Object?>{'content': '#content@html'},
    };

void main() {
  const converter = LegacyStaticTextConverter();

  test('converts a safe static source and infers the query parameter', () {
    final result = converter.convertRecord(_record());

    expect(result.outcome, LegacyStaticTextConversionOutcome.converted);
    expect(result.definition, isNotNull);
    final definition = result.definition!;
    expect(definition.sourceId, startsWith('legacy-'));
    expect(definition.searchQueryParameter, 'keyword');
    expect(definition.searchEndpoint.toString(), 'https://fixture.test/search');
    expect(definition.rules.searchItemSelector, 'article.book');
    expect(definition.rules.searchTitle.selector, 'a.title');
    expect(definition.rules.searchLinkSelector, 'a.title');
    expect(definition.rules.chapterBodySelector, '#content');
    expect(definition.toJson()['schema'], 'xaocen.webBook');
  });

  test('converted draft drives the offline search/detail/toc/body chain', () {
    final definition = converter.convertRecord(_record()).definition!;
    final engine = WebBookRuleEngine(definition.rules);
    final source = definition.toSource();
    const html = '''
      <article class="book">
        <a class="title" href="/books/1">目标书</a>
        <span class="author">作者甲</span>
      </article>
      <body>
        <h1>目标书</h1><span class="author">作者甲</span>
        <div class="intro"><p>简介</p></div>
        <a class="chapter" href="/books/1/1">第一章</a>
        <article id="content"><p>正文</p></article>
      </body>
    ''';

    final search = engine.search(
      html: html,
      baseUri: definition.endpoint,
      source: source,
    );
    final detail = engine.detail(html: html);
    final toc = engine.tableOfContents(
      html: html,
      baseUri: definition.endpoint,
      source: source,
    );

    expect(search.single.title, '目标书');
    expect(search.single.author, '作者甲');
    expect(detail?.title, '目标书');
    expect(detail?.description, '简介');
    expect(toc.single.title, '第一章');
    expect(engine.chapterBody(html: html), contains('正文'));
  });

  test('normalizes only the documented class.foo shorthand', () {
    final record = _record();
    final search = Map<String, Object?>.from(record['ruleSearch']! as Map);
    search['bookList'] = 'class.book';
    record['ruleSearch'] = search;

    final result = converter.convertRecord(record);

    expect(result.outcome, LegacyStaticTextConversionOutcome.converted);
    expect(result.definition!.rules.searchItemSelector, '.book');
  });

  test('unsupported loss such as replacement or explore is downgraded', () {
    final record = _record();
    final content = Map<String, Object?>.from(record['ruleContent']! as Map);
    content['replaceRegex'] = '##广告';
    record['ruleContent'] = content;

    final result = converter.convertRecord(record);

    expect(result.outcome, LegacyStaticTextConversionOutcome.manualReview);
    expect(result.definition, isNull);
    expect(result.reasons.single, contains('ruleContent.replaceRegex'));
  });

  test('non-eligible JS source is skipped, never executed or drafted', () {
    final record = _record();
    final content = Map<String, Object?>.from(record['ruleContent']! as Map);
    content['content'] = '@js:java.url()';
    record['ruleContent'] = content;

    final result = converter.convertRecord(record);

    expect(result.outcome, LegacyStaticTextConversionOutcome.skipped);
    expect(result.definition, isNull);
    expect(result.scanDisposition.code, 'UNSUPPORTED');
  });
}
