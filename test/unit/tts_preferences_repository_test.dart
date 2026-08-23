import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/tts_preferences_repository.dart';
import 'package:xaocen_reader/domain/reader/tts_preferences.dart';

void main() {
  late AppDatabase db;
  late TtsPreferencesRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = TtsPreferencesRepository(db: db);
  });

  tearDown(() => db.close());

  test('rate and voice persist and reload', () async {
    await repository.update(
      const TtsPreferences(
        speechRate: 1.35,
        voiceName: 'Chinese voice',
        voiceLocale: 'zh-CN',
        voiceIdentifier: 'voice-1',
      ),
    );

    final loaded = await repository.load();
    expect(loaded.speechRate, 1.35);
    expect(loaded.voiceName, 'Chinese voice');
    expect(loaded.voiceLocale, 'zh-CN');
    expect(loaded.voiceIdentifier, 'voice-1');
  });

  test('invalid or missing values safely use defaults', () async {
    final loaded = await repository.load();
    expect(loaded.speechRate, TtsPreferences.defaultSpeechRate);
    expect(loaded.voiceName, isNull);

    await repository.update(const TtsPreferences(speechRate: 10));
    expect((await repository.load()).speechRate, 2.0);
  });
}
