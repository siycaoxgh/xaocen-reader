import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';

ReaderChrome chrome({
  required bool visible,
  required ReaderMode mode,
  String title = 'City Edge',
  int? chapter = 53,
  double? chapterPercent,
  int? page,
  int? pages,
  double? bookPercent = .37,
  ReaderStatusBarMode statusBarMode = ReaderStatusBarMode.system,
}) => ReaderChrome(
  visible: visible,
  title: 'Book',
  mode: mode,
  onBack: () {},
  onToc: () {},
  onAppearance: () {},
  onMore: () {},
  onBookmarks: () {},
  onSearch: () {},
  onModeSelected: (_) {},
  currentChapterTitle: title,
  currentChapterNumber: chapter,
  chapterProgressPercent: chapterPercent,
  chapterPageNumber: page,
  chapterPageCount: pages,
  progressPercent: bookPercent,
  statusBarMode: statusBarMode,
);

void main() {
  testWidgets('chrome progress labels use stable Chinese text', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: chrome(
        visible: true,
        mode: ReaderMode.paged,
        page: 7,
        pages: 12,
      ),
    )));
    expect(find.text('第 53 章  City Edge'), findsOneWidget);
    expect(find.text('本章 7 / 12 页'), findsOneWidget);
    expect(find.text('全书 37%'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: chrome(
        visible: true,
        mode: ReaderMode.vertical,
        chapterPercent: .68,
      ),
    )));
    expect(find.text('第 53 章  City Edge'), findsOneWidget);
    expect(find.text('本章 68%'), findsOneWidget);
    expect(find.text('全书 37%'), findsOneWidget);
  });

  testWidgets('hidden chrome renders one top and one bottom info region', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: chrome(
        visible: false,
        mode: ReaderMode.vertical,
        chapterPercent: .68,
        statusBarMode: ReaderStatusBarMode.readerInfo,
      ),
    )));
    expect(find.text('第 53 章  City Edge'), findsNWidgets(2));
    expect(find.text('本章 68%'), findsNWidgets(2));
    expect(find.text('全书 37%'), findsNWidgets(2));
    expect(find.byKey(readerTopInfoRegionKey), findsOneWidget);
    expect(find.byKey(readerBottomInfoRegionKey), findsOneWidget);
  });

  testWidgets('hidden paged info uses chapter page metrics', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: chrome(
        visible: false,
        mode: ReaderMode.paged,
        page: 7,
        pages: 12,
      ),
    )));
    expect(find.text('本章 7 / 12 页'), findsOneWidget);
    expect(find.text('全书 37%'), findsOneWidget);
  });

  testWidgets('hidden no-chapter info does not invent chapter progress', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: MediaQuery(
        data: const MediaQueryData(
          size: Size(412, 915),
          viewPadding: EdgeInsets.fromLTRB(0, 34, 0, 24),
        ),
        child: chrome(
          visible: false,
          mode: ReaderMode.paged,
          title: '全文',
          chapter: null,
        ),
      ),
    )));
    expect(find.text('全文'), findsOneWidget);
    expect(find.text('全书 37%'), findsOneWidget);
    expect(find.textContaining('本章'), findsNothing);
  });
}
