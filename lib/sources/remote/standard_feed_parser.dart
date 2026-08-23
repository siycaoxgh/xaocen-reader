import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../../domain/library/library_entities.dart';
import '../../domain/local_txt/text_encoding.dart';
import '../../domain/reader/reader_content.dart';
import '../../domain/remote/remote_source.dart';
import 'feed_html_normalizer.dart';

/// The two feed formats supported by this offline foundation parser.
enum StandardFeedFormat { rss, atom }

@immutable
final class StandardFeedItem {
  const StandardFeedItem({
    required this.identity,
    required this.title,
    required this.body,
    this.author,
    this.publishedAt,
    this.link,
    this.summary,
    this.imageLinks = const <Uri>[],
  });

  final String identity;
  final String title;
  final String body;
  final String? author;
  final DateTime? publishedAt;
  final Uri? link;
  final String? summary;

  /// Remote image references captured as sidecar metadata. They are never
  /// inserted into canonical text; the Reader may cache them as local files.
  final List<Uri> imageLinks;
}

@immutable
final class StandardFeedParseResult {
  const StandardFeedParseResult({
    required this.source,
    required this.format,
    required this.title,
    required this.items,
    this.author,
    this.description,
  });

  final StandardFeedSource source;
  final StandardFeedFormat format;
  final String title;
  final String? author;
  final String? description;
  final List<StandardFeedItem> items;

  String get stableSourceIdentity => source.id.value;
}

/// Minimal RSS 2.0 / Atom parser. It parses supplied XML only and performs no
/// HTTP, refresh, notification, script, HTML fetch, or subscription work.
final class StandardFeedParser {
  const StandardFeedParser();

  StandardFeedParseResult parse({
    required String xml,
    required StandardFeedSource source,
  }) {
    final document = _parseXml(xml);
    final root = document.rootElement;
    final rootName = root.localName.toLowerCase();
    if (rootName == 'rss') return _parseRss(root, source);
    if (rootName == 'feed') return _parseAtom(root, source);
    throw const StandardFeedParseException('只支持 RSS 2.0 或 Atom feed');
  }

  StandardFeedParseResult _parseRss(
    XmlElement root,
    StandardFeedSource source,
  ) {
    final channel = _child(root, 'channel') ?? root;
    final title = _text(_child(channel, 'title')) ?? '未命名订阅';
    final description = _text(_child(channel, 'description'));
    final author =
        _text(_child(channel, 'creator')) ?? _text(_child(channel, 'author'));
    final items = <StandardFeedItem>[];
    for (final element in _children(channel, 'item')) {
      final itemTitle =
          _text(_child(element, 'title')) ??
          _text(_child(element, 'link')) ??
          '未命名条目';
      final link = _parseUri(_text(_child(element, 'link')));
      final guid = _text(_child(element, 'guid'));
      final publishedAt = _parseDate(
        _text(_child(element, 'pubDate')) ?? _text(_child(element, 'date')),
      );
      final rawSummary = _rawHtml(_child(element, 'description'));
      final encoded = _children(element, 'encoded').firstOrNull;
      // A number of RSS 2.0 feeds (including China Daily) publish the full
      // article in a plain <content> element instead of the namespaced
      // content:encoded element. Prefer encoded when present, then accept
      // the standard un-namespaced form before falling back to description.
      final rawContent = _rawHtml(
        encoded ?? _children(element, 'content').firstOrNull,
      );
      final summary = FeedHtmlNormalizer.normalize(rawSummary);
      final body = FeedHtmlNormalizer.selectBody(
        content: rawContent,
        fallback: rawSummary,
      );
      final imageLinks = FeedHtmlNormalizer.extractImageUris(
        rawContent ?? rawSummary,
        baseUri: source.endpoint,
      );
      final itemAuthor =
          _text(_child(element, 'creator')) ?? _text(_child(element, 'author'));
      final identity = _stableItemIdentity(
        source: source,
        explicitId: guid,
        link: link,
        title: itemTitle,
        publishedAt: publishedAt,
      );
      items.add(
        StandardFeedItem(
          identity: identity,
          title: itemTitle,
          body: body,
          author: itemAuthor,
          publishedAt: publishedAt,
          link: link,
          summary: summary,
          imageLinks: imageLinks,
        ),
      );
    }
    return StandardFeedParseResult(
      source: source,
      format: StandardFeedFormat.rss,
      title: title,
      author: author,
      description: description,
      items: List.unmodifiable(items),
    );
  }

  StandardFeedParseResult _parseAtom(
    XmlElement root,
    StandardFeedSource source,
  ) {
    final title = _text(_child(root, 'title')) ?? '未命名订阅';
    final subtitle = _text(_child(root, 'subtitle'));
    final feedAuthor = _atomAuthor(_child(root, 'author'));
    final items = <StandardFeedItem>[];
    for (final entry in _children(root, 'entry')) {
      final itemTitle = _text(_child(entry, 'title')) ?? '未命名条目';
      final link = _atomLink(entry);
      final explicitId = _text(_child(entry, 'id'));
      final publishedAt = _parseDate(
        _text(_child(entry, 'published')) ?? _text(_child(entry, 'updated')),
      );
      final rawSummary = _rawHtml(_child(entry, 'summary'));
      final rawContent = _rawHtml(_child(entry, 'content'));
      final summary = FeedHtmlNormalizer.normalize(rawSummary);
      final body = FeedHtmlNormalizer.selectBody(
        content: rawContent,
        fallback: rawSummary,
      );
      final imageLinks = FeedHtmlNormalizer.extractImageUris(
        rawContent ?? rawSummary,
        baseUri: source.endpoint,
      );
      final identity = _stableItemIdentity(
        source: source,
        explicitId: explicitId,
        link: link,
        title: itemTitle,
        publishedAt: publishedAt,
      );
      items.add(
        StandardFeedItem(
          identity: identity,
          title: itemTitle,
          body: body,
          author: _atomAuthor(_child(entry, 'author')) ?? feedAuthor,
          publishedAt: publishedAt,
          link: link,
          summary: summary,
          imageLinks: imageLinks,
        ),
      );
    }
    return StandardFeedParseResult(
      source: source,
      format: StandardFeedFormat.atom,
      title: title,
      author: feedAuthor,
      description: subtitle,
      items: List.unmodifiable(items),
    );
  }

  /// Builds the existing runtime ReaderContent projection without creating a
  /// second Reader or changing persistence. A later import layer can write
  /// these document bodies to managed storage before opening Reader.
  StandardFeedReaderContentProjection toReaderContent(
    StandardFeedParseResult feed, {
    String? contentId,
  }) {
    final collectionId =
        contentId ?? 'rss-collection:${_hash(feed.source.id.value)}';
    final documents = <LibraryDocument>[];
    final navigation = <LibraryTocEntry>[];
    final textByDocumentId = <String, String>{};
    final joined = StringBuffer();
    for (var index = 0; index < feed.items.length; index++) {
      final item = feed.items[index];
      if (joined.isNotEmpty) joined.write('\n\n');
      final start = joined.length;
      final body = item.body.trim().isEmpty ? item.title : item.body.trim();
      joined.write(body);
      final end = joined.length;
      final itemId = 'rss-item:${item.identity}';
      final documentId = '$collectionId:document:$index';
      documents.add(
        LibraryDocument(
          id: documentId,
          itemId: itemId,
          storagePath: 'rss://$itemId',
          mediaType: 'text/plain',
          startCharacterOffset: start,
          endCharacterOffset: end,
          contentHash: _hash(body),
          normalizationVersion: 'rss-text-v1',
        ),
      );
      navigation.add(
        LibraryTocEntry(
          id: '$collectionId:toc:$index',
          collectionId: collectionId,
          itemId: itemId,
          parentId: null,
          kind: 'chapter',
          level: 0,
          title: item.title,
          orderIndex: index,
          startCharacterOffset: start,
          endCharacterOffset: end,
        ),
      );
      textByDocumentId[documentId] = body;
    }
    final normalizedText = joined.toString();
    final collection = LibraryCollection(
      id: collectionId,
      sourceId: feed.source.id.value,
      title: feed.title,
      subtitle: null,
      itemCount: feed.items.length,
      normalizedCharacterLength: normalizedText.length,
      detectedEncoding: TextEncoding.utf8,
      sourceSize: utf8.encode(normalizedText).length,
      importedAt: DateTime.now().toUtc(),
      author: feed.author,
      description: feed.description,
      metadataSource: 'autoDetected',
      titleSource: 'autoDetected',
      authorSource: feed.author == null ? 'unknown' : 'autoDetected',
    );
    final content = ReaderContent(
      identity: ReaderContentIdentity(
        contentId: collection.id,
        sourceId: collection.sourceId,
        sourceKind: ReaderContentSourceKinds.rss,
        sourceRevision: _hash(normalizedText),
      ),
      metadata: ReaderContentMetadata.fromCollection(collection),
      documents: documents,
      navigation: navigation,
      normalizedCharacterLength: normalizedText.length,
    );
    return StandardFeedReaderContentProjection(
      content: content,
      documentTextById: Map.unmodifiable(textByDocumentId),
    );
  }

  XmlDocument _parseXml(String xml) {
    try {
      return XmlDocument.parse(xml);
    } catch (error) {
      throw StandardFeedParseException('Feed XML 无法解析: $error');
    }
  }

  static XmlElement? _child(XmlElement parent, String localName) =>
      _children(parent, localName).firstOrNull;

  static Iterable<XmlElement> _children(XmlElement parent, String localName) =>
      parent.children.whereType<XmlElement>().where(
        (element) => element.localName.toLowerCase() == localName.toLowerCase(),
      );

  static String? _text(XmlElement? element) {
    final value = element?.innerText.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Keeps CDATA/nested HTML markup intact for the normalizer. `innerText`
  /// would flatten nested `<p>`/`<br>` nodes before we can restore line breaks.
  static String? _rawHtml(XmlElement? element) {
    if (element == null) return null;
    // Atom feeds commonly split a single HTML body into several CDATA
    // sections.  Serializing those nodes reintroduces the XML delimiters
    // (<![CDATA[ ... ]]>), which then leak into the Reader as visible "]]>"
    // text between paragraphs.  Read CDATA/text nodes by value while keeping
    // real nested elements serialized for the HTML normalizer.
    final value = element.children.map((node) {
      if (node is XmlCDATA) return node.value;
      if (node is XmlText) return node.value;
      return node.toXmlString();
    }).join();
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return normalized
        .replaceFirst(RegExp(r'^<!\[CDATA\[', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\]\]>\s*$', caseSensitive: false), '')
        .trim();
  }

  static String? _atomAuthor(XmlElement? author) =>
      _text(_child(author ?? _emptyElement(), 'name')) ?? _text(author);

  static Uri? _atomLink(XmlElement entry) {
    final links = _children(entry, 'link').toList(growable: false);
    final alternate = links.firstWhereOrNull(
      (link) => (link.getAttribute('rel') ?? 'alternate') == 'alternate',
    );
    final href =
        alternate?.getAttribute('href') ??
        links.firstOrNull?.getAttribute('href');
    return _parseUri(href);
  }

  static Uri? _parseUri(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    return uri == null || !uri.hasScheme ? null : uri;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  static String _stableItemIdentity({
    required StandardFeedSource source,
    required String? explicitId,
    required Uri? link,
    required String title,
    required DateTime? publishedAt,
  }) {
    final seed = explicitId?.trim().isNotEmpty == true
        ? explicitId!.trim()
        : link?.toString() ??
              '$title|${publishedAt?.toUtc().toIso8601String() ?? ''}';
    return '${source.id.value}:${_hash(seed)}';
  }

  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static XmlElement _emptyElement() => XmlElement(XmlName('empty'));
}

@immutable
final class StandardFeedReaderContentProjection {
  const StandardFeedReaderContentProjection({
    required this.content,
    required this.documentTextById,
  });

  final ReaderContent content;
  final Map<String, String> documentTextById;
}

final class StandardFeedParseException implements Exception {
  const StandardFeedParseException(this.message);

  final String message;

  @override
  String toString() => 'StandardFeedParseException: $message';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}
