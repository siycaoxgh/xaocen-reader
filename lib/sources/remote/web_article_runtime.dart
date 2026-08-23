import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../domain/remote/remote_source.dart';
import '../../domain/reader/content_transform.dart';
import '../../domain/reader/reader_content.dart';
import '../../domain/library/library_entities.dart';
import '../../domain/local_txt/text_encoding.dart';
import '../../domain/remote/web_source_contracts.dart';
import 'feed_html_normalizer.dart';
import 'remote_http_transport.dart';

/// Extraction rules are data-only.  A rule can select a bounded HTML region,
/// but it cannot execute JavaScript, load a WebView or issue another request.
@immutable
final class WebArticleExtractionRules {
  WebArticleExtractionRules({
    required this.id,
    this.version = 1,
    RegExp? titlePattern,
    List<RegExp>? bodyPatterns,
    RegExp? authorPattern,
    RegExp? descriptionPattern,
    RegExp? canonicalPattern,
  }) : titlePattern = titlePattern ?? _defaultTitlePattern,
       bodyPatterns = List.unmodifiable(bodyPatterns ?? _defaultBodyPatterns),
       authorPattern = authorPattern ?? _defaultAuthorPattern,
       descriptionPattern = descriptionPattern ?? _defaultDescriptionPattern,
       canonicalPattern = canonicalPattern ?? _defaultCanonicalPattern;

  /// A conservative HTML rule set suitable for the first public POC.
  WebArticleExtractionRules.genericHtml() : this(id: 'generic-html-v1');

  final String id;
  final int version;
  final RegExp titlePattern;
  final List<RegExp> bodyPatterns;
  final RegExp authorPattern;
  final RegExp descriptionPattern;
  final RegExp canonicalPattern;

  static final _defaultTitlePattern = RegExp(
    r'<title\b[^>]*>([\s\S]*?)</title>',
    caseSensitive: false,
  );
  static final _defaultBodyPatterns = <RegExp>[
    RegExp(r'<article\b[^>]*>([\s\S]*?)</article>', caseSensitive: false),
    RegExp(r'<main\b[^>]*>([\s\S]*?)</main>', caseSensitive: false),
    RegExp(r'<body\b[^>]*>([\s\S]*?)</body>', caseSensitive: false),
  ];
  static final _defaultAuthorPattern = RegExp(
    r'''<meta\b[^>]*\bname\s*=\s*["']author["'][^>]*\bcontent\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );
  static final _defaultDescriptionPattern = RegExp(
    r'''<meta\b[^>]*\bname\s*=\s*["']description["'][^>]*\bcontent\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );
  static final _defaultCanonicalPattern = RegExp(
    r'''<link\b[^>]*\brel\s*=\s*["']canonical["'][^>]*\bhref\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );
}

enum WebArticleFailureKind {
  transport,
  http,
  redirectOutsideSource,
  emptyBody,
  extraction,
}

@immutable
final class WebArticleRuntimeFailure {
  const WebArticleRuntimeFailure({
    required this.kind,
    required this.message,
    this.statusCode,
    this.cause,
  });

  final WebArticleFailureKind kind;
  final String message;
  final int? statusCode;
  final Object? cause;
}

@immutable
final class WebArticleFetchOutcome {
  const WebArticleFetchOutcome.success({
    required this.document,
    required this.response,
  }) : failure = null;

  const WebArticleFetchOutcome.failure({required this.failure, this.response})
    : document = null;

  final WebArticleDocument? document;
  final RemoteHttpResponse? response;
  final WebArticleRuntimeFailure? failure;

  bool get isSuccess => document != null && failure == null;
}

/// Minimal real HTTP article runtime.  It performs one GET and one bounded
/// HTML extraction pass, then returns canonical text for the existing Reader
/// projection.  No persistence, pagination or Reader state is owned here.
final class WebArticleHttpRuntime {
  WebArticleHttpRuntime({
    required this.transport,
    WebArticleExtractionRules? rules,
  }) : rules = rules ?? WebArticleExtractionRules.genericHtml();

  final RemoteHttpTransport transport;
  final WebArticleExtractionRules rules;

  Future<WebArticleFetchOutcome> tryFetch({
    required WebArticleSource source,
    required WebArticleListItem item,
    RemoteHeaders? headers,
  }) async {
    try {
      final result = await _fetchWithResponse(
        source: source,
        item: item,
        headers: headers,
      );
      return WebArticleFetchOutcome.success(
        document: result.$1,
        response: result.$2,
      );
    } on _WebArticleRuntimeException catch (error) {
      return WebArticleFetchOutcome.failure(
        failure: error.failure,
        response: error.response,
      );
    } on RemoteHttpException catch (error) {
      return WebArticleFetchOutcome.failure(
        failure: _mapTransportFailure(error),
      );
    } catch (error) {
      return WebArticleFetchOutcome.failure(
        failure: WebArticleRuntimeFailure(
          kind: WebArticleFailureKind.extraction,
          message: '文章解析失败',
          cause: error,
        ),
      );
    }
  }

  Future<WebArticleDocument> fetch({
    required WebArticleSource source,
    required WebArticleListItem item,
    RemoteHeaders? headers,
  }) async {
    final result = await _fetchWithResponse(
      source: source,
      item: item,
      headers: headers,
    );
    return result.$1;
  }

  /// Projects a fetched article into the same ReaderContent shape used by
  /// TXT, EPUB and RSS.  This is a runtime read model only; persistence,
  /// progress and Locator ownership remain in the existing library/Reader
  /// layers.
  WebArticleReaderContentProjection toReaderContent({
    required WebArticleSource source,
    required WebArticleDocument document,
    String? contentId,
  }) {
    final stableContentId =
        contentId ?? 'web-article:${source.id.value}:${document.item.identity}';
    final itemId = 'web-article-item:${document.item.identity}';
    final text = document.body.canonical.text;
    final documentId = '$stableContentId:document:0';
    final collection = LibraryCollection(
      id: stableContentId,
      sourceId: source.id.value,
      title: document.item.title,
      subtitle: null,
      itemCount: 1,
      normalizedCharacterLength: text.length,
      detectedEncoding: TextEncoding.utf8,
      sourceSize: utf8.encode(text).length,
      importedAt: DateTime.now().toUtc(),
      author: document.author,
      description: document.description,
      metadataSource: 'autoDetected',
      titleSource: 'autoDetected',
      authorSource: document.author == null ? 'unknown' : 'autoDetected',
    );
    final documents = <LibraryDocument>[
      LibraryDocument(
        id: documentId,
        itemId: itemId,
        storagePath: 'web-article://${document.item.identity}',
        mediaType: 'text/plain',
        startCharacterOffset: 0,
        endCharacterOffset: text.length,
        contentHash: document.body.canonical.sourceRevision,
        normalizationVersion: 'web-article-html-v1',
      ),
    ];
    final navigation = <LibraryTocEntry>[
      LibraryTocEntry(
        id: '$stableContentId:toc:0',
        collectionId: stableContentId,
        itemId: itemId,
        parentId: null,
        kind: 'article',
        level: 0,
        title: document.item.title,
        orderIndex: 0,
        startCharacterOffset: 0,
        endCharacterOffset: text.length,
      ),
    ];
    return WebArticleReaderContentProjection(
      content: ReaderContent(
        identity: ReaderContentIdentity(
          contentId: stableContentId,
          sourceId: source.id.value,
          sourceKind: ReaderContentSourceKinds.online,
          sourceRevision: document.body.canonical.sourceRevision,
        ),
        metadata: ReaderContentMetadata.fromCollection(collection),
        documents: documents,
        navigation: navigation,
        normalizedCharacterLength: text.length,
      ),
      documentTextById: <String, String>{documentId: text},
    );
  }

  Future<(WebArticleDocument, RemoteHttpResponse)> _fetchWithResponse({
    required WebArticleSource source,
    required WebArticleListItem item,
    RemoteHeaders? headers,
  }) async {
    if (item.uri != source.articleUri) {
      throw ArgumentError.value(item.uri, 'item.uri', '文章 URI 不属于来源');
    }
    final plan = source.planRequest(uri: item.uri, headers: headers);
    final response = await transport.execute(plan);
    if (!source.accepts(response.finalUri)) {
      throw _WebArticleRuntimeException(
        WebArticleRuntimeFailure(
          kind: WebArticleFailureKind.redirectOutsideSource,
          message: '文章重定向地址不属于当前来源',
        ),
        response,
      );
    }
    if (!response.isSuccess) {
      throw _WebArticleRuntimeException(
        WebArticleRuntimeFailure(
          kind: WebArticleFailureKind.http,
          message: '文章返回 HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        ),
        response,
      );
    }
    final html = response.decodeText();
    return (
      _extract(
        item: item,
        html: html,
        finalUri: response.finalUri,
        response: response,
      ),
      response,
    );
  }

  WebArticleDocument _extract({
    required WebArticleListItem item,
    required String html,
    required Uri finalUri,
    required RemoteHttpResponse response,
  }) {
    final title = _normalizedCapture(rules.titlePattern, html) ?? item.title;
    final bodyHtml = _firstCapture(rules.bodyPatterns, html);
    final body = FeedHtmlNormalizer.selectBody(
      content: bodyHtml,
      fallback: html,
    );
    if (body == FeedHtmlNormalizer.noBodyMessage || body.trim().isEmpty) {
      throw _WebArticleRuntimeException(
        const WebArticleRuntimeFailure(
          kind: WebArticleFailureKind.emptyBody,
          message: '文章未提供可读正文',
        ),
        response,
      );
    }
    final canonicalUri = _resolvedCapture(
      rules.canonicalPattern,
      html,
      finalUri,
    );
    final updatedItem = WebArticleListItem(
      identity: item.identity,
      title: title,
      uri: item.uri,
      summary: item.summary,
      publishedAt: item.publishedAt,
    );
    return WebArticleDocument(
      item: updatedItem,
      author: _normalizedCapture(rules.authorPattern, html),
      description: _normalizedCapture(rules.descriptionPattern, html),
      canonicalUri: canonicalUri,
      body: WebSourceBody(
        canonical: CanonicalContent(
          contentId: item.identity,
          sourceRevision: _revision(finalUri, body),
          text: body,
        ),
      ),
      ruleSet: WebRuleSetRef(id: rules.id, version: rules.version),
    );
  }

  static String? _firstCapture(Iterable<RegExp> patterns, String input) {
    for (final pattern in patterns) {
      final value = _capture(pattern, input);
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  static String? _capture(RegExp pattern, String input) =>
      pattern.firstMatch(input)?.groupCount == 0
      ? null
      : pattern.firstMatch(input)?.group(1);

  static String? _normalizedCapture(RegExp pattern, String input) {
    final value = _capture(pattern, input);
    if (value == null) return null;
    final normalized = FeedHtmlNormalizer.normalize(value);
    return normalized.isEmpty ? null : normalized;
  }

  static Uri? _resolvedCapture(RegExp pattern, String input, Uri base) {
    final raw = _capture(pattern, input)?.trim();
    if (raw == null || raw.isEmpty) return base;
    return base.resolve(raw);
  }

  static String _revision(Uri uri, String body) =>
      sha256.convert(utf8.encode('${uri.toString()}\n$body')).toString();

  static WebArticleRuntimeFailure _mapTransportFailure(
    RemoteHttpException error,
  ) => WebArticleRuntimeFailure(
    kind: error.kind == RemoteHttpFailureKind.httpStatus
        ? WebArticleFailureKind.http
        : error.kind == RemoteHttpFailureKind.redirectOutsideSource
        ? WebArticleFailureKind.redirectOutsideSource
        : WebArticleFailureKind.transport,
    message: error.message,
    statusCode: error.statusCode,
    cause: error,
  );
}

final class _WebArticleRuntimeException implements Exception {
  const _WebArticleRuntimeException(this.failure, this.response);

  final WebArticleRuntimeFailure failure;
  final RemoteHttpResponse? response;
}

@immutable
final class WebArticleReaderContentProjection {
  const WebArticleReaderContentProjection({
    required this.content,
    required this.documentTextById,
  });

  final ReaderContent content;
  final Map<String, String> documentTextById;
}
