# M5.7s.8b-1 — Windows Tray Left Click Restore

## Scope

Only the Windows tray left-click restore path was changed. Tray menus, exit,
Explorer restart behavior, shortcuts, mouse Boss Raw Input, Android, Reader UI,
and transparency were not changed.

## Root cause

The tray icon uses `NOTIFYICON_VERSION_4`, where the notification code is packed
into the low word of the callback `lParam`. The runner compared the entire
`lParam` directly with `WM_LBUTTONUP`/`WM_LBUTTONDBLCLK`, so the left-click
restore branch could be skipped. The callback now decodes `LOWORD(lParam)` and
accepts the legacy direct form as compatibility.

`ShowFromTray` now explicitly restores minimized windows, reapplies maximized
state when present, raises the window, activates it, foregrounds it, and focuses
the Flutter child window.

## Results

- TRAY LEFT RESTORE = AUTOMATED PASS; local desktop click validation required.
- WINDOW FOCUS = AUTOMATED PASS by native call chain; local desktop validation required.
- WINDOW STATE RESTORE = AUTOMATED PASS by restore/maximize path; local desktop validation required.

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: PASS
- Windows Release: PASS
- `git diff --check`: PASS

Manual checks remain:

1. V hide → tray left click restores.
2. LMB+RMB hide → tray left click restores.
3. Minimize → tray left click restores.
4. Maximize → hide → tray left click remains maximized.
