import 'dart:convert';

import '../../domain/windows_shell_preferences.dart';
import '../database/app_database.dart';

/// Typed boundary for Windows shell settings. Storage keys and JSON stay
/// private to this repository just like other app_settings repositories.
final class WindowsShellPreferencesRepository {
  WindowsShellPreferencesRepository({required this._db});

  static const String _key = 'windows.shell.preferences.v1';
  final AppDatabase _db;

  Future<WindowsShellPreferences> load() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(_key))).getSingleOrNull();
    return _decode(row?.value);
  }

  Stream<WindowsShellPreferences> watch() =>
      (_db.select(_db.appSettings)..where((t) => t.key.equals(_key)))
          .watchSingleOrNull()
          .map((row) => _decode(row?.value));

  Future<WindowsShellPreferences> update({
    required bool showTaskbarIcon,
    required bool showTrayIcon,
  }) async {
    if (!showTaskbarIcon && !showTrayIcon) {
      throw const WindowsShellVisibilityException();
    }
    final next = WindowsShellPreferences(
      showTaskbarIcon: showTaskbarIcon,
      showTrayIcon: showTrayIcon,
      version: WindowsShellPreferences.currentVersion,
      updatedAt: DateTime.now().toUtc(),
    );
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _key,
            value: jsonEncode(_encode(next)),
            updatedAt: next.updatedAt,
          ),
        );
    return next;
  }

  Future<WindowsShellPreferences> resetToDefaults() async {
    await (_db.delete(_db.appSettings)..where((t) => t.key.equals(_key))).go();
    return load();
  }

  Map<String, Object?> _encode(WindowsShellPreferences preferences) => {
    'version': preferences.version,
    'showTaskbarIcon': preferences.showTaskbarIcon,
    'showTrayIcon': preferences.showTrayIcon,
    'updatedAt': preferences.updatedAt.toUtc().toIso8601String(),
  };

  WindowsShellPreferences _decode(String? raw) {
    if (raw == null || raw.isEmpty) return WindowsShellPreferences.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return WindowsShellPreferences.defaults;
      final version = decoded['version'];
      if (version is! int || version > WindowsShellPreferences.currentVersion) {
        return WindowsShellPreferences.defaults;
      }
      final taskbar = decoded['showTaskbarIcon'];
      final tray = decoded['showTrayIcon'];
      if (taskbar is! bool || tray is! bool || (!taskbar && !tray)) {
        return WindowsShellPreferences.defaults;
      }
      return WindowsShellPreferences(
        showTaskbarIcon: taskbar,
        showTrayIcon: tray,
        version: version,
        updatedAt: _parseDate(decoded['updatedAt']) ?? DateTime.now().toUtc(),
      );
    } catch (_) {
      return WindowsShellPreferences.defaults;
    }
  }

  DateTime? _parseDate(Object? value) => switch (value) {
    String value => DateTime.tryParse(value),
    _ => null,
  };
}
