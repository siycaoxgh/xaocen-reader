import '../../data/repositories/feed_subscription_repository.dart';
import '../../domain/remote/feed_subscription.dart';
import '../../domain/remote/remote_source.dart';
import 'remote_http_transport.dart';

/// Coordinates explicit user subscription actions and manual refreshes.
/// There is intentionally no timer, background isolate, notification or sync
/// behavior in this service.
final class FeedSubscriptionService {
  const FeedSubscriptionService({
    required this.repository,
    required this.transport,
  });

  final FeedSubscriptionRepository repository;
  final RemoteHttpTransport transport;

  Future<List<FeedSubscription>> listSubscriptions() => repository.list();

  Future<FeedSubscription> addSubscription(StandardFeedSource source) =>
      repository.add(source);

  Future<bool> removeSubscription(String sourceId) =>
      repository.remove(sourceId);

  Future<FeedSubscription> refresh(String sourceId) async {
    final subscription = await repository.find(sourceId);
    if (subscription == null) {
      throw StateError('RSS subscription not found: $sourceId');
    }
    final source = subscription.toSource();
    final fetched = await transport.fetchStandardFeed(source: source);
    return repository.saveRefresh(source: source, feed: fetched.feed);
  }
}
