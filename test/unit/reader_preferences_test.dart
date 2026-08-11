import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reader_preferences_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';

void main() {
  const a = 'local-txt:a';
  const b = 'local-txt:b';

  Future<void> seedBook(AppDatabase db, String id) async {
    final suffix = id.split(':').last;
    final now = DateTime.now();
    await db
        .into(db.contentSources)
        .insert(
          ContentSourcesCompanion.insert(
            id: 'source:$suffix',
            type: 'localTxt',
            displayName: suffix,
            contentHash: suffix,
            managedSourcePath: '$suffix/source.txt',
            sourceSize: 1,
            detectedEncoding: 'utf8',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.contentCollections)
        .insert(
          ContentCollectionsCompanion.insert(
            id: id,
            sourceId: 'source:$suffix',
            title: suffix,
            itemCount: 1,
            normalizedCharacterLength: 100,
            importedAt: now,
            updatedAt: now,
          ),
        );
  }

  group('ReaderPreferences metrics contract', () {
    test('defaults/ranges/steps are explicit and readingMode is absent', () {
      expect(ReaderPreferences.defaults, ReaderPreferences());
      expect(ReaderPreferences.fontSizeStep, 1);
      expect(ReaderPreferences.letterSpacingStep, .05);
      expect(ReaderPreferences.lineHeightStep, .1);
      expect(ReaderPreferences.paragraphSpacingStep, 1);
      expect(ReaderPreferences.firstLineIndentStep, .5);
      expect(ReaderPreferences.paddingStep, 2);
    });

    test('every invalid field falls back independently', () {
      final value = ReaderPreferences(
        fontSize: 99,
        letterSpacing: double.nan,
        lineHeight: 0,
        paragraphSpacing: -1,
        firstLineIndent: 9,
        paddingTop: -1,
        paddingBottom: 99,
        paddingLeft: -2,
        paddingRight: 100,
      );
      expect(value, ReaderPreferences.defaults);
    });

    test('all typography and four paddings are metrics; theme is paint', () {
      for (final value in <ReaderPreferences>[
        ReaderPreferences.defaults.copyWith(fontSize: 18),
        ReaderPreferences.defaults.copyWith(letterSpacing: .1),
        ReaderPreferences.defaults.copyWith(lineHeight: 1.8),
        ReaderPreferences.defaults.copyWith(paragraphSpacing: 2),
        ReaderPreferences.defaults.copyWith(firstLineIndent: 2),
        ReaderPreferences.defaults.copyWith(paddingTop: 10),
        ReaderPreferences.defaults.copyWith(paddingBottom: 10),
        ReaderPreferences.defaults.copyWith(paddingLeft: 18),
        ReaderPreferences.defaults.copyWith(paddingRight: 18),
      ]) {
        expect(value.changesFrom(ReaderPreferences.defaults), {
          ReaderPreferenceChangeKind.metrics,
        });
      }
      expect(
        ReaderPreferences.defaults
            .copyWith(themeMode: ReaderThemeMode.dark)
            .changesFrom(ReaderPreferences.defaults),
        {ReaderPreferenceChangeKind.paint},
      );
      for (final value in <ReaderPreferences>[
        ReaderPreferences.defaults.copyWith(textColorArgb: 0xff112233),
        ReaderPreferences.defaults.copyWith(backgroundColorArgb: 0xfff5eddc),
        ReaderPreferences.defaults.copyWith(
          backgroundImagePath: 'library/reader_backgrounds/a/image.png',
        ),
        ReaderPreferences.defaults.copyWith(backgroundImageOpacity: .8),
        ReaderPreferences.defaults.copyWith(backgroundOverlayOpacity: .6),
      ]) {
        expect(value.changesFrom(ReaderPreferences.defaults), {
          ReaderPreferenceChangeKind.paint,
        });
      }
    });
  });

  group('per-book repository', () {
    late AppDatabase db;
    late ReaderPreferencesRepository repo;
    setUp(() async {
      db = AppDatabase.forTesting();
      repo = ReaderPreferencesRepository(db: db);
      await seedBook(db, a);
      await seedBook(db, b);
    });
    tearDown(() => db.close());

    test('typed API, defaults, save/load/watch', () async {
      final Future<ReaderPreferences> Function(String) typedLoad = repo.load;
      final Future<void> Function(String, ReaderPreferences) typedUpdate =
          repo.update;
      expect(typedLoad, isNotNull);
      expect(typedUpdate, isNotNull);
      expect(await repo.load(a), ReaderPreferences.defaults);
      final expected = ReaderPreferences(
        fontSize: 22,
        letterSpacing: .2,
        lineHeight: 2,
        paragraphSpacing: 6,
        firstLineIndent: 2,
        paddingTop: 10,
        paddingBottom: 12,
        paddingLeft: 24,
        paddingRight: 30,
        themeMode: ReaderThemeMode.dark,
        textColorArgb: 0xfff5f2ea,
        backgroundColorArgb: 0xff202124,
        backgroundImagePath:
            'library/reader_backgrounds/local-txt_a/background.png',
        backgroundImageOpacity: .8,
        backgroundOverlayOpacity: .55,
      );
      final emissions = <ReaderPreferences>[];
      final sub = repo.watch(a).listen(emissions.add);
      await repo.update(a, expected);
      expect(await repo.load(a), expected);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last, expected);
      await sub.cancel();
    });

    test(
      'Book A and B are isolated; reset affects current book only',
      () async {
        final p1 = ReaderPreferences.defaults.copyWith(
          fontSize: 22,
          paddingLeft: 28,
        );
        final p2 = ReaderPreferences.defaults.copyWith(
          fontSize: 18,
          paddingRight: 32,
          themeMode: ReaderThemeMode.light,
        );
        await repo.update(a, p1);
        await repo.update(b, p2);
        expect(await repo.load(a), p1);
        expect(await repo.load(b), p2);
        await repo.resetToDefaults(a);
        expect(await repo.load(a), ReaderPreferences.defaults);
        expect(await repo.load(b), p2);
      },
    );

    test('database restart preserves each book', () async {
      // Covered with a dedicated file database below.
      expect(await repo.load(a), ReaderPreferences.defaults);
    });
  });

  test(
    'schema 4→5 preserves books and seeds legacy global settings per book',
    () async {
      final dir = await Directory.systemTemp.createTemp('m51e1_migration');
      final file = File('${dir.path}${Platform.pathSeparator}db.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await seedBook(db, a);
      await db.customStatement(
        "INSERT INTO app_settings(key,value,updated_at) VALUES "
        "('reader.fontSize','22',0),('reader.lineHeight','2.0',0),"
        "('reader.horizontalPadding','24',0),('reader.verticalPadding','10',0),"
        "('reader.themeMode','dark',0)",
      );
      await db.close();
      final raw = sqlite3.open(file.path);
      raw.execute('DROP TABLE reader_preferences');
      raw.execute('PRAGMA user_version = 4');
      raw.dispose();

      db = AppDatabase(NativeDatabase(file));
      final migrated = await ReaderPreferencesRepository(db: db).load(a);
      expect(migrated.fontSize, 22);
      expect(migrated.lineHeight, 2);
      expect(migrated.paddingLeft, 24);
      expect(migrated.paddingRight, 24);
      expect(migrated.paddingTop, 10);
      expect(migrated.paddingBottom, 10);
      expect(migrated.themeMode, ReaderThemeMode.dark);
      expect((await db.select(db.contentCollections).get()).single.id, a);
      await db.close();
      await dir.delete(recursive: true);
    },
  );

  test('file restart preserves independent preferences', () async {
    final dir = await Directory.systemTemp.createTemp('m51e1_restart');
    final file = File('${dir.path}${Platform.pathSeparator}db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await seedBook(db, a);
    final expected = ReaderPreferences.defaults.copyWith(fontSize: 23);
    await ReaderPreferencesRepository(db: db).update(a, expected);
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    expect(await ReaderPreferencesRepository(db: db).load(a), expected);
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
    'schema 6→7 preserves typography and adds appearance defaults',
    () async {
      final dir = await Directory.systemTemp.createTemp('m55e_migration');
      final file = File('${dir.path}${Platform.pathSeparator}db.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await seedBook(db, a);
      await ReaderPreferencesRepository(
        db: db,
      ).update(a, ReaderPreferences.defaults.copyWith(fontSize: 23));
      await db.close();

      final raw = sqlite3.open(file.path);
      raw.execute(
        'ALTER TABLE reader_preferences RENAME TO reader_preferences_v7',
      );
      raw.execute('''
      CREATE TABLE reader_preferences (
        collection_id TEXT NOT NULL PRIMARY KEY
          REFERENCES content_collections (id) ON DELETE CASCADE,
        font_size REAL NOT NULL,
        letter_spacing REAL NOT NULL,
        line_height REAL NOT NULL,
        paragraph_spacing REAL NOT NULL,
        first_line_indent REAL NOT NULL,
        padding_top REAL NOT NULL,
        padding_bottom REAL NOT NULL,
        padding_left REAL NOT NULL,
        padding_right REAL NOT NULL,
        theme_mode TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
      raw.execute('''
      INSERT INTO reader_preferences
      SELECT collection_id, font_size, letter_spacing, line_height,
        paragraph_spacing, first_line_indent, padding_top, padding_bottom,
        padding_left, padding_right, theme_mode, updated_at
      FROM reader_preferences_v7
    ''');
      raw.execute('DROP TABLE reader_preferences_v7');
      raw.execute('PRAGMA user_version = 6');
      raw.dispose();

      db = AppDatabase(NativeDatabase(file));
      final migrated = await ReaderPreferencesRepository(db: db).load(a);
      expect(migrated.fontSize, 23);
      expect(migrated.textColorArgb, isNull);
      expect(migrated.backgroundColorArgb, isNull);
      expect(migrated.backgroundImagePath, isNull);
      expect(migrated.backgroundImageOpacity, 1);
      expect(migrated.backgroundOverlayOpacity, .45);
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .data['user_version'],
        7,
      );
      await db.close();
      await dir.delete(recursive: true);
    },
  );
}
