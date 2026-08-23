# M5.8s.3 — TTS Sleep Timer

## Result

TTS now has a transient sleep-timer state owned by the existing
`TtsReadingController`. The timer is not persisted, does not create a
background task, and does not create a second reading-progress or Locator
truth.

The Reader TTS controls expose:

- Off
- 15 minutes
- 30 minutes
- 60 minutes
- Stop after the current chapter

The duration modes use a deadline based on the controller clock. The periodic
foreground tick only refreshes the displayed remaining time and enforces the
deadline; it does not keep the app alive in the background.

## Semantics

- Countdown uses real elapsed time and therefore continues while speech is
  paused.
- When the deadline is reached, the speech engine is stopped, the TTS state
  returns to idle, and the timer state reports an explicit expired status.
- Current-chapter mode uses the existing Reader chapter boundary/absolute
  UTF-16 offsets. It stops before the next chapter segment and never changes
  the Reader Locator.
- Manual navigation continues to restart TTS from the new Reader position and
  updates the chapter boundary supplied by the Reader.
- `stop()`, Reader disposal, and app/route teardown cancel the timer. No timer
  state is restored across an app restart.
- Timer expiry clears the transient speech highlight; starting again uses the
  current Reader position.

## Verification

| Gate | Result | Evidence |
| --- | --- | --- |
| 15/30/60 TIMER | PASS | Controller tests verify all three deadlines and expiry |
| STOP AFTER CHAPTER | PASS | Controller test stops after the first segment boundary without speaking the next chapter |
| PAUSE SEMANTICS | PASS | Injected clock test advances the deadline while state is paused |
| TIMER CLEANUP | PASS | Stop/dispose tests cancel the ticker and release the TTS engine |
| TTS REGRESSION | PASS | Existing continuous/follow and TTS UI tests remain green |

Commands executed from the canonical project root:

- `C:\Users\TOM\flutter\bin\flutter.bat analyze --no-pub` — PASS
- `C:\Users\TOM\flutter\bin\flutter.bat test --no-pub --reporter compact` — PASS (621 tests)
- `C:\Users\TOM\flutter\bin\flutter.bat test test/unit/tts_reading_controller_test.dart test/widget/reader_tts_ui_test.dart` — PASS (12 tests)
- `C:\Users\TOM\flutter\bin\flutter.bat build windows --release` — PASS
- `C:\Users\TOM\flutter\bin\flutter.bat build apk --release` — PASS
- `git diff --check` — PASS (only existing line-ending warnings)

Build outputs:

- Windows: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`

No TXT parser, pagination, Locator, ReaderProgress, platform TTS boundary,
Windows transparency, or Android Reader behavior was changed.
