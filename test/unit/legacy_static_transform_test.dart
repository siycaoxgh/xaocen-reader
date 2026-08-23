import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xaocen_reader/sources/remote/legacy_static_transform.dart';
import 'package:xaocen_reader/sources/remote/legacy_static_text_converter.dart';
import 'package:xaocen_reader/sources/remote/web_book_rule_engine.dart';
import 'package:xaocen_reader/sources/remote/xaocen_web_book_source_definition.dart';

Map<String, Object?> _record({String name = 'a.title@text##书名：'}) =>
    <String, Object?>{
      'bookSourceName': '静态变换 fixture',
      'bookSourceUrl': 'https://fixture.test/books/',
      'bookSourceType': 0,
      'searchUrl': '/search?q={{key}}',
      'ruleSearch': <String, Object?>{
        'bookList': 'article.book',
        'name': name,
        'bookUrl': 'a.title@href',
      },
      'ruleBookInfo': <String, Object?>{'name': 'h1@text'},
      'ruleToc': <String, Object?>{
        'chapterList': 'a.chapter',
        'chapterName': '@text',
        'chapterUrl': '@href',
      },
      'ruleContent': <String, Object?>{'content': '#content@html'},
    };

void main() {
  test('maps a literal prefix removal without executing regex', () {
    final result = LegacyStaticTransform.parse('class.book@tag.a@text##书名：');

    expect(result.selector, '.book a');
    expect(result.attribute, isNull);
    expect(result.removePrefix, '书名：');
    expect(result.fallbackSelectors, isEmpty);
  });

  test(
    'maps ordered fallback selectors and the runtime uses the first match',
    () {
      final result = LegacyStaticTransform.parse(
        'a.primary@text||h2.title@text',
      );
      expect(result.selector, 'a.primary');
      expect(result.fallbackSelectors, ['h2.title']);

      final root = html_parser.parse('<h2 class="title">备用标题</h2>').body!;
      final field = WebBookFieldSelector(
        selector: result.selector,
        fallbackSelectors: result.fallbackSelectors,
      );
      expect(field.read(root), '备用标题');
    },
  );

  test('rejects regex replacement and mismatched alternatives', () {
    expect(
      () => LegacyStaticTransform.parse('.title@text##<.*?>'),
      throwsA(isA<LegacyStaticTransformException>()),
    );
    expect(
      () => LegacyStaticTransform.parse('.a@text||.b@href'),
      throwsA(isA<LegacyStaticTransformException>()),
    );
    expect(
      () => LegacyStaticTransform.parse('.a@text##x##y'),
      throwsA(isA<LegacyStaticTransformException>()),
    );
  });

  test('converted prefix and fallback survive XAOCEN JSON round trip', () {
    final record = _record(name: 'a.primary@text||h2.title@text');
    final result = const LegacyStaticTextConverter().convertRecord(record);
    expect(result.outcome, LegacyStaticTextConversionOutcome.converted);
    final definition = result.definition!;
    expect(definition.rules.searchTitle.fallbackSelectors, ['h2.title']);

    final decoded = XaocenWebBookSourceDefinition.fromJson(definition.toJson());
    expect(decoded.rules.searchTitle.fallbackSelectors, ['h2.title']);
    expect(decoded.toJson(), definition.toJson());
  });

  test('top-level selector alternatives stay manual instead of guessing', () {
    final record = _record();
    final search = Map<String, Object?>.from(record['ruleSearch']! as Map);
    search['bookList'] = 'article.book||section.book';
    record['ruleSearch'] = search;
    final result = const LegacyStaticTextConverter().convertRecord(record);
    expect(result.outcome, LegacyStaticTextConversionOutcome.manualReview);
    expect(result.reasons.single, contains('ruleSearch.bookList'));
  });
}
