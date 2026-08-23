# M5.8s.6 TTS UX & Preferences Closure

## Changes

- Added app-level `TtsPreferences` and `TtsPreferencesRepository` backed by
  the existing Drift `app_settings` table. No schema migration or second
  progress/Locator truth was introduced.
- Speech rate (0.5x–2.0x) and selected voice identity (name, locale, stable
  identifier) are restored when Reader opens and saved immediately when the
  TTS controls change.
- If a saved voice is no longer enumerated, its selection is cleared and the
  platform TTS engine uses the system default; no replacement voice is guessed.
- Existing Reader TTS sheet is the lightweight control bar: previous,
  play/pause, next, stop, sleep timer, speed, and voice entry. All transport
  buttons use the shared `TtsCommand` path.
- TTS highlight continues to use the effective Reader theme color. No Reader
  geometry, true-transparency, Locator, pagination, or Android/Windows input
  behavior was changed.
- Sleep timer remains session-only by the M5.8s.3 contract and does not cross
  app restart.

## Verification

| Gate | Result |
| --- | --- |
| VOICE PERSISTENCE | PASS |
| SPEED PERSISTENCE | PASS |
| VOICE FALLBACK | PASS |
| CONTROL BAR | PASS |
| THEME | PASS (uses current Reader theme; protected visual baseline unchanged) |
| TRUE TRANSPARENCY | PASS (protected baseline; no implementation changes) |
| WINDOWS | PASS (Release build; existing in-process TTS path preserved) |
| ANDROID | PASS (Debug/Release build, emulator install and launcher smoke) |

## Test/build evidence

- `flutter analyze --no-pub` — PASS
- `flutter test --no-pub --concurrency=8 test/unit test/widget` — PASS (608 tests)
- `flutter test --no-pub --concurrency=8 test/contracts test/fixtures` — PASS (18 tests)
- TTS + preferences targeted tests — PASS (15 tests)
- `flutter build apk --release` — PASS (60.1 MB)
- `flutter build windows --release` — PASS
- `git diff --check` — PASS (only existing line-ending warnings)

Real speech/voice and Bluetooth headset acceptance remains a device/manual
step; no physical headset was available in this run.

## Artifacts (canonical project path)

- Windows Release: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android Release: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`
