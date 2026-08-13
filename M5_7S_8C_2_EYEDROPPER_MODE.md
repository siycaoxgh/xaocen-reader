# M5.7s.8c-2 — Windows Eyedropper Interaction Mode

## Scope

This task adds a Windows-only, temporary desktop picking controller on top of
the existing `DesktopColorSampler`. It does not add Reader color UI, Palette,
Tray, shortcuts, Boss Key, transparency, Android, or Reader layout changes.

## Interaction contract

- States are `idle → picking → confirmed/cancelled → idle`.
- `startPicking` is single-entry; a second start while picking is rejected.
- While picking, a 33 ms timer samples the current physical cursor position
  through the existing virtual-desktop `GetDC(nullptr) + GetPixel` sampler and
  emits `sampleUpdated` with x/y/RGB/HEX.
- Left mouse down confirms the current sample.
- Right mouse down or Escape cancels without a confirmed sample.
- The native low-level mouse/keyboard hooks and timer are installed only while
  picking and are removed before the confirmation/cancellation callback.
- Native hooks always call `CallNextHookEx`; they do not block or alter other
  applications' input or drawing.
- Window destruction also stops the controller defensively.

## Results

| Check | Result | Evidence |
|---|---|---|
| EYEDROPPER ENTER | AUTOMATED PASS | Dedicated method channel and single-entry controller state machine. |
| LIVE SAMPLE | AUTOMATED PASS | Timer samples cursor through the existing desktop sampler and emits updates. |
| LEFT CONFIRM | AUTOMATED PASS / MANUAL REQUIRED | Native LMB path confirms once; local desktop click validation remains required. |
| ESC CANCEL | AUTOMATED PASS / MANUAL REQUIRED | Native keyboard hook cancels and unhooks; local key validation remains required. |
| RIGHT CANCEL | AUTOMATED PASS / MANUAL REQUIRED | Native RMB path cancels and unhooks; local mouse validation remains required. |
| CROSS-APP PICKING | AUTOMATED PASS / MANUAL REQUIRED | `WH_MOUSE_LL` observes desktop-wide pointer movement while forwarding events; local other-window validation remains required. |
| LISTENER CLEANUP | AUTOMATED PASS | `Stop()` kills timer, unhooks both hooks, clears callbacks, and is idempotent. |

The interaction layer deliberately does not expose a magnifier or user-facing
color setting; those remain later work.

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: PASS (585 tests, including the sampler/controller contracts)
- Windows Release: PASS
- `git diff --check`: PASS

Windows Release executable:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

Local manual checks remain required for desktop/other-app movement, left-click
confirmation, Escape/right-click cancellation, and ten repeated enter/exit
cycles.

