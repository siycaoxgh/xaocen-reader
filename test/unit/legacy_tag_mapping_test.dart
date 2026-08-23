import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/sources/remote/legacy_source_capability_scanner.dart';
import 'package:xaocen_reader/sources/remote/legacy_static_text_converter.dart';
import 'package:xaocen_reader/sources/remote/legacy_tag_mapping.dart';
import 'package:xaocen_reader/sources/remote/web_book_rule_engine.dart';

void main() {
  test('maps safe descendant tags and bounded actions', () {
    final text = LegacyTagMapping.map('class.result@tag.li@tag.a@text');
    expect(text?.selector, '.result li a');
    expect(text?.attribute, isNull);

    final href = LegacyTagMapping.map('class.result@tag.li@tag.a@href');
    expect(href?.selector, '.result li a');
    expect(href?.attribute, 'href');

    final wildcard = LegacyTagMapping.map('@tag.article@tag.*@html');
    expect(wildcard?.selector, 'article *');
    expect(wildcard?.attribute, isNull);
  });

  test('rejects indexes, branches and dynamic actions', () {
    expect(
      () => LegacyTagMapping.map('class.result@tag.li.0@text'),
      throwsA(isA<LegacyTagMappingException>()),
    );
    expect(
      () => LegacyTagMapping.map('class.result@tag.li||.fallback@text'),
      throwsA(isA<LegacyTagMappingException>()),
    );
    expect(
      () => LegacyTagMapping.map('class.result@tag.li@js:run()'),
      throwsA(isA<LegacyTagMappingException>()),
    );
  });

  test('offline fixture converts and evaluates a complete tag-based source', () {
    final record = <String, Object?>{
      'bookSourceName': 'Legacy Tag Fixture',
      'bookSourceUrl': 'https://fixture.invalid/search',
      'searchUrl': 'https://fixture.invalid/search?q={{key}}',
      'ruleSearch': <String, Object?>{
        'bookList': 'class.results@tag.li',
        'name': 'h2@tag.a@text',
        'author': 'span.author@text',
        'bookUrl': 'a@href',
      },
      'ruleBookInfo': <String, Object?>{
        'name': 'header@tag.h1@text',
        'author': 'header@tag.span@text',
        'intro': 'article@tag.p@text',
      },
      'ruleToc': <String, Object?>{
        'chapterList': 'ul.chapters@tag.li',
        'chapterName': 'a@text',
        'chapterUrl': '@href',
      },
      'ruleContent': <String, Object?>{
        'content': 'main@tag.article@html',
      },
    };

    final result = const LegacyStaticTextConverter().convertRecord(record);
    expect(result.outcome, LegacyStaticTextConversionOutcome.converted);
    final definition = result.definition!;
    final source = definition.toSource();
    final engine = WebBookRuleEngine(definition.rules);

    final results = engine.search(
      html: '''<div class="results"><ul><li><h2><a href="/book/1">书一</a></h2><span class="author">作者</span></li></ul></div>''',
      baseUri: Uri.parse('https://fixture.invalid/search'),
      source: source,
    );
    expect(results.single.title, '书一');
    expect(results.single.author, '作者');

    final detail = engine.detail(
      html: '''<header><h1>书一</h1><span>作者</span></header><article><p>简介</p></article>''',
    );
    expect(detail?.title, '书一');
    expect(detail?.description, '简介');

    final toc = engine.tableOfContents(
      html: '''<ul class="chapters"><li href="/book/1/1"><a>第一章</a></li><li href="/book/1/2"><a>第二章</a></li></ul>''',
      baseUri: Uri.parse('https://fixture.invalid/book/1'),
      source: source,
    );
    expect(toc.map((entry) => entry.title), <String>['第一章', '第二章']);
    expect(
      engine.chapterBody(
        html: '<main><article><p>正文一</p><p>正文二</p></article></main>',
      ),
      contains('正文二'),
    );
  });

  test('automatic scanner candidates with tag rules remain eligible', () {
    final scan = const LegacySourceCapabilityScanner().scanRecord(
      <String, Object?>{
        'bookSourceName': 'tag scan',
        'bookSourceUrl': 'https://fixture.invalid',
        'ruleSearch': <String, Object?>{
          'bookList': '.results@tag.li',
          'name': 'h2@tag.a@text',
          'bookUrl': 'a@href',
        },
        'ruleBookInfo': <String, Object?>{'name': 'h1@text'},
        'ruleToc': <String, Object?>{
          'chapterList': 'ul@tag.li',
          'chapterName': 'a@text',
          'chapterUrl': 'a@href',
        },
        'ruleContent': <String, Object?>{'content': 'article@text'},
      },
    );
    expect(scan.disposition, LegacySourceDisposition.automaticallyConvertible);
  });
}
