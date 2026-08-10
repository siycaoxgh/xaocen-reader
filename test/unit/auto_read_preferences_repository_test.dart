import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/auto_read_preferences_repository.dart';
import 'package:xaocen_reader/data/repositories/reader_input_bindings_repository.dart';
import 'package:xaocen_reader/domain/reader/auto_read_preferences.dart';
import 'package:xaocen_reader/domain/reader/reader_input_bindings.dart';

void main() {
  late AppDatabase db;
  late AutoReadPreferencesRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = AutoReadPreferencesRepository(db: db);
  });

  tearDown(() => db.close());

  test('defaults and derived velocity mapping are typed', () async {
    expect(db.schemaVersion, 6);
    final preferences = await repository.load();
    expect(preferences.verticalSpeedPreset, VerticalSpeedPreset.standard);
    expect(preferences.pagedIntervalSeconds, 5);
    expect(preferences.verticalVelocityPixelsPerSecond, 40);
  });

  test('custom velocity is canonical and preset is derived', () async {
    await repository.update(
      AutoReadPreferences(verticalVelocityPixelsPerSecond: 47),
    );
    final loaded = await repository.load();
    expect(loaded.verticalVelocityPixelsPerSecond, 47);
    expect(loaded.verticalSpeedPreset, isNull);

    final row = await (db.select(
      db.appSettings,
    )..where((t) => t.key.equals(_key))).getSingle();
    final json = jsonDecode(row.value) as Map<String, dynamic>;
    expect(json['verticalVelocityPixelsPerSecond'], 47);
    expect(json.containsKey('verticalSpeedPreset'), isFalse);
  });

  test('update, setters, reset, and watch persist typed values', () async {
    final values = <AutoReadPreferences>[];
    final subscription = repository.watch().listen(values.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    await repository.update(
      AutoReadPreferences(
        verticalSpeedPreset: VerticalSpeedPreset.faster,
        pagedIntervalSeconds: 8,
      ),
    );
    expect(
      (await repository.load()).verticalSpeedPreset,
      VerticalSpeedPreset.faster,
    );
    await repository.setVerticalSpeed(VerticalSpeedPreset.slow);
    await repository.setPagedInterval(15);
    expect((await repository.load()).pagedIntervalSeconds, 15);
    expect(values.last.verticalSpeedPreset, VerticalSpeedPreset.slow);

    await repository.resetToDefaults();
    expect((await repository.load()).pagedIntervalSeconds, 5);
    expect(
      (await repository.load()).verticalSpeedPreset,
      VerticalSpeedPreset.standard,
    );
  });

  test('invalid values and corrupted JSON fall back safely', () async {
    await _putRaw(
      db,
      _key,
      jsonEncode({
        'version': 1,
        'verticalSpeedPreset': 'not-a-preset',
        'pagedIntervalSeconds': 99,
        'updatedAt': 'not-a-date',
      }),
    );
    var preferences = await repository.load();
    expect(preferences.verticalSpeedPreset, VerticalSpeedPreset.standard);
    expect(preferences.pagedIntervalSeconds, 5);

    await _putRaw(db, _key, '{broken');
    preferences = await repository.load();
    expect(preferences.verticalSpeedPreset, VerticalSpeedPreset.standard);
    expect(preferences.pagedIntervalSeconds, 5);
  });

  test('older versions migrate while future versions fall back', () async {
    await _putRaw(
      db,
      _key,
      jsonEncode({
        'version': 0,
        'verticalSpeedPreset': 'fast',
        'pagedIntervalSeconds': 3,
        'updatedAt': '2026-08-10T00:00:00Z',
      }),
    );
    var preferences = await repository.load();
    expect(preferences.version, AutoReadPreferences.currentVersion);
    expect(preferences.verticalSpeedPreset, VerticalSpeedPreset.fast);
    expect(preferences.pagedIntervalSeconds, 3);

    await _putRaw(
      db,
      _key,
      jsonEncode({
        'version': 1,
        'verticalSpeedPreset': 'fast',
        'pagedIntervalSeconds': 3,
      }),
    );
    preferences = await repository.load();
    expect(preferences.verticalVelocityPixelsPerSecond, 76);
    expect(preferences.verticalSpeedPreset, VerticalSpeedPreset.fast);

    await _putRaw(
      db,
      _key,
      jsonEncode({
        'version': 2,
        'verticalVelocityPixelsPerSecond': 121,
        'pagedIntervalSeconds': 3,
      }),
    );
    preferences = await repository.load();
    expect(preferences.verticalVelocityPixelsPerSecond, 40);
    expect(preferences.verticalSpeedPreset, VerticalSpeedPreset.standard);

    await _putRaw(db, _key, jsonEncode({'version': 999}));
    preferences = await repository.load();
    expect(preferences.pagedIntervalSeconds, 5);
  });

  test(
    'restart preserves AutoReadPreferences and isolates other settings',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'xaocen-auto-read-',
      );
      final file = File('${directory.path}\\settings.sqlite');
      final firstDb = AppDatabase(NativeDatabase(file));
      final first = AutoReadPreferencesRepository(db: firstDb);
      await first.update(
        AutoReadPreferences(
          verticalSpeedPreset: VerticalSpeedPreset.slower,
          pagedIntervalSeconds: 10,
        ),
      );
      await firstDb.close();

      final secondDb = AppDatabase(NativeDatabase(file));
      final second = AutoReadPreferencesRepository(db: secondDb);
      final loaded = await second.load();
      expect(loaded.verticalSpeedPreset, VerticalSpeedPreset.slower);
      expect(loaded.pagedIntervalSeconds, 10);
      expect(
        (await secondDb.select(secondDb.readerPreferencesRows).get()),
        isEmpty,
      );
      final input = ReaderInputBindingsRepository(db: secondDb);
      expect(
        (await input.load(
          ReaderInputPlatform.windows,
        )).commandFor(PhysicalInputId.keyboardArrowLeft),
        ReaderCommand.previousPage,
      );
      expect(secondDb.schemaVersion, 6);
      await secondDb.close();
      await directory.delete(recursive: true);
    },
  );
}

const _key = 'reader.autoRead.preferences.v1';

Future<void> _putRaw(AppDatabase db, String key, String value) async {
  await db
      .into(db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: key,
          value: value,
          updatedAt: DateTime.now(),
        ),
      );
}
