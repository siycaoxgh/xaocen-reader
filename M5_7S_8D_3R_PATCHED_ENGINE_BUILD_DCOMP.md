# M5.7s.8d-3R — Patched Windows Engine Build + DComp Validation

日期：2026-08-14
XAOCEN 生产目录：C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader
Engine：C:\xaocen-engine\src（实际 GN source/output 位于 engine\src）

## Gate 复核

- Flutter Engine revision：69c8c61792f04cc809dfef0c910414fb9afc06cd
- Patched checkout HEAD：69c8c61792f04cc809dfef0c910414fb9afc06cd
- Revision match：PASS
- Alpha patch：PASS（dcomp_window_surface.cc/.h、Windows EGL/engine/view wiring 均仍在 checkout/build graph）
- GN output：C:\xaocen-engine\src\engine\src\out\host_debug_unopt
- args.gn、build.ninja：存在且有效

## 增量编译

继续使用既有 output/cache，未执行 clean、reset、reclone、全量 sync 或删除 out。

第一次续编的首个真实编译错误为：

    flutter/shell/platform/windows/egl/dcomp_window_surface.cc(142,23):
    error: use of undeclared identifier 'DXGI_SWAP_CHAIN_FLAG_SHARED'

该 Windows SDK（10.0.22621.0）没有这个枚举。只对 Engine patch 做了最小编译修正：保留 composition swapchain 的 flags 为 0，并保留后续 IDXGIResource1::CreateSharedHandle 路径。未修改 XAOCEN 生产代码。

第二次使用同一 output 增量续编，仅剩 18 个目标，随后成功完成：

- flutter_windows.dll：C:\xaocen-engine\src\engine\src\out\host_debug_unopt\flutter_windows.dll
- DLL size：127,090,688 bytes
- DLL timestamp：2026-08-14 03:38:15 UTC
- DLL SHA-256：16CD096ABB4AB1810003388796AC42463F2ECA12738803BB904C286E0D7C9425
- patched object：...\obj\flutter\shell\platform\windows\egl\flutter_windows_source.dcomp_window_surface.obj
- patched object timestamp：2026-08-14 03:36:59 UTC
- ninja -C ...\out\host_debug_unopt -n flutter_windows.dll：no work to do

## DComp fixture 运行验证

使用独立 fixture：

C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\windows_engine_patches\flutter_engine_spike_test_app

fixture 使用当前 patched DLL（与 Engine DLL SHA-256 相同），并通过 Engine 正确的 debug 开关环境变量启动：

    $env:FLUTTER_ENGINE_SWITCHES = '1'
    $env:FLUTTER_ENGINE_SWITCH_1 = 'enable-windows-alpha-surface'

日志确认 alpha surface 请求已进入：

    Windows alpha surface requested; transparent creation will fall back to opaque before first frame on failure

但 fixture 初始化在 shared texture 导出阶段失败：

    [ERROR:flutter/shell/platform/windows/egl/dcomp_window_surface.cc(29)]
    Backbuffer shared-handle export failed: 0x80070057
    [WARNING:flutter/shell/platform/windows/flutter_windows_view.cc(813)]
    Windows alpha surface unavailable; using opaque ANGLE surface

0x80070057 是真实运行时错误（swapchain backbuffer 未能导出可供 ANGLE client-buffer 使用的 shared handle），不是编译超时。Engine 因此回退到 opaque surface。证据截图：
C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\windows_engine_patches\fixture_evidence\dcomp_runtime_failure_bg0.png

本轮仅为独立 fixture 的窗口创建补充 WS_EX_NOREDIRECTIONBITMAP，未修改 XAOCEN production Runner；该改动不能掩盖 shared-handle 初始化失败。

## 最终 Gate

    ENGINE REVISION MATCH = PASS
    PATCH PRESENT = PASS
    INCREMENTAL CACHE REUSED = PASS
    PATCH COMPILED = PASS
    PATCHED ENGINE BUILD = PASS
    PATCHED ARTIFACT = VALID

    DCOMP PROTOTYPE = FAIL
    BG 100 / FG 100 = NOT RUN
    BG 75 / FG 100 = NOT RUN
    BG 50 / FG 100 = NOT RUN
    BG 25 / FG 100 = NOT RUN
    BG 0 / FG 100 = NOT RUN
    PREMULTIPLIED ALPHA = NOT RUN

### 当前阻断

Patched Engine 已完成增量编译，但现有 DComp patch 的 CreateSwapChainForComposition backbuffer 没有成功导出 shared handle，无法建立：

Flutter frame → shared D3D texture → ANGLE EGL client buffer → DComp composition swapchain

因此不能证明 BG 0% / FG 100%，也不能宣称 premultiplied alpha 或真实桌面透出 PASS。此处是 DComp interop/runtime blocker，不是 XAOCEN UI 问题。

按 Gate 要求本轮停止。不要进入 M5.7s.8d-4-1；不要接入 XAOCEN production Runner。
