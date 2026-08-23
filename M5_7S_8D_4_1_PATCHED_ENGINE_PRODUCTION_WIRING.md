# M5.7s.8d-4-1 — Patched Engine Production Wiring

Date: 2026-08-14
XAOCEN project root: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## Scope

This phase adds one build-time engine selector. It does not enable Reader
transparency, add opacity settings, or change Reader/Theme/geometry code.
The Flutter SDK and its global cache are not modified.

The single selector is:

```powershell
.\tool\build_windows_engine.ps1 -Engine Standard
.\tool\build_windows_engine.ps1 -Engine Patched
```

`Standard` is the default when `-Engine` is omitted. The script builds the
normal Flutter Windows bundle, then stages the selected engine DLL into a
mode-specific artifact directory and writes `engine-selection.json` beside it.
There is no competing environment-variable, CMake, or manual-copy selector.

## Gate reconciliation

`M5_7S_8D_3R_PATCHED_ENGINE_BUILD_DCOMP.md` records the earlier
composition-swapchain-backbuffer shared-handle attempt as failed. The later
`M5_7S_8D_3R_2_DCOMP_INTEROP_PATH.md` is the corrected interop gate and records
the validated path:

`app-owned D3D11 texture → ANGLE D3D texture client buffer → one diagnostic GPU copy → DComp composition swapchain`

The corrected gate supplies the required `D3D TEXTURE → DCOMP = PASS` and
`BG 0 / FG 100 = PASS`. No failed legacy backbuffer-export path is wired into
the production build selector.

## Revision and artifact guards

- Flutter stable: 3.44.7
- Flutter engine revision: `69c8c61792f04cc809dfef0c910414fb9afc06cd`
- Patched checkout HEAD: `69c8c61792f04cc809dfef0c910414fb9afc06cd`
- Patched artifact SHA-256: `16CD096ABB4AB1810003388796AC42463F2ECA12738803BB904C286E0D7C9425`
- Patched object is present in the `flutter_windows.dll` Ninja link graph:
  `obj/flutter/shell/platform/windows/egl/flutter_windows_source.dcomp_window_surface.obj`

The manifest used by the selector is:

`windows_engine_patches\patched_engine_artifact.json`

Patched selection fails before building if the Flutter revision, patched Git
revision, artifact hash, GN output, patch sources, patch object, or Ninja link
graph does not match the manifest.

## Build outputs

| Mode | Result | Staged output |
|---|---|---|
| Standard | PASS | `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\standard\Release` |
| Patched | PASS | `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\patched\Release` |

Standard executable:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\standard\Release\xaocen_reader.exe`

Patched executable:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\patched\Release\xaocen_reader.exe`

Patched DLL source:

`C:\xaocen-engine\src\engine\src\out\host_debug_unopt\flutter_windows.dll`

Patched DLL staged path:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\patched\Release\flutter_windows.dll`

The ordinary Flutter build output remains at:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

## Verification

- `flutter analyze --no-pub` — PASS
- `flutter test --no-pub` — PASS (604 tests)
- Standard Windows Release build — PASS
- Patched Windows Release staging — PASS
- `git diff --check` — PASS (only existing LF/CRLF warnings)
- Standard fallback bundle present with a distinct SDK DLL hash — PASS

Launch smoke was attempted for both staged bundles. A XAOCEN instance was
already resident under the fixed single-instance mutex
`XAOCEN.Reader.StandardInstance`; both launchers returned cleanly and invoked
the existing-instance activation path. An isolated fresh-process launch of
the patched DLL could not be measured without closing the resident user
instance, so the status is explicitly deferred rather than represented as a
patched runtime PASS.

## Final status

```text
STANDARD ENGINE BUILD = PASS
PATCHED ENGINE BUILD = PASS
ENGINE REVISION GUARD = PASS
PATCHED ARTIFACT GUARD = PASS
BUILD SELECTION METHOD = PASS
STANDARD LAUNCH = DEFERRED — resident single-instance process
PATCHED LAUNCH = DEFERRED — resident single-instance process
STANDARD FALLBACK = PASS
```

This phase stops here. It does not enter M5.7s.8d-4-2 and does not enable
Reader true transparency.
