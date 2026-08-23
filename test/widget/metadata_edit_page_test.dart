import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/metadata_edit_page.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';

void main() {
  final collection = LibraryCollection(
    id: 'local-txt:metadata-editor-test',
    sourceId: 'local-txt-source:metadata-editor-test',
    title: '测试书',
    subtitle: null,
    author: '作者',
    description: '简介',
    itemCount: 12,
    normalizedCharacterLength: 1000,
    detectedEncoding: TextEncoding.utf8,
    sourceSize: 1000,
    importedAt: DateTime(2026, 1, 1),
    fileName: '测试书.txt',
    sourcePath: 'library/测试书.txt',
  );

  Future<void> pumpEditor(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [localBookCoverRepositoryProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: MetadataEditPage(collection: collection)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'wide editor keeps save in app bar and places cover beside fields',
    (tester) async {
      await pumpEditor(tester, const Size(1200, 800));

      expect(
        find.byKey(const ValueKey('metadata-editor-save')),
        findsOneWidget,
      );
      final title = find.byType(TextField).first;
      final cover = find.byKey(const ValueKey('metadata-cover-preview'));
      expect(
        tester.getTopLeft(cover).dx,
        greaterThan(tester.getTopRight(title).dx),
      );
      expect(tester.getSize(cover), const Size(128, 192));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('narrow editor stacks metadata before cover without overflow', (
    tester,
  ) async {
    await pumpEditor(tester, const Size(390, 844));

    final description = find.byType(TextField).at(2);
    final cover = find.byKey(const ValueKey('metadata-cover-preview'));
    expect(
      tester.getTopLeft(cover).dy,
      greaterThan(tester.getBottomRight(description).dy),
    );
    expect(find.byKey(const ValueKey('metadata-editor-save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
