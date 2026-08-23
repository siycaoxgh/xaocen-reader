import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/library/library_entities.dart';
import '../../domain/reader/reader_content.dart';
import '../../domain/reader/reader_rendering.dart';
import 'epub_models.dart';

/// Converts parsed EPUB spine content into the existing ReaderContent shape.
///
/// The adapter only creates runtime projections. Persistence, import UI and
/// Reader progress remain owned by the existing library/data layers.
final class EpubReaderContentAdapter implements ReaderContentAdapter {
  const EpubReaderContentAdapter();

  @override
  String get sourceKind => ReaderContentSourceKinds.epub;

  @override
  bool canAdapt(LibraryCollection collection) =>
      collection.sourceId.startsWith('epub-source:');

  @override
  ReaderContent adapt({
    required LibraryCollection collection,
    required List<LibraryDocument> documents,
    required List<LibraryTocEntry> navigation,
  }) {
    return ReaderContent(
      identity: ReaderContentIdentity(
        contentId: collection.id,
        sourceId: collection.sourceId,
        sourceKind: sourceKind,
        sourceRevision: _firstNonEmptyDocumentHash(documents),
      ),
      metadata: ReaderContentMetadata.fromCollection(collection),
      documents: documents,
      navigation: navigation,
      normalizedCharacterLength: collection.normalizedCharacterLength,
    );
  }

  /// Builds a ReaderContent projection directly from a parsed EPUB package.
  /// [contentId] and [sourceId] are supplied by the future import layer so
  /// identity remains stable and is never derived from a display title.
  ReaderContent adaptBook({
    required EpubBook book,
    required String contentId,
    required String sourceId,
  }) {
    final documents = <LibraryDocument>[];
    final ranges = <({int start, int end})>[];
    final text = StringBuffer();
    for (var index = 0; index < book.spine.length; index++) {
      final item = book.spine[index];
      if (text.isNotEmpty) text.write('\n\n');
      final start = text.length;
      text.write(item.text);
      final end = text.length;
      ranges.add((start: start, end: end));
      final itemId = '$contentId:item:$index';
      documents.add(
        LibraryDocument(
          id: '$contentId:document:$index',
          itemId: itemId,
          storagePath: item.href,
          mediaType: item.mediaType,
          startCharacterOffset: start,
          endCharacterOffset: end,
          contentHash: _hash(item.text),
          normalizationVersion: 'epub-text-v1',
        ),
      );
    }

    final navigation = <LibraryTocEntry>[];
    final tocIdsBySourceIndex = <int, String>{};
    for (var index = 0; index < book.navigation.length; index++) {
      final item = book.navigation[index];
      final spineIndex = item.spineIndex;
      if (spineIndex == null || spineIndex < 0 || spineIndex >= ranges.length) {
        continue;
      }
      final range = ranges[spineIndex];
      final itemId = '$contentId:item:$spineIndex';
      final tocId = '$contentId:toc:$index';
      tocIdsBySourceIndex[index] = tocId;
      navigation.add(
        LibraryTocEntry(
          id: tocId,
          collectionId: contentId,
          itemId: itemId,
          parentId: item.parentIndex == null
              ? null
              : tocIdsBySourceIndex[item.parentIndex],
          kind: 'chapter',
          level: item.level,
          title: item.title,
          orderIndex: index,
          startCharacterOffset: range.start,
          endCharacterOffset: range.end,
        ),
      );
    }

    final normalizedText = text.toString();
    return ReaderContent(
      identity: ReaderContentIdentity(
        contentId: contentId,
        sourceId: sourceId,
        sourceKind: sourceKind,
        sourceRevision: _hash(normalizedText),
      ),
      metadata: ReaderContentMetadata(
        title: book.metadata.title,
        author: book.metadata.author,
        description: book.metadata.description,
        metadataSource: 'autoDetected',
        titleSource: book.metadata.titleSource,
        authorSource: book.metadata.authorSource,
      ),
      documents: documents,
      navigation: navigation,
      normalizedCharacterLength: normalizedText.length,
    );
  }

  /// Converts EPUB presentation annotations into the source-neutral rendering
  /// sidecar used by the Reader.  Offsets are calculated against the same
  /// spine join as [adaptBook], so the normalized text remains canonical.
  ReaderRenderingMetadata renderingForBook(EpubBook book) {
    final styles = <ReaderInlineStyleRun>[];
    final images = <ReaderImagePlacement>[];
    var base = 0;
    for (var index = 0; index < book.spine.length; index++) {
      final item = book.spine[index];
      for (final run in item.styleRuns) {
        styles.add(
          ReaderInlineStyleRun(
            startCharacterOffset: base + run.startCharacterOffset,
            endCharacterOffset: base + run.endCharacterOffset,
            bold: run.bold,
            italic: run.italic,
            headingLevel: run.headingLevel,
          ),
        );
      }
      for (final image in item.images) {
        images.add(
          ReaderImagePlacement(
            characterOffset: base + image.characterOffset,
            // The repository replaces this source href with its managed path
            // before writing the manifest.
            storagePath: image.href,
            altText: image.altText,
            width: image.width,
            height: image.height,
          ),
        );
      }
      base += item.text.length;
      if (index + 1 < book.spine.length) base += 2;
    }
    return ReaderRenderingMetadata(styleRuns: styles, images: images);
  }

  String? _firstNonEmptyDocumentHash(List<LibraryDocument> documents) {
    for (final document in documents) {
      if (document.contentHash.trim().isNotEmpty) return document.contentHash;
    }
    return null;
  }

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
}
