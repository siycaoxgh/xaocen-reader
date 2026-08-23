# M5.8s.8b — TTS Live Speech Rate

Date: 2026-08-15
Project root: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## Implementation

Platform TTS engines commonly apply `setSpeechRate` only to a subsequent
utterance. `TtsReadingController.setSpeechRate` now handles an active utterance
as a position-preserving paint/audio transition:

1. capture the current active segment and absolute UTF-16 speech offset;
2. stop the current utterance;
3. apply the new clamped rate;
4. speak only the remaining segment substring from that offset;
5. map subsequent platform progress back to the same absolute Reader offset.

Paused/idle states keep the new rate for the next resume/start without an
unnecessary restart. Segment/chapter, Locator and ReaderProgress ownership are
unchanged. No second TTS progress truth was introduced.

## Verification

| Gate | Result | Evidence |
|---|---|---|
| LIVE RATE | PASS (logic) / MANUAL REQUIRED (audible) | Controller restarts the current utterance without replaying its prefix; real listening still needs a human |
| ANDROID | PASS (build/regression) / MANUAL REQUIRED (audible) | Android Release build and Emulator install succeeded; physical speech-rate listening remains manual |
| WINDOWS | PASS (build/regression) / MANUAL REQUIRED (audible) | Windows Release canonical staging and launch smoke succeeded; real SAPI listening remains manual |
| POSITION CONTINUITY | PASS | UTF-16 offset is retained as utterance base and test verifies remainder-only restart |
| LOCATOR REGRESSION | PASS | No Reader locator/pagination/progress code changed; full test directories remain green |

Automated evidence:

- `flutter analyze --no-pub` — PASS.
- `tts_reading_controller_test.dart` — PASS (16 tests, including live-rate
  restart from the current UTF-16 position).
- Full test directories (`test/unit`, `test/widget`, `test/contracts`,
  `test/fixtures`) — PASS (626 tests).
- `flutter build windows --release` — PASS.
- `tool\build_windows_engine.ps1 -Engine Standard -Configuration Release -Smoke`
  — PASS; canonical artifact staged and launch smoke stayed alive.
- `flutter build apk --release` — PASS.
- `git diff --check` — PASS (existing line-ending warnings only).

Canonical artifacts:

```text
C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe
C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk
```
