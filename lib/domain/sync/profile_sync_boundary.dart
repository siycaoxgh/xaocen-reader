import 'package:flutter/foundation.dart';

/// A local storage scope owned by a profile. The scope identity is deliberately
/// separate from UserProfile and from the physical DataRoot directory.
@immutable
final class ProfileDataScope {
  const ProfileDataScope({required this.profileId, required this.rootId})
    : assert(profileId != ''),
      assert(rootId != '');

  final String profileId;
  final String rootId;
}

enum ProfileMembershipKind { libraryCollection, subscription, sourceRule }

extension ProfileMembershipKindName on ProfileMembershipKind {
  String get wireName => switch (this) {
    ProfileMembershipKind.libraryCollection => 'library_collection',
    ProfileMembershipKind.subscription => 'subscription',
    ProfileMembershipKind.sourceRule => 'source_rule',
  };
}

/// Membership is a profile-to-entity relationship, not a replacement for the
/// collection/content identity itself.
@immutable
final class ProfileMembership {
  const ProfileMembership({
    required this.profileId,
    required this.entityId,
    required this.kind,
    required this.addedAt,
  });

  final String profileId;
  final String entityId;
  final ProfileMembershipKind kind;
  final DateTime addedAt;

  String get stableKey => '$profileId:${kind.wireName}:$entityId';
}

enum SyncEntityType {
  profile,
  libraryMembership,
  collectionMetadata,
  readerProgress,
  bookmark,
  history,
  subscription,
  sourceRule,
  readerPreferences,
  canonicalContent,
  normalizedContent,
  rawSource,
  coverFile,
  cache,
  authSecret,
  ttsSession,
}

extension SyncEntityTypeName on SyncEntityType {
  String get wireName => switch (this) {
    SyncEntityType.profile => 'profile',
    SyncEntityType.libraryMembership => 'library_membership',
    SyncEntityType.collectionMetadata => 'collection_metadata',
    SyncEntityType.readerProgress => 'reader_progress',
    SyncEntityType.bookmark => 'bookmark',
    SyncEntityType.history => 'history',
    SyncEntityType.subscription => 'subscription',
    SyncEntityType.sourceRule => 'source_rule',
    SyncEntityType.readerPreferences => 'reader_preferences',
    SyncEntityType.canonicalContent => 'canonical_content',
    SyncEntityType.normalizedContent => 'normalized_content',
    SyncEntityType.rawSource => 'raw_source',
    SyncEntityType.coverFile => 'cover_file',
    SyncEntityType.cache => 'cache',
    SyncEntityType.authSecret => 'auth_secret',
    SyncEntityType.ttsSession => 'tts_session',
  };
}

enum SyncDisposition { syncable, localOnly, deferred }

@immutable
final class SyncEntityClassification {
  const SyncEntityClassification(this.disposition, this.reason);

  final SyncDisposition disposition;
  final String reason;

  bool get isSyncable => disposition == SyncDisposition.syncable;
}

/// The single product truth for what may cross a future SyncProvider boundary.
final class SyncBoundary {
  const SyncBoundary._();

  static SyncEntityClassification classify(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.libraryMembership:
      case SyncEntityType.collectionMetadata:
      case SyncEntityType.readerProgress:
      case SyncEntityType.bookmark:
      case SyncEntityType.history:
      case SyncEntityType.subscription:
      case SyncEntityType.sourceRule:
      case SyncEntityType.readerPreferences:
        return const SyncEntityClassification(
          SyncDisposition.syncable,
          'profile-scoped metadata or user state',
        );
      case SyncEntityType.profile:
        return const SyncEntityClassification(
          SyncDisposition.deferred,
          'account identity and conflict policy are not implemented locally',
        );
      case SyncEntityType.canonicalContent:
      case SyncEntityType.normalizedContent:
      case SyncEntityType.rawSource:
      case SyncEntityType.coverFile:
      case SyncEntityType.cache:
      case SyncEntityType.authSecret:
      case SyncEntityType.ttsSession:
        return const SyncEntityClassification(
          SyncDisposition.localOnly,
          'device content, file, secret, cache, or transient runtime state',
        );
    }
  }

  static SyncOutboxSpec outboxSpec({
    required ProfileDataScope scope,
    required SyncEntityType entityType,
    required String entityId,
    required String operation,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    final classification = classify(entityType);
    if (!classification.isSyncable) {
      throw ArgumentError(
        'entity is not eligible for SyncOutbox: ${entityType.wireName}',
      );
    }
    _requireText(entityId, 'entityId');
    _requireText(operation, 'operation');
    return SyncOutboxSpec(
      profileId: scope.profileId,
      rootId: scope.rootId,
      entityType: entityType.wireName,
      entityId: entityId,
      operation: operation,
      payload: payload,
    );
  }

  static void _requireText(String value, String name) {
    if (value.trim().isEmpty) throw ArgumentError('$name must not be empty');
  }
}

/// Data-shaped boundary matching the existing SyncOutbox enqueue fields.
/// The data layer remains responsible for writing it; this domain contract
/// performs no disk or network operation.
@immutable
final class SyncOutboxSpec {
  const SyncOutboxSpec({
    required this.profileId,
    required this.rootId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.payload = const <String, Object?>{},
  });

  final String profileId;
  final String rootId;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, Object?> payload;
}

/// Future transport owner. No account, server, or concrete implementation is
/// introduced in M5.9c-2.
abstract interface class SyncProvider {
  String get providerId;

  Set<String> get supportedEntityTypes;
}
