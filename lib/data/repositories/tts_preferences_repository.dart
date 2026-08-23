import 'dart:convert';

import '../../domain/reader/tts_preferences.dart';
import '../database/app_database.dart';

/// Typed app-level storage for TTS voice and rate. Timer state intentionally
/// remains session-only, matching the TTS sleep-timer contract.
final class TtsPreferencesRepository {
  TtsPreferencesRepository({required this._db});

  static const String _key = 'reader.tts.preferences.v1';
  final AppDatabase _db;

  Future<TtsPreferences> load() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((table) => table.key.equals(_key))).getSingleOrNull();
    return _decode(row?.value);
  }

  Stream<TtsPreferences> watch() =>
      (_db.select(_db.appSettings)..where((table) => table.key.equals(_key)))
          .watchSingleOrNull()
          .map((row) => _decode(row?.value));

  Future<void> update(TtsPreferences preferences) async {
    final safe = preferences.copyWith(version: TtsPreferences.currentVersion);
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _key,
            value: jsonEncode({
              'version': safe.version,
              'speechRate': safe.speechRate,
              'voiceName': safe.voiceName,
              'voiceLocale': safe.voiceLocale,
              'voiceIdentifier': safe.voiceIdentifier,
            }),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> resetToDefaults() async {
    await (_db.delete(
      _db.appSettings,
    )..where((table) => table.key.equals(_key))).go();
  }

  TtsPreferences _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const TtsPreferences();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] is! int) {
        return const TtsPreferences();
      }
      final rate = decoded['speechRate'];
      return TtsPreferences(
        speechRate: rate is num ? rate.toDouble() : 1.0,
        voiceName: decoded['voiceName'] as String?,
        voiceLocale: decoded['voiceLocale'] as String?,
        voiceIdentifier: decoded['voiceIdentifier'] as String?,
        version: TtsPreferences.currentVersion,
      ).copyWith();
    } catch (_) {
      return const TtsPreferences();
    }
  }
}
