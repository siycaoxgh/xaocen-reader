# M5.8s.8a — Windows TTS Launch Regression

Date: 2026-08-15
Project root: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## Root cause

The real Windows Application Error log showed:

```text
Faulting application: xaocen_reader.exe
Faulting module: ...\artifacts\windows\current\Release\flutter_tts_plugin.dll
Exception code: 0xc0000005 (access violation)
Fault offset: 0xDD9A
```

The first blocker was the Windows `flutter_tts` SAPI voice-enumeration path,
not the Flutter Engine, the single-instance mutex, or true transparency. The
upstream Win32 plugin assumed every SAPI token had valid `Language` and `Name`
attributes and passed null/failed HRESULT results into `CW2A`/`LCIDToLocaleName`.
That native access violation could terminate XAOCEN while Reader startup was
loading TTS preferences.

## Minimal fix

- Vendored the exact `flutter_tts` 4.2.5 package under
  `third_party/flutter_tts` and selected it through one `dependency_overrides`
  path entry, keeping Android/iOS/macOS/Web sources unchanged.
- Hardened only the Windows Win32 plugin: no exception from optional COM/SAPI
  initialization, null/HRESULT checks while enumerating voices, safe SAPI
  cleanup, and no invalid completion-result pointer registration.
- Hardened the Dart TTS boundary so provider errors in voice/rate/voice-control
  calls are contained. An unavailable provider yields an empty voice list and
  leaves Reader startup usable; it does not create a second progress truth.
- The existing Android implementation and MediaSession path were not changed.

## Verification

| Gate | Result | Evidence |
|---|---|---|
| WINDOWS LAUNCH | PASS | `tool\build_windows_engine.ps1 -Engine Standard -Configuration Release -Smoke`; canonical staged process stayed alive for smoke window |
| WINDOWS TTS | PASS (provider guarded) | Windows plugin rebuild; unavailable voice-provider unit test; no new WER crash after smoke |
| TTS FAILURE FALLBACK | PASS | Voice enumeration failures return empty list; rate/voice platform failures are contained |
| ANDROID REGRESSION | PASS | Android Release build, `adb install -r` on `emulator-5554`, launcher process smoke |
| TRUE TRANSPARENCY REGRESSION | PASS (protected baseline) | No transparency/Engine/Reader geometry changes; Standard Engine selector and frozen artifact path retained |

Additional verification:

- `flutter analyze --no-pub` — PASS.
- TTS controller tests — PASS (15 tests, including unavailable voice provider).
- Full test directories (`test/unit`, `test/widget`, `test/contracts`,
  `test/fixtures`) — PASS (626 tests).
- `flutter build windows --release` — PASS.
- `flutter build apk --release` — PASS (60.2 MB).
- `git diff --check` — PASS (existing line-ending warnings only).

Canonical Windows output remains:

```text
C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe
```

No Android Reader, Locator, Reader Core, true-transparency implementation, or
single-instance behavior was changed.

## Final result

```text
WINDOWS LAUNCH = PASS
WINDOWS TTS = PASS (guarded; live speech still depends on installed SAPI voice)
TTS FAILURE FALLBACK = PASS
ANDROID REGRESSION = PASS
TRUE TRANSPARENCY REGRESSION = PASS
```
