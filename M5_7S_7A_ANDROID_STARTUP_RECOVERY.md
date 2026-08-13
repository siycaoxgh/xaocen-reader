# M5.7s.7a Android Install / White Screen Recovery

Date: 2026-08-13  
Device: `ce8df63f` / `23013RK75C` / Android 15 / `arm64-v8a`

## Root cause

- **App disappearance: UNKNOWN.** Repository scripts and available project
  history contain no `adb uninstall` or `pm clear` command. The recorded
  device flow uses `install -r`, `am force-stop`, and Launcher/`monkey` start.
  A destructive cleanup that would explain removal of the user package could
  not be proven, so it is not claimed.
- **White-screen mechanism: not directly reproducible in this run.** The project
  engineering record documents that `flutter test integration_test` can
  overwrite `build/app/outputs/flutter-apk/app-debug.apk` with a test-runner
  entry point. Installing that artifact as the normal application can leave a
  live process with no normal Reader home UI. This is the documented/probable
  mechanism for the earlier white-screen report, but no command log proves it
  was the exact artifact installed in that incident. The recovery procedure
  rebuilds the ordinary APK after tests and installs only that artifact.

## Audit and non-destructive install

- `adb devices -l`: USB device `ce8df63f` is `device`; no wireless channel was
  used.
- Final command: `flutter build apk --debug`.
- APK: `build/app/outputs/flutter-apk/app-debug.apk` (ordinary application,
  185,303,036 bytes).
- Package: `com.xaocen.xaocen_reader`, version `0.1.0-dev.4` / code `4`,
  primary ABI `arm64-v8a`.
- Install: `adb -s ce8df63f install -r <apk>` → `Success`.
- No `uninstall`, `pm clear`, DataRoot deletion, database deletion, or book
  deletion was performed.

The package `firstInstallTime` stayed `2026-08-13 09:24:33` across the final
install (`lastUpdateTime` advanced), which is consistent with data-preserving
replacement. The app-private DataRoot remains present at
`files/xaocen_reader/`, including `database/xaocen_v4_local.sqlite`, `books/`,
`settings/`, `fonts/`, `backups/`, and the root metadata/lock files.

## White-screen diagnosis

After clearing logcat, force-stopping, and launching from the normal Launcher
entry, the app process and `MainActivity` became resumed. The app-specific log
contained no `FATAL EXCEPTION`, `AndroidRuntime`, `FlutterError`,
`PlatformException`, `MissingPlugin`, Drift/SQLite, migration/schema, or Dart
exception. Flutter reported the expected Impeller/Vulkan initialization and
viewport metrics. A device screenshot showed the normal XAOCEN home page with
the three primary destinations (首页 / 书架 / 我的), not a white screen.

Three additional cold starts (force-stop → Launcher start, five-second settle)
all resumed `com.xaocen.xaocen_reader/.MainActivity` without app-specific
errors. The home route remained usable after the final install; no startup
code change was necessary.

## Verification result

- Cold startup: **PASS**
- Home visible: **PASS**
- Package/activity stable across three launches: **PASS**
- User data preservation for this `install -r`: **YES** (package data directory,
  DataRoot database and managed directories remained; prior disappearance cannot
  be reconstructed and is recorded as UNKNOWN above).
- Full integration suite: intentionally **NOT RUN** in this recovery task to
  avoid replacing the application APK again.

## Checks

- `flutter analyze`: PASS
- Flutter tests: PASS — 540 tests
- `flutter build apk --debug`: PASS
- `git diff --check`: PASS
- Android physical device: USB targeted startup smoke PASS

## Final artifacts

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

`ANDROID STARTUP = PASS`  
`ROOT CAUSE = UNKNOWN for the specific incident; documented stale
integration-test APK mechanism is the probable white-screen cause; app
disappearance remains UNKNOWN`
