# M5.7s.8b-3 — Windows Tray Exit Closure

## Scope

This change is limited to the Tray menu **Exit XAOCEN Reader** lifecycle.
Tray left-click restore, the right-click menu structure, Boss Key bindings,
mouse chord handling, Reader input, Android, and Reader UI were not changed.

## Root cause

The Tray Exit command set `quit_requested_` and posted `WM_CLOSE`, but the
Flutter window subclass still had an opportunity to consume that close message
before the native `DefWindowProc` path destroyed the HWND. In that case the
process message loop could remain alive after the visible window disappeared.

## Fix

- Tray Exit marks an explicit process shutdown (`quit_on_close_ = true`).
- `FlutterWindow::MessageHandler` routes an explicit quit directly to the
  native `Win32Window::MessageHandler` instead of allowing an optional Flutter
  close handler to consume it.
- The normal Windows lifecycle remains in use:

  `Tray Exit → WM_CLOSE → DefWindowProc → WM_DESTROY → OnDestroy → Flutter
  controller disposal + tray removal → PostQuitMessage(0)`

- No `TerminateProcess`, forced process kill, or alternate shutdown path was
  introduced.
- The path is valid while the window is normal, minimized, maximized, or
  hidden, because it posts to the existing top-level HWND.

## Acceptance status

| Check | Result | Evidence |
|---|---|---|
| TRAY EXIT | AUTOMATED PASS | Native command routes to `QuitApplication()` and the standard close lifecycle. |
| PROCESS TERMINATION | AUTOMATED PASS / MANUAL REQUIRED | `PostQuitMessage(0)` is reached after `WM_DESTROY`; a local shell/process observation is still required for final visual acceptance. |
| TRAY ICON CLEANUP | AUTOMATED PASS / MANUAL REQUIRED | `RemoveTrayIcon()` is called on explicit exit and again defensively during destroy. |
| HIDDEN EXIT | AUTOMATED PASS / MANUAL REQUIRED | Posted `WM_CLOSE` targets the hidden top-level HWND; no show/restore is required. |

Manual checks A–D remain appropriate on a local Windows desktop: normal exit,
hidden-by-key exit, hidden-by-mouse-chord exit, and restart without a stale tray
icon.

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: PASS (582 tests)
- Windows Release: PASS
- `git diff --check`: PASS

Windows Release executable:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

