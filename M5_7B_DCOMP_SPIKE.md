# M5.7b DirectComposition Alpha Surface Spike

## Scope

The prototype is isolated under `tools/windows_dcomp_spike/`. It does not link
Flutter, modify the Flutter engine, or use Reader data/UI. It does not use
whole-window alpha, color-key transparency, desktop screenshots, or mouse
click-through.

## Prototype pipeline

```text
borderless HWND (WS_EX_NOREDIRECTIONBITMAP)
  -> D3D11 device (hardware, WARP fallback)
  -> IDXGISwapChain1::CreateSwapChainForComposition
  -> DXGI_ALPHA_MODE_PREMULTIPLIED
  -> IDCompositionTarget/Visual
  -> desktop compositor
```

The SDR path uses `DXGI_FORMAT_B8G8R8A8_UNORM` (the BGRA8 form of an RGBA8
surface). The CPU-generated test image is premultiplied before it is copied to
the swapchain. The background is rendered at 0/25/50/75/100% alpha while the
center foreground test block is always alpha 1.0.

## Results

The source and build recipe are committed as an isolated spike. A local visual
desktop-through test requires a real interactive DWM/GPU session. This remote
session can compile and run the resource self-test, but cannot make a reliable
claim about desktop pixels, screenshot composition, or visual text opacity.

The remote Windows build ran the non-visual self-test successfully:

```text
monitors=1
D3D11 device: hardware, feature level 0xb000
Adapter: Intel(R) UHD Graphics
RGBA8_CREATE=PASS
RGBA8_ALPHA_CONTRACT=PASS (premultiplied background, opaque foreground)
DPI=120
RESIZE_RESOURCE_RECREATE=PASS
MAXIMIZE_RESTORE=PASS
FP16_CREATE=PASS
FP16_PRESENT=PASS
SELF_TEST=PASS
```

This proves resource creation, premultiplied alpha submission, presentation,
resize-triggered resource recreation, current DPI query, maximize/restore
calls, and the FP16 swapchain path. It does **not** by itself prove that the
desktop is visible through the top-level window. That requires a local
interactive DWM/GPU visual check:

- RGBA8 alpha surface: resource-level PASS; local visual validation deferred
- background 0% + foreground 100%: local visual validation deferred
- FP16/scRGB creation/present: resource-level PASS; HDR/scRGB visual validation deferred
- continuous resize/DPI/multi-monitor: resize/DPI smoke PASS; local multi-monitor validation deferred
- tray/Boss Key: not part of the isolated prototype; existing shell integration remains untouched

A remote desktop screenshot was also attempted. It did not provide reliable
evidence of the DComp surface (the RDP/compositor capture omitted the spike
window), so this run deliberately does not claim desktop-through success.

## Interpretation and next gate

The prototype is the lowest-cost way to validate a transparent native host
without touching Flutter. If a local DWM session confirms the RGBA8 contract,
the next step is a separate Flutter-surface integration spike. It must not be
merged into Reader until alpha composition, resize/recreation, screenshot, and
GPU fallback are verified locally. FP16/scRGB is a capability probe, not a
product promise; SDR fallback remains required.
