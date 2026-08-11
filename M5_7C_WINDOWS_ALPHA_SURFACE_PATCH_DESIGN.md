# M5.7c.0 Flutter Windows Alpha Surface Patch — Implementation Design

## 1. Baseline and hard boundary

- Flutter framework: `3.44.7`, revision `84fc5cbb22`
- Flutter engine: `69c8c61792f04cc809dfef0c910414fb9afc06cd`
- Current app HEAD: `f6a66d2408c36e60a6a61891ec1449255d682f2f`
- Drift schema: `12`

This document is a design only. No Flutter SDK, engine, Reader, or database
files are modified by M5.7c.0. The eventual patch is Windows-only and must not
touch the Dart VM, framework, Skia/Impeller common code, Android, iOS, macOS,
or Linux.

## 2. Current fixed-version call chain

At engine revision `69c8c61792`, the GPU path is:

```text
FlutterWindowsEngine::Run / compositor setup
  -> CompositorOpenGL::CreateBackingStore
  -> FlutterWindowsView::OnFrameGenerated
  -> FlutterWindowsView::surface_ (egl::WindowSurface)
  -> egl::WindowSurface::MakeCurrent
  -> CompositorOpenGL::glBlitFramebuffer
  -> egl::WindowSurface::SwapBuffers
  -> egl::Surface::SwapBuffers
  -> eglSwapBuffers(display, surface)
  -> ANGLE EGL window surface created from HWND
```

The relevant fixed-version source files are:

1. `engine/src/flutter/shell/platform/windows/flutter_windows_engine.h/.cc`
   creates `egl::Manager`, selects `CompositorOpenGL`, and installs the
   Embedder `FlutterCompositor` callbacks.
2. `engine/src/flutter/shell/platform/windows/flutter_windows_view.h/.cc`
   owns `std::unique_ptr<egl::WindowSurface> surface_`, creates it in
   `CreateRenderSurface`, destroys/recreates it in `ResizeRenderSurface`, and
   synchronizes resize completion in `OnFramePresented`.
3. `engine/src/flutter/shell/platform/windows/egl/manager.h/.cc`
   initializes ANGLE/D3D11, chooses an EGL config with 8-bit RGBA channels, and
   calls `eglCreateWindowSurface(display, config, HWND, attributes)`.
4. `engine/src/flutter/shell/platform/windows/egl/surface.h/.cc` and
   `egl/window_surface.h/.cc` provide the virtual `MakeCurrent`, `SwapBuffers`,
   `Destroy`, size, and vsync contract.
5. `engine/src/flutter/shell/platform/windows/compositor_opengl.h/.cc`
   renders Flutter layers into a GLES framebuffer and blits them to the
   surface's default framebuffer before calling `SwapBuffers`.
6. `engine/src/flutter/shell/platform/windows/BUILD.gn` owns the Windows source
   set and its native libraries.

The current ANGLE EGL surface is the blocking stage: it is an HWND-bound ANGLE
swapchain/child surface and is opaque to DWM even though the EGL config has an
alpha channel. Adding alpha to the EGL config alone is insufficient.

## 3. Minimum patch boundary

The first implementation should touch only these engine files:

```text
engine/src/flutter/shell/platform/windows/BUILD.gn
engine/src/flutter/shell/platform/windows/egl/dcomp_window_surface.h   (new)
engine/src/flutter/shell/platform/windows/egl/dcomp_window_surface.cc   (new)
engine/src/flutter/shell/platform/windows/egl/manager.h
engine/src/flutter/shell/platform/windows/egl/manager.cc
engine/src/flutter/shell/platform/windows/flutter_windows_view.h
engine/src/flutter/shell/platform/windows/flutter_windows_view.cc
engine/src/flutter/shell/platform/windows/flutter_windows_engine.h
engine/src/flutter/shell/platform/windows/flutter_windows_engine.cc
engine/src/flutter/shell/platform/windows/flutter_windows_view_unittests.cc
```

`compositor_opengl.cc` should remain unchanged in the first patch. Its existing
virtual `WindowSurface` calls are the intended integration seam. If the
shared-texture experiment proves that a direct compositor change is required,
stop and split that work into a separately reviewed patch; do not silently grow
the patch into a renderer fork.

`egl/surface.*` and `egl/window_surface.*` should remain source-compatible. The
new surface subclasses `egl::WindowSurface` (or an equivalent minimal surface
interface if subclassing is rejected by tests) so the existing compositor and
resize/first-frame contracts remain intact.

## 4. Transparent surface design

### 4.1 Runtime paths

The engine receives a Windows-only render-surface request before the first
surface is created:

```text
Opaque (default)
  Manager::CreateWindowSurface(HWND, width, height)
  -> existing ANGLE EGL window surface

Transparent (opt-in)
  Manager::CreateDcompWindowSurface(HWND, width, height)
  -> D3D11 composition swapchain
  -> EGL render target backed by the current shared D3D texture
  -> DirectComposition target/visual attached to the same HWND
```

Opaque remains byte-for-byte the existing path. Transparent is selected only
when the runner requests it and the adapter has passed all capability checks.
Any failure while creating the D3D11 device, shared texture, EGL interop
surface, DirectComposition target, or Present path immediately falls back to
opaque before exposing the window. No partially transparent window is allowed.

### 4.2 Proposed `DCompWindowSurface`

`DCompWindowSurface` owns, on the raster thread:

- `ID3D11Device`/`ID3D11DeviceContext` obtained from the existing
  `egl::Manager::GetDevice` path;
- `IDXGISwapChain1` from `IDXGIFactory2::CreateSwapChainForComposition`;
- `IDCompositionDevice`, `IDCompositionTarget`, and root visual;
- the current back-buffer shared handle and its EGL pbuffer/client-buffer
  surface;
- size and vsync state.

Creation sequence:

1. Obtain the ANGLE-selected D3D11 device; do not create a second GPU device.
2. Create a composition swapchain with:
   - `DXGI_FORMAT_B8G8R8A8_UNORM` (RGBA8/BGRA8 SDR)
   - `DXGI_ALPHA_MODE_PREMULTIPLIED`
   - two buffers, sample count 1, flip-sequential, composition scaling
3. Create the DirectComposition device/target for the existing HWND and set a
   visual whose content is the swapchain.
4. Obtain the current swapchain buffer as a shareable D3D texture. Verify the
   actual `IDXGIResource1::CreateSharedHandle`/ANGLE interop path on the pinned
   engine and GPU. If the composition swapchain buffer cannot be opened by
   `EGL_D3D_TEXTURE_ANGLE` or the share-handle extension, return failure and
   keep the opaque path; do not introduce CPU copies.
5. Use the existing `Manager::CreateSurfaceFromHandle` seam to create an EGL
   client-buffer/pbuffer surface for the shared texture. `MakeCurrent` remains
   normal EGL context binding.
6. On `SwapBuffers`, flush the EGL rendering work, present the composition
   swapchain, and commit the DirectComposition device. The method must not call
   `UpdateLayeredWindow`, read pixels back to CPU memory, or manipulate whole
   window alpha.

The key invariant is that `CompositorOpenGL::glBlitFramebuffer` still writes
the Flutter GLES framebuffer into the current GPU texture. The DComp surface
then presents that GPU texture directly. There is no CPU readback, desktop
screenshot, native text renderer, or second layout engine.

The shared-handle step is an explicit implementation gate. Composition
swapchain creation by itself is not proof that ANGLE can render into its
backbuffer.

### 4.3 Resize, DPI, and Present

The existing `FlutterWindowsView` state machine is retained:

```text
OnWindowSizeChanged
  -> resize_status = kResizeStarted
  -> Flutter frame at target size
  -> OnFrameGenerated
  -> DCompWindowSurface::Resize (ResizeBuffers + recreate EGL interop)
  -> CompositorOpenGL::Present
  -> DCompWindowSurface::SwapBuffers
  -> OnFramePresented
  -> kDone + DwmFlush
```

`ResizeBuffers` and the shared EGL surface must run on the raster thread, just
like the current EGL destroy/recreate path. A failed resize invalidates the
transparent surface and triggers the opaque fallback/recovery path. DPI and
multi-monitor notifications continue through the unchanged window binding and
metrics events.

VSync remains controlled by the existing `NeedsVsync`/`SetVSyncEnabled`
contract. The DComp implementation uses the composition swapchain Present
flags appropriate to the current vsync policy; it must not busy-loop.

## 5. Engine-facing selection and capability

Add an internal Windows render-surface mode, not a Dart/Reader setting:

```text
WindowsRenderSurfaceMode::kOpaque
WindowsRenderSurfaceMode::kTransparent
```

The default is opaque. A runner/embedding request is accepted only before the
first Flutter frame. The engine reports a structured result internally:

```text
requested transparent
created transparent
or
requested transparent
fallback opaque + reason
```

The app-level `PlatformCapabilities` remains the public product contract. It
must not contain DirectComposition types. The native runner can expose only a
boolean/result DTO through the existing capability channel; the actual
DirectComposition objects remain inside the patched engine/platform code.

Runtime switching is not part of the first patch. Switching from opaque to
transparent requires replacing the render surface and DComp visual on the
raster thread; until that lifecycle is proven, capability is evaluated at
startup and the transparent window mode is disabled when unavailable.

## 6. Accessibility, input, and plugins

The HWND and `WindowBindingHandler` are unchanged. Therefore the patch must
not alter:

- pointer, keyboard, focus, IME, and platform channel dispatch;
- accessibility bridge and semantics HWND relationship;
- plugin registrar, external textures, or platform views;
- Flutter widget/text/font rendering.

`WS_EX_NOREDIRECTIONBITMAP`/borderless style belongs to the existing Windows
runner and is not a substitute for a working engine surface. No click-through
style (`HTTRANSPARENT`) is permitted.

## 7. Capability and fallback rules

Transparent creation is supported only when all are true:

1. Windows desktop adapter reports desktop transparency capability.
2. D3D11 hardware/WARP device and required DXGI version are available.
3. Premultiplied RGBA8 composition swapchain succeeds.
4. Swapchain buffer ↔ ANGLE EGL client-buffer interop succeeds.
5. DComp target/visual commit and first Present succeed.

Fallback reasons map to the existing capability contract:

- no Windows/native support: `unsupportedPlatform`
- no D3D/DComp/ANGLE interop: `backendUnavailable`
- standard window mode: `standardWindow`
- EGL/ANGLE or shared surface mismatch: `rendererUnsupported`
- display/compositor rejection: `displayUnsupported`
- unclassified HRESULT: `unknown`

The fallback must be observable in diagnostics and must never claim desktop
transparency support after a failed first frame.

## 8. Tests and stop conditions

### Engine/native tests

- Opaque path remains the default and passes existing Windows engine tests.
- Transparent request with a mocked/unavailable DComp device falls back before
  the first frame.
- RGBA8 premultiplied swapchain and first Present succeed on a real D3D11
  device.
- `ResizeBuffers` recreates the EGL interop surface without stale handles.
- Present/vsync and first-frame callback fire exactly once per frame.
- No CPU readback API is linked or called.

### Local visual test (required before product merge)

On a local DWM/GPU session, capture a real desktop frame while the prototype is
at `background=0%, text/foreground=100%`, then verify a desktop pixel outside
the opaque foreground and an opaque foreground pixel. Repeat for borderless,
resize, maximize/restore, DPI, multi-monitor, screenshot, tray hide/restore,
and Boss Key hide/restore. RDP screenshots are evidence only of the RDP path,
not of local DWM transparency.

### Immediate stop conditions

Stop M5.7c.1 without merging if any of these occur:

- shared D3D texture ↔ ANGLE EGL interop is unavailable on the pinned engine;
- implementing the path requires CPU readback, `UpdateLayeredWindow`, color key,
  or native text/layout;
- accessibility/input/IME or plugin lifecycle changes are required;
- a change to Skia/Impeller common code or a broad engine fork is required;
- opaque mode, resize, or normal Android builds regress.

## 9. Patch maintenance and build strategy

Keep the patch outside the application source tree in an isolated directory:

```text
windows_engine_patches/
  flutter_engine_revision.txt
  0001-windows-dcomp-alpha-surface.patch
  apply.ps1
  verify.ps1
  manifest.json
```

`manifest.json` records:

- framework and engine revisions;
- exact touched file list;
- SHA-256 of each upstream file before patching;
- patch SHA-256 and toolchain requirements;
- whether the build is `host_debug_unopt` or `host_release`.

`apply.ps1` must:

1. check `git rev-parse HEAD` equals the pinned engine revision;
2. verify every upstream file hash;
3. run `git apply --check` and then apply the patch;
4. write the patched revision/hash manifest.

`verify.ps1` must fail on an engine revision mismatch, upstream hash drift,
unexpected touched files, missing DComp libraries, or a patch that no longer
applies. Flutter SDK upgrades require a deliberate manifest refresh and a new
review; they must never silently reuse this patch.

Build the patched engine in a separate checkout at the pinned revision using
the normal Windows engine GN/Ninja flow, producing `host_debug_unopt` and
`host_release`. Use Flutter's supported local-engine flags for Windows:

```text
flutter build windows --debug --local-engine=host_debug_unopt \
  --local-engine-host=host_debug_unopt \
  --local-engine-src-path=<patched-flutter-engine-root>

flutter build windows --release --local-engine=host_release \
  --local-engine-host=host_release \
  --local-engine-src-path=<patched-flutter-engine-root>
```

Normal `flutter build apk`, Android tests, and unpatched Windows builds keep
using the installed SDK artifacts. The patched engine is opt-in and must not
be copied into the global Flutter cache.

## 10. Recommendation for M5.7c.1

Proceed only with a **small implementation spike**, not production Reader
integration. The recommended order is:

1. Prove composition-swapchain-backbuffer shared-handle ↔ ANGLE EGL pbuffer
   interop on the pinned engine/GPU.
2. Add `DCompWindowSurface` and opaque fallback behind an engine-only flag.
3. Run engine/native tests and local visual DWM validation.
4. Only after all stop conditions pass, expose the capability to the app and
   consider Reader integration in a later milestone.

At this point the architecture is viable in principle and the M5.7b native
spike proves DirectComposition resource creation, but the Flutter-frame-to-
composition-swapchain interop and local desktop-through pixel result are not
yet proven. Therefore M5.7c.1 is **conditionally recommended as an isolated
engine spike**, not as a production Reader patch.
