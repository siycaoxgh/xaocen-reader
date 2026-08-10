import 'dart:convert';

// The public parameter is intentionally named `db`; the private field keeps
// storage details out of callers.
// ignore_for_file: prefer_initializing_formals

import '../../domain/reader/auto_read_preferences.dart';
import '../database/app_database.dart';

/// Strongly typed global AutoRead preferences boundary.
///
/// The app_settings key and JSON format are private to this repository. No
/// AutoRead driver or UI should know either storage detail.
final class AutoReadPreferencesRepository {
  AutoReadPreferencesRepository({required AppDatabase db}) : _db = db;

  static const String _key = 'reader.autoRead.preferences.v1';
  final AppDatabase _db;

  Future<AutoReadPreferences> load() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(_key))).getSingleOrNull();
    return _decode(row?.value);
  }

  Stream<AutoReadPreferences> watch() =>
      (_db.select(_db.appSettings)..where((t) => t.key.equals(_key)))
          .watchSingleOrNull()
          .map((row) => _decode(row?.value));

  Future<void> update(AutoReadPreferences preferences) async {
    final safe = AutoReadPreferences(
      verticalVelocityPixelsPerSecond:
          preferences.verticalVelocityPixelsPerSecond,
      pagedIntervalSeconds: preferences.pagedIntervalSeconds,
      version: preferences.version,
      updatedAt: preferences.updatedAt,
    );
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _key,
            value: jsonEncode(_encode(safe)),
            updatedAt: safe.updatedAt,
          ),
        );
  }

  Future<void> setVerticalSpeed(VerticalSpeedPreset preset) async {
    await setVerticalVelocity(preset.velocityPixelsPerSecond);
  }

  Future<void> setVerticalVelocity(int velocity) async {
    final current = await load();
    await update(
      current.copyWith(
        verticalVelocityPixelsPerSecond: velocity,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> setPagedInterval(int seconds) async {
    final current = await load();
    await update(
      current.copyWith(
        pagedIntervalSeconds: seconds,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> resetToDefaults() async {
    await (_db.delete(_db.appSettings)..where((t) => t.key.equals(_key))).go();
  }

  Map<String, Object?> _encode(AutoReadPreferences preferences) => {
    'version': preferences.version,
    'verticalVelocityPixelsPerSecond':
        preferences.verticalVelocityPixelsPerSecond,
    'pagedIntervalSeconds': preferences.pagedIntervalSeconds,
    'updatedAt': preferences.updatedAt.toUtc().toIso8601String(),
  };

  AutoReadPreferences _decode(String? raw) {
    final defaults = AutoReadPreferences.defaults;
    if (raw == null || raw.isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return defaults;
      final version = decoded['version'];
      if (version is! int || version > AutoReadPreferences.currentVersion) {
        return defaults;
      }
      final velocity = _parseCanonicalVelocity(
        decoded['verticalVelocityPixelsPerSecond'],
      );
      return AutoReadPreferences(
        verticalVelocityPixelsPerSecond:
            velocity ?? _parseLegacyPreset(decoded['verticalSpeedPreset']),
        pagedIntervalSeconds: _parseInterval(decoded['pagedIntervalSeconds']),
        version: version,
        updatedAt: _parseDate(decoded['updatedAt']) ?? defaults.updatedAt,
      );
    } catch (_) {
      return defaults;
    }
  }

  int? _parseCanonicalVelocity(Object? value) {
    if (value is! num || value.isNaN || value.isInfinite) return null;
    final velocity = value.toInt();
    if (value != velocity) return null;
    if (velocity < AutoReadPreferences.minVerticalVelocityPixelsPerSecond ||
        velocity > AutoReadPreferences.maxVerticalVelocityPixelsPerSecond) {
      return null;
    }
    return velocity;
  }

  int _parseLegacyPreset(Object? value) => VerticalSpeedPreset.values
      .firstWhere(
        (preset) => preset.name == value,
        orElse: () => AutoReadPreferences.defaultVerticalSpeedPreset,
      )
      .velocityPixelsPerSecond;

  int _parseInterval(Object? value) =>
      value is int &&
          AutoReadPreferences.supportedPagedIntervals.contains(value)
      ? value
      : AutoReadPreferences.defaultPagedIntervalSeconds;

  DateTime? _parseDate(Object? value) => switch (value) {
    String value => DateTime.tryParse(value),
    _ => null,
  };
}
