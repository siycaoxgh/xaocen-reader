import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

void main() {
  testWidgets('cutout-aware metadata grows Chrome instead of overflowing', (
    tester,
  ) async {
    const cutout = DisplayFeature(
      bounds: Rect.fromLTWH(180, 0, 30, 42),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 260),
            displayFeatures: [cutout],
          ),
          child: Scaffold(
            body: ReaderChrome(
              visible: true,
              title: 'A long title that must remain bounded',
              mode: ReaderMode.paged,
              currentChapterTitle: 'City Edge',
              currentChapterNumber: 53,
              chapterPageNumber: 7,
              chapterPageCount: 12,
              chapterProgressPercent: .58,
              progressPercent: .37,
              extendIntoDisplayCutout: true,
              onBack: () {},
              onToc: () {},
              onAppearance: () {},
              onMore: () {},
              onBookmarks: () {},
              onSearch: () {},
              onModeSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final surface = tester.getRect(find.byKey(readerTopChromeSurfaceKey));
    final chrome = tester.getRect(find.byKey(readerTopChromeKey));
    expect(chrome.top, greaterThanOrEqualTo(surface.top));
    expect(chrome.bottom, lessThanOrEqualTo(surface.bottom));
  });

  testWidgets('top chrome surface paints the SafeArea inset', (tester) async {
    const surface = Color(0xff123456);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: surface,
          ).copyWith(surface: surface),
        ),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 32),
          ),
          child: Scaffold(
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
            ),
          ),
        ),
      ),
    );

    final surfaceBox = tester.widget<ColoredBox>(
      find.byKey(readerTopChromeSurfaceKey),
    );
    final surfaceRect = tester.getRect(find.byKey(readerTopChromeSurfaceKey));
    final chromeRect = tester.getRect(find.byKey(readerTopChromeKey));
    final chrome = tester.widget<Container>(find.byKey(readerTopChromeKey));
    final bottomChrome = tester.widget<Material>(
      find.byKey(readerBottomChromeKey),
    );
    expect(surfaceBox.color, surface);
    expect(bottomChrome.color, surface);
    expect((chrome.decoration! as BoxDecoration).border, isNull);
    expect(surfaceRect.top, 0);
    expect(chromeRect.top, 32);
    expect(surfaceRect.bottom, chromeRect.bottom);
  });

  testWidgets(
    'mobile Reader keeps primary chrome compact and groups low-frequency actions',
    (tester) async {
      var searchOpened = false;
      var autoReadOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: ReaderChrome(
                visible: true,
                title: 'Book',
                mode: ReaderMode.vertical,
                onBack: () {},
                onToc: () {},
                onAppearance: () {},
                onMore: () async {
                  await showReaderMorePreview(
                    tester.element(find.byType(ReaderChrome)),
                    onSearch: () => searchOpened = true,
                  );
                },
                onBookmarks: () {},
                onSearch: () {},
                onModeSelected: (_) {},
                onAutoRead: () => autoReadOpened = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(readerTocActionKey), findsOneWidget);
      expect(find.byKey(readerBookmarksActionKey), findsOneWidget);
      expect(find.byKey(readerAppearanceActionKey), findsOneWidget);
      expect(find.byKey(readerMoreActionKey), findsOneWidget);
      expect(find.byKey(readerSearchActionKey), findsNothing);
      expect(find.byKey(readerAutoReadActionKey), findsOneWidget);

      await tester.tap(find.byKey(readerAutoReadActionKey));
      expect(autoReadOpened, isTrue);

      await tester.tap(find.byKey(readerMoreActionKey));
      await tester.pumpAndSettle();
      expect(find.byKey(readerSearchActionKey), findsOneWidget);
      // The primary AutoRead action remains in the underlying bottom bar;
      // the More sheet must only avoid adding a second AutoRead entry.
      expect(find.byKey(readerAutoReadActionKey), findsOneWidget);
      await tester.tap(find.byKey(readerSearchActionKey));
      await tester.pumpAndSettle();
      expect(searchOpened, isTrue);
    },
  );
}
