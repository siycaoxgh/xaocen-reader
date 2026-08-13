# M5.7s.8c-1 — Windows Desktop Pixel Sampler

## Scope

This task adds only the Windows platform-side desktop pixel sampler. It does
not add eyedropper UI, color settings, Tray behavior, input bindings,
transparency, Android code, or Reader UI.

## Architecture

- Dart boundary: `DesktopColorSampler.sampleDesktopPixel(x, y)` and the
  development helper `sampleAtCursor()` return a typed `ColorSample` containing
  physical coordinates, RGB channels, and an uppercase `#RRGGBB` value.
- Native boundary: `windows/runner/desktop_color_sampler.cpp` uses the Windows
  virtual desktop device context (`GetDC(nullptr)`) and `GetPixel` for one
  requested physical coordinate.
- The virtual desktop bounds come from `SM_XVIRTUALSCREEN`,
  `SM_YVIRTUALSCREEN`, `SM_CXVIRTUALSCREEN`, and `SM_CYVIRTUALSCREEN`, so
  negative monitor coordinates and multiple displays are supported.
- No full-screen capture, Flutter screenshot, Widget capture, system color
  mutation, or Reader-domain dependency is used.
- The existing Per-Monitor-V2 manifest means callers must pass physical screen
  coordinates. Flutter/UI code can perform its own logical-to-physical mapping
  at the platform boundary; the native sampler never guesses a DPI or assumes
  the primary monitor.

## Results

| Check | Result | Evidence |
|---|---|---|
| DESKTOP PIXEL SAMPLING | AUTOMATED PASS | Native C++ sampler compiled and is exposed through a dedicated method channel. |
| CROSS-APP SAMPLING | AUTOMATED PASS / MANUAL REQUIRED | `GetDC(nullptr)` targets the composed virtual desktop, including other windows; local color-block validation remains required. |
| DPI COORDINATE | AUTOMATED PASS / MANUAL REQUIRED | Per-monitor-V2 runner and virtual-screen physical bounds are used; mixed-DPI monitor validation remains local. |

## Development verification entry

`DesktopColorSampler.sampleAtCursor()` requests the current physical cursor
coordinate and returns `x/y`, `r/g/b`, and `hex`. The explicit-coordinate API is
used for test color blocks and multi-monitor coordinates. This is an API-level
diagnostic entry only; no user-facing eyedropper UI was added.

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: PASS (583 tests, including the new sampler contract)
- Windows Release: PASS
- `git diff --check`: PASS

Windows Release executable:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

Local manual checks still required for actual white/black/pure-color blocks,
other-application sampling, and mixed-DPI/multi-monitor alignment.

