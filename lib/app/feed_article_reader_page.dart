import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../data/database/app_database.dart';
import '../data/data_root.dart';
import '../data/repositories/library_file_manager.dart';
import '../data/repositories/reading_progress_repository.dart';
import '../domain/library/library_entities.dart';
import '../domain/local_txt/text_encoding.dart';
import '../domain/remote/feed_subscription.dart';
import '../reader/normalized_document_loader.dart';
import '../reader/reader_page.dart';
import '../domain/reader/reader_rendering.dart';
import '../sources/remote/feed_image_cache.dart';

/// Opens a persisted feed article in the existing Reader surface.
Future<void> openRemoteFeedArticle(
  BuildContext context, {
  required FeedSubscription subscription,
  required FeedArticle article,
  required DataRoot dataRoot,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RemoteFeedArticleReaderPage(
        subscription: subscription,
        article: article,
        dataRoot: dataRoot,
      ),
    ),
  );
}

/// A transient Reader session for a feed article.
///
/// Feed snapshots remain profile-persisted by FeedSubscriptionRepository. The
/// temporary database here only gives the existing Reader its normal progress
/// foreign-key context during this session; it is closed when the Reader is
/// closed and never becomes a second product progress store.
class RemoteFeedArticleReaderPage extends StatefulWidget {
  const RemoteFeedArticleReaderPage({
    super.key,
    required this.subscription,
    required this.article,
    this.dataRoot,
  });

  final FeedSubscription subscription;
  final FeedArticle article;
  final DataRoot? dataRoot;

  @override
  State<RemoteFeedArticleReaderPage> createState() =>
      _RemoteFeedArticleReaderPageState();
}

class _RemoteFeedArticleReaderPageState
    extends State<RemoteFeedArticleReaderPage> {
  ReaderPage? _reader;
  AppDatabase? _database;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  @override
  Widget build(BuildContext context) {
    final reader = _reader;
    if (reader != null) return reader;
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('文章')),
        body: Center(child: Text('打开文章失败：$_error')),
      );
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Future<void> _prepare() async {
    AppDatabase? database;
    try {
      final body = widget.article.body.trim().isEmpty
          ? widget.article.title
          : widget.article.body;
      final imageFiles = <File?>[];
      if (widget.dataRoot != null) {
        final imageCache = FeedImageCache(
          directory: widget.dataRoot!.remoteFeedImagesDirectory,
        );
        try {
          for (final imageLink in widget.article.imageLinks) {
            imageFiles.add(await imageCache.fetch(imageLink));
          }
        } finally {
          imageCache.close();
        }
      }
      final digest = sha256
          .convert(
            utf8.encode(
              '${widget.subscription.sourceId}:${widget.article.identity}',
            ),
          )
          .toString();
      database = AppDatabase.forTesting();
      final now = DateTime.now().toUtc();
      final sourceId = 'rss-article-source:$digest';
      final collectionId = 'rss-article:$digest';
      final itemId = '$collectionId:item:0';
      final documentId = '$collectionId:document:0';
      final normalizedBytes = utf8.encode(body);
      final normalizedHash = sha256.convert(normalizedBytes).toString();
      await database
          .into(database.contentSources)
          .insert(
            ContentSourcesCompanion.insert(
              id: sourceId,
              type: 'rss',
              displayName: widget.article.title,
              contentHash: digest,
              managedSourcePath: 'rss://$digest/normalized.txt',
              sourceSize: normalizedBytes.length,
              detectedEncoding: TextEncoding.utf8.name,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.contentCollections)
          .insert(
            ContentCollectionsCompanion.insert(
              id: collectionId,
              sourceId: sourceId,
              title: widget.article.title,
              author: Value(widget.article.author),
              description: Value(widget.article.summary),
              metadataSource: const Value('autoDetected'),
              titleSource: const Value('autoDetected'),
              authorSource: Value(
                widget.article.author == null ? 'unknown' : 'autoDetected',
              ),
              itemCount: 1,
              normalizedCharacterLength: body.length,
              importedAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.contentItems)
          .insert(
            ContentItemsCompanion.insert(
              id: itemId,
              collectionId: collectionId,
              kind: 'chapter',
              title: widget.article.title,
              orderIndex: 0,
              startCharacterOffset: 0,
              endCharacterOffset: body.length,
              createdAt: now,
            ),
          );
      await database
          .into(database.contentDocuments)
          .insert(
            ContentDocumentsCompanion.insert(
              id: documentId,
              itemId: itemId,
              storagePath: 'rss://$digest/normalized.txt',
              mediaType: 'text/plain',
              startCharacterOffset: 0,
              endCharacterOffset: body.length,
              contentHash: normalizedHash,
              normalizationVersion: 'rss-text-v1',
            ),
          );
      await database
          .into(database.tocEntries)
          .insert(
            TocEntriesCompanion.insert(
              id: '$collectionId:toc:0',
              collectionId: collectionId,
              itemId: Value(itemId),
              parentId: const Value(null),
              kind: 'chapter',
              level: 0,
              title: widget.article.title,
              orderIndex: 0,
              startCharacterOffset: 0,
              endCharacterOffset: body.length,
            ),
          );

      final collection = LibraryCollection(
        id: collectionId,
        sourceId: sourceId,
        title: widget.article.title,
        subtitle: null,
        itemCount: 1,
        normalizedCharacterLength: body.length,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: normalizedBytes.length,
        importedAt: now,
        author: widget.article.author,
        description: widget.article.summary,
        metadataSource: 'autoDetected',
        titleSource: 'autoDetected',
        authorSource: widget.article.author == null
            ? 'unknown'
            : 'autoDetected',
      );
      // The document is injected directly into ReaderPage; no managed file is
      // written for a remote snapshot, so the loader root is never touched.
      final libraryRoot =
          widget.dataRoot?.booksDirectory ?? Directory.systemTemp;
      final fileManager = LibraryFileManager(libraryRoot: libraryRoot);
      final document = NormalizedDocument(
        text: body,
        normalizedHash: normalizedHash,
        normalizationVersion: 'rss-text-v1',
        parserVersion: 'rss-reader-v1',
        indexFormatVersion: 'v1',
        sourceFileName: widget.article.title,
        rendering: _buildImageRendering(body, imageFiles, libraryRoot),
      );
      final launch = ReaderLaunchContext(
        collection: collection,
        documents: [
          LibraryDocument(
            id: documentId,
            itemId: itemId,
            storagePath: 'rss://$digest/normalized.txt',
            mediaType: 'text/plain',
            startCharacterOffset: 0,
            endCharacterOffset: body.length,
            contentHash: normalizedHash,
            normalizationVersion: 'rss-text-v1',
          ),
        ],
        toc: [
          LibraryTocEntry(
            id: '$collectionId:toc:0',
            collectionId: collectionId,
            itemId: itemId,
            parentId: null,
            kind: 'chapter',
            level: 0,
            title: widget.article.title,
            orderIndex: 0,
            startCharacterOffset: 0,
            endCharacterOffset: body.length,
          ),
        ],
        normalizedCharacterLength: body.length,
        documentLoader: NormalizedDocumentLoader(fileManager: fileManager),
        progressRepository: ReadingProgressRepository(db: database),
      );
      if (!mounted) {
        await database.close();
        return;
      }
      _database = database;
      setState(
        () => _reader = ReaderPage(launch: launch, documentOverride: document),
      );
    } catch (error) {
      await database?.close();
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  ReaderRenderingMetadata? _buildImageRendering(
    String body,
    List<File?> files,
    Directory libraryRoot,
  ) {
    if (files.isEmpty) return null;
    final placements = <ReaderImagePlacement>[];
    var searchFrom = 0;
    for (final file in files) {
      if (file == null) continue;
      final marker = RegExp(r'\[图片(?:：[^\]]+)?\]');
      final match = marker.firstMatch(body.substring(searchFrom));
      if (match == null) continue;
      final offset = searchFrom + match.start;
      final relative = p
          .relative(file.path, from: libraryRoot.path)
          .replaceAll('\\', '/');
      placements.add(
        ReaderImagePlacement(
          characterOffset: offset,
          storagePath: relative,
          altText: '订阅图片',
        ),
      );
      searchFrom = searchFrom + match.end;
    }
    return placements.isEmpty
        ? null
        : ReaderRenderingMetadata(images: placements);
  }

  @override
  void dispose() {
    final database = _database;
    _database = null;
    if (database != null) {
      unawaited(database.close());
    }
    super.dispose();
  }
}
