# M5.7s.7c-2 — Smart Screen Awake / Sleep Protection

## Scope

Implemented Reader-only screen-awake policy. No Android global timeout or
`WRITE_SETTINGS` permission is used. ReaderLocator, pagination, ReaderInfo
geometry, AutoRead drivers, and ReadingSession contracts remain unchanged.

## Contract

- `followSystem`: XAOCEN never owns `FLAG_KEEP_SCREEN_ON`.
- `whileReading`: the Reader route owns the flag only while it is foreground;
  leaving Reader or entering app background releases it immediately.
- `smart`: real Reader activity starts/resets the inactivity timer. The default
  timeout is 30 minutes, with 15/30/60-minute choices. On timeout the flag is
  released and a running AutoRead driver is paused with `inactivityTimeout`.
- Automatic scroll/page ticks, animation frames, layout, theme, clock, battery
  and ReaderInfo updates do not count as activity.
- Resume is not synthetic activity: smart mode waits for the next real input;
  while-reading mode restores the policy when the Reader is foreground again.

## Architecture

`ReaderScreenAwakeController` is a platform-independent state owner with an
injected timer/scheduler and keep-awake callback. `ReaderPage` is the only
Reader lifecycle bridge; Android uses the existing `setKeepScreenOn` channel
through `ReaderKeepAwake`. No keep-awake logic was added to Reader engine,
shell pages, or AutoRead drivers.

## Persistence

`ReaderPreferences` now stores `screenAwakeMode` and
`screenAwakeInactivityMinutes` per book. Schema 17→18 adds the two columns with
`followSystem` and `30` defaults. Existing typography, appearance, progress,
history, and Locator data are preserved.

## Verification

- `flutter analyze`: PASS
- Full Flutter test suite: PASS (572 tests)
- Screen-awake controller tests: PASS
- ReaderPreferences/repository/schema migration tests: PASS
- Reader settings responsive/widget tests: PASS
- Android Debug APK: PASS
- Emulator `xaocen_api35_x86_64` booted with `sys.boot_completed=1`,
  `install -r` succeeded, and launcher activity was focused: PASS
- Windows Release build: PASS
- `git diff --check`: PASS

The emulator smoke launch did not clear data, uninstall the app, or run an
integration-test runner over the final APK.

## Gate result

SCREEN AWAKE MODE = PASS

SMART INACTIVITY = PASS

AUTOREAD SLEEP PROTECTION = PASS

BACKGROUND RELEASE = PASS

Final APK: `build/app/outputs/flutter-apk/app-debug.apk`

Final Windows executable: `build/windows/x64/runner/Release/xaocen_reader.exe`
