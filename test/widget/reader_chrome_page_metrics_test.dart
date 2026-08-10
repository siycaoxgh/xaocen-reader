import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

void main() {
  testWidgets('paged chrome shows chapter page and whole-book progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderChrome(
            visible: true,
            title: 'Book',
            mode: ReaderMode.paged,
            onBack: () {},
            onToc: () {},
            onAppearance: () {},
            onMore: () {},
            onBookmarks: () {},
            onSearch: () {},
            onModeSelected: (_) {},
            currentChapterTitle: 'City Edge',
            currentChapterNumber: 53,
            chapterPageNumber: 7,
            chapterPageCount: 12,
            progressPercent: 0.37,
          ),
        ),
      ),
    );

    expect(find.textContaining('/ 12'), findsOneWidget);
    expect(find.textContaining('37%'), findsOneWidget);
  });
}
