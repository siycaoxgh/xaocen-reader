# M5.7s.8b-2 — Windows Tray Right Click Menu

## Scope

Only tray right-click notification decoding and popup-menu foreground handling
were changed. Left-click restore, Tray exit, Explorer recovery, shortcuts,
mouse Boss, Reader, Android, and transparency remain unchanged.

## Root cause

The icon is registered with `NOTIFYICON_VERSION_4`, which packs the callback
notification code in `LOWORD(lParam)`. The right-click branch still compared the
whole value, so `WM_RBUTTONUP` could be missed. It now accepts the decoded event
code (and the legacy direct form).

The popup now uses the native tray pattern: obtain the cursor position, make the
window the foreground owner, call `TrackPopupMenu` with `TPM_RIGHTBUTTON`, then
destroy the menu and post `WM_NULL` to complete the menu-dismiss handshake.
Existing command IDs remain unchanged: show, hide, separator, exit.

## Results

- TRAY RIGHT MENU = AUTOMATED PASS; local tray-click validation required.
- SHOW WINDOW = AUTOMATED PASS through existing `ShowFromTray`.
- HIDE WINDOW = AUTOMATED PASS through existing `HideToTray`.
- TRAY LEFT REGRESSION = unchanged code path; automated build/tests pass.

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: PASS, 582 tests
- Windows Release: PASS
- `git diff --check`: PASS

Manual checks remain:

1. Right-click tray opens the menu at the cursor.
2. Hide window works.
3. Right-click again and Show window restores/focuses it.
4. Repeat five cycles and verify tray left click still restores.
