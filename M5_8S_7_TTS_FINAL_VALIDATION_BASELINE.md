# M5.8s.7 — TTS Final Validation & Baseline Freeze

Date: 2026-08-15
Project root: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## Scope

This is a validation and documentation pass only. No new TTS feature was added.
The existing TTS implementation remains attached to the shared readable-text
source and the existing absolute UTF-16 Reader locator. It does not maintain an
independent TTS reading-progress store.

## Gate results

| Gate | Result | Evidence / limitation |
|---|---|---|
| Start from current reading location | PASS | Offset-to-segment and Reader integration tests |
| Pause / resume / stop | PASS | Controller and widget tests |
| Previous / next | PASS | Unified TTS command path and tests |
| Continuous segment reading | PASS | Completion advances the existing readable-text queue |
| Continuous chapter reading | PASS | Chapter boundary continuation tests |
| Vertical automatic follow | PASS | Existing UTF-16 follow contract; no layout mutation |
| Paged automatic follow | PASS | Existing paged window/follow contract |
| Voice selection | PASS (automated) | System voice enumeration, persistence and fallback; live speech is MANUAL REQUIRED |
| Speech rate | PASS | Persisted/clamped preference and control-sheet tests |
| Sleep timer | PASS | 15/30/60 minute and fake-clock expiry tests |
| Stop after current chapter | PASS | Stops at chapter boundary without entering next chapter |
| Android screen-off | MANUAL REQUIRED | Requires a real utterance and physical/emulator screen-off acceptance |
| Android background | MANUAL REQUIRED | Foreground-service path built; live background speech not run in this pass |
| Windows minimized | MANUAL REQUIRED | Existing in-process path/build preserved; live speech acceptance pending |
| Windows Tray hidden | MANUAL REQUIRED | Existing Tray path/build preserved; live speech acceptance pending |
| Media / headset controls | MANUAL REQUIRED / DEFERRED | Android MediaSession and notification path built; Bluetooth/lock-screen requires hardware; Windows native media control is DEFERRED |
| Reader close cleanup | PASS | Controller dispose stops TTS and releases listeners/session |
| App exit cleanup | PASS (automated/native path) | Dispose and Android Activity/service stop paths covered; live OS exit remains part of manual acceptance |
| UTF-16 Locator regression | PASS | Full unit/widget/contract coverage; TTS is paint/follow only |
| ReaderProgress regression | PASS | No TTS progress persistence or schema change |
| Windows true transparency regression | PASS (protected baseline) | Existing manually accepted 8d-4-FINAL path untouched by TTS |

## Verification commands

- `C:\Users\TOM\flutter\bin\flutter.bat analyze --no-pub` — PASS.
- `C:\Users\TOM\flutter\bin\flutter.bat test --no-pub --concurrency=8 --reporter compact test/unit test/widget` — PASS.
- `C:\Users\TOM\flutter\bin\flutter.bat test --no-pub --concurrency=8 --reporter compact test/contracts test/fixtures` — PASS.
- Test total: 626 across the four test directories above.
- `C:\Users\TOM\flutter\bin\flutter.bat build windows --release` — PASS.
- `C:\Users\TOM\flutter\bin\flutter.bat build apk --release` — PASS (60.1 MB).
- `C:\Users\TOM\AppData\Local\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk` — PASS.
- Emulator launcher smoke for `com.xaocen.xaocen_reader` — PASS.
- `git diff --check` — PASS (existing line-ending warnings only).

## Final status

```text
TTS FOUNDATION = PASS
CONTINUOUS READING = PASS
SLEEP TIMER = PASS
BACKGROUND READING = MANUAL REQUIRED
MEDIA CONTROL = MANUAL REQUIRED / WINDOWS DEFERRED
PREFERENCES = PASS
LOCATOR REGRESSION = PASS
TRANSPARENCY REGRESSION = PASS (protected baseline)
TTS BASELINE = PASS WITH MANUAL ACCEPTANCE ITEMS OPEN
```

The remaining manual items are intentionally not converted to PASS. No EPUB or
RSS work is started by this milestone.
