import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/remote/feed_subscription.dart';
import '../../domain/remote/remote_source.dart';
import '../../sources/remote/standard_feed_parser.dart';
import '../data_root.dart';

/// Profile-scoped persistence for StandardFeed subscriptions and snapshots.
///
/// This deliberately uses a small atomically-written JSON document under the
/// current [DataRoot] settings directory. RSS subscriptions are profile data,
/// but they do not need a new Drift table or a second database truth at this
/// stage.
final class FeedSubscriptionRepository {
  FeedSubscriptionRepository(this.root);

  static const int formatVersion = 1;
  static const String fileName = 'rss_subscriptions.json';

  final DataRoot root;

  File get storageFile => File(p.join(root.settingsDirectory.path, fileName));

  Future<List<FeedSubscription>> list() async {
    final subscriptions = await _read();
    subscriptions.sort((a, b) => a.sourceId.compareTo(b.sourceId));
    return List.unmodifiable(subscriptions);
  }

  Future<FeedSubscription?> find(String sourceId) async {
    final normalized = _requireId(sourceId);
    for (final subscription in await _read()) {
      if (subscription.sourceId == normalized) return subscription;
    }
    return null;
  }

  /// Adds a subscription idempotently. Re-adding the same source updates its
  /// endpoint/request limits without duplicating persisted articles.
  Future<FeedSubscription> add(StandardFeedSource source) async {
    final subscriptions = await _read();
    final now = DateTime.now().toUtc();
    final index = subscriptions.indexWhere(
      (subscription) => subscription.sourceId == source.id.value,
    );
    final current = index < 0 ? null : subscriptions[index];
    final value = FeedSubscription(
      sourceId: source.id.value,
      endpoint: source.endpoint,
      format: source.format,
      title: current?.title ?? source.id.value,
      author: current?.author,
      description: current?.description,
      subscribedAt: current?.subscribedAt ?? now,
      updatedAt: now,
      lastRefreshedAt: current?.lastRefreshedAt,
      followRedirects: source.requestCapabilities.followRedirects,
      maxResponseBytes: source.requestCapabilities.maxResponseBytes,
      timeout: source.requestCapabilities.timeout,
      articles: current?.articles ?? const <FeedArticle>[],
    );
    if (index < 0) {
      subscriptions.add(value);
    } else {
      subscriptions[index] = value;
    }
    await _write(subscriptions);
    return value;
  }

  Future<bool> remove(String sourceId) async {
    final normalized = _requireId(sourceId);
    final subscriptions = await _read();
    final before = subscriptions.length;
    subscriptions.removeWhere((item) => item.sourceId == normalized);
    if (subscriptions.length == before) return false;
    await _write(subscriptions);
    return true;
  }

  /// Upserts the latest parser snapshot by stable article identity.
  /// Existing articles are updated in place; articles omitted by a feed window
  /// remain persisted rather than being silently lost.
  Future<FeedSubscription> saveRefresh({
    required StandardFeedSource source,
    required StandardFeedParseResult feed,
    DateTime? refreshedAt,
  }) async {
    final subscriptions = await _read();
    final index = subscriptions.indexWhere(
      (subscription) => subscription.sourceId == source.id.value,
    );
    final now = (refreshedAt ?? DateTime.now()).toUtc();
    final existing = index < 0 ? null : subscriptions[index];
    final oldByIdentity = <String, FeedArticle>{
      for (final article in existing?.articles ?? const <FeedArticle>[])
        article.identity: article,
    };
    final merged = <FeedArticle>[];
    final seen = <String>{};
    for (final item in feed.items) {
      if (!seen.add(item.identity)) continue;
      final old = oldByIdentity.remove(item.identity);
      merged.add(_mergeArticle(old, item, now));
    }
    // Keep previously persisted articles that are outside the current feed
    // window, in their existing order and with their original identity.
    merged.addAll(oldByIdentity.values);
    final value = FeedSubscription(
      sourceId: source.id.value,
      endpoint: source.endpoint,
      format: source.format,
      title: feed.title,
      author: feed.author,
      description: feed.description,
      subscribedAt: existing?.subscribedAt ?? now,
      updatedAt: now,
      lastRefreshedAt: now,
      followRedirects: source.requestCapabilities.followRedirects,
      maxResponseBytes: source.requestCapabilities.maxResponseBytes,
      timeout: source.requestCapabilities.timeout,
      articles: merged,
    );
    if (index < 0) {
      subscriptions.add(value);
    } else {
      subscriptions[index] = value;
    }
    await _write(subscriptions);
    return value;
  }

  Future<List<FeedSubscription>> _read() async {
    if (!await storageFile.exists()) return <FeedSubscription>[];
    try {
      final decoded = jsonDecode(await storageFile.readAsString());
      if (decoded is! Map || decoded['subscriptions'] is! List) {
        throw const FormatException('invalid subscription store');
      }
      final storedProfileId = decoded['profileId'];
      final storedRootId = decoded['rootId'];
      if (storedProfileId is String && storedProfileId != root.profileId) {
        throw const FormatException(
          'subscription store belongs to another profile',
        );
      }
      if (storedRootId is String && storedRootId != root.rootId) {
        throw const FormatException(
          'subscription store belongs to another data root',
        );
      }
      final result = <FeedSubscription>[];
      final identities = <String>{};
      for (final value in decoded['subscriptions'] as List) {
        final subscription = FeedSubscription.fromJson(value);
        if (!identities.add(subscription.sourceId)) {
          throw const FormatException('duplicate feed subscription');
        }
        result.add(subscription);
      }
      return result;
    } catch (error) {
      throw DataRootException('cannot read RSS subscriptions: $error');
    }
  }

  Future<void> _write(List<FeedSubscription> subscriptions) async {
    await storageFile.parent.create(recursive: true);
    final payload = <String, Object?>{
      'formatVersion': formatVersion,
      'profileId': root.profileId,
      'rootId': root.rootId,
      'subscriptions': subscriptions.map((item) => item.toJson()).toList(),
    };
    final temporary = File('${storageFile.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await temporary.rename(storageFile.path);
  }

  static FeedArticle _mergeArticle(
    FeedArticle? old,
    StandardFeedItem item,
    DateTime now,
  ) {
    if (old == null) {
      return FeedArticle(
        identity: item.identity,
        title: item.title,
        body: item.body,
        author: item.author,
        publishedAt: item.publishedAt,
        link: item.link,
        summary: item.summary,
        imageLinks: item.imageLinks,
        firstSeenAt: now,
        updatedAt: now,
      );
    }
    return FeedArticle(
      identity: old.identity,
      title: item.title,
      body: item.body,
      author: item.author,
      publishedAt: item.publishedAt,
      link: item.link,
      summary: item.summary,
      imageLinks: item.imageLinks,
      firstSeenAt: old.firstSeenAt,
      updatedAt: now,
    );
  }

  static String _requireId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const DataRootException('feed sourceId must not be empty');
    }
    return normalized;
  }
}
