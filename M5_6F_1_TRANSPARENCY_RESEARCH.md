# M5.6f.1 Windows Borderless Transparency Re-investigation

日期：2026-08-12  
实际 HEAD：`75bc0c3dae5b44282c106435b36dbec54f3d4108`  
Drift schema：12  
Flutter：3.44.7 stable（engine `69c8c61792`）

本轮只做 Windows 透明渲染研究和隔离探针，不修改生产 Reader、数据库、分页、Locator、AutoRead 或字体系统。

## 1. 结论摘要

XAOCEN 当前的 borderless、resize、DPI、多显示器、tray、Boss Key 均运行在一个普通 Win32 顶层窗口上；Flutter 自己的 `FLUTTERVIEW` child HWND 仍承载 EGL/ANGLE GPU surface。把顶层窗口设为 DWM 的 transparent-gradient **可以成功调用 API**，但不能把 Flutter child surface 变成可透出桌面的 per-pixel-alpha surface。

因此本轮 Prototype A 的严格目标：

`desktop → transparent host → transparent Flutter surface → alpha background + opaque text`

未成立。阻断点不是 borderless hit-test，而是 Flutter child/swapchain 的宿主和合成链路没有公开的透明 surface 配置。

这不是“Flutter 完全不能透明”的泛化结论：如果应用自己拥有每帧 ARGB 位图，Win32 layered window 可以做到独立 alpha；但 XAOCEN 当前 Flutter child 并不提供这条路径。

结论：不将 host-only alpha hack 合入生产；若仍要产品化，必须单独维护自定义 Flutter Windows embedder/compositor，或把 Reader 正文改为原生 per-pixel renderer。两者都不属于低风险 runner 小修。

## 2. 参考项目的真实原理

### binbyu/Reader

该项目不是 Flutter。它在 borderless/fullscreen 状态把窗口切到 layered/per-pixel 绘制路径：

1. `WS_EX_LAYERED` + 自己创建 ARGB DIB/DC；
2. 背景色或图片先写入带 alpha 的位图；
3. 正文由 Win32/GDI/GDI+ 绘制到独立 text DC，再用 `AlphaBlend` 合入；
4. 最终通过 `UpdateLayeredWindow(..., ULW_ALPHA)` 把整张 premultiplied ARGB 帧交给 DWM；
5. `_textAlpha` 只影响文字绘制，背景 alpha 由另一条路径控制。

源码中的 `OnDraw`、`AlphaBlend`、`UpdateLayeredWindow`、`_textAlpha` 和 borderless 时的 `bLayered = TRUE` 共同构成这个行为。项目 README 也明确说明透明背景/不透明字体只在隐藏边框或全屏可用，并提示该模式绘制效率较低。

这解释了“隐藏边框后背景透出、字体仍清晰”：它拥有最终像素和 alpha，而不是把一个 Flutter child 交给普通 HWND。

参考（仅行为/原理）：

- [binbyu/Reader README](https://github.com/binbyu/Reader)
- [binbyu/Reader Reader.cpp](https://github.com/binbyu/Reader/blob/master/Reader/Reader.cpp)

### leanflutter/window_manager

当前 Windows 实现的 `WindowManager::SetBackgroundColor`：

- 在**顶层 HWND** 上动态调用 `SetWindowCompositionAttribute`；
- 透明色时使用 `ACCENT_ENABLE_TRANSPARENTGRADIENT`；
- 没有修改 Flutter child HWND，也没有提供 Flutter render-surface alpha 参数。

`WindowOptions(backgroundColor: Colors.transparent)` 因而是 host/window composition 请求，不是一个保证 Flutter 内容 per-pixel alpha 的 embedder contract。

其 `SetOpacity` 则给顶层窗口加 `WS_EX_LAYERED` 并调用 `SetLayeredWindowAttributes(..., LWA_ALPHA)`；这是**整窗** alpha，文字和背景一起淡出，不能满足 XAOCEN 的独立 opacity 合同。微软文档还指出，调用 `SetLayeredWindowAttributes` 后再直接使用 `UpdateLayeredWindow` 会失败，除非先清除并重新设置 layered style。

参考：

- [window_manager README/example](https://github.com/leanflutter/window_manager)
- [window_manager Windows implementation](https://github.com/leanflutter/window_manager/blob/main/packages/window_manager/windows/window_manager.cpp)
- [window_manager changelog](https://pub.dev/packages/window_manager/changelog)

## 3. XAOCEN 当前渲染链路

```text
Top-level HWND: FLUTTER_RUNNER_WIN32_WINDOW
  └─ child HWND: FLUTTERVIEW
       └─ FlutterWindowsView::CreateRenderSurface
            └─ EGL/ANGLE window surface bound to child HWND
                 └─ CompositorOpenGL::Present → eglSwapBuffers
                      └─ Flutter Reader widgets (Scaffold/ColoredBox/Text)
```

对应代码：

- `windows/runner/flutter_window.cpp` 构造 `FlutterViewController`，然后把 `view()->GetNativeWindow()` 交给 `SetChildContent`；
- `windows/runner/win32_window.cpp` 负责顶层 style、`WM_NCHITTEST`、resize、DPI 和 child positioning；
- 当前 runner 没有 `WS_EX_LAYERED`、`SetLayeredWindowAttributes`、`UpdateLayeredWindow`、`SetWindowCompositionAttribute`、DirectComposition 或 custom swapchain；
- Flutter 3.44.7 engine 的公共 `FlutterDesktopViewControllerCreate`/`FlutterDesktopViewGetHWND` API 没有 transparent/alpha surface 参数；
- engine 的 `egl::Manager` 虽然选择了 `EGL_ALPHA_SIZE = 8`，但仍通过 `eglCreateWindowSurface(hwnd, ...)` 建立普通 EGL window surface；公开 embedder API 没有把该 alpha 通道声明为桌面可合成透明目标；
- Reader 的 `Scaffold`、`_buildReaderBackground`、paged `ColoredBox` 都在同一个 Flutter child 内绘制背景和正文。

实际运行探针（当前 Release exe）：

| 对象 | class | ex-style |
|---|---|---:|
| top-level | `FLUTTER_RUNNER_WIN32_WINDOW` | `0x40100` |
| Flutter child | `FLUTTERVIEW` | `0x0` |

`WS_EX_LAYERED` 是 `0x80000`，因此两个窗口在实际运行时都没有 layered style。

## 4. Prototype A：Borderless + Transparent Host

### 探针方法

不改生产二进制源码，启动当前 Release exe，读取真实 top/child HWND，然后在临时 PowerShell P/Invoke 类型中对 top-level HWND 调用：

```text
SetWindowCompositionAttribute(
  topHwnd,
  ACCENT_ENABLE_TRANSPARENTGRADIENT,
  flags = 2,
  color = 0
)
```

结果：调用返回 `TRUE`。调用前后 top-level ex-style 仍为 `0x40100`，Flutter child ex-style 仍为 `0x0`。这是一个可逆的 host-only probe，不修改应用设置或数据库。

### A1：background 0% + text 100%

**结果：不成立（surface boundary blocked）。**

顶层 DWM accent 成功并不改变 `FLUTTERVIEW` 的 EGL/ANGLE child surface。即使 Dart 把 Reader `ColoredBox` 设为 `Colors.transparent`，这个透明色也只是在 child surface 内部绘制；child surface 本身仍以一个普通窗口内容参与父窗口合成，桌面不会可靠透出。因为文字也在同一 surface，无法从 host 层把背景 alpha 与文字 alpha 分离。

本轮未把这个 probe 宣称为视觉 PASS：远程环境没有本地 DWM/GPU 视觉确认，`LOCAL VISUAL TRANSPARENCY VALIDATION = DEFERRED`。

### A2：Flutter background 0/25/50/75/100%，text 100%

Reader 内部的 background alpha 可以作为 Flutter paint 参数变化，但它仍然只改变 child 内的颜色合成；不会产生 `desktop + semi-transparent Reader background + opaque Flutter text` 的结果。因此 A2 也不能作为产品透明能力验收。

## 5. 为什么 DirectComposition 不是当前的小修

Flutter issue #108486 讨论的是用 DirectComposition 把外部 HWND、MediaFoundation source、DXGI swapchain 或 `IDCompositionVisual` 嵌入 Flutter tree；它不是一个现成的“给 Flutter root surface 打开桌面 alpha”开关。

微软 API 的边界也很明确：

- `IDCompositionDevice::CreateSurfaceFromHwnd` 包装的是 **layered window** 的 rasterization；未 layered 时内容不会出现在该 composition visual；
- `CreateTargetForHwnd` 允许把 visual tree 绑定到 HWND，但 child windows 可能裁剪 visual tree；
- 真正的 composition swapchain 需要 alpha-enabled DXGI/EGL surface、visual tree、resize/DPI 同步和输入/无障碍转发；
- XAOCEN 当前 Flutter engine 已经拥有自己的 EGL/ANGLE window surface 和 `SwapBuffers` 路径，runner 没有 API 把它重绑到自建 DirectComposition target。

所以 Prototype C 若继续推进，实际范围是：

1. 自定义 Flutter Windows embedder/engine surface；或
2. fork/维护 Flutter Windows compositor，使 alpha surface、DComp target、child/input/accessibility 生命周期一致。

这明显高于普通 runner flag，也必须重新验证 GPU、resize、DPI、截图、tray/Boss Key 与 Flutter 插件。

参考：

- [Flutter issue #108486](https://github.com/flutter/flutter/issues/108486)
- [Flutter engine Windows view](https://github.com/flutter/engine/blob/main/shell/platform/windows/flutter_windows_view.cc)
- [Flutter engine Windows EGL manager](https://github.com/flutter/engine/blob/main/shell/platform/windows/egl/manager.cc)
- [DirectComposition overview](https://learn.microsoft.com/en-us/windows/win32/directcomp/why-use-directcomposition-)
- [CreateSurfaceFromHwnd](https://learn.microsoft.com/en-us/windows/win32/api/dcomp/nf-dcomp-idcompositiondevice-createsurfacefromhwnd)
- [CreateTargetForHwnd](https://learn.microsoft.com/en-us/windows/win32/api/dcomp/nf-dcomp-idcompositiondesktopdevice-createtargetforhwnd)

## 6. Prototype B：binbyu 原理能否适配

### 可直接应用于 XAOCEN top-level HWND？

只能应用 host API/窗口 style 的一部分，不能得到独立 Flutter 背景/正文 alpha。`SetLayeredWindowAttributes` 是整窗 alpha，明确禁止作为产品方案。

### 可应用于 Flutter child HWND？

理论上 Windows 8+ 支持 child layered window，但 Flutter engine 的 child HWND、EGL swapchain、resize 和输入生命周期不是按 per-pixel layered presentation 设计的；直接给 `FLUTTERVIEW` 加 style 不会把 EGL swapchain变成 `UpdateLayeredWindow` 的 ARGB source。

### 是否需要替换 Flutter rendering host？

是。要保留独立 alpha，必须由 host/compositor 获得最终带 alpha 的 Flutter frame，或让 Flutter 输出到可合成 alpha swapchain；当前公共 API没有这层契约。

### 是否只能用 native overlay text？

不必然，但这是低层 native renderer 的一条可行路径。若将正文改为 DirectWrite/GDI/Direct2D/native overlay，必须重做排版、选择、滚动、分页、字体和输入整条链路，违反当前 Reader 的低风险目标，不产品化。

## 7. Borderless、系统能力与风险

现有 borderless 的 `WM_NCHITTEST`、四边/四角 resize、drag band、maximize/restore、DPI 和多显示器恢复均属于 top-level shell，技术上可与未来透明 host 共存；但一旦引入 layered child 或 DirectComposition，还必须重新验证：

- child HWND 的 hit-test/keyboard focus 与拖动区域；
- `WM_SIZE` 与 swapchain/visual resize 的同步；
- `WM_DPICHANGED`、monitor change 和物理像素 alpha surface；
- maximize/restore、tray hide/show、Boss Key hide/show 后的 composition commit；
- GPU/ANGLE fast path、remote desktop、截图/任务栏缩略图和高 DPI；
- DWM 不可用/驱动回退时的降级路径。

binbyu 的 per-pixel native path 已报告 borderless 下绘制效率下降；XAOCEN 若复制同层级，也应把 GPU/CPU、连续 resize 和文字抗锯齿作为正式验收项。

## 8. 最低成本可产品化方案

按风险排序：

1. **当前阶段推荐：不实现桌面透出**。保留 Reader Palette、图片背景、Flutter 内背景/遮罩调节；透明度 UI 继续明确标记为 deferred，不伪装成 host alpha。
2. **若产品必须透出桌面：独立 native prototype 分支**。先做小型 DirectComposition/alpha-swapchain host，不接入 Reader 数据和路由；证明 A1/A2、resize/DPI/GPU/输入后，再评估自定义 embedder 维护成本。
3. **原生 per-pixel Reader**。技术上最确定，但成本最高、会重写 Reader rendering，不建议作为 XAOCEN 当前路线。

建议产品合同：**即使未来实现，也只在“无边框阅读”模式开放背景透明度；标准窗口禁用并说明原因。** 这是必要条件而非充分条件：无边框不会自动解决 Flutter surface alpha。

## 9. Reader Text Opacity

文字透明度作为 Flutter paint-only 概念是安全的：只对最终 `textColor` 应用 alpha（例如 `Color.fromARGB(alpha, r, g, b)`），不改变 RGB、font metrics、layout signature、PageWindow 或 ReaderLocator。它不需要 native window alpha。

但当前代码没有独立持久化的 `textOpacity` 字段；本轮不增加字段、不升级 schema。未来若要保存，应作为 per-book appearance preference，并在现有 paint-only resolver 中接入；不要把它误称为桌面透明已经实现。

## 10. 性能、维护与视觉验证

| 路径 | 当前结论 |
|---|---|
| 普通 Flutter surface + host accent | 不能证明桌面透出；风险低但不满足目标 |
| `WS_EX_LAYERED` + `SetLayeredWindowAttributes` | 整窗 alpha，违反独立文字合同；禁止 |
| native `UpdateLayeredWindow` ARGB | 可独立 alpha，但需要 native 最终帧/重写 Reader |
| DirectComposition + alpha swapchain/custom embedder | 理论可行，维护和 GPU/输入/DPI 风险高 |

本轮没有修改生产代码，未执行整套回归构建；当前已有 Release runner 的 native HWND probe 只用于确定性边界验证。远程桌面无法替代本地 DWM/GPU 视觉验收，因此：

`LOCAL VISUAL TRANSPARENCY VALIDATION = DEFERRED`

后续若进入正式 prototype，必须在真实本地 Windows 上验证：background 0% + text 100%、四档/多档背景 alpha、Palette/图片、resize/maximize、DPI/multi-monitor、tray/Boss Key、截图和性能。

## 11. Schema 与 Reader 合同

- Drift schema 保持 12；本轮无 migration。
- `ReaderLocator = normalized.txt UTF-16 absolute offset` 不变。
- 不持久化 pageIndex、scrollPixels、窗口 index、透明渲染状态。
- 不修改 `PagedLayoutEngine`、`PageWindow`、`ReadingSession`、`AutoRead`、字体 metrics 或 `normalized.txt`。

## 12. 最终判断

1. binbyu/Reader 的独立 alpha 来自其自有 ARGB layered renderer，不是 Flutter child transparency。
2. window_manager 的 transparent background 是顶层 host composition；`setOpacity` 是整窗 alpha，不能直接满足 XAOCEN 合同。
3. Prototype A 在 XAOCEN 当前 public Flutter runner 上被 `FLUTTERVIEW`/EGL window surface 边界阻断；`background 0% + text 100%` **未成立**。
4. Prototype B 可解释行为但不能低成本移植；Prototype C 需要 custom embedder/compositor，暂不产品化。
5. 当前不合入透明 hack；等待用户确认后再决定是否开独立 native compositor spike。

