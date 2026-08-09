import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_search.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';

void main() {
  testWidgets('search sheet debounces, highlights and opens exact result', (
    tester,
  ) async {
    ReaderSearchResult? tapped;
    const result = ReaderSearchResult(
      startOffset: 2,
      endOffset: 5,
      contextStartOffset: 0,
      contextEndOffset: 24,
      snippet: '前文关键词后文',
      derivedChapterTitle: '第二章',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showReaderSearch(
                context,
                onQueryChanged: (_) async => const [result],
                onResultTap: (value) async => tapped = value,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '关键词');
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('reader-search-results')), findsOneWidget);
    expect(find.textContaining('第二章'), findsOneWidget);
    expect(find.text('关键词'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reader-search-result-0')));
    await tester.pumpAndSettle();
    expect(tapped, same(result));
  });

  testWidgets('clearing search results does not invoke navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showReaderSearch(
                context,
                onQueryChanged: (_) async => const [],
                onResultTap: (_) async {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'query');
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('无结果'), findsOneWidget);
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pump();
    expect(find.text('输入关键词开始搜索'), findsOneWidget);
  });
}
