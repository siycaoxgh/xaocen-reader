import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/sources/remote/legacy_source_pack_converter.dart';
import 'package:xaocen_reader/sources/remote/xaocen_source_pack.dart';

Map<String, Object?> _record({bool withOptional = false}) =>
    <String, Object?>{
      'bookSourceName': 'Source Pack fixture',
      'bookSourceUrl': 'https://fixture.test/books/',
      'bookSourceType': 0,
      'searchUrl': '/search?keyword={{key}}',
      'ruleSearch': <String, Object?>{
        'bookList': 'article.book',
        'name': 'a.title@text',
        'author': '.author@text',
        'bookUrl': 'a.title@href',
        if (withOptional) 'coverUrl': 'img@src',
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
  const converter = LegacySourcePackConverter();

  test('optional legacy fields produce a runnable partial draft', () {
    final result = converter.convertRecord(
      _record(withOptional: true),
      sourceFile: 'fixture.json',
    );

    expect(result.compatibility, LegacyCompatibilityLevel.runnablePartial);
    expect(result.definition, isNotNull);
    expect(result.legacyFields['ruleSearch.coverUrl'], 'img@src');
    expect(result.definition!.searchQueryParameter, 'keyword');
  });

  test('a source with only supported fields is FULL', () {
    final result = converter.convertRecord(
      _record(),
      sourceFile: 'fixture.json',
    );

    expect(result.compatibility, LegacyCompatibilityLevel.full);
    expect(result.legacyFields, isEmpty);
    expect(result.definition, isNotNull);
  });

  test('source pack holds multiple entries and round trips', () {
    final full = converter.convertRecord(_record(), sourceFile: 'a.json');
    final partial = converter.convertRecord(
      _record(withOptional: true),
      sourceFile: 'b.json',
    );
    final pack = XaocenWebBookSourcePack(
      packId: 'pack-test-v1',
      name: '测试包',
      sources: <XaocenSourcePackEntry>[
        full.toPackEntry(),
        partial.toPackEntry(),
      ],
    );

    final decoded = XaocenWebBookSourcePack.fromJsonString(
      pack.toJsonString(),
    );
    expect(decoded.sources, hasLength(2));
    expect(decoded.sources.first.legacySourceId, startsWith('legado:'));
    expect(
      decoded.sources.map((source) => source.compatibility),
      containsAll(<LegacyCompatibilityLevel>[
        LegacyCompatibilityLevel.full,
        LegacyCompatibilityLevel.runnablePartial,
      ]),
    );
    expect(decoded.sources.last.legacyFields, contains('ruleSearch.coverUrl'));
  });

  test('pack rejects duplicate source identities', () {
    final result = converter.convertRecord(_record(), sourceFile: 'a.json');
    final entry = result.toPackEntry().toJson();
    final json = <String, Object?>{
      'schema': XaocenWebBookSourcePack.schema,
      'version': XaocenWebBookSourcePack.schemaVersion,
      'packId': 'duplicate-test',
      'name': 'duplicate',
      'sources': <Object?>[entry, entry],
    };

    expect(
      () => XaocenWebBookSourcePack.fromJson(json),
      throwsFormatException,
    );
  });
}
