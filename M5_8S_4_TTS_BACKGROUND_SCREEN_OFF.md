# M5.8s.4 — TTS Background & Screen-Off

## Implementation

TTS remains owned by the existing `TtsReadingController`; no Locator,
pagination, or ReaderProgress path was changed.

On Android, a speaking session now uses a platform-only background session:

- `TtsForegroundService` is declared as a `mediaPlayback` foreground service.
- The service keeps the app process eligible to continue system TTS while the
  Activity is backgrounded or the display is off.
- The notification shows `晓枨阅读`, `正在朗读`, and a `停止朗读` action.
- `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, and
  `FOREGROUND_SERVICE_MEDIA_PLAYBACK` are declared; the notification permission
  is requested only when TTS first starts on Android 13+.
- The service is stopped on TTS stop, timer expiry, speech error, Reader
  dispose, and normal Activity finish. It is not a separate speech queue or
  background task system.
- Android audio focus uses speech/navigation audio attributes. Focus loss
  pauses the current utterance; focus gain resumes only when that pause came
  from focus loss. A user pause is not auto-resumed.

Windows keeps the existing in-process `flutter_tts` path. Minimize/Tray hiding
does not dispose the Reader or TTS controller; normal Reader/App disposal
still stops TTS.

Smart Awake remains independent: AppLifecycle background transitions release
`KEEP_SCREEN_ON` as before, and TTS does not call the Smart Awake activity
recording path.

## Verification

| Gate | Result | Evidence |
| --- | --- | --- |
| ANDROID SCREEN OFF | PLATFORM MANUAL REQUIRED | Android foreground-service path is built; a real TTS utterance plus screen-off cycle was not executed in this run |
| ANDROID BACKGROUND | PLATFORM MANUAL REQUIRED | Emulator installed/launched the final APK, but no live TTS/background interaction was performed |
| AUDIO FOCUS | PASS (automated) / PLATFORM MANUAL REQUIRED (device) | Controller test verifies focus loss pauses and focus gain resumes; call/audio takeover still requires device acceptance |
| WINDOWS MINIMIZED | PLATFORM MANUAL REQUIRED | Existing Windows TTS path is unchanged and Release build passed; live speech/minimize acceptance remains required |
| WINDOWS TRAY | PLATFORM MANUAL REQUIRED | Existing Tray path is unchanged and Release build passed; live speech/Tray acceptance remains required |
| APP EXIT CLEANUP | PASS | Controller disposal test verifies TTS/background-session cleanup; native Activity finish also stops the service |

## Commands

Executed from the canonical project root:

- `C:\Users\TOM\flutter\bin\flutter.bat analyze --no-pub` — PASS
- `C:\Users\TOM\flutter\bin\flutter.bat test --no-pub --reporter compact` — PASS (623 tests)
- `C:\Users\TOM\flutter\bin\flutter.bat build apk --debug` — PASS
- `C:\Users\TOM\flutter\bin\flutter.bat build apk --release` — PASS
- `C:\Users\TOM\flutter\bin\flutter.bat build windows --release` — PASS
- `git diff --check` — PASS (existing line-ending warnings only)

Android smoke evidence:

- AVD `xaocen_api35_x86_64`, device `emulator-5554`, `sys.boot_completed=1`
- `adb install -r` — PASS
- Launcher/MainActivity — PASS
- No Flutter or AndroidRuntime exception in the captured startup log
- Package service/permissions are present in `dumpsys package`

Final artifacts:

- Windows: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android Release: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`
- Android Debug: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

No Android data was cleared, no uninstall was performed, and no Reader
Locator or progress data was modified.
