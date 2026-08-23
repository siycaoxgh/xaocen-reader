import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/web_book_runtime.dart';
import 'package:xaocen_reader/sources/remote/xaocen_web_book_source_definition.dart';

void main() {
  final enabled = const String.fromEnvironment('XAOCEN_SUDUGU_POC') == '1';

  test(
    'runs the Sudugu Qing Shan detail → TOC → chapter → ReaderContent POC',
    () async {
      final endpoint = const String.fromEnvironment('XAOCEN_LIVE_SOURCE_URL');
      if (endpoint.isEmpty) {
        fail('Set XAOCEN_LIVE_SOURCE_URL locally for live network POC');
      }
      final detailUri = Uri.parse(endpoint);
      final definition = XaocenWebBookSourceDefinition.fromJson({
        'schema': XaocenWebBookSourceDefinition.schema,
        'version': XaocenWebBookSourceDefinition.schemaVersion,
        'sourceId': 'poc-sudugu-qingshan',
        'name': '速读谷 · 青山',
        'endpoint': detailUri.toString(),
        'searchEndpoint': null,
        'bookKey': '5',
        'ruleVersion': 1,
        'rules': <String, Object?>{
          'search': <String, Object?>{
            'itemSelector': '#unused-search-result',
            'title': <String, Object?>{},
          },
          'detail': <String, Object?>{
            'selector': '.container',
            'title': <String, Object?>{'selector': 'h1 a'},
            'author': <String, Object?>{
              'selector': 'a[href*="/zuozhe/"]',
              'removePrefix': '作者：',
            },
            'description': <String, Object?>{'selector': '.des'},
          },
          'toc': <String, Object?>{
            'entrySelector': r'#list.dir a[href$=".html"]',
          },
          'chapter': <String, Object?>{'bodySelector': '.con'},
        },
      });
      final source = definition.toSource();
      final rules = definition.toExtractionRules();

      final transport = RemoteHttpTransport();
      addTearDown(transport.close);
      final runtime = WebBookHttpRuntime(transport: transport, rules: rules);
      final result = WebBookSearchResult(
        bookKey: source.bookKey,
        title: '青山',
        detailUri: detailUri,
      );
      final detail = await runtime.openDetail(source: source, result: result);
      final toc = await runtime.loadTableOfContents(
        source: source,
        detail: detail,
      );

      expect(detail.bookKey, source.bookKey);
      expect(detail.title, '青山');
      expect(detail.author, '会说话的肘子');
      expect(detail.description, contains('青山'));
      expect(toc.entries.length, greaterThan(700));
      expect(toc.entries.first.title, '第1章 归零');
      expect(toc.entries.first.orderIndex, 0);

      final latestIndex = toc.entries.indexWhere(
        (entry) => entry.title.contains('第781章 消息有误'),
      );
      expect(latestIndex, greaterThan(0));
      expect(toc.entries[latestIndex].orderIndex, latestIndex);

      final middleIndex = toc.entries.length ~/ 2;
      final selected = <WebBookTocEntry>[
        toc.entries.first,
        toc.entries[middleIndex],
        toc.entries[latestIndex],
      ];
      final chapters = <WebBookChapter>[
        for (final entry in selected)
          await runtime.openChapter(
            source: source,
            detail: detail,
            entry: entry,
          ),
      ];
      expect(chapters.map((chapter) => chapter.entry.orderIndex), [
        0,
        middleIndex,
        latestIndex,
      ]);
      expect(
        chapters.every((chapter) => chapter.body.canonical.text.isNotEmpty),
        isTrue,
      );
      expect(chapters.first.body.canonical.text, contains('洛城'));
      expect(chapters.first.body.canonical.text, isNot(contains('<p>')));

      final projection = runtime.toReaderContent(
        source: source,
        detail: detail,
        chapters: chapters,
      );
      expect(projection.content.metadata.title, '青山');
      expect(projection.content.metadata.author, '会说话的肘子');
      // ReaderContent receives the selected chapters in source order and
      // assigns its own contiguous navigation indexes for that projection.
      expect(projection.content.navigation.map((entry) => entry.orderIndex), [
        0,
        1,
        2,
      ]);
      expect(projection.content.documents, isNotEmpty);
      expect(
        projection.content.documents.last.endCharacterOffset,
        projection.content.normalizedCharacterLength,
      );
    },
    skip: !enabled ? 'Set XAOCEN_SUDUGU_POC=1 for live network POC' : false,
  );
}
