import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'remote_source.dart';

/// A persisted article snapshot owned by one profile's feed subscription.
///
/// The [identity] comes from the source adapter (guid/id, link, or its stable
/// fallback). It is not a Reader locator and does not replace any local book
/// identity.
@immutable
final class FeedArticle {
  FeedArticle({
    required String identity,
    required String title,
    required String body,
    this.author,
    this.publishedAt,
    this.link,
    this.summary,
    List<Uri> imageLinks = const <Uri>[],
    required this.firstSeenAt,
    required this.updatedAt,
  }) : identity = _requiredText(identity, 'identity'),
       title = _requiredText(title, 'title'),
       body = _requiredText(body, 'body'),
       imageLinks = List.unmodifiable(imageLinks);

  final String identity;
  final String title;
  final String body;
  final String? author;
  final DateTime? publishedAt;
  final Uri? link;
  final String? summary;
  final List<Uri> imageLinks;
  final DateTime firstSeenAt;
  final DateTime updatedAt;

  FeedArticle copyWith({
    String? title,
    String? body,
    String? author,
    DateTime? publishedAt,
    Uri? link,
    String? summary,
    List<Uri>? imageLinks,
    DateTime? updatedAt,
  }) => FeedArticle(
    identity: identity,
    title: title ?? this.title,
    body: body ?? this.body,
    author: author ?? this.author,
    publishedAt: publishedAt ?? this.publishedAt,
    link: link ?? this.link,
    summary: summary ?? this.summary,
    imageLinks: imageLinks ?? this.imageLinks,
    firstSeenAt: firstSeenAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'identity': identity,
    'title': title,
    'body': body,
    if (author != null) 'author': author,
    if (publishedAt != null)
      'publishedAt': publishedAt!.toUtc().toIso8601String(),
    if (link != null) 'link': link.toString(),
    if (summary != null) 'summary': summary,
    if (imageLinks.isNotEmpty)
      'imageLinks': imageLinks.map((uri) => uri.toString()).toList(),
    'firstSeenAt': firstSeenAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static FeedArticle fromJson(Object? value) {
    if (value is! Map ||
        value['identity'] is! String ||
        value['title'] is! String ||
        value['body'] is! String ||
        value['firstSeenAt'] is! String ||
        value['updatedAt'] is! String) {
      throw const FormatException('invalid feed article');
    }
    return FeedArticle(
      identity: value['identity'] as String,
      title: value['title'] as String,
      body: value['body'] as String,
      author: _optionalString(value['author']),
      publishedAt: _optionalDate(value['publishedAt']),
      link: _optionalUri(value['link']),
      summary: _optionalString(value['summary']),
      imageLinks: _uriList(value['imageLinks']),
      firstSeenAt: _requiredDate(value['firstSeenAt'], 'firstSeenAt'),
      updatedAt: _requiredDate(value['updatedAt'], 'updatedAt'),
    );
  }
}

List<Uri> _uriList(Object? value) {
  if (value is! List) return const <Uri>[];
  return List.unmodifiable(
    value
        .whereType<String>()
        .map(Uri.tryParse)
        .whereType<Uri>()
        .where((uri) => {'http', 'https'}.contains(uri.scheme.toLowerCase())),
  );
}

/// Profile-scoped persisted subscription metadata and article snapshots.
@immutable
final class FeedSubscription {
  FeedSubscription({
    required String sourceId,
    required this.endpoint,
    required String format,
    required String title,
    this.author,
    this.description,
    required this.subscribedAt,
    required this.updatedAt,
    this.lastRefreshedAt,
    this.followRedirects = false,
    this.maxResponseBytes = 8 * 1024 * 1024,
    this.timeout = const Duration(seconds: 20),
    List<FeedArticle> articles = const <FeedArticle>[],
  }) : sourceId = _requiredText(sourceId, 'sourceId'),
       format = _requiredText(format, 'format'),
       title = _requiredText(title, 'title'),
       articles = _freezeArticles(articles) {
    if (endpoint.scheme != 'http' && endpoint.scheme != 'https') {
      throw ArgumentError.value(endpoint, 'endpoint', '只允许 http/https Feed');
    }
    if (maxResponseBytes <= 0 || timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Feed 请求资源限制必须为正数');
    }
  }

  final String sourceId;
  final Uri endpoint;
  final String format;
  final String title;
  final String? author;
  final String? description;
  final DateTime subscribedAt;
  final DateTime updatedAt;
  final DateTime? lastRefreshedAt;
  final bool followRedirects;
  final int maxResponseBytes;
  final Duration timeout;
  final List<FeedArticle> articles;

  StandardFeedSource toSource() => StandardFeedSource(
    id: RemoteSourceId(sourceId),
    endpoint: endpoint,
    format: format,
    requestCapabilities: RemoteRequestCapabilities(
      followRedirects: followRedirects,
      maxResponseBytes: maxResponseBytes,
      timeout: timeout,
    ),
  );

  FeedSubscription copyWith({
    Uri? endpoint,
    String? format,
    String? title,
    String? author,
    String? description,
    DateTime? updatedAt,
    DateTime? lastRefreshedAt,
    bool? followRedirects,
    int? maxResponseBytes,
    Duration? timeout,
    List<FeedArticle>? articles,
  }) => FeedSubscription(
    sourceId: sourceId,
    endpoint: endpoint ?? this.endpoint,
    format: format ?? this.format,
    title: title ?? this.title,
    author: author ?? this.author,
    description: description ?? this.description,
    subscribedAt: subscribedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    followRedirects: followRedirects ?? this.followRedirects,
    maxResponseBytes: maxResponseBytes ?? this.maxResponseBytes,
    timeout: timeout ?? this.timeout,
    articles: articles ?? this.articles,
  );

  Map<String, Object?> toJson() => {
    'sourceId': sourceId,
    'endpoint': endpoint.toString(),
    'format': format,
    'title': title,
    if (author != null) 'author': author,
    if (description != null) 'description': description,
    'subscribedAt': subscribedAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    if (lastRefreshedAt != null)
      'lastRefreshedAt': lastRefreshedAt!.toUtc().toIso8601String(),
    'followRedirects': followRedirects,
    'maxResponseBytes': maxResponseBytes,
    'timeoutMillis': timeout.inMilliseconds,
    'articles': articles.map((article) => article.toJson()).toList(),
  };

  static FeedSubscription fromJson(Object? value) {
    if (value is! Map ||
        value['sourceId'] is! String ||
        value['endpoint'] is! String ||
        value['format'] is! String ||
        value['title'] is! String ||
        value['subscribedAt'] is! String ||
        value['updatedAt'] is! String ||
        value['articles'] is! List) {
      throw const FormatException('invalid feed subscription');
    }
    final endpoint = Uri.tryParse(value['endpoint'] as String);
    if (endpoint == null) throw const FormatException('invalid feed endpoint');
    final timeoutMillis = value['timeoutMillis'];
    final articles = <FeedArticle>[];
    for (final item in value['articles'] as List) {
      articles.add(FeedArticle.fromJson(item));
    }
    return FeedSubscription(
      sourceId: value['sourceId'] as String,
      endpoint: endpoint,
      format: value['format'] as String,
      title: value['title'] as String,
      author: _optionalString(value['author']),
      description: _optionalString(value['description']),
      subscribedAt: _requiredDate(value['subscribedAt'], 'subscribedAt'),
      updatedAt: _requiredDate(value['updatedAt'], 'updatedAt'),
      lastRefreshedAt: _optionalDate(value['lastRefreshedAt']),
      followRedirects: value['followRedirects'] == true,
      maxResponseBytes: value['maxResponseBytes'] is int
          ? value['maxResponseBytes'] as int
          : 8 * 1024 * 1024,
      timeout: Duration(
        milliseconds: timeoutMillis is int ? timeoutMillis : 20000,
      ),
      articles: articles,
    );
  }

  static List<FeedArticle> _freezeArticles(List<FeedArticle> values) {
    final identities = <String>{};
    for (final article in values) {
      if (!identities.add(article.identity)) {
        throw ArgumentError.value(
          values,
          'articles',
          'Feed article identity 重复',
        );
      }
    }
    return UnmodifiableListView(values);
  }
}

String _requiredText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, name, '不能为空');
  return normalized;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('invalid optional string');
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime _requiredDate(Object? value, String name) {
  if (value is! String) throw FormatException('invalid $name');
  final date = DateTime.tryParse(value);
  if (date == null) throw FormatException('invalid $name');
  return date.toUtc();
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('invalid optional date');
  final date = DateTime.tryParse(value);
  if (date == null) throw const FormatException('invalid optional date');
  return date.toUtc();
}

Uri? _optionalUri(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('invalid optional URI');
  final uri = Uri.tryParse(value);
  if (uri == null) throw const FormatException('invalid optional URI');
  return uri;
}
