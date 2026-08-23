import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/sync/profile_sync_boundary.dart';

void main() {
  test('profile scope keeps profile and DataRoot identities distinct', () {
    const scope = ProfileDataScope(profileId: 'default', rootId: 'root-1');
    expect(scope.profileId, isNot(scope.rootId));
  });

  test('membership key is stable and includes its profile scope', () {
    final membership = ProfileMembership(
      profileId: 'default',
      entityId: 'book-1',
      kind: ProfileMembershipKind.libraryCollection,
      addedAt: DateTime.utc(2026, 1, 1),
    );

    expect(membership.stableKey, 'default:library_collection:book-1');
  });

  test(
    'sync boundary classifies user state, content, and account separately',
    () {
      expect(
        SyncBoundary.classify(SyncEntityType.readerProgress).disposition,
        SyncDisposition.syncable,
      );
      expect(
        SyncBoundary.classify(SyncEntityType.normalizedContent).disposition,
        SyncDisposition.localOnly,
      );
      expect(
        SyncBoundary.classify(SyncEntityType.profile).disposition,
        SyncDisposition.deferred,
      );
    },
  );

  test('syncable changes project to the existing SyncOutbox shape', () {
    final spec = SyncBoundary.outboxSpec(
      scope: const ProfileDataScope(profileId: 'default', rootId: 'root-1'),
      entityType: SyncEntityType.readerProgress,
      entityId: 'book-1',
      operation: 'upsert',
      payload: const <String, Object?>{'offset': 42},
    );

    expect(spec.profileId, 'default');
    expect(spec.rootId, 'root-1');
    expect(spec.entityType, 'reader_progress');
    expect(spec.payload['offset'], 42);
  });

  test('local-only content cannot enter the SyncOutbox boundary', () {
    expect(
      () => SyncBoundary.outboxSpec(
        scope: const ProfileDataScope(profileId: 'default', rootId: 'root-1'),
        entityType: SyncEntityType.normalizedContent,
        entityId: 'book-1',
        operation: 'upsert',
      ),
      throwsArgumentError,
    );
  });

  test('membership kinds remain separate from source/content kinds', () {
    expect(ProfileMembershipKind.subscription.wireName, 'subscription');
    expect(SyncEntityType.sourceRule.wireName, 'source_rule');
  });
}
