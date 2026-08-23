import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/app/web_book_page.dart';
import 'package:xaocen_reader/data/repositories/web_book_source_registry.dart';
import 'package:xaocen_reader/sources/remote/xaocen_web_book_source_definition.dart';

XaocenWebBookSourceDefinition _definition() {
  return XaocenWebBookSourceDefinition.fromJson({
    'schema': XaocenWebBookSourceDefinition.schema,
    'version': XaocenWebBookSourceDefinition.schemaVersion,
    'sourceId': 'fixture-source',
    'name': '测试书源',
    'endpoint': 'https://example.com/book',
    'searchEndpoint': 'https://example.com/search',
    'bookKey': 'book-1',
    'ruleVersion': 1,
    'rules': <String, Object?>{
      'search': <String, Object?>{
        'itemSelector': '.book',
        'title': <String, Object?>{},
      },
      'detail': <String, Object?>{
        'selector': '.detail',
        'title': <String, Object?>{},
      },
      'toc': <String, Object?>{'entrySelector': '.toc a'},
      'chapter': <String, Object?>{'bodySelector': '.chapter'},
    },
  });
}

void main() {
  testWidgets(
    'source registry and search entry remain usable on narrow screens',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            webBookSourceEntriesProvider.overrideWith(
              (ref) async => [
                WebBookSourceRegistryEntry(
                  definition: _definition(),
                  enabled: true,
                ),
              ],
            ),
          ],
          child: const MediaQuery(
            data: MediaQueryData(size: Size(320, 640)),
            child: MaterialApp(home: WebBookPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('书源管理'), findsOneWidget);
      expect(find.text('测试书源'), findsOneWidget);
      expect(find.text('搜索在线书籍'), findsOneWidget);
      expect(find.text('搜索'), findsOneWidget);
    },
  );
}
