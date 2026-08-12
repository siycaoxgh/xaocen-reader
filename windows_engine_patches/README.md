# M5.7c.1 isolated Windows alpha-surface engine spike

This directory is an opt-in patch for Flutter engine revision
`69c8c61792f04cc809dfef0c910414fb9afc06cd` (Flutter 3.44.7). It is not part
of the XAOCEN Reader runtime and must never be copied into the global Flutter
cache.

The patch keeps the normal opaque ANGLE `eglCreateWindowSurface` path. A test
runner can opt into the transparent path with the pre-engine switch
`--enable-windows-alpha-surface`; failure to create DirectComposition or the
ANGLE D3D shared-handle client buffer disables the opt-in before the first
frame and falls back to opaque.

The transparent surface uses a BGRA8 premultiplied composition swapchain and
imports its backbuffer with `EGL_D3D_TEXTURE_2D_SHARE_HANDLE_ANGLE`. It does
not use CPU readback, `UpdateLayeredWindow`, color keys, a desktop screenshot,
or native text rendering.

## Apply and verify

```powershell
./windows_engine_patches/apply.ps1 -EngineRoot C:/path/to/flutter-checkout
./windows_engine_patches/verify.ps1 -EngineRoot C:/path/to/flutter-checkout
```

The scripts refuse an engine revision, upstream blob hash, patch hash, or
dirty-worktree mismatch. Re-run them against a fresh detached checkout when
upgrading Flutter; do not apply this patch to an unknown engine.

## Isolated build

The engine checkout requires the normal Flutter engine depot_tools/dependency
sync and Visual Studio Windows toolchain. Build `host_debug_unopt` or
`host_release` in that checkout, then point only the test app at the output:

```powershell
flutter build windows --debug --local-engine=host_debug_unopt `
  --local-engine-host=host_debug_unopt `
  --local-engine-src-path=C:/path/to/patched/flutter-checkout
```

The XAOCEN app and Android builds continue to use ordinary SDK artifacts.
`flutter_engine_spike_test_app` is a minimal fixture with a transparent root,
adjustable background alpha, opaque text, a button, TextField, and animation.
