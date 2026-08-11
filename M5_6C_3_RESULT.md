# M5.6c.3 Result — Windows Transparency Native Spike

Status: **blocked / stopped after spike**. No production transparency code was
added.

## Spike findings

1. The current Flutter Windows embedder creates an opaque Flutter child HWND.
   The local `FlutterViewController` / `flutter_windows.h` API exposes the view
   handle, but no transparent-surface or alpha-composition configuration.
2. A reversible native probe added `WS_EX_LAYERED` and
   `SetLayeredWindowAttributes(alpha=128)` to the top-level Release window.
   The call succeeded, but the Flutter surface did not become a selectively
   transparent background; the captured before/after pixels were identical.
3. Applying the same probe to the first Flutter child HWND also did not provide
   a reliable separate background channel. Even if a child compositor path were
   forced to accept alpha, it would apply to the entire Flutter surface, so
   Reader background and text would fade together.

## Contract decision

The requested combination — background opacity 0–100%, independent text alpha,
opaque text at background 0%, with resize/maximize/borderless/tray/Boss Key/DPI
and GPU safety — cannot be implemented safely with the current runner surface.
`WS_EX_LAYERED`, color-key transparency, or a whole-window alpha hack would
violate the separate A/B opacity contract and risk Flutter rendering, images,
Palette, and native window behavior. Mouse-through is not enabled.

Formal implementation is therefore deferred pending a dedicated transparent
Flutter surface/native compositor design and a rendering spike that can produce
independent background and text layers. No ReaderLocator, pagination, schema,
ReaderPreferences, or shell behavior changed.

## Validation

- `flutter analyze`: PASS
- Full Flutter unit/contract/widget: 496 PASS
- Windows Release build: PASS —
  `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- `git diff --check`: PASS
- Drift schema: 11, unchanged
