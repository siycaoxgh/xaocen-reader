import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/windows_shell.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/windows_shell_preferences_repository.dart';
import 'package:xaocen_reader/domain/windows_shell_preferences.dart';

void main() {
  late AppDatabase db;
  late WindowsShellPreferencesRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = WindowsShellPreferencesRepository(db: db);
  });

  tearDown(() async => db.close());

  test('defaults keep taskbar as the recovery entry', () async {
    final value = await repository.load();
    expect(value.showTaskbarIcon, isTrue);
    expect(value.showTrayIcon, isFalse);
    expect(value.hasRecoveryEntry, isTrue);
  });

  test('updates and reloads typed shell preferences', () async {
    await repository.update(showTaskbarIcon: false, showTrayIcon: true);
    final reloaded = await repository.load();
    expect(reloaded.showTaskbarIcon, isFalse);
    expect(reloaded.showTrayIcon, isTrue);
  });

  test('rejects disabling both recovery entries', () async {
    expect(
      () => repository.update(showTaskbarIcon: false, showTrayIcon: false),
      throwsA(isA<WindowsShellVisibilityException>()),
    );
    expect((await repository.load()).showTaskbarIcon, isTrue);
  });

  test(
    'corrupt or unsafe JSON falls back without affecting other settings',
    () async {
      await db
          .into(db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: 'windows.shell.preferences.v1',
              value: jsonEncode({
                'version': 1,
                'showTaskbarIcon': false,
                'showTrayIcon': false,
              }),
              updatedAt: DateTime.now(),
            ),
          );
      final value = await repository.load();
      expect(value, WindowsShellPreferences.defaults);
    },
  );

  test('watch emits persisted changes', () async {
    final values = <WindowsShellPreferences>[];
    final subscription = repository.watch().listen(values.add);
    await Future<void>.delayed(Duration.zero);
    await repository.update(showTaskbarIcon: true, showTrayIcon: true);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    expect(values.any((value) => value.showTrayIcon), isTrue);
  });

  test('boss key tracker triggers once until both buttons release', () {
    final tracker = BossKeyTracker();
    expect(tracker.update(left: true, right: false), isFalse);
    expect(tracker.update(left: true, right: true), isTrue);
    expect(tracker.update(left: true, right: true), isFalse);
    expect(tracker.update(left: true, right: false), isFalse);
    expect(tracker.update(left: true, right: true), isTrue);
    tracker.clear();
    expect(tracker.update(left: true, right: true), isTrue);
  });
}
