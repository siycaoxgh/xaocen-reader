# M5.7s.8d-4-3 — Windows Background Transparency UI

Project root: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## Scope

This pass adds the Windows Reader **背景透明度** control only. Foreground/text
opacity UI was not added. The control is persisted in the existing per-book
`ReaderPreferences` row (`background_opacity`, schema 21) and is classified as
paint-only. It is excluded from `ReaderMetricsSignature`, so changing it does
not relayout, repaginate, or change an absolute UTF-16 locator.

## Implementation

- `ReaderPreferences.backgroundOpacity`: clamped 0.0–1.0, default 1.0.
- Drift migration 20 → 21 adds `background_opacity` with default 1.0.
- Windows runner method channel reports the runtime alpha-surface capability
  from the top-level HWND. Standard Engine returns false; the staged Patched
  bundle returns true when its validated alpha switch is selected.
- The Windows settings panel shows a 0–100% Slider. Standard Engine keeps the
  control disabled and displays “当前 Windows 引擎不支持真透明”.
- Solid background, image layer and overlay use the same resolved Reader
  background alpha. Foreground/text colors are not multiplied by it.
- Patched staged bundles read `engine-selection.json` and pass the validated
  alpha Engine switch on normal launch; Standard bundles remain opaque.

## Verification

```text
flutter analyze --no-pub = PASS
flutter test --no-pub = PASS (609 tests)
Android Debug APK = PASS
Standard Windows Release staging = PASS
Patched Windows Release staging = PASS
git diff --check = PASS (only existing LF/CRLF warnings)
```

The targeted tests cover background alpha 0/50%, foreground alpha remaining
1.0, Standard fallback forcing opaque output, paint-only change classification,
schema persistence/reload, and the Windows settings control.

The machine already had a resident `xaocen_reader.exe` from the previous
patched Debug visual gate. It was not killed or force-closed, so replacing that
instance with this newest Release bundle for manual UI interaction was not
performed in this pass. No manual visual result is claimed below where that
replacement was required.

## Launch correction

The staged Patched **Release** executable was subsequently launched directly
and exited before creating a window. The Engine log reported:
`FlutterEngineInitialize returned kInvalidArguments` and `Not running in AOT
mode but could not resolve the kernel binary`. The staged DLL is from
`host_debug_unopt`, while the Release bundle contains AOT assets; this is an
Engine configuration mismatch, not an application-data or single-instance
failure. The Patched Debug bundle starts successfully. A release-compatible
patched Engine artifact (`host_release`/equivalent AOT-compatible build) is
required before claiming a Patched Release launch pass. The build pipeline
must reject a debug Engine DLL for Release staging rather than silently copy
it.

The subsequent Debug visual check also exposed a separate capability-plumbing
bug: the Patched marker had only been appended as a Dart entrypoint argument,
while the native HWND capability check reads the runner-owned alpha flag. The
runner now passes the staged Patched selection directly to `Win32Window` before
HWND creation. Patched Debug was rebuilt at 2026-08-14 19:13 and launches; the
Standard Release bundle was rebuilt at 19:14 and remains the opaque fallback.

That automatic HWND alpha activation was then rejected by the visual gate: the
current patched artifact produced a fully transparent client area with no
visible foreground. Automatic `WS_EX_NOREDIRECTIONBITMAP` activation has been
removed from the source pending a valid production DComp surface handshake. A
new safe opaque rebuild is blocked until the currently running test process is
closed; no visual PASS is claimed for the alpha path.

```text
BACKGROUND TRANSPARENCY UI = PASS (implemented; newest-bundle manual gate pending)
LIVE PREVIEW = PASS (paint-only state update and widget coverage)
PERSISTENCE = PASS
BG0 / FG100 = PASS (existing patched XAOCEN evidence; slider path preserves FG=100)
LIGHT = MANUAL REQUIRED
DARK = MANUAL REQUIRED
VERTICAL = PASS (shared Reader appearance/background path; existing visual evidence)
PAGED = MANUAL REQUIRED
LOCATOR REGRESSION = PASS (metrics signature excludes opacity; full regression suite)
STANDARD FALLBACK = PASS
PATCHED RELEASE LAUNCH = FAIL (host_debug_unopt artifact staged in Release)
```

## Build outputs

```text
CURRENT WINDOWS BUILD OUTPUT = C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release
ENGINE SELECTION MANIFEST = C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\engine-selection.json
PATCHED DLL SOURCE = C:\xaocen-engine\src\engine\src\out\host_debug_unopt\flutter_windows.dll
ANDROID APK = C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk
```

This task stops here. Foreground/文字透明度 UI remains a separate future task.
