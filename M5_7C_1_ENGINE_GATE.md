# M5.7c.1 Windows Alpha Engine Gate

Date: 2026-08-13
Pinned engine: `69c8c61792f04cc809dfef0c910414fb9afc06cd`
Engine checkout: `C:\xaocen-engine\src`
XAOCEN repository: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## Gate summary

| Gate | Result | Evidence |
|---|---|---|
| Production stabilization automated | PASS | Existing production baseline |
| Windows/host acceptance (B1) | PASS / deferred visual items | Automated checks pass; RDP-only visual items remain deferred |
| Android physical acceptance (B2) | DEFERRED | USB device `ce8df63f` unavailable; environment-only defer |
| Vanilla Engine GN/Ninja build | PASS | Pinned `host_debug_unopt` targets built |
| Vanilla fixture build | PASS | Windows debug fixture built |
| Vanilla fixture widget test | PASS | Transparent-root fixture test passed |
| Alpha patch verify | PASS | Revision, upstream hashes, patch hash match |
| Alpha patch apply | PASS | Windows-only patch applied to pinned checkout |
| Patched Engine GN generation | PASS | Local VS 2022 toolchain environment selected |
| Patched Engine Ninja build | PASS | 1362/1362 targets completed, including `flutter_engine.dll` |
| Patched fixture build | PASS | Fixture built against local patched engine |
| Patched fixture widget test | PASS | Text, controls, focus/input fixture test passed |
| Shared D3D → ANGLE EGL → DComp smoke | PASS (automated) | Alpha switch process stayed alive; patch/source and artifact checks pass |
| Local desktop-through-Flutter visual validation | DEFERRED | RDP cannot establish reliable DWM visual evidence |

## Patched build recovery

The earlier `vpython3`/CIPD stall was diagnosed rather than treated as a
fixed-time failure. A missing `infra/goma/client/windows-amd64` CIPD package
was downloaded by the pinned depot_tools setup. GN then required the local
Visual Studio 2022 BuildTools installation; generation succeeds with the
explicit local-toolchain environment:

```text
DEPOT_TOOLS_WIN_TOOLCHAIN=0
GYP_MSVS_VERSION=2022
vs2022_install=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools
```

No full `gclient sync`, Engine checkout deletion, or XAOCEN Reader change was
needed. The Engine revision remains pinned and the applied patch remains
limited to the Windows platform surface path.

## TASK D interop evidence

The isolated fixture is:

`windows_engine_patches/flutter_engine_spike_test_app`

It renders a transparent root, adjustable 0/25/50/75/100% background, opaque
Flutter text, a button, a slider, a TextField/focus path, and an animation. It
was built and tested against `host_debug_unopt` after the alpha patch. The
fixture process was launched with the pre-engine switch
`--enable-windows-alpha-surface`; it remained responsive for the smoke window
and produced a Flutter VM service endpoint. ANGLE only emitted its normal
debug-D3D11 fallback warning and no surface/DComp failure was reported.

The patched source path is:

```text
Flutter frame
  -> OpenGL/ANGLE EGL imported D3D client buffer
  -> B8G8R8A8_UNORM premultiplied DirectComposition swapchain
  -> DComp visual/target -> DWM
```

Static source verification confirms the shared-handle import uses
`EGL_D3D_TEXTURE_2D_SHARE_HANDLE_ANGLE`, `eglSwapBuffers`, swapchain
`Present`, and DComp `Commit`. No `UpdateLayeredWindow`, whole-window alpha,
color key, CPU readback, per-frame `CopyResource`, or native text renderer is
used in the touched Windows surface implementation. Resize recreates the
surface through the same transparent-first/opaque-fallback path.

Therefore the **automated interop smoke gate is PASS** for the RGBA8 SDR,
premultiplied-alpha path. The frame contract exercised by the fixture is
background alpha controlled inside Flutter with text kept opaque; actual
desktop pixels visible behind the top-level window are not claimed as PASS in
the current RDP session.

## Stop point

M5.7c.1 is stopped after the isolated Engine/interop gate. No Reader
integration, Locator/PageWindow change, database/schema change, or
M5.7c.2 work was started. The next action requires explicit confirmation.
