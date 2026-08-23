import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../domain/library/library_entities.dart';
import '../../domain/local_txt/text_encoding.dart';
import '../../domain/reader/content_transform.dart';
import '../../domain/reader/reader_content.dart';
import '../../domain/remote/remote_source.dart';
import '../../domain/remote/web_source_contracts.dart';
import 'feed_html_normalizer.dart';
import 'remote_http_transport.dart';
import 'web_book_rule_engine.dart';

/// Conservative static-HTML rules for a book source.
///
/// The rules only select bounded markup regions. They do not execute
/// JavaScript, open a WebView, follow an embedded link or perform a second
/// request on behalf of a page.
@immutable
final class WebBookExtractionRules {
  WebBookExtractionRules({
    required this.id,
    this.version = 1,
    this.cssRuleSet,
    RegExp? searchItemPattern,
    RegExp? detailPattern,
    RegExp? tocEntryPattern,
    List<RegExp>? chapterBodyPatterns,
    RegExp? titlePattern,
    RegExp? authorPattern,
    RegExp? descriptionPattern,
    String? nextPageSelector,
    this.maxChapterPages = 8,
  }) : searchItemPattern = searchItemPattern ?? _defaultSearchItemPattern,
       detailPattern = detailPattern ?? _defaultDetailPattern,
       tocEntryPattern = tocEntryPattern ?? _defaultTocEntryPattern,
       chapterBodyPatterns = List.unmodifiable(
         chapterBodyPatterns ?? _defaultChapterBodyPatterns,
       ),
       titlePattern = titlePattern ?? _defaultTitlePattern,
       authorPattern = authorPattern ?? _defaultAuthorPattern,
       descriptionPattern = descriptionPattern ?? _defaultDescriptionPattern,
       nextPageSelector =
           nextPageSelector ?? cssRuleSet?.chapterNextPageSelector {
    if (maxChapterPages < 1) {
      throw ArgumentError.value(maxChapterPages, 'maxChapterPages');
    }
  }

  WebBookExtractionRules.genericHtml() : this(id: 'generic-book-html-v1');

  final String id;
  final int version;
  final WebBookCssRuleSet? cssRuleSet;
  final RegExp searchItemPattern;
  final RegExp detailPattern;
  final RegExp tocEntryPattern;
  final List<RegExp> chapterBodyPatterns;
  final RegExp titlePattern;
  final RegExp authorPattern;
  final RegExp descriptionPattern;
  final String? nextPageSelector;
  final int maxChapterPages;

  /// Expected shape: <a data-book-key="..." href="...">Title</a>.
  static final _defaultSearchItemPattern = RegExp(
    r'''<a\b([^>]*\bdata-book-key\s*=\s*["'][^"']+["'][^>]*)>([\s\S]*?)</a>''',
    caseSensitive: false,
  );

  /// Expected shape: <article data-book-key="...">...</article>.
  static final _defaultDetailPattern = RegExp(
    r'''<(?:article|div)\b([^>]*\bdata-book-key\s*=\s*["'][^"']+["'][^>]*)>([\s\S]*?)</(?:article|div)>''',
    caseSensitive: false,
  );

  /// Expected shape: <a data-chapter-key="..." href="...">Chapter</a>.
  static final _defaultTocEntryPattern = RegExp(
    r'''<a\b([^>]*\bdata-chapter-key\s*=\s*["'][^"']+["'][^>]*)>([\s\S]*?)</a>''',
    caseSensitive: false,
  );

  static final _defaultChapterBodyPatterns = <RegExp>[
    RegExp(
      r'''<article\b[^>]*\bclass\s*=\s*["'][^"']*chapter[^"']*["'][^>]*>([\s\S]*?)</article>''',
      caseSensitive: false,
    ),
    RegExp(r'<main\b[^>]*>([\s\S]*?)</main>', caseSensitive: false),
    RegExp(
      r'''<div\b[^>]*\bclass\s*=\s*["'][^"']*(?:chapter|content)[^"']*["'][^>]*>([\s\S]*?)</div>''',
      caseSensitive: false,
    ),
    RegExp(r'<body\b[^>]*>([\s\S]*?)</body>', caseSensitive: false),
  ];

  static final _defaultTitlePattern = RegExp(
    r'<h1\b[^>]*>([\s\S]*?)</h1>',
    caseSensitive: false,
  );
  static final _defaultAuthorPattern = RegExp(
    r'''<meta\b[^>]*\bname\s*=\s*["']author["'][^>]*\bcontent\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );
  static final _defaultDescriptionPattern = RegExp(
    r'''<meta\b[^>]*\bname\s*=\s*["']description["'][^>]*\bcontent\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );
}

enum WebBookFailureKind {
  transport,
  http,
  redirectOutsideSource,
  emptySearch,
  detailNotFound,
  emptyToc,
  emptyChapter,
  extraction,
}

@immutable
final class WebBookRuntimeFailure {
  const WebBookRuntimeFailure({
    required this.kind,
    required this.message,
    this.statusCode,
    this.cause,
  });

  final WebBookFailureKind kind;
  final String message;
  final int? statusCode;
  final Object? cause;
}

@immutable
final class WebBookRuntimeResult<T> {
  const WebBookRuntimeResult.success({required this.value, this.response})
    : failure = null;

  const WebBookRuntimeResult.failure({required this.failure, this.response})
    : value = null;

  final T? value;
  final RemoteHttpResponse? response;
  final WebBookRuntimeFailure? failure;

  bool get isSuccess => value != null && failure == null;
}

/// Minimal HTTP runtime for a static HTML novel source.
///
/// The source owns the semantic book identity and the runtime owns only the
/// request/extraction boundary. It never sorts TOC entries: HTML order is the
/// source order and is carried into [WebBookTableOfContents.entries].
final class WebBookHttpRuntime {
  WebBookHttpRuntime({required this.transport, WebBookExtractionRules? rules})
    : rules = rules ?? WebBookExtractionRules.genericHtml(),
      cssEngine =
          (rules ?? WebBookExtractionRules.genericHtml()).cssRuleSet == null
          ? null
          : WebBookRuleEngine(
              (rules ?? WebBookExtractionRules.genericHtml()).cssRuleSet!,
            );

  final RemoteHttpTransport transport;
  final WebBookExtractionRules rules;
  final WebBookRuleEngine? cssEngine;

  Future<List<WebBookSearchResult>> search({
    required WebBookSource source,
    required WebBookSearchRequest request,
    RemoteHeaders? headers,
  }) async {
    // A source may expose a dedicated search endpoint. The query is carried
    // as ordinary URL parameters so a static public endpoint can filter
    // results server-side without JS.
    if (request.query.trim().isEmpty) {
      throw _WebBookRuntimeException(
        const WebBookRuntimeFailure(
          kind: WebBookFailureKind.emptySearch,
          message: '请输入书名或关键词',
        ),
        null,
      );
    }
    final searchUri = _searchUri(source, request);
    final response = await _fetchHtml(source, searchUri, headers: headers);
    if (cssEngine != null) {
      final results = cssEngine!.search(
        html: response.$2,
        baseUri: response.$1.finalUri,
        source: source,
      );
      final start = request.page * request.pageSize;
      final page = results.skip(start).take(request.pageSize).toList();
      if (page.isEmpty) {
        throw _WebBookRuntimeException(
          const WebBookRuntimeFailure(
            kind: WebBookFailureKind.emptySearch,
            message: '搜索页面未提供可用书籍结果',
          ),
          response.$1,
        );
      }
      return page;
    }
    final matches = rules.searchItemPattern.allMatches(response.$2).toList();
    if (matches.isEmpty) {
      throw _WebBookRuntimeException(
        const WebBookRuntimeFailure(
          kind: WebBookFailureKind.emptySearch,
          message: '未找到可用书籍结果',
        ),
        response.$1,
      );
    }
    final results = <WebBookSearchResult>[];
    final start = request.page * request.pageSize;
    for (final match in matches.skip(start).take(request.pageSize)) {
      final attributes = match.group(1) ?? '';
      final title = _normalized(match.group(2));
      final rawHref = _attribute(attributes, 'href');
      final bookKey = _attribute(attributes, 'data-book-key');
      if (title == null ||
          title.isEmpty ||
          rawHref == null ||
          bookKey == null) {
        continue;
      }
      final detailUri = response.$1.finalUri.resolve(rawHref);
      if (!source.accepts(detailUri)) continue;
      results.add(
        WebBookSearchResult(
          bookKey: bookKey,
          title: title,
          detailUri: detailUri,
          author: _normalized(_attribute(attributes, 'data-author')),
        ),
      );
    }
    if (results.isEmpty) {
      throw _WebBookRuntimeException(
        const WebBookRuntimeFailure(
          kind: WebBookFailureKind.emptySearch,
          message: '搜索页面未提供可用书籍结果',
        ),
        response.$1,
      );
    }
    return results;
  }

  Future<WebBookDetail> openDetail({
    required WebBookSource source,
    required WebBookSearchResult result,
    RemoteHeaders? headers,
  }) async {
    final response = await _fetchHtml(
      source,
      result.detailUri,
      headers: headers,
    );
    if (cssEngine != null) {
      final data = cssEngine!.detail(html: response.$2);
      if (data == null) {
        throw _WebBookRuntimeException(
          const WebBookRuntimeFailure(
            kind: WebBookFailureKind.detailNotFound,
            message: '书籍详情未找到',
          ),
          response.$1,
        );
      }
      final bookKey = data.bookKey ?? result.bookKey;
      if (bookKey != result.bookKey) {
        throw _WebBookRuntimeException(
          const WebBookRuntimeFailure(
            kind: WebBookFailureKind.extraction,
            message: '书籍详情标识与搜索结果不一致',
          ),
          response.$1,
        );
      }
      return WebBookDetail(
        bookKey: bookKey,
        title: data.title ?? result.title,
        detailUri: result.detailUri,
        author: data.author ?? result.author,
        description: data.description,
        ruleSet: WebRuleSetRef(id: rules.id, version: rules.version),
      );
    }
    final match = rules.detailPattern.firstMatch(response.$2);
    if (match == null) {
      throw _WebBookRuntimeException(
        const WebBookRuntimeFailure(
          kind: WebBookFailureKind.detailNotFound,
          message: '书籍详情未找到',
        ),
        response.$1,
      );
    }
    final attributes = match.group(1) ?? '';
    final body = match.group(2) ?? '';
    final bookKey = _attribute(attributes, 'data-book-key') ?? result.bookKey;
    if (bookKey != result.bookKey) {
      throw _WebBookRuntimeException(
        const WebBookRuntimeFailure(
          kind: WebBookFailureKind.extraction,
          message: '书籍详情标识与搜索结果不一致',
        ),
        response.$1,
      );
    }
    final title =
        _normalized(_capture(rules.titlePattern, body)) ??
        _attribute(attributes, 'data-title') ??
        result.title;
    final author =
        _normalized(_attribute(attributes, 'data-author')) ??
        _normalizedCapture(rules.authorPattern, body) ??
        result.author;
    final description =
        _normalized(_attribute(attributes, 'data-description')) ??
        _normalizedCapture(rules.descriptionPattern, body) ??
        _normalizedCapture(
          RegExp(
            r'''<p\b[^>]*\bclass\s*=\s*["'][^"']*description[^"']*["'][^>]*>([\s\S]*?)</p>''',
            caseSensitive: false,
          ),
          body,
        );
    return WebBookDetail(
      bookKey: bookKey,
      title: title,
      detailUri: result.detailUri,
      author: author,
      description: description,
      ruleSet: WebRuleSetRef(id: rules.id, version: rules.version),
    );
  }

  Future<WebBookTableOfContents> loadTableOfContents({
    required WebBookSource source,
    required WebBookDetail detail,
    RemoteHeaders? headers,
  }) async {
    final response = await _fetchHtml(
      source,
      detail.detailUri,
      headers: headers,
    );
    if (cssEngine != null) {
      final entries = cssEngine!.tableOfContents(
        html: response.$2,
        baseUri: response.$1.finalUri,
        source: source,
      );
      if (entries.isEmpty) {
        throw _WebBookRuntimeException(
          const WebBookRuntimeFailure(
            kind: WebBookFailureKind.emptyToc,
            message: '书籍目录未找到',
          ),
          response.$1,
        );
      }
      return WebBookTableOfContents(
        bookKey: detail.bookKey,
        entries: entries,
        sourceRevision: _hash(
          entries
              .map((entry) => '${entry.chapterKey}|${entry.chapterUri}')
              .join('\n'),
        ),
      );
    }
    final entries = <WebBookTocEntry>[];
    for (final match in rules.tocEntryPattern.allMatches(response.$2)) {
      final attributes = match.group(1) ?? '';
      final rawHref = _attribute(attributes, 'href');
      if (rawHref == null || rawHref.trim().isEmpty) continue;
      final chapterUri = response.$1.finalUri.resolve(rawHref);
      if (!source.accepts(chapterUri)) continue;
      final title = _normalized(match.group(2));
      if (title == null || title.isEmpty) continue;
      final key =
          _attribute(attributes, 'data-chapter-key') ??
          'chapter-${_hash('${chapterUri.toString()}\n$title').substring(0, 16)}';
      // The list index is deliberate: it preserves the source's DOM order
      // even when a site prints a non-sequential display number.
      entries.add(
        WebBookTocEntry(
          chapterKey: key,
          title: title,
          orderIndex: entries.length,
          chapterUri: chapterUri,
        ),
      );
    }
    if (entries.isEmpty) {
      throw _WebBookRuntimeException(
        const WebBookRuntimeFailure(
          kind: WebBookFailureKind.emptyToc,
          message: '书籍目录未找到',
        ),
        response.$1,
      );
    }
    return WebBookTableOfContents(
      bookKey: detail.bookKey,
      entries: entries,
      sourceRevision: _hash(
        entries
            .map((entry) => '${entry.chapterKey}|${entry.chapterUri}')
            .join('\n'),
      ),
    );
  }

  Future<WebBookChapter> openChapter({
    required WebBookSource source,
    required WebBookDetail detail,
    required WebBookTocEntry entry,
    RemoteHeaders? headers,
  }) async {
    final visited = <Uri>{};
    final pageBodies = <String>[];
    var currentUri = entry.chapterUri;
    RemoteHttpResponse? lastResponse;
    for (var page = 0; page < rules.maxChapterPages; page++) {
      final response = await _fetchHtml(source, currentUri, headers: headers);
      lastResponse = response.$1;
      final finalUri = response.$1.finalUri;
      if (!visited.add(finalUri)) break;
      final bodyHtml = cssEngine == null
          ? _firstRegexChapterBody(response.$2)
          : cssEngine!.chapterBody(html: response.$2);
      final body = FeedHtmlNormalizer.selectBody(
        content: bodyHtml,
        fallback: response.$2,
      );
      if (body == FeedHtmlNormalizer.noBodyMessage || body.trim().isEmpty) {
        throw _WebBookRuntimeException(
          const WebBookRuntimeFailure(
            kind: WebBookFailureKind.emptyChapter,
            message: '章节未提供可读正文',
          ),
          response.$1,
        );
      }
      pageBodies.add(body.trim());
      final next = _nextPageUri(
        html: response.$2,
        baseUri: finalUri,
        source: source,
        visited: visited,
      );
      if (next == null) break;
      if (page == rules.maxChapterPages - 1) {
        throw _WebBookRuntimeException(
          const WebBookRuntimeFailure(
            kind: WebBookFailureKind.extraction,
            message: '章节分页超过最大页数，已停止继续加载',
          ),
          response.$1,
        );
      }
      currentUri = next;
    }
    final body = pageBodies.join('\n\n');
    if (body.trim().isEmpty || lastResponse == null) {
      throw _WebBookRuntimeException(
        const WebBookRuntimeFailure(
          kind: WebBookFailureKind.emptyChapter,
          message: '章节未提供可读正文',
        ),
        lastResponse,
      );
    }
    return WebBookChapter(
      bookKey: detail.bookKey,
      entry: entry,
      body: WebSourceBody(
        canonical: CanonicalContent(
          contentId: '${detail.bookKey}:${entry.chapterKey}',
          sourceRevision: _hash('${entry.chapterUri}\n$body'),
          text: body,
        ),
      ),
      ruleSet:
          detail.ruleSet ?? WebRuleSetRef(id: rules.id, version: rules.version),
    );
  }

  Future<WebBookRuntimeResult<List<WebBookSearchResult>>> trySearch({
    required WebBookSource source,
    required WebBookSearchRequest request,
    RemoteHeaders? headers,
  }) => _try(() => search(source: source, request: request, headers: headers));

  Future<WebBookRuntimeResult<WebBookDetail>> tryOpenDetail({
    required WebBookSource source,
    required WebBookSearchResult result,
    RemoteHeaders? headers,
  }) =>
      _try(() => openDetail(source: source, result: result, headers: headers));

  Future<WebBookRuntimeResult<WebBookTableOfContents>> tryLoadTableOfContents({
    required WebBookSource source,
    required WebBookDetail detail,
    RemoteHeaders? headers,
  }) => _try(
    () => loadTableOfContents(source: source, detail: detail, headers: headers),
  );

  Future<WebBookRuntimeResult<WebBookChapter>> tryOpenChapter({
    required WebBookSource source,
    required WebBookDetail detail,
    required WebBookTocEntry entry,
    RemoteHeaders? headers,
  }) => _try(
    () => openChapter(
      source: source,
      detail: detail,
      entry: entry,
      headers: headers,
    ),
  );

  /// Projects chapters in the supplied TOC order into the existing Reader.
  /// No chapter sorting, pagination, progress or database write occurs here.
  WebBookReaderContentProjection toReaderContent({
    required WebBookSource source,
    required WebBookDetail detail,
    required List<WebBookChapter> chapters,
    String? contentId,
  }) {
    if (chapters.isEmpty) {
      throw ArgumentError.value(chapters, 'chapters', '章节列表不能为空');
    }
    final stableContentId =
        contentId ?? 'web-book:${source.id.value}:${detail.bookKey}';
    final textByDocumentId = <String, String>{};
    final documents = <LibraryDocument>[];
    final navigation = <LibraryTocEntry>[];
    final chapterKeys = <String>{};
    final joined = StringBuffer();
    for (var index = 0; index < chapters.length; index++) {
      final chapter = chapters[index];
      if (chapter.bookKey != detail.bookKey) {
        throw ArgumentError.value(
          chapter.bookKey,
          'chapters[$index].bookKey',
          '章节不属于当前书籍',
        );
      }
      if (!chapterKeys.add(chapter.entry.chapterKey)) {
        throw ArgumentError.value(
          chapter.entry.chapterKey,
          'chapters[$index].entry.chapterKey',
          '章节 identity 重复',
        );
      }
      if (joined.isNotEmpty) joined.write('\n\n');
      final start = joined.length;
      final body = chapter.body.canonical.text;
      joined.write(body);
      final end = joined.length;
      final itemId = '$stableContentId:item:${chapter.entry.chapterKey}';
      final documentId = '$stableContentId:document:$index';
      documents.add(
        LibraryDocument(
          id: documentId,
          itemId: itemId,
          storagePath:
              'web-book://${detail.bookKey}/${chapter.entry.chapterKey}',
          mediaType: 'text/plain',
          startCharacterOffset: start,
          endCharacterOffset: end,
          contentHash: chapter.body.canonical.sourceRevision,
          normalizationVersion: 'web-book-html-v1',
        ),
      );
      navigation.add(
        LibraryTocEntry(
          id: '$stableContentId:toc:${chapter.entry.chapterKey}',
          collectionId: stableContentId,
          itemId: itemId,
          parentId: null,
          kind: 'chapter',
          level: 0,
          title: chapter.entry.title,
          orderIndex: index,
          startCharacterOffset: start,
          endCharacterOffset: end,
        ),
      );
      textByDocumentId[documentId] = body;
    }
    final normalizedText = joined.toString();
    final collection = LibraryCollection(
      id: stableContentId,
      sourceId: source.id.value,
      title: detail.title,
      subtitle: null,
      itemCount: chapters.length,
      normalizedCharacterLength: normalizedText.length,
      detectedEncoding: TextEncoding.utf8,
      sourceSize: utf8.encode(normalizedText).length,
      importedAt: DateTime.now().toUtc(),
      author: detail.author,
      description: detail.description,
      metadataSource: 'autoDetected',
      titleSource: 'autoDetected',
      authorSource: detail.author == null ? 'unknown' : 'autoDetected',
    );
    return WebBookReaderContentProjection(
      content: ReaderContent(
        identity: ReaderContentIdentity(
          contentId: stableContentId,
          sourceId: source.id.value,
          sourceKind: ReaderContentSourceKinds.online,
          sourceRevision: _hash(normalizedText),
        ),
        metadata: ReaderContentMetadata.fromCollection(collection),
        documents: documents,
        navigation: navigation,
        normalizedCharacterLength: normalizedText.length,
      ),
      documentTextById: Map.unmodifiable(textByDocumentId),
    );
  }

  Future<WebBookRuntimeResult<T>> _try<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return WebBookRuntimeResult.success(value: await operation());
    } on _WebBookRuntimeException catch (error) {
      return WebBookRuntimeResult.failure(
        failure: error.failure,
        response: error.response,
      );
    } on RemoteHttpException catch (error) {
      return WebBookRuntimeResult.failure(failure: _mapTransportFailure(error));
    } catch (error) {
      return WebBookRuntimeResult.failure(
        failure: WebBookRuntimeFailure(
          kind: WebBookFailureKind.extraction,
          message: '书籍页面解析失败',
          cause: error,
        ),
      );
    }
  }

  Future<(RemoteHttpResponse, String)> _fetchHtml(
    WebBookSource source,
    Uri uri, {
    RemoteHeaders? headers,
  }) async {
    final plan = source.planRequest(uri: uri, headers: headers);
    final response = await transport.execute(plan);
    if (!source.accepts(response.finalUri)) {
      throw _WebBookRuntimeException(
        const WebBookRuntimeFailure(
          kind: WebBookFailureKind.redirectOutsideSource,
          message: '书籍页面重定向地址不属于当前来源',
        ),
        response,
      );
    }
    if (!response.isSuccess) {
      throw _WebBookRuntimeException(
        WebBookRuntimeFailure(
          kind: WebBookFailureKind.http,
          message: '书籍页面返回 HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        ),
        response,
      );
    }
    return (response, response.decodeText());
  }

  Uri _searchUri(WebBookSource source, WebBookSearchRequest request) {
    final endpoint = source.searchEndpoint ?? source.endpoint;
    final parameters = <String, String>{...endpoint.queryParameters};
    parameters.remove('q');
    parameters.removeWhere((key, _) => key == source.searchQueryParameter);
    parameters[source.searchQueryParameter] = request.query.trim();
    if (request.page > 0) parameters['page'] = '${request.page}';
    if (request.pageSize != 20) {
      parameters['pageSize'] = '${request.pageSize}';
    }
    return endpoint.replace(
      queryParameters: parameters.isEmpty ? null : parameters,
    );
  }

  Uri? _nextPageUri({
    required String html,
    required Uri baseUri,
    required WebBookSource source,
    required Set<Uri> visited,
  }) {
    final selector = rules.nextPageSelector;
    if (selector == null || selector.trim().isEmpty) return null;
    final document = html_parser.parse(html);
    final candidates = document.querySelectorAll(selector);
    for (final element in candidates) {
      final href = element.attributes['href'];
      if (href == null || href.trim().isEmpty) continue;
      if (_looksLikeNextChapter(element)) continue;
      final uri = baseUri.resolve(href.trim());
      if (!source.accepts(uri) || !_sameOrigin(baseUri, uri)) continue;
      if (visited.contains(uri)) continue;
      return uri;
    }
    return null;
  }

  static bool _sameOrigin(Uri left, Uri right) =>
      left.scheme.toLowerCase() == right.scheme.toLowerCase() &&
      left.host.toLowerCase() == right.host.toLowerCase() &&
      (left.hasPort ? left.port : _defaultPort(left.scheme)) ==
          (right.hasPort ? right.port : _defaultPort(right.scheme));

  static int _defaultPort(String scheme) =>
      scheme.toLowerCase() == 'https' ? 443 : 80;

  static bool _looksLikeNextChapter(Element element) {
    final signal = [
      element.attributes['rel'],
      element.attributes['class'],
      element.attributes['id'],
      element.text,
    ].whereType<String>().join(' ').toLowerCase();
    return signal.contains('next chapter') ||
        signal.contains('next-chapter') ||
        signal.contains('下一章') ||
        signal.contains('下 一 章');
  }

  static String? _capture(RegExp pattern, String? input) {
    if (input == null) return null;
    return pattern.firstMatch(input)?.group(1);
  }

  String? _firstRegexChapterBody(String html) {
    for (final pattern in rules.chapterBodyPatterns) {
      final body = _capture(pattern, html);
      if (body != null && body.trim().isNotEmpty) return body;
    }
    return null;
  }

  static String? _normalized(String? input) {
    final value = FeedHtmlNormalizer.normalize(input);
    return value.isEmpty ? null : value;
  }

  static String? _normalizedCapture(RegExp pattern, String input) =>
      _normalized(_capture(pattern, input));

  static String? _attribute(String attributes, String name) {
    final escaped = RegExp.escape(name);
    final doubleQuoted = RegExp(
      '$escaped\\s*=\\s*"([^"]*)"',
      caseSensitive: false,
    ).firstMatch(attributes);
    if (doubleQuoted != null) return doubleQuoted.group(1);
    return RegExp(
      "$escaped\\s*=\\s*'([^']*)'",
      caseSensitive: false,
    ).firstMatch(attributes)?.group(1);
  }

  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static WebBookRuntimeFailure _mapTransportFailure(
    RemoteHttpException error,
  ) => WebBookRuntimeFailure(
    kind: error.kind == RemoteHttpFailureKind.httpStatus
        ? WebBookFailureKind.http
        : error.kind == RemoteHttpFailureKind.redirectOutsideSource
        ? WebBookFailureKind.redirectOutsideSource
        : WebBookFailureKind.transport,
    message: error.message,
    statusCode: error.statusCode,
    cause: error,
  );
}

final class _WebBookRuntimeException implements Exception {
  const _WebBookRuntimeException(this.failure, this.response);

  final WebBookRuntimeFailure failure;
  final RemoteHttpResponse? response;
}

@immutable
final class WebBookReaderContentProjection {
  const WebBookReaderContentProjection({
    required this.content,
    required this.documentTextById,
  });

  final ReaderContent content;
  final Map<String, String> documentTextById;
}
