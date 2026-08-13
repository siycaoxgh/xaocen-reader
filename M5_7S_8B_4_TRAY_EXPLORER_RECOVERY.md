# M5.7s.8b-4 — Windows Tray Explorer Restart Recovery

## Scope

This change is limited to re-registering the existing XAOCEN Tray icon after
the Windows shell broadcasts `TaskbarCreated` (for example, after
`Explorer.exe` restarts). Tray left-click restore, the right-click menu and
exit commands, Boss Keys, shortcut capture, Reader navigation, and window state
were not changed.

## Implementation

- The existing registered `TaskbarCreated` message remains handled by the
  existing `Win32Window` Tray owner.
- On every notification, the current registration is removed through the
  existing `RemoveTrayIcon()` and then re-added through the existing
  `AddTrayIcon()` using the same callback message, icon resource, and owner
  HWND.
- Re-registration is idempotent. Repeated broadcasts cannot create a second
  logical owner or leave the old registration flagged as active.
- If re-registration fails, the existing shell safety invariant restores the
  taskbar entry rather than leaving a hidden, unreachable window.

## Acceptance status

| Check | Result | Evidence |
|---|---|---|
| TASKBAR_CREATED HANDLING | AUTOMATED PASS | Registered `TaskbarCreated` message is handled in `Win32Window::MessageHandler`. |
| TRAY RE-REGISTER | AUTOMATED PASS | `RemoveTrayIcon() → AddTrayIcon()` reuses the current owner/callback/resource. |
| DUPLICATE TRAY ICON | AUTOMATED PASS | Existing registration is removed before every add; duplicate broadcasts are idempotent. |
| TRAY CALLBACK AFTER RESTART | MANUAL REQUIRED | Requires local Explorer restart to verify shell delivery and icon interaction. |

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: PASS (582 tests)
- Windows Release: PASS
- `git diff --check`: PASS

Windows Release executable:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

Manual acceptance remains required: restart Explorer two or three times,
confirm one icon, then exercise Tray left-click, right-click menu, and Tray
Exit.

