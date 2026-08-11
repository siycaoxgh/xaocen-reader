# M5.7 Platform Rendering & Packaging Foundation — Architecture Audit

日期：2026-08-12  
审计基线 HEAD：`e6fdb0ec900dd9e4d3e252ba068cc9aef1f4b24d`  
Drift schema：12  
Flutter：3.44.7 stable；framework `84fc5cbb22`；engine `69c8c61792`；Dart 3.12.2  
本轮只做源码审计、官方 API 研究和构建产物测量；未修改 Reader、分页、Locator、数据库或 Flutter engine。

## 结论摘要

1. Windows 真透明的正式推荐路线是 **DirectComposition + alpha-capable composition swapchain + Flutter Windows platform-surface patch**。这不是 runner 上加一个窗口属性，而是让 Flutter frame 进入带 premultiplied alpha 的 composition surface。
2. 不需要 fork 整个 Flutter engine，但当前公开 Windows embedder API 不足以只改 runner 完成它；需要维护一个尽量小、固定版本的 Windows embedder/compositor 增量（或推动同等上游能力）。
3. 同一套 DirectComposition 树可以同时承载透明与 Advanced Color。透明模式优先使用 `DXGI_FORMAT_R16G16B16A16_FLOAT` + premultiplied alpha + scRGB；不支持时回退到现有 SDR 路径。
4. DirectWrite/Direct2D 是可行的隔离备选，但会产生第二套文字测量、分页、字体和交互实现，不应作为当前产品主路线。
5. Android 当前是 Flutter 3.44.7 的默认 Impeller（API 29+ 且 Vulkan 可用），否则回退 OpenGL；项目没有显式宽色域、HDR 或 Surface frame-rate 合同。Windows 当前是 ANGLE/D3D11 + EGL RGBA8，已具备 Per-Monitor V2/DPI 适配，但尚未暴露 HDR/WCG 能力。
6. `>180 MB` 只代表 debug 多 ABI 开发包，不代表用户 arm64 安装包。当前 arm64 release 为约 20.08 MiB；已测量的最大安全收益来自 release/ABI split，而不是删除字体、书库或 Reader 资源。

## 1. Windows 真透明正式推荐技术路线

### 1.1 当前 XAOCEN 渲染链

```text
Top-level HWND: FLUTTER_RUNNER_WIN32_WINDOW
  └─ child HWND: FLUTTERVIEW
       └─ FlutterWindowsView::CreateRenderSurface
            └─ EGL/ANGLE window surface bound to FLUTTERVIEW
                 └─ CompositorOpenGL::Present → eglSwapBuffers
                      └─ Flutter Reader widgets (Scaffold/ColoredBox/Text)
```

当前 runner 在 `flutter_window.cpp` 创建 `FlutterViewController`，再把 `view()->GetNativeWindow()` 交给 `SetChildContent`；`win32_window.cpp` 只负责 top-level style、拖动/resize、`WM_DPICHANGED` 和 child 定位。实际 runner 没有 `WS_EX_LAYERED`、`UpdateLayeredWindow`、DirectComposition 或自定义 swapchain。

Flutter engine 本地源码显示：Windows EGL manager 请求 RGBA8（R/G/B/A 各 8 bit），显示属性选择 ANGLE D3D11，窗口 surface 通过 `eglCreateWindowSurface(hwnd, ...)` 创建，present 路径是 `eglSwapBuffers`。公开的 `FlutterDesktopEngineProperties` 没有 alpha surface、composition swapchain 或色彩空间参数；`FlutterDesktopViewGetHWND` 只返回 backing HWND。

### 1.2 推荐 Plan A

正式产品路线应拆成一个隔离的 Windows compositor 增量：

1. top-level borderless HWND 继续由现有 shell 管理；标准带边框窗口先禁用桌面透明。
2. 创建 D3D11 device / DirectComposition device 和 visual tree，绑定到 top-level HWND。
3. 用 DXGI flip-model composition swapchain（`CreateSwapChainForComposition` 或等价的 composition presentation surface）承载 Flutter frame；swapchain 设为 `DXGI_ALPHA_MODE_PREMULTIPLIED`。
4. Reader 的透明背景以 alpha 0 绘制，正文以独立 alpha 绘制。premultiplied 合成保证 `backgroundOpacity = 0%`、`textOpacity = 100%` 时桌面透出而文字仍完整。
5. 窗口 resize、DPI 和 monitor change 时重建/调整 surface 与 visual bounds；输入仍由原有 Flutter child/host 路径转发，不把输入绑定塞进 native renderer。
6. 透明模式下优先使用 `DXGI_FORMAT_R16G16B16A16_FLOAT`，颜色空间采用 scRGB；不支持 FP16/Advanced Color 的设备回退到 8-bit SDR alpha surface，不能静默声称 HDR。

Microsoft 的 composition-swapchain 示例明确展示 presentation surface 与 DirectComposition visual 的绑定、alpha mode/color space 的原子更新以及 `R16G16B16A16_FLOAT` 可作为 composition buffer；`DXGI_ALPHA_MODE_PREMULTIPLIED` 的语义是颜色先乘 alpha。参考：

- [Composition swapchain examples](https://learn.microsoft.com/en-us/windows/win32/comp_swapchain/comp-swapchain-examples)
- [DXGI alpha modes](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_2/ne-dxgi1_2-dxgi_alpha_mode)
- [CreateSwapChainForComposition](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_3/nf-dxgi1_3-idxgifactory2-createswapchainforcomposition)
- [DWM overview](https://learn.microsoft.com/en-us/windows/win32/dwm/dwm-overview)

### 1.3 是否需要 fork Flutter engine

**不需要 fork 完整 Flutter engine，但需要维护 Windows platform/compositor 级别的 engine delta。** 原因是当前 public runner API 没有把 EGL window surface 替换成外部 alpha composition surface 的入口；仅在 `win32_window.cpp` 设置 DWM accent 或 top-level style，无法改变 `FLUTTERVIEW` 的 swapchain 语义。

最低维护成本应是：

- pin 一个明确 Flutter engine revision；
- 只维护 Windows `FlutterWindowsView`/surface factory/Present 相关小补丁；
- 将 alpha mode、surface format、color space、resize/recreate、capability fallback 封装为一个 native module；
- 每次 Flutter 升级先跑 compositor contract test，再决定是否 rebase；
- 不做 CPU readback、截图回写、伪透明和 native text overlay。

这仍然属于“维护一个小型 embedder/compositor 分支”，不是“完全不 fork”。如果验证发现必须修改 Skia/Impeller 大范围路径、维护多个 engine 分支，或无法保持标准 Flutter frame/input/accessibility 生命周期，应触发 stop condition，而不是继续扩大 patch。

### 1.4 透明与 HDR/WCG 是否共用一个 compositor

可以共用同一棵 DirectComposition visual tree 和 capability/fallback 管线，但不要把“透明”“HDR”“WCG”合成一个用户开关：

- surface contract：RGBA/FP16、premultiplied alpha、surface lifetime；
- display contract：当前 output 的 `BitsPerColor`、`ColorSpace`、luminance；
- feature contract：透明背景、图片/Palette、HDR/WCG 分别决定是否启用。

Windows `IDXGIOutput6::GetDesc1` 提供当前 output 的色彩空间、每通道 bit 数和亮度信息；`RGB_FULL_G22_NONE_P709` 表示当前 SDR/sRGB，而 `RGB_FULL_G2084_NONE_P2020` 表示 HDR Advanced Color。Microsoft Advanced Color 文档建议通用应用使用 FP16 scRGB；HDR10 `R10G10B10A2` 路线不适合需要 alpha 混合的透明阅读窗口。参考：[DXGI_OUTPUT_DESC1](https://learn.microsoft.com/en-us/windows/win32/api/dxgi1_6/ns-dxgi1_6-dxgi_output_desc1)、[Advanced Color/HDR](https://learn.microsoft.com/en-us/windows/win32/direct3darticles/high-dynamic-range)、[DXGI formats](https://learn.microsoft.com/en-us/windows/win32/api/dxgiformat/ne-dxgiformat-dxgi_format)。

## 2. Plan B：DirectWrite/Direct2D 原生透明 Reader

### 2.1 可复用部分

Plan B 可以继续复用：

- `ReaderLocator`（normalized.txt UTF-16 absolute offset）；
- TOC/chapter boundary、bookmark/search/history 数据合同；
- ReaderPreferences、FontRegistry、AutoRead 的 domain 状态；
- 输入路由和窗口 shell 的一部分。

### 2.2 必须重新实现的部分

原生 surface 仍需重新实现 Flutter 目前承担的：

- UTF-16 到 glyph/run 的测量和换行；
- 首行缩进、段距、行距、四向 padding、字体 fallback；
- vertical scroll visible-range confirm；
- paged layout、chapter-first-page、bounded PageWindow 的 native 等价物；
- 字体导入/失效 fallback、图片背景、Palette、选取和文本输入；
- 无障碍、命中测试、selection、搜索/书签定位和跨模式 restore。

因此它可以满足 per-pixel alpha，却会产生第二套 layout/pagination truth。除非未来明确接受“透明阅读是另一个 native renderer”，否则不值得作为 XAOCEN 的主实现。保留它作为 Plan A 长期阻断时的技术备援，不进入当前生产分支。

参考项目 [binbyu/Reader 的实现](https://github.com/binbyu/Reader/blob/master/Reader/Reader.cpp) 使用自己的 ARGB/layered 绘制路径：borderless 时使用 layered window，将背景和文字合成到带 alpha 的帧，再提交给 DWM，并可独立调整文字 alpha。这解释了“背景透明、文字不透明”，但它不是 Flutter child HWND 的透明开关，也不应复制其受限源码。

## 3. 当前 Windows/Android DPI、分辨率与渲染能力

### 3.1 Windows

源码与本机审计结果：

- `windows/runner/runner.exe.manifest` 声明 `PerMonitorV2`；
- runner 处理 `WM_DPICHANGED`，并按 monitor DPI 缩放初始 bounds；
- 1080p、1440p、4K 没有专用分支，Flutter logical pixels + per-monitor physical pixels 是正确的架构；
- 多显示器移动时已有 DPI/bounds 处理，但未来透明 swapchain 必须同步重建 surface/visual；
- 本机远程环境的可见桌面为 `1536×864`，Intel UHD 报告 `1920×1080 @ 144 Hz`；另有 GameViewer virtual adapter 和 NVIDIA RTX 3060 Laptop GPU。该数值是审计机能力，不代表所有用户显示器；
- 当前 Flutter Windows backend 为 ANGLE/D3D11 EGL，EGL config 是 8-bit RGBA + depth/stencil；当前 app 没有 `IDXGIOutput6` HDR/WCG 检测、swapchain color-space 设置或 HDR metadata。

结论：DPI/分辨率架构可用；当前 HDR/WCG 是 **未暴露、未验证、不能宣称支持**。当前 surface 应按 SDR/8-bit 处理。

### 3.2 Android

- `devicePixelRatio`、物理分辨率、cutout/insets 应继续由 Flutter `MediaQuery`/真实 system insets 派生，不写设备型号分支；本轮未连接 Android 设备，未测量具体 panel。
- Flutter 3.44.7 文档说明：Android API 29+ 默认使用 Impeller；不支持 Vulkan 的设备回退 legacy OpenGL。项目 manifest 没有 `EnableImpeller=false`，所以 Android 15/API 35 设备应走默认 Impeller，最终 backend 仍应以运行日志/诊断页为准。参考：[Impeller rendering engine](https://docs.flutter.dev/perf/impeller)。
- 项目没有 `android:colorMode="wideColorGamut"`、`setColorMode(COLOR_MODE_WIDE_COLOR_GAMUT)`、HDR capability detection 或 wide-gamut surface contract；因此当前 Android 只按标准色彩输出，HDR/WCG 为未实现/未验证。
- 项目没有 `Surface.setFrameRate` 或 `preferredDisplayModeId` bridge；60/90/120 Hz 由系统 Choreographer/display mode 决定，应用当前不主动请求。

## 4. 高刷新率合同

### Windows

当前 EGL/ANGLE + vsync 会随系统显示刷新节拍工作；审计机报告了 144 Hz，但 runner 没有显式刷新率选择或 monitor mode 请求。这样对普通阅读是安全的：静态阅读采用系统默认，手势/Ticker 只消费实际 vsync，不强制 120 Hz。未来若要统计，应从 output mode/Present timing 读实际值，而不是由 UI 假定。

### Android

Android `Surface.setFrameRate`（API 31）是“意向帧率”而非保证，系统可以选择可用 display mode，也不会替应用生成更多 frame；`0` 表示接受系统选择。它适合未来 AutoRead/gesture 的可选 hint，但不应现在强制高刷：

- static reading：不调用，遵循系统/default；
- gesture 或 AutoRead running：能力检测后可请求合适的 rate；
- pause/idle/background：清除请求，回到默认；
- API 不支持、设备无高刷或切换不 seamless：静默回退。

参考：[Surface.setFrameRate](https://developer.android.com/reference/android/view/Surface#setFrameRate(float,%20int,%20int))、[Android frame-rate guidance](https://developer.android.com/media/optimize/performance/frame-rate)。

## 5. HDR/WCG 当前真实边界

| 平台 | 当前可确认 | 当前不能宣称 | 未来安全边界 |
|---|---|---|---|
| Windows | D3D11/ANGLE、8-bit RGBA、DPI/多显示器基础 | HDR、WCG、FP16、透明 alpha composition | 先用 `IDXGIOutput6::GetDesc1` 检测，再以 FP16 scRGB composition surface；不支持则 SDR fallback |
| Android | Flutter 标准 surface；API 29+ 默认 Impeller 条件 | HDR/WCG Activity/surface 输出 | 以 `isScreenWideColorGamut`/display capabilities 和 `colorMode` 条件启用，失败回退 sRGB |

Android 官方宽色域文档明确要求 Activity 的 `wideColorGamut` 请求，并允许通过 `isScreenWideColorGamut()` 判断；当前 manifest 没有该请求，因此不应把 Palette 的普通 RGB 选择描述为 HDR/WCG。参考：[Enhance graphics with wide color content](https://developer.android.com/training/wide-color-gamut)。

## 6. Android 包体审计

### 6.1 实测文件

构建工具：`C:\Users\TOM\develop\flutter\bin\flutter.bat`。文件大小同时给出十进制 bytes 和二进制 MiB；Flutter CLI 的 MB 显示为近似值。

| 产物 | 实际路径 | bytes | MiB |
|---|---|---:|---:|
| Debug universal APK | `build/app/outputs/flutter-apk/app-debug.apk` | 184,628,253 | 176.08 |
| Release universal APK | `build/app/outputs/flutter-apk/app-release.apk` | 61,101,014 | 58.27 |
| Release armeabi-v7a | `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` | 18,558,778 | 17.70 |
| Release arm64-v8a | `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | 21,050,826 | 20.08 |
| Release x86_64 | `build/app/outputs/flutter-apk/app-x86_64-release.apk` | 22,598,030 | 21.55 |
| Release universal AAB | `build/app/outputs/bundle/release/app-release.aab` | 56,788,698 | 54.16 |

`flutter build appbundle --analyze-size` 在多 ABI 默认配置下会被 Flutter 拒绝（要求指定单 ABI）；按工具要求以 `--target-platform android-arm64` 重跑成功：

- arm64 analyze-size AAB：21,591,861 bytes（20.59 MiB，CLI 约 20.6 MB）；
- JSON：`C:\Users\TOM\.flutter-devtools\aab-code-size-analysis_01.json`，8,599,389 bytes；
- code-size 输出中，`BUNDLE-METADATA` debug symbols 约 9 MB；base assets 约 212 KB；base dex 约 254 KB；arm64 base lib 约 10 MB；Dart AOT decompressed accounting 约 7 MB。

### 6.2 Debug 为何超过 180 MB

Debug 包不是用户发布包，主要组成是：

- `assets/flutter_assets/kernel_blob.bin`：72,628,064 bytes；
- 三 ABI 的 `libflutter.so` 合计：108,372,244 bytes；
- `isolate_snapshot_data`：11,093,091 bytes；
- arm64 `libVkLayer_khronos_validation.so`：15,240,080 bytes；
- debug MaterialIcons 未 tree-shake 前：1,645,184 bytes；
- 其余是 SQLite native libs、classes、NOTICES 和少量 Flutter assets。

这解释了 184.6 MB：JIT kernel、校验层和三份 Flutter engine 同时存在。Release 已移除 kernel/validation 层并使用 AOT；MaterialIcons 在 release tree-shake 到 8,892 bytes。

### 6.3 Release/arm64/AAB 的真实来源

arm64 release APK 的主要未压缩条目：

- `lib/arm64-v8a/libflutter.so`：11,581,856 bytes；
- `lib/arm64-v8a/libapp.so`：7,209,872 bytes；
- `lib/arm64-v8a/libsqlite3.so`：1,526,536 bytes；
- `classes.dex`：577,684 bytes；
- Flutter assets 总体约 262 KB，其中 GB18030 index 约 97 KB，MaterialIcons 约 9 KB，shaders/NOTICE 占其余主要部分。

universal release APK 把三个 ABI 的 `libflutter.so`/`libapp.so`/SQLite 同时放入一个包，因此约 61.1 MB；AAB 也包含多 ABI 模块和 bundle metadata，但 Play/商店分发时会按设备拆分。arm64 split APK 是当前最接近实际 arm64 用户下载/安装量的可测代理，不能用 184.6 MB debug 值替代。

## 7. 可安全减少多少体积

当前最安全、收益最大的措施是分发策略，而不是删除功能资源：

- debug → arm64 release：从 184.63 MB 降到 21.05 MB，减少约 **88.6%**；
- universal release → arm64 split：从 61.10 MB 降到 21.05 MB，减少约 **65.5%**；
- release 内 MaterialIcons、GB18030、shaders 已经很小；当前没有 bundled reader fonts/images 可以安全删除；`libflutter.so`、`libapp.so`、SQLite 是运行时核心，不能为追求数字直接裁剪。

因此可安全承诺的 reduction 是 **发布 arm64/split 后的 40 MB 左右（相对 universal release）**；在 arm64 release 基础上，本轮没有证据支持再安全减少数 MB。后续若要进一步压缩，必须以 analyze-size、ABI 使用率和真实功能回归为前提，不得破坏字体导入、DataRoot、SQLite 或 Reader engine。

## 8. 推荐实施顺序

1. **Capability layer（先做）**：Windows output/DPI/HDR/WCG/refresh 诊断；Android renderer/display/wide-color/refresh 诊断；所有结果只读、可回退。
2. **Isolated DirectComposition spike**：不接 Reader 数据，使用 borderless window + alpha text/background test pattern；分别验证 RGBA8 和 FP16 scRGB、resize、DPI、multi-monitor、screenshot、GPU/remote desktop。
3. **Flutter Windows surface patch**：若 spike 成功，只维护 pinned engine 的 Windows surface/compositor 增量；让 Flutter frame 进入 alpha swapchain，保留现有 Dart Reader、Locator、PageWindow、AutoRead 和 input contract。
4. **Reader integration**：先接 background alpha，再接独立 text alpha；标准窗口关闭透明设置；失败设备回退 SDR/opaque，并显示明确状态。
5. **Advanced Color**：以 output capability 和色彩空间为条件启用 FP16/scRGB；不把 HDR/WCG、透明、Palette 合成一个持久化开关。
6. **Packaging**：发布 AAB/ABI split；将 universal APK 只用于内部旁载/测试，保留 debug 作为开发包；在每次 Flutter/AGP 升级后重复 size analysis 和 native smoke test。

## 9. 风险与 stop condition

- **Surface boundary**：当前 `FLUTTERVIEW`/EGL window surface 仍是阻断点；host-only DWM accent、整窗 alpha、color key 和桌面截图均不满足合同。
- **Engine maintenance**：如果 alpha surface 需要修改完整 raster/compositor、无法只隔离 Windows patch，或每次 Flutter 升级都产生大范围冲突，停止产品化并重新评估 Plan B。
- **Text correctness**：不得通过 CPU readback、native text overlay 或第二套 pagination 伪造成功；任何导致 font metrics、chapter-first-page、Locator restore 改变的方案停止。
- **DComp/child HWND**：必须验证 `WM_NCHITTEST`、keyboard focus、resize/recreate、DPI、maximize/restore、tray、Boss Key、screenshot 和 background hit-test；child visual/target 的裁剪不能吞掉透明区域或输入。
- **FP16/HDR**：FP16 会增加带宽、显存和合成成本；跨 SDR/HDR 多显示器时必须接受 DWM down-convert/fallback，不能假定所有 output 都支持 Advanced Color。
- **Remote desktop**：当前机器显示能力含 virtual display，远程环境不能代替本地 DWM/GPU 视觉验收；`LOCAL VISUAL TRANSPARENCY VALIDATION` 仍须在真实本地 Windows 做。
- **Android frame-rate/color**：`Surface.setFrameRate` 和 wide-color 都是能力/意向 API，不是保证；任何不支持都必须回到 system/default、sRGB、60/系统刷新。
- **Packaging regression**：AAB 体积包含 bundle metadata/debug symbols，不能直接当成 Play 用户下载量；必须同时报告 split APK 和商店实际 delivery 结果。

## 10. 最终回答（12 项）

1. Windows 真透明正式路线：DirectComposition + premultiplied alpha composition swapchain，Flutter Windows platform-surface 小型增量。
2. 是否 fork engine：不 fork 完整 engine；当前 public API 不够，需维护小型 Windows embedder/compositor delta 或上游化同等能力。
3. 一个 compositor 是否可同时打基础：可以；FP16 scRGB + alpha 是透明与 Advanced Color 的共同 surface 基础，feature/capability 仍分离。
4. Plan B：保留为 contingency，不作为主路线；第二套 DirectWrite/Direct2D layout/pagination 维护成本过高。
5. DPI/高分辨率：Windows PerMonitorV2 + `WM_DPICHANGED`，架构覆盖 1080p/1440p/4K/多显示器；Android 用 devicePixelRatio/insets，未做机型分支。
6. 高刷新率：Windows 当前 vsync 跟随系统（审计机报告 144 Hz）；Android 跟随 Choreographer/系统，未接 `Surface.setFrameRate`，不强制 120。
7. HDR/WCG：Windows 当前 8-bit ANGLE/EGL、无检测/色彩空间设置；Android 无 wideColorGamut/HDR 合同。两端均应 capability-gated、失败回退。
8. Android 180 MB 来源：debug JIT kernel + 三 ABI libflutter + isolate snapshot + Vulkan validation layer；不是书库、Reader 字体或图片。
9. 实际大小：debug 184,628,253；release universal APK 61,101,014；arm64 split 21,050,826；universal AAB 56,788,698；arm64 analyze-size AAB 21,591,861。
10. 可安全减少：发布 ABI split/AAB 相对 universal release 约减少 40 MB；arm64 release 已接近核心运行时下限，本轮没有额外安全裁剪证据。
11. 实施顺序：capability layer → 隔离 DComp spike → pinned Windows surface patch → Reader alpha integration → FP16/HDR → packaging distribution。
12. 风险/停止条件：alpha surface 仍不可从 public runner 接入、需要完整 engine fork/CPU readback/native second layout、DComp 生命周期破坏输入或 Reader contracts、或本地 DWM/GPU 验收失败时停止，不做 hack。

本轮停止于架构审计和测量；未进入 TTS、EPUB、RSS，未修改 Drift schema 或生产渲染代码。
