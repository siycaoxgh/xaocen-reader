import '../../domain/app_theme_mode.dart';
import '../database/app_database.dart';

/// Persists the application-shell theme without touching per-book Reader
/// preferences. It deliberately uses the existing app_settings key/value
/// table, so changing the shell theme does not require a schema migration.
final class AppThemePreferencesRepository {
  AppThemePreferencesRepository(this._database);

  static const _key = 'app.themeMode';
  final AppDatabase _database;

  Future<AppThemeMode> load() async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((table) => table.key.equals(_key))).getSingleOrNull();
    return AppThemeModeX.parse(row?.value);
  }

  Future<void> save(AppThemeMode mode) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _key,
            value: mode.name,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> reset() async {
    await (_database.delete(
      _database.appSettings,
    )..where((table) => table.key.equals(_key))).go();
  }
}
