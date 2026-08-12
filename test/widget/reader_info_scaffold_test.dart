import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

Widget _host({
  required bool top,
  required bool bottom,
  required bool divider,
  EdgeInsets padding = EdgeInsets.zero,
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
          chapterInfoSlot: ReaderInfoSlot.topLeft,
          chapterProgressInfoSlot: ReaderInfoSlot.topRight,
          clockInfoSlot: ReaderInfoSlot.bottomLeft,
          wholeBookProgressInfoSlot: ReaderInfoSlot.bottomRight,
          infoDividerSlot: ReaderInfoSlot.topCenter,
          statusBarMode: ReaderStatusBarMode.readerInfo,
          timeDisplayMode: ReaderTimeDisplayMode.hidden,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('top and bottom regions never intersect Reader body', (
    tester,
  ) async {
    await tester.pumpWidget(_host(
      top: true,
      bottom: true,
      divider: true,
      padding: const EdgeInsets.fromLTRB(0, 34, 0, 24),
    ));
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

  testWidgets('divider visibility does not change body geometry', (tester) async {
    await tester.pumpWidget(_host(top: true, bottom: true, divider: true));
    final shown = tester.getRect(find.byKey(const Key('reader-body')));
    await tester.pumpWidget(_host(top: true, bottom: true, divider: false));
    final hidden = tester.getRect(find.byKey(const Key('reader-body')));
    expect(hidden, shown);
  });
}
