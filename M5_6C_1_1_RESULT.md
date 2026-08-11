# M5.6c.1.1 Result — Windows Boss Key customization

Status: complete. Drift schema remains 10.

## Contract

- `WindowsShellPreferences` now stores an app-local `bossKeyEnabled` flag and
  a canonical `WindowsBossKeyGesture` in `app_settings`.
- The default gesture is the left + right mouse-button chord.
- Keyboard single keys and `Ctrl` / `Alt` / `Shift` combinations use a stable
  Windows-owned key registry. Windows/System keys are not accepted.
- Mouse left + right remains the only supported mouse chord. No global hook is
  installed; the gesture is recognized only while the app window is active.
- Version-1 shell JSON migrates taskbar/tray settings and supplies the default
  Boss Key gesture. Invalid gestures fall back to that safe default without
  dropping shell visibility settings.

## Capture and safety

- Capture is focused and explicit: waiting → candidate → confirm/cancel.
  Candidate input is not persisted until confirmation; retry and cancel leave
  the current profile unchanged.
- A keyboard gesture that is already bound to a Windows Reader command is
  rejected with a conflict message. Boss Key remains a shell action and is not
  added to `ReaderCommand`.
- Disabling Boss Key is persisted as an explicit boolean. Reset restores the
  default mouse chord and enabled state for Windows only.
- Hiding still requires an active tray recovery route. The repository continues
  to reject disabling both taskbar and tray entries, and native fallback keeps a
  taskbar entry if tray creation fails.

## Validation

- `flutter analyze`: PASS
- Full Flutter unit/contract/widget suite: 492 PASS
- Windows integration: 11 files / 14 scenarios PASS
- Windows Release: PASS
- Android Debug regression build: PASS
- `git diff --check`: PASS
- Drift schema: 10, unchanged

Build artifacts:

- Windows: `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android: `build\\app\\outputs\\flutter-apk\\app-debug.apk`

Interactive tray/Boss Key desktop validation remains a manual follow-up; no
Android device validation was required for this Windows-only change.
