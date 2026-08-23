import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/data_root.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reader_font_repository.dart';
import 'package:xaocen_reader/data/repositories/reader_preferences_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_font.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/reader/reader_metrics_signature.dart';

void main() {
  late AppDatabase db;
  late DataRoot root;
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('xaocen-font-');
    root = await DataRoot.forDirectory(Directory('${temp.path}\\root'));
    db = AppDatabase.forTesting();
    await db
        .into(db.contentSources)
        .insert(
          ContentSourcesCompanion.insert(
            id: 'font-source',
            type: 'localTxt',
            displayName: 'Font source',
            contentHash: 'font-source-hash',
            managedSourcePath: 'library/font/source.txt',
            sourceSize: 1,
            detectedEncoding: 'utf8',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    await db
        .into(db.contentCollections)
        .insert(
          ContentCollectionsCompanion.insert(
            id: 'font-book',
            sourceId: 'font-source',
            title: 'Font book',
            itemCount: 1,
            normalizedCharacterLength: 10,
            importedAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
  });

  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  test('defaults and per-book fontId are typed and persistent', () async {
    final repository = ReaderPreferencesRepository(db: db);
    expect(ReaderPreferences.defaults.fontId, isNull);
    final saved = ReaderPreferences(fontId: 'windows.system.family.segoe_ui');
    await repository.update('font-book', saved);
    expect(
      (await repository.load('font-book')).fontId,
      'windows.system.family.segoe_ui',
    );
  });

  test('font selection is a metrics-changing preference', () {
    final selected = ReaderPreferences(
      fontId: 'windows.system.family.segoe_ui',
    );
    expect(
      selected.changesFrom(ReaderPreferences.defaults),
      contains(ReaderPreferenceChangeKind.metrics),
    );
    expect(
      ReaderMetricsSignature.fromPreferences(selected),
      isNot(ReaderMetricsSignature.fromPreferences(ReaderPreferences.defaults)),
    );
  });

  test(
    'TTF/OTF import is managed, checksum deduplicated, and delete falls back',
    () async {
      final source = File('${temp.path}/sample.ttf')
        ..writeAsBytesSync(<int>[0, 1, 0, 0, 0, 0, 0, 0]);
      final fonts = ReaderFontRepository(db: db, dataRoot: root);
      final first = await fonts.importFile(source);
      expect(first.format, ReaderFontFormat.ttf);
      expect(first.relativePath, startsWith('fonts/'));
      expect(
        File('${root.rootDirectory.path}/${first.relativePath}').existsSync(),
        isTrue,
      );
      final duplicate = await fonts.importFile(source);
      expect(duplicate.fontId, first.fontId);

      final preferences = ReaderPreferencesRepository(db: db);
      await preferences.update(
        'font-book',
        ReaderPreferences(fontId: first.fontId),
      );
      await fonts.delete(first.fontId);
      expect((await preferences.load('font-book')).fontId, isNull);
      expect(await fonts.get(first.fontId), isNull);
    },
  );

  test('TTC is explicitly deferred and malformed fonts are rejected', () async {
    final ttc = File('${temp.path}/sample.ttc')
      ..writeAsBytesSync(<int>[0, 1, 0, 0]);
    final bad = File('${temp.path}/sample.otf')
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);
    final fonts = ReaderFontRepository(db: db, dataRoot: root);
    await expectLater(
      fonts.importFile(ttc),
      throwsA(isA<ReaderFontException>()),
    );
    await expectLater(
      fonts.importFile(bad),
      throwsA(isA<ReaderFontException>()),
    );
  });

  test(
    'schema 11 to 13 migration preserves progress and adds font assets',
    () async {
      final file = File('${temp.path}/migration.sqlite');
      var old = AppDatabase(NativeDatabase(file));
      await old.customStatement('''
      INSERT INTO content_sources
        (id, type, display_name, content_hash, managed_source_path,
         source_size, detected_encoding, created_at, updated_at)
      VALUES ('source', 'localTxt', 'Font migration', 'hash', 'library/source.txt',
              1, 'utf8', 0, 0)
    ''');
      await old.customStatement('''
      INSERT INTO content_collections
        (id, source_id, title, item_count, normalized_character_length,
         imported_at, updated_at)
      VALUES ('book', 'source', 'Font book', 1, 12, 0, 0)
    ''');
      await old.customStatement('''
      INSERT INTO reading_progress
        (collection_id, absolute_character_offset, reading_mode, item_id_hint,
         updated_at, locator_version, normalization_version)
      VALUES ('book', 8, 'paged', NULL, 0, 1, 'v1')
    ''');
      await old.customStatement(
        'ALTER TABLE reader_preferences DROP COLUMN font_id',
      );
      await old.customStatement(
        'ALTER TABLE reader_preferences DROP COLUMN show_top_info_divider',
      );
      await old.customStatement(
        'ALTER TABLE reader_preferences DROP COLUMN show_bottom_info_divider',
      );
      await old.customStatement(
        'ALTER TABLE reader_preferences DROP COLUMN show_system_status_bar',
      );
      await old.customStatement(
        'ALTER TABLE reader_preferences DROP COLUMN hide_navigation_bar',
      );
      await old.customStatement(
        'ALTER TABLE reader_preferences DROP COLUMN extend_into_display_cutout',
      );
      await old.customStatement(
        'ALTER TABLE reader_preferences DROP COLUMN screen_orientation',
      );
      await old.customStatement(
        'ALTER TABLE reader_preferences DROP COLUMN show_battery_info',
      );
      await old.customStatement(
        'ALTER TABLE reader_preferences DROP COLUMN battery_info_slot',
      );
      await old.customStatement('DROP TABLE reader_font_asset_rows');
      await old.customStatement('PRAGMA user_version = 11');
      await old.close();

      final migrated = AppDatabase(NativeDatabase(file));
      final progress = await migrated
          .select(migrated.readingProgress)
          .getSingle();
      expect(progress.absoluteCharacterOffset, 8);
      expect(progress.readingMode, 'paged');
      expect(
        (await migrated.customSelect('PRAGMA user_version').getSingle())
            .data['user_version'],
        21,
      );
      expect(
        await migrated.select(migrated.readerFontAssetRows).get(),
        isEmpty,
      );
      await migrated.close();
    },
  );
}
