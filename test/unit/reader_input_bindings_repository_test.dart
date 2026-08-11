import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reader_input_bindings_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_input_bindings.dart';

void main() {
  late AppDatabase db;
  late ReaderInputBindingsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = ReaderInputBindingsRepository(db: db);
  });

  tearDown(() => db.close());

  test('defaults are platform-specific and schema remains 6', () async {
    expect(db.schemaVersion, 10);
    final windows = await repository.load(ReaderInputPlatform.windows);
    final android = await repository.load(ReaderInputPlatform.android);
    expect(
      windows.commandFor(PhysicalInputId.keyboardArrowLeft),
      ReaderCommand.previousPage,
    );
    expect(
      windows.commandFor(PhysicalInputId.mouseWheelDown),
      ReaderCommand.nextPage,
    );
    expect(
      android.commandFor(PhysicalInputId.androidVolumeUp),
      ReaderCommand.previousPage,
    );
    expect(android.commandFor(PhysicalInputId.keyboardArrowLeft), isNull);
    expect(windows.platform, ReaderInputPlatform.windows);
    expect(android.platform, ReaderInputPlatform.android);
  });

  test('bind, unbind/null, and reset are strongly typed', () async {
    await repository.bind(
      ReaderInputPlatform.windows,
      PhysicalInputId.keyboardArrowLeft,
      ReaderCommand.openToc,
    );
    var profile = await repository.load(ReaderInputPlatform.windows);
    expect(
      profile.commandFor(PhysicalInputId.keyboardArrowLeft),
      ReaderCommand.openToc,
    );
    await repository.unbind(
      ReaderInputPlatform.windows,
      PhysicalInputId.keyboardArrowLeft,
    );
    profile = await repository.load(ReaderInputPlatform.windows);
    expect(profile.hasBinding(PhysicalInputId.keyboardArrowLeft), isTrue);
    expect(profile.commandFor(PhysicalInputId.keyboardArrowLeft), isNull);
    await repository.resetToDefaults(ReaderInputPlatform.windows);
    profile = await repository.load(ReaderInputPlatform.windows);
    expect(
      profile.commandFor(PhysicalInputId.keyboardArrowLeft),
      ReaderCommand.previousPage,
    );
  });

  test(
    'update persists across repository recreation and isolates platforms',
    () async {
      final updated = ReaderInputProfile(
        platform: ReaderInputPlatform.android,
        version: ReaderInputProfile.currentVersion,
        bindings: {
          ReaderInputGesture.single(PhysicalInputId.androidVolumeUp):
              ReaderCommand.nextChapter,
          ReaderInputGesture.single(PhysicalInputId.androidVolumeDown): null,
        },
        updatedAt: DateTime(2026, 8, 9),
      );
      await repository.update(ReaderInputPlatform.android, updated);
      final recreated = ReaderInputBindingsRepository(db: db);
      final android = await recreated.load(ReaderInputPlatform.android);
      final windows = await recreated.load(ReaderInputPlatform.windows);
      expect(
        android.commandFor(PhysicalInputId.androidVolumeUp),
        ReaderCommand.previousPage,
      );
      expect(android.commandFor(PhysicalInputId.androidVolumeDown), isNull);
      expect(
        windows.commandFor(PhysicalInputId.keyboardArrowLeft),
        ReaderCommand.previousPage,
      );
      expect(await (db.select(db.readerPreferencesRows)).get(), isEmpty);
    },
  );

  test('app restart preserves the profile in the SQLite file', () async {
    final temp = await Directory.systemTemp.createTemp('xaocen-input-');
    final file = File('${temp.path}\\settings.sqlite');
    final firstDb = AppDatabase(NativeDatabase(file));
    final first = ReaderInputBindingsRepository(db: firstDb);
    await first.bind(
      ReaderInputPlatform.windows,
      PhysicalInputId.keyboardArrowRight,
      ReaderCommand.nextChapter,
    );
    await firstDb.close();
    final secondDb = AppDatabase(NativeDatabase(file));
    final second = ReaderInputBindingsRepository(db: secondDb);
    expect(
      (await second.load(
        ReaderInputPlatform.windows,
      )).commandFor(PhysicalInputId.keyboardArrowRight),
      ReaderCommand.nextChapter,
    );
    await secondDb.close();
    await temp.delete(recursive: true);
  });

  test('invalid whole JSON falls back only for that platform', () async {
    await _putRaw(db, 'reader.inputBindings.windows.v1', '{not-json');
    await repository.bind(
      ReaderInputPlatform.android,
      PhysicalInputId.androidVolumeUp,
      ReaderCommand.openToc,
    );
    final windows = await repository.load(ReaderInputPlatform.windows);
    final android = await repository.load(ReaderInputPlatform.android);
    expect(
      windows.commandFor(PhysicalInputId.keyboardArrowLeft),
      ReaderCommand.previousPage,
    );
    expect(
      android.commandFor(PhysicalInputId.androidVolumeUp),
      ReaderCommand.previousPage,
    );
  });

  test(
    'unknown entries are ignored while valid and null entries survive',
    () async {
      final raw = jsonEncode({
        'version': 1,
        'platform': 'windows',
        'updatedAt': '2026-08-09T00:00:00Z',
        'bindings': {
          'keyboard.arrowLeft': null,
          'keyboard.arrowRight': 'nextChapter',
          'keyboard.unknown': 'openToc',
          'keyboard.pageUp': 'unknownCommand',
          '42': 'nextPage',
        },
      });
      await _putRaw(db, 'reader.inputBindings.windows.v1', raw);
      final profile = await repository.load(ReaderInputPlatform.windows);
      expect(profile.hasBinding(PhysicalInputId.keyboardArrowLeft), isTrue);
      expect(profile.commandFor(PhysicalInputId.keyboardArrowLeft), isNull);
      expect(
        profile.commandFor(PhysicalInputId.keyboardArrowRight),
        ReaderCommand.nextChapter,
      );
      expect(
        profile.commandFor(PhysicalInputId.keyboardPageUp),
        ReaderCommand.previousPage,
      );
    },
  );

  test('profile version migration fills missing known defaults', () async {
    final raw = jsonEncode({
      'version': 0,
      'platform': 'windows',
      'bindings': {'keyboard.arrowLeft': null},
    });
    await _putRaw(db, 'reader.inputBindings.windows.v1', raw);
    final profile = await repository.load(ReaderInputPlatform.windows);
    expect(profile.version, ReaderInputProfile.currentVersion);
    expect(profile.commandFor(PhysicalInputId.keyboardArrowLeft), isNull);
    expect(
      profile.commandFor(PhysicalInputId.keyboardArrowRight),
      ReaderCommand.nextPage,
    );
  });

  test('watch emits typed fallback and persisted profiles', () async {
    final values = <ReaderInputProfile>[];
    final sub = repository
        .watch(ReaderInputPlatform.windows)
        .listen(values.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);
    await repository.bind(
      ReaderInputPlatform.windows,
      PhysicalInputId.mouseWheelUp,
      ReaderCommand.toggleReaderControls,
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      values.last.commandFor(PhysicalInputId.mouseWheelUp),
      ReaderCommand.toggleReaderControls,
    );
  });

  test('combination gesture persists canonically across restart', () async {
    final gesture = ReaderInputGesture(
      primaryInput: PhysicalInputId.keyboardPageDown,
      modifiers: [ReaderInputModifier.ctrl, ReaderInputModifier.shift],
    );
    await repository.bind(
      ReaderInputPlatform.windows,
      gesture,
      ReaderCommand.nextChapter,
    );
    final recreated = ReaderInputBindingsRepository(db: db);
    expect(
      (await recreated.load(ReaderInputPlatform.windows)).commandFor(gesture),
      ReaderCommand.nextChapter,
    );
  });

  test('version 1 plain-key JSON migrates without clearing bindings', () async {
    await _putRaw(
      db,
      'reader.inputBindings.windows.v1',
      jsonEncode({
        'version': 1,
        'platform': 'windows',
        'bindings': {'keyboard.keyA': 'openToc'},
      }),
    );
    final profile = await repository.load(ReaderInputPlatform.windows);
    expect(profile.version, ReaderInputProfile.currentVersion);
    expect(
      profile.commandFor(PhysicalInputId.keyboardKeyA),
      ReaderCommand.openToc,
    );
  });

  test('unsupported Android commands migrate to platform defaults', () async {
    await _putRaw(
      db,
      'reader.inputBindings.android.v1',
      jsonEncode({
        'version': 2,
        'platform': 'android',
        'bindings': [
          {
            'primary': 'android.volumeUp',
            'modifiers': <String>[],
            'command': 'nextChapter',
          },
          {
            'primary': 'android.volumeDown',
            'modifiers': <String>[],
            'command': null,
          },
        ],
      }),
    );
    final profile = await repository.load(ReaderInputPlatform.android);
    expect(
      profile.commandFor(PhysicalInputId.androidVolumeUp),
      ReaderCommand.previousPage,
    );
    expect(profile.hasBinding(PhysicalInputId.androidVolumeDown), isTrue);
    expect(profile.commandFor(PhysicalInputId.androidVolumeDown), isNull);
  });

  test('Android repository rejects unsupported command writes', () async {
    await repository.bind(
      ReaderInputPlatform.android,
      PhysicalInputId.androidVolumeUp,
      ReaderCommand.nextChapter,
    );
    final profile = await repository.load(ReaderInputPlatform.android);
    expect(
      profile.commandFor(PhysicalInputId.androidVolumeUp),
      ReaderCommand.previousPage,
    );
  });
}

Future<void> _putRaw(AppDatabase db, String key, String value) async {
  await db
      .into(db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: key,
          value: value,
          updatedAt: DateTime(2026, 8, 9),
        ),
      );
}
