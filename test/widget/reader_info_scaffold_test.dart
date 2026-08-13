import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';
import 'package:xaocen_reader/reader/android_reader_window.dart';

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
  Color? regionBackgroundColor,
  Brightness brightness = Brightness.light,
  List<DisplayFeature> displayFeatures = const [],
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        padding: padding,
        displayFeatures: displayFeatures,
      ),
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
          batteryInfoSlot: ReaderInfoSlot.bottomCenter,
          wholeBookProgressInfoSlot: ReaderInfoSlot.bottomRight,
          infoDividerSlot: ReaderInfoSlot.topCenter,
          statusBarMode: ReaderStatusBarMode.readerInfo,
          timeDisplayMode: ReaderTimeDisplayMode.hidden,
          readerTextColor: readerTextColor,
          readerBackgroundColor: readerBackgroundColor,
          regionBackgroundColor: regionBackgroundColor,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('top info and divider clear a real cutout bound', (tester) async {
    const cutout = DisplayFeature(
      bounds: Rect.fromLTWH(320, 0, 80, 52),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
    );
    await tester.pumpWidget(
      _host(
        top: true,
        bottom: false,
        divider: false,
        topDivider: true,
        padding: EdgeInsets.zero,
        displayFeatures: const [cutout],
      ),
    );
    final divider = tester.getRect(find.byKey(readerTopInfoDividerKey));
    expect(divider.top, greaterThanOrEqualTo(52 + 4));
    expect(divider.left, 0);
    expect(divider.right, 800);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
    for (final brightness in Brightness.values) {
      testWidgets('Reader info owns the Reader palette background on '
          '${platform.name} ${brightness.name}', (tester) async {
        const readerBackground = Color(0xff16323c);
        await tester.pumpWidget(
          _host(
            top: true,
            bottom: true,
            divider: false,
            brightness: brightness,
            readerBackgroundColor: readerBackground,
          ),
        );
        final topRegion = tester.widget<ColoredBox>(
          find
              .ancestor(
                of: find.byKey(readerTopInfoRegionKey),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        final bottomRegion = tester.widget<ColoredBox>(
          find
              .ancestor(
                of: find.byKey(readerBottomInfoRegionKey),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(topRegion.color, readerBackground);
        expect(bottomRegion.color, readerBackground);
      });
    }
  }

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

  testWidgets('top and bottom information switches are independent', (
    tester,
  ) async {
    await tester.pumpWidget(_host(top: true, bottom: false, divider: false));
    final topOnly = tester.getRect(find.byKey(const Key('reader-body')));
    expect(find.byKey(readerTopInfoRegionKey), findsOneWidget);
    expect(find.byKey(readerBottomInfoRegionKey), findsNothing);

    await tester.pumpWidget(_host(top: false, bottom: true, divider: false));
    final bottomOnly = tester.getRect(find.byKey(const Key('reader-body')));
    expect(find.byKey(readerTopInfoRegionKey), findsNothing);
    expect(find.byKey(readerBottomInfoRegionKey), findsOneWidget);
    expect(bottomOnly.height, closeTo(topOnly.height, 0.01));

    await tester.pumpWidget(_host(top: false, bottom: false, divider: false));
    final neither = tester.getRect(find.byKey(const Key('reader-body')));
    expect(neither.height, greaterThan(topOnly.height));
  });

  testWidgets('hidden info content still reserves independent regions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(top: true, bottom: false, divider: false, showInfoContent: false),
    );
    expect(find.byKey(readerTopInfoRegionKey), findsOneWidget);
    expect(find.byKey(readerBottomInfoRegionKey), findsNothing);
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
    expect(top.width, 800);
    expect(bottom.width, 800);
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

  testWidgets('battery item renders percent and charging indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderMinimalInfoLayer(
            mode: ReaderMode.vertical,
            currentChapterTitle: 'City Edge',
            currentChapterNumber: 53,
            chapterProgressPercent: .68,
            chapterPageNumber: null,
            chapterPageCount: null,
            progressPercent: .37,
            showTopInfoBar: false,
            showBottomInfoBar: true,
            showProgressInfo: true,
            showClockInfo: false,
            showBatteryInfo: true,
            batteryStatus: const BatteryStatus(percent: 85, charging: true),
            batteryInfoSlot: ReaderInfoSlot.bottomCenter,
            statusBarMode: ReaderStatusBarMode.readerInfo,
            timeDisplayMode: ReaderTimeDisplayMode.hidden,
          ),
        ),
      ),
    );
    expect(find.text('85% ⚡'), findsOneWidget);
  });
}
