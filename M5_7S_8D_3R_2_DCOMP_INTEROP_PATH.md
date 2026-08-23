# M5.7s.8d-3R-2 — DComp Interop Path Correction

日期：2026-08-14
XAOCEN 项目：C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader
Engine：C:\xaocen-engine\src

## 前置 Gate

已读取 M5_7S_8D_3R_PATCHED_ENGINE_BUILD_DCOMP.md：

- ENGINE REVISION MATCH = PASS
- PATCH PRESENT = PASS
- PATCH COMPILED = PASS
- PATCHED ENGINE BUILD = PASS
- PATCHED ARTIFACT = VALID

本轮没有重新 gn gen、clean、reset、reclone，也没有覆盖 XAOCEN production flutter_windows.dll。

## 旧 backbuffer share 路径审计

旧路径：

CreateSwapChainForComposition
→ swapchain->GetBuffer(0)
→ IDXGIResource1::CreateSharedHandle
→ EGL_D3D_TEXTURE_2D_SHARE_HANDLE_ANGLE

该路径无效。Composition swapchain backbuffer 不是由本 patch 以 D3D11_RESOURCE_MISC_SHARED_NTHANDLE 创建的 app-owned texture；不能假定它可直接导出 NT shared handle。运行时实际返回：

    Backbuffer shared-handle export failed: 0x80070057

因此 CURRENT BACKBUFFER SHARE PATH VALID = NO。

不再向 DXGI_SWAP_CHAIN_DESC1.Flags 塞不存在或错误的 DXGI_SWAP_CHAIN_FLAG_SHARED。该枚举在当前 Windows SDK 中不存在；把 flags 设为 0 只能解决编译问题，不能使 swapchain backbuffer 变成可共享纹理。

## ANGLE runtime capability

使用同一 patched Engine checkout 构建的 ANGLE runtime，独立查询得到：

    EGL_ANGLE_d3d_texture_client_buffer=YES
    EGL_ANGLE_d3d_share_handle_client_buffer=YES
    EGL_ANGLE_keyed_mutex=YES

测试运行日志保存在：

C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\windows_engine_patches\dcomp_interop_spike\run8.out.log
C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\windows_engine_patches\dcomp_interop_spike\run8.err.log

## App-owned D3D11 texture spike

独立测试程序：

C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\windows_engine_patches\dcomp_interop_spike\dcomp_interop_spike.exe

创建的纹理：

- ID3D11Texture2D
- DXGI_FORMAT_B8G8R8A8_UNORM
- D3D11_USAGE_DEFAULT
- D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE
- 单采样
- 无 CPU staging/readback

使用 EGL_D3D_TEXTURE_ANGLE 直接把同一设备创建的 texture 作为 EGL pbuffer client buffer：

    APP_OWNED_TEXTURE=PASS
    ANGLE_D3D_TEXTURE=PASS

ANGLE 在该纹理上先清除 alpha=0 的背景，再以 alpha=1 清除前景矩形。随后使用同一 D3D11 device 将纹理单次 CopyResource 到 DComp composition swapchain backbuffer，并 Present。

## DComp 输出验证

DComp composition swapchain 使用：

- DXGI_FORMAT_B8G8R8A8_UNORM
- DXGI_ALPHA_MODE_PREMULTIPLIED
- DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL

实际运行输出：

    D3D_TEXTURE_TO_DCOMP=PASS copy=single-diagnostic-frame

真实桌面截图：

C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\windows_engine_patches\dcomp_interop_spike\BG0_FG100_d3d_texture_to_dcomp_v5.png

截图像素抽样：

- 前景测试块：RGB(255,255,255)
- 测试块外桌面区域：RGB(53,115,152)、RGB(15,79,114) 等真实桌面像素

这证明在独立 spike 中，透明背景区域能透出真实 Windows 桌面，前景块保持不透明。该前景块用于替代文字做 alpha contract 的最小验证。

## 路径比较

### A：ANGLE → app-owned texture → CopyResource → DComp swapchain

本轮已验证 PASS。它不要求 composition swapchain backbuffer 可导出 shared handle，资源所有权和同步关系明确，适合作为下一阶段的正确性优先路径。

本轮 CopyResource 仅执行一次诊断帧。生产集成仍需单独设计同步、resize/recreate 和性能策略；本轮没有接入 XAOCEN。

### B：ANGLE texture → DirectComposition 直接接受的 raw texture/content

本轮未找到可直接把 ID3D11Texture2D 作为 IDCompositionVisual content 的稳定公开路径。DirectComposition 直接 content 形态是 composition swapchain 或 IDCompositionSurface；不能把 raw ANGLE texture 直接当作 composition visual content 使用。

因此 D3D TEXTURE → DCOMP 的推荐实现为 A，而不是继续沿用错误的 backbuffer CreateSharedHandle 路径。

## 最终状态

    CURRENT BACKBUFFER SHARE PATH VALID = NO
    CREATE_SHARED_HANDLE ROOT CAUSE = composition swapchain backbuffer 不是可直接导出的 app-owned shared texture；CreateSharedHandle 返回 0x80070057
    ANGLE D3D TEXTURE EXTENSION = PASS
    APP-OWNED D3D11 TEXTURE = PASS
    ANGLE → D3D TEXTURE = PASS
    D3D TEXTURE → DCOMP = PASS
    BG 0 / FG 100 = PASS

## RECOMMENDED PRODUCTION INTEROP PATH

后续若获准进入 Engine/production wiring，采用：

Flutter/ANGLE rendering
→ 与 ANGLE 同一 D3D11 device 创建的 app-owned B8G8R8A8_UNORM texture
→ 明确的 GPU synchronization
→ CopyResource/等价 GPU blit 到 B8G8R8A8_UNORM + PREMULTIPLIED composition swapchain
→ DirectComposition Present

本轮没有修改 XAOCEN production Runner、Reader、Theme、透明度 UI，也没有进入 M5.7s.8d-4-1。
