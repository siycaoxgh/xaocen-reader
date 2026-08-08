import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reader_preferences_repository.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/domain/reader/reader_progress_state.dart';
import 'package:xaocen_reader/domain/reader/reading_mode.dart';

void main() {
  group('ReaderPreferences 强类型合同', () {
    test('默认值、合法范围与职责边界明确', () {
      expect(
        ReaderPreferences.defaults,
        ReaderPreferences(
          fontSize: 17,
          lineHeight: 1.7,
          horizontalPadding: 16,
          verticalPadding: 8,
          themeMode: ReaderThemeMode.system,
        ),
      );
      expect(ReaderPreferences.minFontSize, 12);
      expect(ReaderPreferences.maxFontSize, 32);
      expect(ReaderPreferences.minLineHeight, 1.2);
      expect(ReaderPreferences.maxLineHeight, 2.4);
      // readingMode 不属于 ReaderPreferences；它继续由 ReaderProgressState 承担。
      const progress = ReaderProgressState(
        collectionId: 'c',
        absoluteCharacterOffset: 42,
        readingMode: ReadingMode.paged,
      );
      expect(progress.readingMode, ReadingMode.paged);
      expect(progress.absoluteCharacterOffset, 42);
    });

    test('非法和非有限值逐字段 fallback，不抛异常', () {
      final preferences = ReaderPreferences(
        fontSize: double.nan,
        lineHeight: 9,
        horizontalPadding: -1,
        verticalPadding: double.infinity,
        themeMode: ReaderThemeMode.dark,
      );
      expect(preferences.fontSize, ReaderPreferences.defaultFontSize);
      expect(preferences.lineHeight, ReaderPreferences.defaultLineHeight);
      expect(
        preferences.horizontalPadding,
        ReaderPreferences.defaultHorizontalPadding,
      );
      expect(
        preferences.verticalPadding,
        ReaderPreferences.defaultVerticalPadding,
      );
      expect(preferences.themeMode, ReaderThemeMode.dark);
    });

    test('metrics 与 paint 变化分类互不混淆', () {
      final metrics = ReaderPreferences.defaults.copyWith(fontSize: 20);
      expect(metrics.changesFrom(ReaderPreferences.defaults), {
        ReaderPreferenceChangeKind.metrics,
      });
      final paint = ReaderPreferences.defaults.copyWith(
        themeMode: ReaderThemeMode.dark,
      );
      expect(paint.changesFrom(ReaderPreferences.defaults), {
        ReaderPreferenceChangeKind.paint,
      });
      final both = metrics.copyWith(themeMode: ReaderThemeMode.light);
      expect(both.changesFrom(ReaderPreferences.defaults), {
        ReaderPreferenceChangeKind.metrics,
        ReaderPreferenceChangeKind.paint,
      });
    });
  });

  group('ReaderPreferencesRepository', () {
    late AppDatabase db;
    late ReaderPreferencesRepository repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = ReaderPreferencesRepository(db: db);
    });

    tearDown(() => db.close());

    test('空库读取默认设置', () async {
      // 编译期合同：Repository 对外只接受/返回强类型对象。
      final Future<ReaderPreferences> Function() typedLoad = repo.load;
      final Future<void> Function(ReaderPreferences) typedUpdate = repo.update;
      expect(typedLoad, isNotNull);
      expect(typedUpdate, isNotNull);
      expect(await repo.load(), ReaderPreferences.defaults);
    });

    test('保存、读取与 watch 均返回强类型设置', () async {
      final expected = ReaderPreferences(
        fontSize: 21,
        lineHeight: 1.9,
        horizontalPadding: 24,
        verticalPadding: 12,
        themeMode: ReaderThemeMode.dark,
      );
      final emissions = <ReaderPreferences>[];
      final subscription = repo.watch().listen(emissions.add);
      await Future<void>.delayed(Duration.zero);
      await repo.update(expected);
      await Future<void>.delayed(Duration.zero);
      expect(await repo.load(), expected);
      expect(emissions, contains(expected));
      await subscription.cancel();
    });

    test('数据库异常字符串逐字段 fallback', () async {
      final now = DateTime.now();
      Future<void> raw(String key, String value) {
        return db
            .into(db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: now,
              ),
            );
      }

      await raw('reader.fontSize', 'not-a-number');
      await raw('reader.lineHeight', 'NaN');
      await raw('reader.horizontalPadding', '-100');
      await raw('reader.verticalPadding', '999');
      await raw('reader.themeMode', 'sepia');
      final preferences = await repo.load();
      expect(preferences, ReaderPreferences.defaults);
    });

    test('reset 只删除 Reader 设置并恢复默认值', () async {
      await repo.update(
        ReaderPreferences(fontSize: 20, themeMode: ReaderThemeMode.light),
      );
      await db
          .into(db.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              key: 'unrelated.setting',
              value: 'keep',
              updatedAt: DateTime.now(),
            ),
          );
      await repo.resetToDefaults();
      expect(await repo.load(), ReaderPreferences.defaults);
      final unrelated = await (db.select(
        db.appSettings,
      )..where((t) => t.key.equals('unrelated.setting'))).getSingle();
      expect(unrelated.value, 'keep');
    });
  });

  test('文件数据库重启后设置仍存在', () async {
    final dir = await Directory.systemTemp.createTemp('m51a_restart');
    final file = File('${dir.path}${Platform.pathSeparator}settings.sqlite');
    final expected = ReaderPreferences(
      fontSize: 19,
      lineHeight: 2,
      horizontalPadding: 28,
      verticalPadding: 10,
      themeMode: ReaderThemeMode.light,
    );
    var db = AppDatabase(NativeDatabase(file));
    await ReaderPreferencesRepository(db: db).update(expected);
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    expect(await ReaderPreferencesRepository(db: db).load(), expected);
    await db.close();
    await dir.delete(recursive: true);
  });

  test('schema 3→4 保留书库、readingMode、Locator 与 managed TXT', () async {
    final dir = await Directory.systemTemp.createTemp('m51a_migration');
    final dbFile = File('${dir.path}${Platform.pathSeparator}migration.sqlite');
    final managed = File('${dir.path}${Platform.pathSeparator}normalized.txt');
    await managed.writeAsString('原有 managed TXT 内容');

    // 先用当前完整 schema 建立一份真实结构和数据，再降为 schema 3 快照：
    // schema 3 与 4 的唯一区别是没有 app_settings。
    var db = AppDatabase(NativeDatabase(dbFile));
    final now = DateTime.now();
    await db
        .into(db.contentSources)
        .insert(
          ContentSourcesCompanion.insert(
            id: 'local-txt-source:keep',
            type: 'localTxt',
            displayName: '保留书籍',
            contentHash: 'keep',
            managedSourcePath: managed.path,
            sourceSize: await managed.length(),
            detectedEncoding: 'utf8',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.contentCollections)
        .insert(
          ContentCollectionsCompanion.insert(
            id: 'local-txt:keep',
            sourceId: 'local-txt-source:keep',
            title: '保留书籍',
            itemCount: 1,
            normalizedCharacterLength: 999,
            importedAt: now,
            updatedAt: now,
          ),
        );
    await ReadingProgressRepository(db: db).saveProgress(
      const ReaderProgressState(
        collectionId: 'local-txt:keep',
        absoluteCharacterOffset: 321,
        readingMode: ReadingMode.paged,
        itemIdHint: 'chapter:1',
      ),
    );
    await db.close();

    final raw = sqlite3.open(dbFile.path);
    raw.execute('DROP TABLE app_settings');
    raw.execute('PRAGMA user_version = 3');
    raw.dispose();

    db = AppDatabase(NativeDatabase(dbFile));
    expect(
      await ReaderPreferencesRepository(db: db).load(),
      ReaderPreferences.defaults,
    );
    final collections = await db.select(db.contentCollections).get();
    expect(collections.single.title, '保留书籍');
    final progress = await ReadingProgressRepository(
      db: db,
    ).getProgress('local-txt:keep');
    expect(progress, isNotNull);
    expect(progress!.absoluteCharacterOffset, 321);
    expect(progress.readingMode, ReadingMode.paged);
    expect(progress.itemIdHint, 'chapter:1');
    expect(await managed.readAsString(), '原有 managed TXT 内容');
    await db.close();
    await dir.delete(recursive: true);
  });

  test('schema 1 可直接跨级升级到 4，不重复添加 readingMode', () async {
    final dir = await Directory.systemTemp.createTemp('m51a_migration_v1');
    final dbFile = File('${dir.path}${Platform.pathSeparator}migration.sqlite');
    var current = AppDatabase(NativeDatabase(dbFile));
    await current.customSelect('SELECT 1').get();
    await current.close();
    final raw = sqlite3.open(dbFile.path);
    raw.execute('DROP TABLE reading_progress');
    raw.execute('DROP TABLE app_settings');
    raw.execute('PRAGMA user_version = 1');
    raw.dispose();

    current = AppDatabase(NativeDatabase(dbFile));
    final tables = await current
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    final names = tables.map((row) => row.data['name']).toSet();
    expect(names, containsAll(<String>{'reading_progress', 'app_settings'}));
    final columns = await current
        .customSelect('PRAGMA table_info(reading_progress)')
        .get();
    expect(
      columns.where((row) => row.data['name'] == 'reading_mode'),
      hasLength(1),
    );
    await current.close();
    await dir.delete(recursive: true);
  });

  test('storage 字符串 key 不泄漏到 UI、Controller 或 Reader', () {
    final roots = [Directory('lib/app'), Directory('lib/reader')];
    for (final root in roots) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        expect(source, isNot(contains('reader.fontSize')), reason: entity.path);
        expect(
          source,
          isNot(contains('reader.themeMode')),
          reason: entity.path,
        );
        expect(source, isNot(contains('.appSettings')), reason: entity.path);
      }
    }
  });
}
