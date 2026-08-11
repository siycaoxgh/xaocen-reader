# M5.7a Cross-Platform Capability Foundation

## Scope

This increment adds a platform-neutral capability contract and a diagnostic
surface. It does not implement DirectComposition or change Reader layout,
position, pagination, AutoRead, ReadingSession, or Drift schema.

## Contract

`PlatformCapabilities` is split into `DisplayCapabilities`,
`RenderingCapabilities`, `DesktopWindowCapabilities`, and
`InputCapabilities`. Capability values distinguish `supported`,
`unsupported`, and `unknown`, with the required fallback reasons. Core code
only consumes this model; native API names stay inside platform adapters.

`supportsDesktopReaderTransparency` is true only when an adapter explicitly
reports support. Android and iOS are unsupported platforms for desktop
transparency. Windows currently reports the existing opaque Flutter EGL child
surface as `unsupported / rendererUnsupported`. macOS, Linux, and future
HarmonyOS adapters remain conservative stubs until native detection exists.

The default adapter reads the real Flutter display view (DPR, physical
resolution, and refresh rate). Windows runner capabilities reflect the current
borderless, tray, and taskbar implementation. Android reports real touch and
volume input capabilities while leaving runtime renderer/HDR/WCG values
unknown where the current stack does not expose a reliable probe.

## Diagnostics

Debug builds expose `Platform capabilities` from Reader Settings and route it to
`/diagnostics/platform`. The page displays platform, renderer/backend, display
measurements, HDR/WCG, window/input capabilities, desktop transparency support,
and its fallback reason. Unknown values are rendered as unknown rather than as
supported.

## Verification

- `flutter analyze`: PASS
- Flutter unit/widget tests: PASS (510 tests)
- Capability unit/widget additions: PASS (4 tests)
- Windows Release: PASS
- Android Debug: PASS
- `git diff --check`: PASS
- Integration suite: the desktop integration runner did not launch in this
  remote environment and was not used to claim a product/device pass.

Artifacts:

- `build/windows/x64/runner/Release/xaocen_reader.exe`
- `build/app/outputs/flutter-apk/app-debug.apk`

Schema remains 12.
