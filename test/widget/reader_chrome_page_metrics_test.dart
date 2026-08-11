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

    expect(find.text('第53章  City Edge'), findsOneWidget);
    expect(find.text('本章 7 / 12 页'), findsOneWidget);
    expect(find.text('全书 37%'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderChrome(
            visible: true,
            title: 'Book',
            mode: ReaderMode.vertical,
            onBack: () {},
            onToc: () {},
            onAppearance: () {},
            onMore: () {},
            onBookmarks: () {},
            onSearch: () {},
            onModeSelected: (_) {},
            currentChapterTitle: 'City Edge',
            currentChapterNumber: 53,
            chapterProgressPercent: 0.68,
            progressPercent: 0.37,
          ),
        ),
      ),
    );
    expect(find.text('第53章  City Edge'), findsOneWidget);
    expect(find.text('本章 68%'), findsOneWidget);
    expect(find.text('全书 37%'), findsOneWidget);

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
            currentChapterTitle: '全文',
            progressPercent: 0.37,
          ),
        ),
      ),
    );
    expect(find.text('全文'), findsOneWidget);
    expect(find.text('全书 37%'), findsOneWidget);
    expect(find.textContaining('本章'), findsNothing);
  });

  testWidgets('hidden chrome shows the minimal vertical information layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderChrome(
            visible: false,
            title: 'Book',
            mode: ReaderMode.vertical,
            onBack: () {},
            onToc: () {},
            onAppearance: () {},
            onMore: () {},
            onBookmarks: () {},
            onSearch: () {},
            onModeSelected: (_) {},
            currentChapterTitle: 'City Edge',
            currentChapterNumber: 53,
            chapterProgressPercent: 0.68,
            progressPercent: 0.37,
          ),
        ),
      ),
    );

    expect(find.text('第 53 章  City Edge'), findsOneWidget);
    expect(find.text('本章 68%'), findsNWidgets(2));
    expect(find.text('全书 37%'), findsNWidgets(2));
  });

  testWidgets('hidden chrome paged layer uses chapter page metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderChrome(
            visible: false,
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

    expect(find.text('本章 7 / 12 页'), findsNWidgets(2));
    expect(find.text('全书 37%'), findsNWidgets(2));
  });

  testWidgets(
    'hidden no-chapter layer uses insets and does not invent chapter progress',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              viewPadding: EdgeInsets.fromLTRB(0, 34, 0, 24),
            ),
            child: Scaffold(
              body: ReaderChrome(
                visible: false,
                mode: ReaderMode.paged,
                title: 'Book',
                onBack: () {},
                onToc: () {},
                onAppearance: () {},
                onMore: () {},
                onBookmarks: () {},
                onSearch: () {},
                onModeSelected: (_) {},
                currentChapterTitle: '全文',
                progressPercent: 0.37,
              ),
            ),
          ),
        ),
      );

      expect(find.text('全文'), findsNWidgets(2));
      expect(find.text('全书 37%'), findsNWidgets(2));
      expect(find.textContaining('本章'), findsNothing);
    },
  );
}
