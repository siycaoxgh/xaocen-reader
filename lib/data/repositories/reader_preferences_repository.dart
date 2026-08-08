/// ReaderPreferencesRepository —— 全局阅读设置的强类型持久化边界。
///
/// app_settings 的字符串 key/value 只存在于本文件与数据库生成层；
/// UI、Controller、Reader 不得解释 storage key。
library;

// ignore_for_file: prefer_initializing_formals

import '../../domain/reader/reader_preferences.dart';
import '../database/app_database.dart';

final class ReaderPreferencesRepository {
  ReaderPreferencesRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  static const _fontSizeKey = 'reader.fontSize';
  static const _lineHeightKey = 'reader.lineHeight';
  static const _horizontalPaddingKey = 'reader.horizontalPadding';
  static const _verticalPaddingKey = 'reader.verticalPadding';
  static const _themeModeKey = 'reader.themeMode';

  static const _ownedKeys = <String>{
    _fontSizeKey,
    _lineHeightKey,
    _horizontalPaddingKey,
    _verticalPaddingKey,
    _themeModeKey,
  };

  /// 读取设置。缺失、非法、非有限或解析失败的字段分别回退默认值。
  Future<ReaderPreferences> load() async {
    final rows = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.isIn(_ownedKeys))).get();
    return _decode(rows);
  }

  /// 监听设置；订阅时立即发出当前值，后续每次表变化发出合法强类型值。
  Stream<ReaderPreferences> watch() {
    return (_db.select(
      _db.appSettings,
    )..where((t) => t.key.isIn(_ownedKeys))).watch().map(_decode);
  }

  /// 原子保存完整设置快照。
  Future<void> update(ReaderPreferences preferences) async {
    final safe = ReaderPreferences(
      fontSize: preferences.fontSize,
      lineHeight: preferences.lineHeight,
      horizontalPadding: preferences.horizontalPadding,
      verticalPadding: preferences.verticalPadding,
      themeMode: preferences.themeMode,
    );
    final values = <String, String>{
      _fontSizeKey: safe.fontSize.toString(),
      _lineHeightKey: safe.lineHeight.toString(),
      _horizontalPaddingKey: safe.horizontalPadding.toString(),
      _verticalPaddingKey: safe.verticalPadding.toString(),
      _themeModeKey: safe.themeMode.name,
    };
    final now = DateTime.now();
    await _db.transaction(() async {
      for (final entry in values.entries) {
        await _db
            .into(_db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                key: entry.key,
                value: entry.value,
                updatedAt: now,
              ),
            );
      }
    });
  }

  /// 删除 Reader 拥有的设置行，恢复默认值；不影响其他 AppSettings。
  Future<void> resetToDefaults() async {
    await (_db.delete(
      _db.appSettings,
    )..where((t) => t.key.isIn(_ownedKeys))).go();
  }

  ReaderPreferences _decode(List<AppSetting> rows) {
    final values = <String, String>{for (final row in rows) row.key: row.value};
    return ReaderPreferences(
      fontSize: _parseDouble(
        values[_fontSizeKey],
        ReaderPreferences.defaultFontSize,
      ),
      lineHeight: _parseDouble(
        values[_lineHeightKey],
        ReaderPreferences.defaultLineHeight,
      ),
      horizontalPadding: _parseDouble(
        values[_horizontalPaddingKey],
        ReaderPreferences.defaultHorizontalPadding,
      ),
      verticalPadding: _parseDouble(
        values[_verticalPaddingKey],
        ReaderPreferences.defaultVerticalPadding,
      ),
      themeMode: _parseThemeMode(values[_themeModeKey]),
    );
  }

  double _parseDouble(String? raw, double fallback) {
    if (raw == null) return fallback;
    return double.tryParse(raw) ?? fallback;
  }

  ReaderThemeMode _parseThemeMode(String? raw) {
    return ReaderThemeMode.values
            .where((mode) => mode.name == raw)
            .firstOrNull ??
        ReaderPreferences.defaultThemeMode;
  }
}
