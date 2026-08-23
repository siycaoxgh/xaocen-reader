import 'package:flutter/foundation.dart';

import '../reader/content_transform.dart';
import 'remote_source.dart';

/// Stages are deliberately explicit so an article source cannot be treated
/// as a chapter source (or vice versa) by a future UI or transport.
enum WebArticleStage { list, article, body, readerContent }

enum WebBookStage { search, detail, toc, chapter, readerContent }

/// Stable rule identity.  The rule is data owned by a future adapter; this
/// contract never executes selectors, JavaScript or a WebView.
@immutable
final class WebRuleSetRef {
  const WebRuleSetRef({required this.id, this.version = 1});

  final String id;
  final int version;
}

/// An immutable body at the source boundary.  It remains canonical text
/// until a caller explicitly applies a [ContentTransform].
@immutable
final class WebSourceBody {
  const WebSourceBody({required this.canonical});

  final CanonicalContent canonical;

  DerivedContent derive(ContentTransform transform) =>
      transform.apply(canonical);
}

@immutable
final class WebArticleListRequest {
  const WebArticleListRequest({
    required this.uri,
    this.pageToken,
    this.limit = 20,
  }) : assert(limit > 0);

  final Uri uri;
  final String? pageToken;
  final int limit;
}

@immutable
final class WebArticleListItem {
  const WebArticleListItem({
    required this.identity,
    required this.title,
    required this.uri,
    this.summary,
    this.publishedAt,
  });

  final String identity;
  final String title;
  final Uri uri;
  final String? summary;
  final DateTime? publishedAt;
}

@immutable
final class WebArticleListPage {
  WebArticleListPage({
    required List<WebArticleListItem> items,
    this.nextPageToken,
    this.sourceRevision,
  }) : items = List.unmodifiable(items);

  final List<WebArticleListItem> items;
  final String? nextPageToken;
  final String? sourceRevision;
}

@immutable
final class WebArticleDocument {
  const WebArticleDocument({
    required this.item,
    required this.body,
    required this.ruleSet,
    this.author,
    this.description,
    this.canonicalUri,
  });

  final WebArticleListItem item;
  final WebSourceBody body;
  final WebRuleSetRef ruleSet;
  final String? author;
  final String? description;
  final Uri? canonicalUri;
}

/// Article flow: list → article → canonical body → persisted ContentSource /
/// ReaderContent.  Implementations are intentionally absent in this stage.
abstract interface class WebArticleSourceAdapter
    implements RemoteSourceReaderAdapter {
  WebArticleSource get source;

  Future<WebArticleListPage> list(WebArticleListRequest request);

  Future<WebArticleDocument> open(WebArticleListItem item);
}

@immutable
final class WebBookSearchRequest {
  const WebBookSearchRequest({
    required this.query,
    this.page = 0,
    this.pageSize = 20,
  }) : assert(page >= 0),
       assert(pageSize > 0);

  final String query;
  final int page;
  final int pageSize;
}

@immutable
final class WebBookSearchResult {
  const WebBookSearchResult({
    required this.bookKey,
    required this.title,
    required this.detailUri,
    this.author,
  });

  final String bookKey;
  final String title;
  final Uri detailUri;
  final String? author;
}

@immutable
final class WebBookDetail {
  const WebBookDetail({
    required this.bookKey,
    required this.title,
    required this.detailUri,
    this.author,
    this.description,
    this.ruleSet,
  });

  final String bookKey;
  final String title;
  final Uri detailUri;
  final String? author;
  final String? description;
  final WebRuleSetRef? ruleSet;
}

@immutable
final class WebBookTocEntry {
  const WebBookTocEntry({
    required this.chapterKey,
    required this.title,
    required this.orderIndex,
    required this.chapterUri,
  });

  final String chapterKey;
  final String title;
  final int orderIndex;
  final Uri chapterUri;
}

@immutable
final class WebBookTableOfContents {
  WebBookTableOfContents({
    required this.bookKey,
    required List<WebBookTocEntry> entries,
    this.sourceRevision,
  }) : entries = List.unmodifiable(entries);

  final String bookKey;
  final List<WebBookTocEntry> entries;
  final String? sourceRevision;
}

@immutable
final class WebBookChapter {
  const WebBookChapter({
    required this.bookKey,
    required this.entry,
    required this.body,
    required this.ruleSet,
  });

  final String bookKey;
  final WebBookTocEntry entry;
  final WebSourceBody body;
  final WebRuleSetRef ruleSet;
}

/// Book flow: search → detail → ordered TOC → chapter → canonical body →
/// persisted ContentSource / ReaderContent.  Chapter ordering is source data;
/// this contract never sorts it implicitly.
abstract interface class WebBookSourceAdapter
    implements RemoteSourceReaderAdapter {
  WebBookSource get source;

  Future<List<WebBookSearchResult>> search(WebBookSearchRequest request);

  Future<WebBookDetail> openDetail(WebBookSearchResult result);

  Future<WebBookTableOfContents> loadTableOfContents(WebBookDetail detail);

  Future<WebBookChapter> openChapter(
    WebBookDetail detail,
    WebBookTocEntry entry,
  );
}
