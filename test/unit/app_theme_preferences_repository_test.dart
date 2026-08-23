import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/app_theme_preferences_repository.dart';
import 'package:xaocen_reader/domain/app_theme_mode.dart';

void main() {
  test('app shell theme persists independently from Reader preferences', () async {
    final database = AppDatabase.forTesting();
    addTearDown(database.close);
    final repository = AppThemePreferencesRepository(database);

    expect(await repository.load(), AppThemeMode.system);
    await repository.save(AppThemeMode.dark);
    expect(await repository.load(), AppThemeMode.dark);

    await repository.save(AppThemeMode.light);
    expect(await repository.load(), AppThemeMode.light);
    await repository.reset();
    expect(await repository.load(), AppThemeMode.system);
  });
}
