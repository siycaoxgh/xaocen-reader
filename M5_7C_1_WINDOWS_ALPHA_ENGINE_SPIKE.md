# M5.7c.1 Flutter Windows Alpha Surface - Isolated Engine Spike

Status: **STOPPED AS AN ISOLATED SPIKE**

The patch infrastructure and Windows-only research implementation are kept for
the next machine that has a complete Flutter engine checkout. The patch was
not connected to XAOCEN Reader and no Reader, database, Locator, PageWindow,
AutoRead, Font, or schema files were changed.

## Pinned inputs

- Flutter framework: 3.44.7, `84fc5cbb223`
- Flutter engine: `69c8c61792f04cc809dfef0c910414fb9afc06cd`
- Engine worktree: `flutter-engine-spike` (detached at the pinned revision)
- Surface gate: `--enable-windows-alpha-surface`
- First format: `DXGI_FORMAT_B8G8R8A8_UNORM`
- Alpha mode: `DXGI_ALPHA_MODE_PREMULTIPLIED`

## Patch implementation

The patch is limited to the Windows platform seam:

```text
engine/src/flutter/shell/platform/windows/BUILD.gn
engine/src/flutter/shell/platform/windows/egl/dcomp_window_surface.cc
engine/src/flutter/shell/platform/windows/egl/dcomp_window_surface.h
engine/src/flutter/shell/platform/windows/egl/manager.cc
engine/src/flutter/shell/platform/windows/egl/manager.h
engine/src/flutter/shell/platform/windows/flutter_windows_engine.cc
engine/src/flutter/shell/platform/windows/flutter_windows_engine.h
engine/src/flutter/shell/platform/windows/flutter_windows_view.cc
```

`CompositorOpenGL`, Skia/Impeller common code, the Dart VM, framework, and all
non-Windows platforms are untouched. `DCompWindowSurface` keeps the existing
`egl::WindowSurface` virtual contract. It creates a composition swapchain,
exports the current backbuffer through a DXGI shared handle, imports that
handle with `EGL_D3D_TEXTURE_2D_SHARE_HANDLE_ANGLE`, and presents with
DirectComposition. There is no CPU readback, `UpdateLayeredWindow`, color key,
desktop screenshot, native text renderer, or second layout.

Transparent creation is opt-in and happens before the first frame. If the
ANGLE extension, D3D device, swapchain, shared handle, EGL client buffer, or
DirectComposition target fails, the view disables transparent mode and creates
the normal opaque ANGLE HWND surface. The normal opaque path remains the
default.

## Verification performed

| Check | Result |
|---|---|
| Apply patch to clean exact engine revision | PASS |
| Verify revision, upstream blobs, patch SHA-256 | PASS |
| Refuse wrong engine revision | PASS |
| Refuse dirty engine worktree | PASS |
| Static forbidden-API check | PASS (no CPU/readback/click-through path) |
| Minimal Flutter fixture `flutter analyze` | PASS |
| Minimal Flutter fixture widget test | PASS |
| Existing isolated DComp native RGBA8/FP16 self-test | PASS |
| Patched Flutter engine build | **BLOCKED** |
| Flutter frame into ANGLE shared client buffer and DComp | **NOT VERIFIED** |
| Local desktop-through visual validation | DEFERRED |

The existing M5.7b native self-test on this machine reported hardware D3D11
(Intel UHD, feature level 0xb000), RGBA8 premultiplied alpha at 0/25/50/75/100%,
resize resource recreation, maximize/restore, and FP16 swapchain Present. That
is useful DComp resource evidence only; it is not proof of Flutter-frame
interop and it intentionally is not used as the c.1 gate.

## Build blocker

The isolated Flutter source worktree has the pinned engine platform sources but
does not have the engine dependency sync (`engine/src/third_party`, ANGLE
headers/dependencies, generated `buildtools/gn`, and Ninja output). The
supported command:

```text
flutter build windows --debug --local-engine=host_debug_unopt \
  --local-engine-host=host_debug_unopt \
  --local-engine-src-path=<patched-engine-checkout>
```

stops before compilation with Flutter's error that no compiled engine `out`
directory exists. Consequently this environment cannot establish the only
required c.1 proof: a real Flutter GPU frame entering the DComp composition
swapchain without a copy.

## Contract answers

1. Shared-texture interop: **not verified**; patch contains the direct
   `IDXGIResource1::CreateSharedHandle`/legacy-handle and ANGLE client-buffer
   gate, but no engine binary was produced.
2. Flutter frame in DComp: **not verified**.
3. Flutter alpha retention: native DComp resource contract is proven by the
   prior spike; Flutter alpha is **not verified**.
4. Background 0% + foreground 100%: **not proven for Flutter**.
5. Opaque path: source-level/default/fallback preservation **PASS**.
6. Resize/recreate: prior native DComp resource recreation **PASS**; patched
   Flutter surface lifecycle **not verified**.
7. Pointer, keyboard, focus, TextField/IME, accessibility, and plugins: the
   existing HWND/view/compositor paths are unchanged; runtime preservation is
   **not verified without an engine build**.
8. Actual patch scope: exactly the eight Windows files listed above.
9. Scope expansion: **none** beyond the M5.7c.0 Windows seam design.
10. GPU copy: the patch has no CPU readback or per-frame `CopyResource`; the
    intended path is shared GPU texture import. This is source-verified, not
    runtime-measured.
11. Performance: **not measured** for the patched Flutter path.
12. Apply/verify: `windows_engine_patches/apply.ps1` checks the exact revision,
    upstream blob IDs, patch SHA-256, and clean worktree; `verify.ps1` checks
    touched files, native libraries, and forbidden APIs.
13. M5.7c.2 Reader Integration: **do not enter yet**. First run this spike on
    a fully synced engine checkout and a local DWM/GPU session, then review
    ANGLE import, first-frame alpha, resize/device-loss, input/IME/a11y, and
    frame pacing evidence.

## Maintained artifacts

- `windows_engine_patches/0001-windows-dcomp-alpha-surface.patch`
- `windows_engine_patches/manifest.json`
- `windows_engine_patches/apply.ps1`
- `windows_engine_patches/verify.ps1`
- `windows_engine_patches/flutter_engine_spike_test_app/`

The test app contains a transparent root, five background-alpha values, opaque
text, a button, TextField, focus/input probe, and animation. It is not a
Reader page. No Android or XAOCEN production build depends on this patch.
