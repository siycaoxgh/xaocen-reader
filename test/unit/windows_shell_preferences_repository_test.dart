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
    expect(value.showWindowBorder, isTrue);
    expect(value.hasRecoveryEntry, isTrue);
    expect(value.bossKeyEnabled, isTrue);
    expect(value.bossKeyGesture.mouseChord, isTrue);
    expect(value.version, WindowsShellPreferences.currentVersion);
  });

  test('updates and reloads typed shell preferences', () async {
    await repository.update(showTaskbarIcon: false, showTrayIcon: true);
    final reloaded = await repository.load();
    expect(reloaded.showTaskbarIcon, isFalse);
    expect(reloaded.showTrayIcon, isTrue);
  });

  test(
    'window border preference persists independently of shell entries',
    () async {
      await repository.updateWindowBorder(false);
      final reloaded = await repository.load();
      expect(reloaded.showWindowBorder, isFalse);
      expect(reloaded.showTaskbarIcon, isTrue);
      expect(reloaded.showTrayIcon, isFalse);
    },
  );

  test(
    'custom keyboard gesture and disabled state persist canonically',
    () async {
      final gesture = WindowsBossKeyGesture.keyboard(
        WindowsShellKey.pageDown,
        modifiers: [WindowsShellModifier.ctrl, WindowsShellModifier.shift],
      );
      await repository.updateBossKey(enabled: true, gesture: gesture);
      expect((await repository.load()).bossKeyGesture, gesture);
      await repository.updateBossKey(enabled: false, gesture: gesture);
      final disabled = await repository.load();
      expect(disabled.bossKeyEnabled, isFalse);
      expect(
        disabled.bossKeyGesture.canonicalKey,
        'ctrl+shift+keyboard.pageDown',
      );
    },
  );

  test('version one shell JSON migrates to default mouse chord', () async {
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'windows.shell.preferences.v1',
            value: jsonEncode({
              'version': 1,
              'showTaskbarIcon': false,
              'showTrayIcon': true,
            }),
            updatedAt: DateTime.now(),
          ),
        );
    final value = await repository.load();
    expect(value.showTaskbarIcon, isFalse);
    expect(value.showTrayIcon, isTrue);
    expect(value.bossKeyEnabled, isTrue);
    expect(value.bossKeyGesture.mouseChord, isTrue);
    expect(value.version, WindowsShellPreferences.currentVersion);
    expect(value.showWindowBorder, isTrue);
  });

  test(
    'invalid gesture falls back without dropping visibility settings',
    () async {
      await db
          .into(db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: 'windows.shell.preferences.v1',
              value: jsonEncode({
                'version': 2,
                'showTaskbarIcon': false,
                'showTrayIcon': true,
                'bossKeyEnabled': true,
                'bossKeyGesture': {
                  'type': 'keyboard',
                  'primary': 'keyboard.winKey',
                  'modifiers': [],
                },
              }),
              updatedAt: DateTime.now(),
            ),
          );
      final value = await repository.load();
      expect(value.showTrayIcon, isTrue);
      expect(value.bossKeyGesture.mouseChord, isTrue);
      expect(value.showWindowBorder, isTrue);
    },
  );

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

  test('boss key keyboard gesture requires primary and exact modifiers', () {
    final tracker = BossKeyTracker();
    final gesture = WindowsBossKeyGesture.keyboard(
      WindowsShellKey.keyB,
      modifiers: [WindowsShellModifier.ctrl],
    );
    expect(
      tracker.updateKeyboard(
        gesture,
        key: WindowsShellKey.keyB,
        modifiers: {WindowsShellModifier.shift},
      ),
      isFalse,
    );
    expect(
      tracker.updateKeyboard(
        gesture,
        key: WindowsShellKey.keyB,
        modifiers: {WindowsShellModifier.ctrl},
      ),
      isTrue,
    );
    expect(
      tracker.updateKeyboard(
        gesture,
        key: WindowsShellKey.keyB,
        modifiers: {WindowsShellModifier.ctrl},
      ),
      isFalse,
    );
    tracker.clear();
    expect(
      tracker.updateKeyboard(gesture, key: WindowsShellKey.keyB, modifiers: {}),
      isFalse,
    );
  });
}
