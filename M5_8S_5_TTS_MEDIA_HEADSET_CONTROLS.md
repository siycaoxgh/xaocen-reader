# M5.8s.5 TTS Media & Headset Controls

## Scope

Android now exposes one native `MediaSession` for the existing
`TtsReadingController`. Media callbacks and notification actions are mapped to
the shared `TtsCommand` enum (`playPause`, `previous`, `next`, `stop`); no
platform-specific playback state or keyboard shortcut binding was added.

The foreground speech service notification uses the active session token and
provides previous, play/pause, next, and stop actions. Audio focus behavior
from M5.8s.4 remains unchanged. Stopping, reaching the end, Reader disposal,
or app finish releases the service and MediaSession.

## Verification

| Gate | Result | Evidence |
| --- | --- | --- |
| ANDROID MEDIA SESSION | PASS (native/build) | API 35 APK builds; MediaSession callback and token are wired in `MainActivity` and the foreground service |
| BLUETOOTH PLAY/PAUSE | PLATFORM MANUAL REQUIRED | Requires a real Bluetooth headset/media-key cycle |
| BLUETOOTH NEXT/PREV | PLATFORM MANUAL REQUIRED | Requires a real Bluetooth headset/media-key cycle |
| LOCK SCREEN CONTROL | PLATFORM MANUAL REQUIRED | Requires a physical lock-screen acceptance run |
| NOTIFICATION CONTROL | PASS (implemented/build) | MediaStyle notification with previous/play-pause/next/stop actions |
| WINDOWS MEDIA CONTROL | DEFERRED | Existing Windows TTS remains in-process; adding native SMTC/media-key ownership would expand the Windows runner architecture and risk the protected shortcut baseline |
| RESOURCE CLEANUP | PASS | Controller media-command and dispose tests; native stop path releases service/session |

## Build evidence

- `C:\Users\TOM\flutter\bin\flutter.bat analyze --no-pub` — PASS
- TTS/repository tests — PASS
- `flutter test --no-pub --concurrency=8 test/unit test/widget` — PASS (608 tests)
- `flutter test --no-pub --concurrency=8 test/contracts test/fixtures` — PASS (18 tests)
- `flutter build apk --debug` — PASS
- `flutter build apk --release` — PASS
- Emulator `emulator-5554` — online; release APK installed with `adb install -r`

## Artifacts

- Android Release: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`
- Android Debug: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
