import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../domain/remote/remote_source.dart';
import '../../domain/remote/web_source_contracts.dart';
import 'feed_html_normalizer.dart';

/// A value extractor relative to the element selected by a rule.
///
/// When [selector] is null, the selected element itself is read. When
/// [attribute] is set, the attribute value is read instead of element text.
/// This keeps rule data separate from the runtime and supports both generic
/// sites and pages whose identity is carried by a data attribute.
@immutable
final class WebBookFieldSelector {
  const WebBookFieldSelector({
    this.selector,
    this.fallbackSelectors = const <String>[],
    this.attribute,
    this.removePrefix,
  });

  const WebBookFieldSelector.text()
    : selector = null,
      fallbackSelectors = const <String>[],
      attribute = null,
      removePrefix = null;

  const WebBookFieldSelector.fromAttribute(String name)
    : selector = null,
      fallbackSelectors = const <String>[],
      attribute = name,
      removePrefix = null;

  final String? selector;
  final List<String> fallbackSelectors;
  final String? attribute;
  final String? removePrefix;

  String? read(Element root) {
    Element? element;
    if (selector == null) {
      element = root;
    } else {
      element = root.querySelector(selector!);
      if (element == null) {
        for (final fallback in fallbackSelectors) {
          element = root.querySelector(fallback);
          if (element != null) break;
        }
      }
    }
    if (element == null) return null;
    final raw = attribute == null
        ? element.innerHtml
        : element.attributes[attribute!];
    var normalized = FeedHtmlNormalizer.normalize(raw);
    if (removePrefix != null && normalized.startsWith(removePrefix!)) {
      normalized = normalized.substring(removePrefix!.length).trim();
    }
    return normalized.isEmpty ? null : normalized;
  }
}

/// Data-only CSS rule configuration for a static HTML WebBook source.
///
/// The engine supports selectors and bounded attribute extraction only. It
/// does not execute scripts, evaluate page code, load WebViews or follow
/// arbitrary embedded resources.
@immutable
final class WebBookCssRuleSet {
  const WebBookCssRuleSet({
    required this.id,
    required this.searchItemSelector,
    required this.searchTitle,
    required this.detailSelector,
    required this.detailTitle,
    required this.tocEntrySelector,
    required this.chapterBodySelector,
    this.searchAuthor,
    this.searchLinkSelector,
    this.detailAuthor,
    this.detailDescription,
    this.tocTitle = const WebBookFieldSelector.text(),
    this.searchBookKeyAttribute = 'data-book-key',
    this.detailBookKeyAttribute = 'data-book-key',
    this.chapterKeyAttribute = 'data-chapter-key',
    this.hrefAttribute = 'href',
    this.chapterNextPageSelector,
  });

  final String id;
  final String searchItemSelector;
  final WebBookFieldSelector searchTitle;
  final WebBookFieldSelector? searchAuthor;
  final String? searchLinkSelector;
  final String detailSelector;
  final WebBookFieldSelector detailTitle;
  final WebBookFieldSelector? detailAuthor;
  final WebBookFieldSelector? detailDescription;
  final String tocEntrySelector;
  final WebBookFieldSelector tocTitle;
  final String chapterBodySelector;

  /// Optional selector for a link to the next page of the same chapter.
  /// When absent, a chapter is treated as a single page.
  final String? chapterNextPageSelector;
  final String? searchBookKeyAttribute;
  final String? detailBookKeyAttribute;
  final String? chapterKeyAttribute;
  final String hrefAttribute;
}

@immutable
final class WebBookRuleDetailData {
  const WebBookRuleDetailData({
    required this.root,
    this.bookKey,
    this.title,
    this.author,
    this.description,
  });

  final Element root;
  final String? bookKey;
  final String? title;
  final String? author;
  final String? description;
}

/// Generic static HTML rule evaluator.
final class WebBookRuleEngine {
  WebBookRuleEngine(this.rules);

  final WebBookCssRuleSet rules;

  List<WebBookSearchResult> search({
    required String html,
    required Uri baseUri,
    required WebBookSource source,
  }) {
    final document = html_parser.parse(html);
    final results = <WebBookSearchResult>[];
    for (final element in document.querySelectorAll(rules.searchItemSelector)) {
      final title = rules.searchTitle.read(element);
      final link = rules.searchLinkSelector == null
          ? element
          : element.querySelector(rules.searchLinkSelector!);
      final href = link?.attributes[rules.hrefAttribute];
      if (title == null || href == null || href.trim().isEmpty) {
        continue;
      }
      final uri = baseUri.resolve(href);
      if (!source.accepts(uri)) continue;
      final key =
          _attribute(element, rules.searchBookKeyAttribute) ??
          _stableBookKey(uri);
      results.add(
        WebBookSearchResult(
          bookKey: key,
          title: title,
          detailUri: uri,
          author: rules.searchAuthor?.read(element),
        ),
      );
    }
    return results;
  }

  WebBookRuleDetailData? detail({required String html}) {
    final document = html_parser.parse(html);
    final root = document.querySelector(rules.detailSelector);
    if (root == null) return null;
    return WebBookRuleDetailData(
      root: root,
      bookKey: _attribute(root, rules.detailBookKeyAttribute),
      title: rules.detailTitle.read(root),
      author: rules.detailAuthor?.read(root),
      description: rules.detailDescription?.read(root),
    );
  }

  List<WebBookTocEntry> tableOfContents({
    required String html,
    required Uri baseUri,
    required WebBookSource source,
  }) {
    final document = html_parser.parse(html);
    final entries = <WebBookTocEntry>[];
    for (final element in document.querySelectorAll(rules.tocEntrySelector)) {
      final href = element.attributes[rules.hrefAttribute];
      final title = rules.tocTitle.read(element);
      if (href == null || href.trim().isEmpty || title == null) continue;
      final uri = baseUri.resolve(href);
      if (!source.accepts(uri)) continue;
      final key = _attribute(element, rules.chapterKeyAttribute);
      final chapterKey = key ?? _stableChapterKey(uri, title);
      entries.add(
        WebBookTocEntry(
          chapterKey: chapterKey,
          title: title,
          orderIndex: entries.length,
          chapterUri: uri,
        ),
      );
    }
    return entries;
  }

  String? chapterBody({required String html}) {
    final document = html_parser.parse(html);
    final element = document.querySelector(rules.chapterBodySelector);
    if (element == null) return null;
    return element.innerHtml;
  }

  static String? _attribute(Element element, String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final value = element.attributes[name];
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  static String _stableChapterKey(Uri uri, String title) =>
      'chapter-${sha256.convert(utf8.encode('${uri.toString()}\n$title')).toString().substring(0, 16)}';

  static String _stableBookKey(Uri uri) =>
      'book-${sha256.convert(utf8.encode(uri.toString())).toString().substring(0, 16)}';
}
