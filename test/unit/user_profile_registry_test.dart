import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:xaocen_reader/data/data_root.dart';
import 'package:xaocen_reader/data/profile/user_profile_registry.dart';
import 'package:xaocen_reader/domain/profile/user_profile.dart';

Future<(Directory, Directory, DataRoot)> _newPortableRoot() async {
  final temporary = await Directory.systemTemp.createTemp('xaocen-profile-');
  final executable = Directory('${temporary.path}${Platform.pathSeparator}app');
  await executable.create(recursive: true);
  final root = await DataRoot.portable(executableDirectory: executable);
  return (temporary, executable, root);
}

void main() {
  test(
    'registry has a typed default profile without embedding DataRoot',
    () async {
      final (temporary, _, root) = await _newPortableRoot();
      addTearDown(() => temporary.delete(recursive: true));

      final registry = UserProfileRegistry(dataRoot: root);
      final profiles = await registry.list();

      expect(profiles.single.id, UserProfile.defaultId);
      expect(profiles.single.displayName, UserProfile.defaultDisplayName);
      expect(profiles.single.isDefault, isTrue);
      expect(root.profileId, UserProfile.defaultId);
    },
  );

  test(
    'create and update persist profile metadata independently of storage root',
    () async {
      final (temporary, _, root) = await _newPortableRoot();
      addTearDown(() => temporary.delete(recursive: true));

      final registry = UserProfileRegistry(dataRoot: root);
      final created = await registry.create(
        id: 'reader-2',
        displayName: '第二用户',
        accountId: 'future-account',
      );
      final updated = await registry.update(
        created.copyWith(displayName: '修改后的用户'),
      );

      final reloaded = await UserProfileRegistry(dataRoot: root).list();
      final saved = reloaded.singleWhere((profile) => profile.id == 'reader-2');
      expect(updated.displayName, '修改后的用户');
      expect(saved.accountId, 'future-account');
      expect(saved.displayName, '修改后的用户');
      expect(root.profileId, UserProfile.defaultId);
    },
  );

  test(
    'switch persists next-start selection and emits restart boundary',
    () async {
      final (temporary, executable, root) = await _newPortableRoot();
      addTearDown(() => temporary.delete(recursive: true));

      final bus = LocalProfileScopeEventBus();
      addTearDown(bus.dispose);
      final registry = UserProfileRegistry(dataRoot: root, events: bus);
      await registry.create(id: 'reader-2');
      final observedEvent = bus.events.first;

      final event = await registry.requestSwitch('reader-2');
      final observed = await observedEvent;

      expect(event.kind, LocalProfileScopeEventKind.selectionPersisted);
      expect(event.fromProfileId, UserProfile.defaultId);
      expect(event.toProfileId, 'reader-2');
      expect(event.requiresRestart, isTrue);
      expect(observed.toProfileId, event.toProfileId);
      // The currently open DataRoot/database is never hot-swapped.
      expect(root.profileId, UserProfile.defaultId);

      final nextRoot = await DataRoot.resolve(
        arguments: const [DataRoot.portableArgument],
        executableDirectory: executable,
      );
      expect(nextRoot.profileId, 'reader-2');
    },
  );

  test('same-profile selection is an explicit no-op event', () async {
    final (temporary, _, root) = await _newPortableRoot();
    addTearDown(() => temporary.delete(recursive: true));

    final bus = LocalProfileScopeEventBus();
    addTearDown(bus.dispose);
    final registry = UserProfileRegistry(dataRoot: root, events: bus);
    final observedEvent = bus.events.first;

    final event = await registry.requestSwitch(UserProfile.defaultId);
    final observed = await observedEvent;

    expect(event.isNoop, isTrue);
    expect(event.requiresRestart, isFalse);
    expect(observed.isNoop, isTrue);
  });

  test('registry rejects unsafe and duplicate profile ids', () async {
    final (temporary, _, root) = await _newPortableRoot();
    addTearDown(() => temporary.delete(recursive: true));

    final registry = UserProfileRegistry(dataRoot: root);
    await expectLater(
      registry.create(id: '../outside'),
      throwsA(isA<DataRootException>()),
    );
    await expectLater(
      registry.create(id: UserProfile.defaultId),
      throwsA(isA<DataRootException>()),
    );
  });
}
