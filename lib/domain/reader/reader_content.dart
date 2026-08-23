import 'package:flutter/foundation.dart';

import '../library/library_entities.dart';
import '../../sources/epub/epub_reader_content_adapter.dart';

/// Stable source-kind values used by the Reader content boundary.
///
/// EPUB, RSS and online sources are intentionally names only in this stage;
/// no adapter or network implementation is provided yet.
abstract final class ReaderContentSourceKinds {
  static const String localTxt = 'localTxt';
  static const String epub = 'epub';
  static const String rss = 'rss';
  static const String online = 'online';
  static const String unknown = 'unknown';
}

/// Identity of a readable content aggregate.
///
/// [contentId] remains the existing collection identity.  [sourceRevision]
/// is an optional source/content revision (for TXT it is the normalized
/// document hash when available); it is not a replacement for the UTF-16
/// ReaderLocator.
@immutable
final class ReaderContentIdentity {
  const ReaderContentIdentity({
    required this.contentId,
    required this.sourceId,
    required this.sourceKind,
    this.sourceRevision,
  });

  final String contentId;
  final String sourceId;
  final String sourceKind;
  final String? sourceRevision;
}

/// Source-neutral metadata needed by Reader surfaces.
///
/// This is a runtime read model.  Persistence remains owned by
/// [ContentCollections] and its repository projections.
@immutable
final class ReaderContentMetadata {
  const ReaderContentMetadata({
    required this.title,
    this.author,
    this.description,
    this.metadataSource = 'unknown',
    this.titleSource = 'unknown',
    this.authorSource = 'unknown',
  });

  factory ReaderContentMetadata.fromCollection(LibraryCollection collection) {
    return ReaderContentMetadata(
      title: collection.title,
      author: collection.author,
      description: collection.description,
      metadataSource: collection.metadataSource,
      titleSource: collection.titleSource,
      authorSource: collection.authorSource,
    );
  }

  final String title;
  final String? author;
  final String? description;
  final String metadataSource;
  final String titleSource;
  final String authorSource;
}

/// Runtime content aggregate consumed by Reader-facing code.
///
/// This object deliberately owns no database writes, file bytes, pagination
/// state or progress state.  It groups the existing collection/document/TOC
/// projections so a future EPUB or RSS adapter can provide the same Reader
/// input without creating another Reader implementation.
@immutable
final class ReaderContent {
  ReaderContent({
    required this.identity,
    required this.metadata,
    required List<LibraryDocument> documents,
    required List<LibraryTocEntry> navigation,
    required this.normalizedCharacterLength,
  }) : documents = List.unmodifiable(documents),
       navigation = List.unmodifiable(navigation);

  final ReaderContentIdentity identity;
  final ReaderContentMetadata metadata;

  /// Read-only projections of persisted ContentDocument rows.
  final List<LibraryDocument> documents;

  /// Source order and hierarchy used by TOC/navigation surfaces.
  final List<LibraryTocEntry> navigation;

  /// Expected UTF-16 length of the logical Reader text.
  final int normalizedCharacterLength;

  List<LibraryTocEntry> get toc => navigation;

  /// Matches the current TXT Reader launch behavior: use the first supplied
  /// document as the normalized-text source.  Selection is not pagination or
  /// Locator state.
  LibraryDocument? get primaryDocument =>
      documents.isEmpty ? null : documents.first;
}

/// Adapter from persisted library projections to the runtime Reader contract.
abstract interface class ReaderContentAdapter {
  String get sourceKind;

  bool canAdapt(LibraryCollection collection);

  ReaderContent adapt({
    required LibraryCollection collection,
    required List<LibraryDocument> documents,
    required List<LibraryTocEntry> navigation,
  });
}

/// Adapter for the existing managed TXT content path.
final class TxtReaderContentAdapter implements ReaderContentAdapter {
  const TxtReaderContentAdapter();

  @override
  String get sourceKind => ReaderContentSourceKinds.localTxt;

  @override
  bool canAdapt(LibraryCollection collection) =>
      collection.sourceId.startsWith('local-txt-source:');

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

  String? _firstNonEmptyDocumentHash(List<LibraryDocument> documents) {
    for (final document in documents) {
      final hash = document.contentHash.trim();
      if (hash.isNotEmpty) return hash;
    }
    return null;
  }
}

/// Adapter for WebBook snapshots written into the existing library tables.
/// The persisted source id is prefixed with `web-book-source:` so a remote
/// book never falls through to the legacy unknown-source projection.
final class WebBookReaderContentAdapter implements ReaderContentAdapter {
  const WebBookReaderContentAdapter();

  @override
  String get sourceKind => ReaderContentSourceKinds.online;

  @override
  bool canAdapt(LibraryCollection collection) =>
      collection.sourceId.startsWith('web-book-source:');

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

  String? _firstNonEmptyDocumentHash(List<LibraryDocument> documents) {
    for (final document in documents) {
      final hash = document.contentHash.trim();
      if (hash.isNotEmpty) return hash;
    }
    return null;
  }
}

/// Central selection point for source adapters.
///
/// TXT, EPUB and persisted WebBook snapshots are implemented. Unknown sources
/// receive a neutral legacy projection so future RSS/online adapters cannot
/// be silently treated as TXT.
final class ReaderContentAdapterRegistry {
  ReaderContentAdapterRegistry({
    List<ReaderContentAdapter> adapters = const <ReaderContentAdapter>[
      TxtReaderContentAdapter(),
      EpubReaderContentAdapter(),
      WebBookReaderContentAdapter(),
    ],
  }) : adapters = List.unmodifiable(adapters);

  static final ReaderContentAdapterRegistry defaultInstance =
      ReaderContentAdapterRegistry();

  final List<ReaderContentAdapter> adapters;

  ReaderContent resolve({
    required LibraryCollection collection,
    required List<LibraryDocument> documents,
    required List<LibraryTocEntry> navigation,
  }) {
    for (final adapter in adapters) {
      if (adapter.canAdapt(collection)) {
        return adapter.adapt(
          collection: collection,
          documents: documents,
          navigation: navigation,
        );
      }
    }

    return ReaderContent(
      identity: ReaderContentIdentity(
        contentId: collection.id,
        sourceId: collection.sourceId,
        sourceKind: ReaderContentSourceKinds.unknown,
      ),
      metadata: ReaderContentMetadata.fromCollection(collection),
      documents: documents,
      navigation: navigation,
      normalizedCharacterLength: collection.normalizedCharacterLength,
    );
  }
}
