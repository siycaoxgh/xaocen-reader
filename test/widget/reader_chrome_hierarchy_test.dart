import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/reader/reader_chrome.dart';
import 'package:xaocen_reader/reader/reader_mode.dart';

void main() {
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
                    onAutoRead: () => autoReadOpened = true,
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
      expect(find.byKey(readerAutoReadActionKey), findsNothing);

      await tester.tap(find.byKey(readerMoreActionKey));
      await tester.pumpAndSettle();
      expect(find.byKey(readerSearchActionKey), findsOneWidget);
      expect(find.byKey(readerAutoReadActionKey), findsOneWidget);
      await tester.tap(find.byKey(readerSearchActionKey));
      await tester.pumpAndSettle();
      expect(searchOpened, isTrue);
      expect(autoReadOpened, isFalse);
    },
  );
}
