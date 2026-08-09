import 'dart:convert';

import '../../domain/reader/reader_input_bindings.dart';
import '../database/app_database.dart';

/// Strongly typed boundary for platform-level Reader input bindings.
///
/// The app_settings key and JSON representation are intentionally private to
/// this repository. UI and Reader code consume only [ReaderInputProfile].
final class ReaderInputBindingsRepository {
  ReaderInputBindingsRepository({required this._db});

  final AppDatabase _db;

  Future<ReaderInputProfile> load(ReaderInputPlatform platform) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(_key(platform)))).getSingleOrNull();
    return _decode(row?.value, platform);
  }

  Stream<ReaderInputProfile> watch(ReaderInputPlatform platform) =>
      (_db.select(_db.appSettings)..where((t) => t.key.equals(_key(platform))))
          .watchSingleOrNull()
          .map((row) => _decode(row?.value, platform));

  Future<void> bind(
    ReaderInputPlatform platform,
    PhysicalInputId input,
    ReaderCommand command,
  ) async {
    final current = await load(platform);
    await update(
      platform,
      current.copyWith(
        bindings: {...current.bindings, input: command},
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> unbind(
    ReaderInputPlatform platform,
    PhysicalInputId input,
  ) async {
    final current = await load(platform);
    await update(
      platform,
      current.copyWith(
        bindings: {...current.bindings, input: null},
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> update(
    ReaderInputPlatform platform,
    ReaderInputProfile profile,
  ) async {
    if (profile.platform != platform) {
      throw ArgumentError.value(profile.platform, 'profile.platform');
    }
    final normalized = _normalize(profile, platform);
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _key(platform),
            value: jsonEncode(_encode(normalized)),
            updatedAt: normalized.updatedAt,
          ),
        );
  }

  Future<void> resetToDefaults(ReaderInputPlatform platform) async {
    await (_db.delete(
      _db.appSettings,
    )..where((t) => t.key.equals(_key(platform)))).go();
  }

  String _key(ReaderInputPlatform platform) =>
      'reader.inputBindings.${platform.name}.v1';

  Map<String, Object?> _encode(ReaderInputProfile profile) => {
    'version': profile.version,
    'platform': profile.platform.name,
    'updatedAt': profile.updatedAt.toUtc().toIso8601String(),
    'bindings': {
      for (final entry in profile.bindings.entries)
        entry.key.value: entry.value?.name,
    },
  };

  ReaderInputProfile _decode(String? raw, ReaderInputPlatform platform) {
    final defaults = ReaderInputProfile.defaults(
      platform,
      updatedAt: DateTime.now(),
    );
    if (raw == null || raw.isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return defaults;
      final version = decoded['version'];
      final storedPlatform = decoded['platform'];
      final rawBindings = decoded['bindings'];
      if (version is! int ||
          storedPlatform != platform.name ||
          rawBindings is! Map) {
        return defaults;
      }
      final merged = <PhysicalInputId, ReaderCommand?>{...defaults.bindings};
      for (final entry in rawBindings.entries) {
        if (entry.key is! String) continue;
        final input = PhysicalInputId.parse(entry.key as String);
        if (input == null || input.platform != platform) continue;
        final value = entry.value;
        if (value == null) {
          merged[input] = null;
        } else if (value is String) {
          final command = _parseCommand(value);
          if (command != null) merged[input] = command;
        }
      }
      final migrated = version < ReaderInputProfile.currentVersion
          ? ReaderInputProfile.currentVersion
          : version;
      final timestamp = _parseDate(decoded['updatedAt']) ?? defaults.updatedAt;
      return ReaderInputProfile(
        platform: platform,
        version: migrated,
        bindings: Map.unmodifiable(merged),
        updatedAt: timestamp,
      );
    } catch (_) {
      return defaults;
    }
  }

  ReaderInputProfile _normalize(
    ReaderInputProfile profile,
    ReaderInputPlatform platform,
  ) {
    final defaults = ReaderInputProfile.defaults(platform);
    final bindings = <PhysicalInputId, ReaderCommand?>{...defaults.bindings};
    for (final entry in profile.bindings.entries) {
      if (entry.key.platform == platform) bindings[entry.key] = entry.value;
    }
    return ReaderInputProfile(
      platform: platform,
      version: ReaderInputProfile.currentVersion,
      bindings: Map.unmodifiable(bindings),
      updatedAt: profile.updatedAt,
    );
  }

  ReaderCommand? _parseCommand(String value) {
    for (final command in ReaderCommand.values) {
      if (command.name == value) return command;
    }
    return null;
  }

  DateTime? _parseDate(Object? value) => switch (value) {
    String value => DateTime.tryParse(value),
    _ => null,
  };
}
