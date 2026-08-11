# M5.6c.1 Result — Windows shell visibility and Boss Key

Status: complete. Drift schema remains 10.

## Implementation

- Added typed `WindowsShellPreferences` and
  `WindowsShellPreferencesRepository` on `app_settings`.
- Taskbar and tray flags are independent, but the repository rejects an update
  that would disable both. Corrupt or unsafe stored values fall back to
  taskbar enabled, so a recovery entry always exists.
- The Windows runner exposes `xaocen/windows_shell`. The native runner owns
  `Shell_NotifyIcon`, the tray menu, close-to-tray, show/hide, explicit exit,
  and taskbar window styles. No global hook is used.
- Explorer restart (`TaskbarCreated`) re-adds the tray icon; if re-add fails,
  the runner restores the taskbar entry.
- Tray actions are Show/Hide window and Exit application. With tray enabled,
  normal close hides instead of terminating; explicit tray exit terminates
  normally and preserves existing window geometry handling.
- Boss Key is an app-local left+right mouse chord in the Flutter shell. It is
  edge-triggered, resets on release/cancel/focus loss, and only hides when a
  tray recovery entry is enabled. Reader engine, Locator, PageWindow,
  AutoRead, and ReadingSession are untouched.

## Validation

- `flutter analyze`: PASS
- Full Flutter unit/contract/widget suite: 488 PASS
- Windows integration: 11 files / all scenarios PASS
- Windows Release: PASS
- Android Debug regression build: PASS
- `git diff --check`: PASS

Build artifacts:

- Windows: `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android: `build\\app\\outputs\\flutter-apk\\app-debug.apk`

Android device validation was not part of this Windows-only change.
