import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

Widget _host({
  required bool top,
  required bool bottom,
  required bool divider,
  bool showInfoContent = true,
  bool? topDivider,
  bool? bottomDivider,
  EdgeInsets padding = EdgeInsets.zero,
  Color readerTextColor = Colors.black,
  Color readerBackgroundColor = Colors.white,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: const Size(800, 600), padding: padding),
      child: Scaffold(
        body: ReaderInfoScaffold(
          body: const ColoredBox(key: Key('reader-body'), color: Colors.white),
          mode: ReaderMode.vertical,
          currentChapterTitle: 'City Edge',
          currentChapterNumber: 53,
          chapterProgressPercent: .68,
          chapterPageNumber: null,
          chapterPageCount: null,
          progressPercent: .37,
          showTopInfoBar: top,
          showBottomInfoBar: bottom,
          showProgressInfo: true,
          showChapterInfo: true,
          showChapterProgressInfo: true,
          showClockInfo: false,
          showWholeBookProgressInfo: true,
          showInfoDivider: divider,
          showInfoContent: showInfoContent,
          showTopInfoDivider: topDivider,
          showBottomInfoDivider: bottomDivider,
          chapterInfoSlot: ReaderInfoSlot.topLeft,
          chapterProgressInfoSlot: ReaderInfoSlot.topRight,
          clockInfoSlot: ReaderInfoSlot.bottomLeft,
          wholeBookProgressInfoSlot: ReaderInfoSlot.bottomRight,
          infoDividerSlot: ReaderInfoSlot.topCenter,
          statusBarMode: ReaderStatusBarMode.readerInfo,
          timeDisplayMode: ReaderTimeDisplayMode.hidden,
          readerTextColor: readerTextColor,
          readerBackgroundColor: readerBackgroundColor,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('top and bottom regions never intersect Reader body', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        top: true,
        bottom: true,
        divider: true,
        padding: const EdgeInsets.fromLTRB(0, 34, 0, 24),
      ),
    );
    final top = tester.getRect(find.byKey(readerTopInfoRegionKey));
    final body = tester.getRect(find.byKey(const Key('reader-body')));
    final bottom = tester.getRect(find.byKey(readerBottomInfoRegionKey));
    expect(top.bottom, lessThanOrEqualTo(body.top));
    expect(body.bottom, lessThanOrEqualTo(bottom.top));
  });

  testWidgets('hiding info releases the reserved body space', (tester) async {
    await tester.pumpWidget(_host(top: true, bottom: true, divider: false));
    final withInfo = tester.getRect(find.byKey(const Key('reader-body')));
    await tester.pumpWidget(_host(top: false, bottom: false, divider: false));
    final hidden = tester.getRect(find.byKey(const Key('reader-body')));
    expect(hidden.height, greaterThan(withInfo.height));
  });

  testWidgets('divider visibility does not change body geometry', (
    tester,
  ) async {
    await tester.pumpWidget(_host(top: true, bottom: true, divider: true));
    final shown = tester.getRect(find.byKey(const Key('reader-body')));
    await tester.pumpWidget(_host(top: true, bottom: true, divider: false));
    final hidden = tester.getRect(find.byKey(const Key('reader-body')));
    expect(hidden, shown);
  });

  testWidgets('Chrome visibility does not change reserved body geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(top: true, bottom: true, divider: true, showInfoContent: true),
    );
    final shown = tester.getRect(find.byKey(const Key('reader-body')));
    await tester.pumpWidget(
      _host(top: true, bottom: true, divider: true, showInfoContent: false),
    );
    final hidden = tester.getRect(find.byKey(const Key('reader-body')));
    expect(hidden, shown);
  });

  testWidgets('top and bottom dividers are independent', (tester) async {
    await tester.pumpWidget(
      _host(
        top: true,
        bottom: true,
        divider: false,
        topDivider: true,
        bottomDivider: false,
      ),
    );
    expect(find.byKey(readerTopInfoDividerKey), findsOneWidget);
    expect(find.byKey(readerBottomInfoDividerKey), findsOneWidget);
    await tester.pumpWidget(
      _host(
        top: true,
        bottom: true,
        divider: false,
        topDivider: false,
        bottomDivider: true,
      ),
    );
    expect(find.byKey(readerTopInfoDividerKey), findsOneWidget);
    expect(find.byKey(readerBottomInfoDividerKey), findsOneWidget);
    final topColor = tester
        .widget<ColoredBox>(find.byKey(readerTopInfoDividerKey))
        .color;
    final bottomColor = tester
        .widget<ColoredBox>(find.byKey(readerBottomInfoDividerKey))
        .color;
    expect(topColor, Colors.transparent);
    expect(bottomColor, isNot(Colors.transparent));
  });

  testWidgets('divider visibility keeps fixed one-physical-pixel geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(top: true, bottom: true, divider: false, padding: EdgeInsets.zero),
    );
    final body = tester.getRect(find.byKey(const Key('reader-body')));
    final top = tester.getRect(find.byKey(readerTopInfoDividerKey));
    final bottom = tester.getRect(find.byKey(readerBottomInfoDividerKey));
    expect(top.height, greaterThanOrEqualTo(1 / tester.view.devicePixelRatio));
    expect(
      bottom.height,
      greaterThanOrEqualTo(1 / tester.view.devicePixelRatio),
    );
    expect(top.height, lessThanOrEqualTo(1));
    expect(bottom.height, lessThanOrEqualTo(1));
    expect(top.bottom, lessThanOrEqualTo(body.top));
    expect(body.bottom, lessThanOrEqualTo(bottom.top));
  });

  testWidgets('enabled dividers paint visible non-background colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        top: true,
        bottom: true,
        divider: false,
        topDivider: true,
        bottomDivider: true,
        readerTextColor: Colors.black,
        readerBackgroundColor: Colors.white,
      ),
    );
    final topColor = tester
        .widget<ColoredBox>(find.byKey(readerTopInfoDividerKey))
        .color;
    final bottomColor = tester
        .widget<ColoredBox>(find.byKey(readerBottomInfoDividerKey))
        .color;
    expect(topColor, isNot(Colors.transparent));
    expect(bottomColor, isNot(Colors.transparent));
    expect(topColor, isNot(Colors.white));
    expect(bottomColor, isNot(Colors.white));
    expect(topColor.computeLuminance(), lessThan(.95));
    expect(bottomColor.computeLuminance(), lessThan(.95));
  });
}
