# M5.8s.8-FINAL — TTS Baseline Freeze

Date: 2026-08-15
Project root: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

This pass added no feature and changed no TTS/AutoRead production code. It
performed the final regression gates and froze the existing product contract.

## Final status

```text
TTS BASELINE = PASS
ANDROID = PASS (build/regression; physical lock-screen, headset and key hardware are MANUAL REQUIRED)
WINDOWS = PASS (Patched Release build and launch smoke; native system media control DEFERRED)
MEDIA CONTROL = PASS (Android MediaSession/notification path); MANUAL REQUIRED for physical lock-screen/headset and AVD KEYCODE route
LOCATOR REGRESSION = PASS
TRANSPARENCY REGRESSION = PASS
```

## Frozen contract

- TTS starts from the current Reader location, follows the shared readable
  text stream across segments and chapters, and stops at end of book.
- AutoRead and TTS are mutually exclusive sessions. Starting one ends the
  other; an old paused session cannot revive after a handoff.
- The Reader bottom Chrome exposes one `自动` entry. AutoRead and TTS use one
  shared floating control shell with the same geometry, rounded shape and
  interaction semantics.
- The production overlay hides after **2.5 seconds** of inactivity and is
  recalled by Reader interaction.
- Live speech-rate changes preserve the active UTF-16 speech offset; paused
  TTS stays paused when its rate is changed.
- TTS sleep modes are off, 15 minutes, 30 minutes, 60 minutes and current
  chapter end. Timers are cleared when Reader/App resources are disposed.
- Android automatic-volume-key behavior is one shared setting: follow normal
  reading, control the active automatic mode, or return keys to system volume.
- Android MediaSession and foreground notification actions use the unified TTS
  command path. Emulator notification actions were verified for pause/resume,
  previous and next. The AVD injected `KEYCODE_MEDIA_*` events were not routed
  to XAOCEN (`Media button session is null`), so they remain manual-required.
- Windows TTS provider failure is contained and falls back to TTS unavailable;
  it does not block Reader startup. Windows native system media control remains
  DEFERRED.

## Verification

- `flutter analyze --no-pub` — PASS.
- `flutter test --no-pub` — PASS, 642 tests.
- Android Release — PASS:
  `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`
- Windows Patched Release — PASS, including short launch smoke:
  `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe`
- `git diff --check` — PASS; only existing line-ending warnings were reported.
- True-transparency, ReaderProgress, UTF-16 Locator and pagination baselines
  remain unchanged and pass their protected regression checks.

Hardware-dependent items are intentionally not promoted to PASS: real
Bluetooth headset media buttons, secure lock-screen controls, physical Android
volume keys and audible speech-rate differences.

EPUB and RSS remain planned/deferred and are neither PASS nor FAIL.
