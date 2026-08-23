import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/profile/user_profile.dart';
import '../data_root.dart';

/// The only local profile-scope transition emitted by this stage.
///
/// Persisting a selection does not replace the running database, Reader, or
/// ProviderScope.  Consumers must restart/re-bootstrap before the target
/// profile becomes the active storage scope.
enum LocalProfileScopeEventKind { selectionPersisted }

final class LocalProfileScopeEvent {
  const LocalProfileScopeEvent({
    required this.kind,
    required this.fromProfileId,
    required this.toProfileId,
    required this.requiresRestart,
    required this.emittedAt,
  });

  final LocalProfileScopeEventKind kind;
  final String fromProfileId;
  final String toProfileId;
  final bool requiresRestart;
  final DateTime emittedAt;

  bool get isNoop => fromProfileId == toProfileId;
}

/// Broadcast boundary for local profile selection events.
///
/// This is intentionally an in-process event channel only.  It performs no
/// navigation, database replacement, account login, or network sync.
final class LocalProfileScopeEventBus {
  LocalProfileScopeEventBus()
    : _controller = StreamController<LocalProfileScopeEvent>.broadcast();

  final StreamController<LocalProfileScopeEvent> _controller;

  Stream<LocalProfileScopeEvent> get events => _controller.stream;

  void emit(LocalProfileScopeEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}

/// Local registry for profile metadata and next-start selection.
///
/// The registry lives beside the profile directories, while each profile's
/// actual books/database/preferences remain owned by its [DataRoot].  This is
/// the explicit boundary that keeps UserProfile and DataRoot separate.
final class UserProfileRegistry {
  UserProfileRegistry({required this.dataRoot, this.events});

  static const int formatVersion = 1;
  static const String registryFileName = 'profile_registry.json';

  final DataRoot dataRoot;
  final LocalProfileScopeEventBus? events;

  Directory get scopeDirectory => dataRoot.profileScopeDirectory;
  File get registryFile => File(p.join(scopeDirectory.path, registryFileName));

  /// Reads profiles and ensures the current/default local identity is listed.
  Future<List<UserProfile>> list() async {
    final profiles = await _read();
    var changed = false;
    final now = DateTime.now().toUtc();
    if (!profiles.any((profile) => profile.id == UserProfile.defaultId)) {
      profiles.add(
        UserProfile(
          id: UserProfile.defaultId,
          displayName: UserProfile.defaultDisplayName,
          createdAt: now,
          updatedAt: now,
        ),
      );
      changed = true;
    }
    if (!profiles.any((profile) => profile.id == dataRoot.profileId)) {
      profiles.add(
        UserProfile(
          id: dataRoot.profileId,
          displayName: dataRoot.profileId == UserProfile.defaultId
              ? UserProfile.defaultDisplayName
              : dataRoot.profileId,
          createdAt: now,
          updatedAt: now,
        ),
      );
      changed = true;
    }
    if (changed) await _write(profiles);
    return _sort(profiles);
  }

  Future<UserProfile> create({
    required String id,
    String? displayName,
    String? accountId,
  }) async {
    final normalizedId = _validateId(id);
    final profiles = [...await list()];
    if (profiles.any((profile) => profile.id == normalizedId)) {
      throw const DataRootException('user profile already exists');
    }
    final now = DateTime.now().toUtc();
    final profile = UserProfile(
      id: normalizedId,
      displayName: _displayName(displayName, normalizedId),
      accountId: accountId,
      createdAt: now,
      updatedAt: now,
    );
    await _write([...profiles, profile]);
    return profile;
  }

  Future<UserProfile> update(UserProfile profile) async {
    _validateId(profile.id);
    final profiles = [...await list()];
    final index = profiles.indexWhere(
      (candidate) => candidate.id == profile.id,
    );
    if (index < 0) throw const DataRootException('user profile not found');
    final normalized = UserProfile(
      id: profile.id,
      displayName: _displayName(profile.displayName, profile.id),
      accountId: profile.accountId,
      createdAt: profile.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    profiles[index] = normalized;
    await _write(profiles);
    return normalized;
  }

  /// Persists which profile the next bootstrap should open.
  ///
  /// The current DataRoot/database remains unchanged.  The returned/emitted
  /// event is therefore a selection boundary, not a hot runtime switch.
  Future<LocalProfileScopeEvent> requestSwitch(String profileId) async {
    final targetId = _validateId(profileId);
    final profiles = await list();
    if (!profiles.any((profile) => profile.id == targetId)) {
      throw const DataRootException('user profile not found');
    }
    await DataRoot.setActiveProfile(
      profileId: targetId,
      mode: dataRoot.mode,
      executableDirectory: dataRoot.mode == DataRootMode.portable
          ? dataRoot.profileScopeDirectory.parent
          : null,
    );
    final event = LocalProfileScopeEvent(
      kind: LocalProfileScopeEventKind.selectionPersisted,
      fromProfileId: dataRoot.profileId,
      toProfileId: targetId,
      requiresRestart: targetId != dataRoot.profileId,
      emittedAt: DateTime.now().toUtc(),
    );
    events?.emit(event);
    return event;
  }

  Future<List<UserProfile>> _read() async {
    if (!await registryFile.exists()) return <UserProfile>[];
    try {
      final decoded = jsonDecode(await registryFile.readAsString());
      if (decoded is! Map || decoded['profiles'] is! List) {
        throw const FormatException('invalid profile registry');
      }
      final profiles = <UserProfile>[];
      for (final value in decoded['profiles'] as List) {
        final profile = UserProfile.fromJson(value);
        _validateId(profile.id);
        if (profiles.any((candidate) => candidate.id == profile.id)) {
          throw const FormatException('duplicate user profile');
        }
        profiles.add(profile);
      }
      return profiles;
    } catch (error) {
      throw DataRootException('cannot read user profile registry: $error');
    }
  }

  Future<void> _write(List<UserProfile> profiles) async {
    await scopeDirectory.create(recursive: true);
    final payload = <String, Object?>{
      'formatVersion': formatVersion,
      'profiles': _sort(profiles).map((profile) => profile.toJson()).toList(),
    };
    final temporary = File('${registryFile.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await temporary.rename(registryFile.path);
  }

  static List<UserProfile> _sort(List<UserProfile> profiles) {
    final sorted = [...profiles];
    sorted.sort((a, b) {
      if (a.id == UserProfile.defaultId) return -1;
      if (b.id == UserProfile.defaultId) return 1;
      return a.id.compareTo(b.id);
    });
    return List.unmodifiable(sorted);
  }

  static String _displayName(String? value, String fallback) {
    final displayName = value?.trim();
    return displayName == null || displayName.isEmpty
        ? (fallback == UserProfile.defaultId
              ? UserProfile.defaultDisplayName
              : fallback)
        : displayName;
  }

  static String _validateId(String value) {
    final id = value.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(id)) {
      throw const DataRootException('invalid user profile id');
    }
    return id;
  }
}
