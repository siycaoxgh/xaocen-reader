# M5.6c.2 Result — Windows Borderless Reader

Status: complete.

## Implementation

- Added the typed Windows shell preference `showWindowBorder`.
  It is stored in the existing `app_settings` repository; Drift schema remains
  11. Existing shell profiles migrate deterministically to a bordered window.
- Added the Windows-only setting “显示窗口边框”. Turning it off applies the
  native borderless presentation immediately; turning it on restores the normal
  frame. Android does not expose or apply this setting.
- The runner uses a popup style that retains native resize, minimize, maximize,
  and system-menu behavior. The borderless hit-test supplies all four edges and
  corners plus a top drag band; native double-click caption behavior continues
  to maximize/restore.
- Window placement persistence stays in the native runner registry contract.
  Normal bounds are restored before maximization, minimized state is not saved,
  and existing monitor/DPI clamping remains active. Tray/taskbar recovery and
  app-local Boss Key are unchanged; a hidden window still requires a valid
  recovery entry.

## Validation

- `flutter analyze`: PASS
- Full Flutter unit/contract/widget suite: 496 PASS
- Windows integration: 11 files / 14 scenarios PASS (serial execution)
- Windows Release: PASS — `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android Debug regression build: PASS — `build\\app\\outputs\\flutter-apk\\app-debug.apk`
- `git diff --check`: PASS
- Drift schema: 11, unchanged
- Android physical-device test: NOT-RUN (Windows-only change)

No Reader engine, ReaderLocator, PageWindow, AutoRead, ReadingSession, or
Android behavior was changed.
