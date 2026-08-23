# M5.7s.8d-1 — Windows True Transparency Re-entry Audit

审计范围：正确项目目录 `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`，以及独立 Engine checkout `C:\xaocen-engine\src`。

本轮只读审计。没有修改生产代码、Flutter Engine、alpha patch、`_bad_scm` 或 schema；没有运行长时间 `gn`/`ninja` 构建。

## 结论

```text
CURRENT PRODUCTION TRANSPARENCY PATH = 标准 Flutter Windows opaque child HWND / ANGLE EGL；不支持透出 Windows 桌面
ENGINE CHECKOUT STATUS = checkout 存在，pinned HEAD 正确；alpha patch 已应用但 worktree dirty、没有可验证 build artifact
ENGINE REVISION MATCH = PASS
EXISTING ALPHA PATCH = PRESENT（applied / build-unverified / not production-integrated）
CURRENT BLOCKER = patched Engine 尚未完成可重复构建，Flutter frame → ANGLE shared texture → DComp 仍无运行时证明
MINIMUM INTEGRATION PATH = 8d-2 Engine 环境 Gate → 8d-3 隔离 Flutter alpha interop → 8d-4 capability-gated Reader integration
```

## 1. XAOCEN 当前 Windows 渲染/窗口链路

当前生产链路是：

```text
main.cpp
 → FlutterWindow
 → Win32Window top-level HWND（标准 WS_OVERLAPPEDWINDOW）
 → FlutterViewController
 → FlutterView::GetNativeWindow() child HWND
 → SetChildContent / client-area resize
 → Flutter stable Windows renderer（Skia / ANGLE / D3D11）
 → 标准 opaque EGL window surface
 → DWM
```

代码证据：

- `windows/runner/flutter_window.cpp` 创建标准
  `flutter::FlutterViewController`，把
  `flutter_controller_->view()->GetNativeWindow()` 交给 `SetChildContent()`。
- `windows/runner/win32_window.cpp` 用 `WS_OVERLAPPEDWINDOW` 创建 top-level
  HWND；`SetChildContent()` 使用 `SetParent()`，并把 child 调整到 client area。
- Runner manifest 的 PerMonitorV2 只负责 DPI 行为，不改变 Flutter surface 的
  alpha 能力。

生产 Runner 没有 alpha-capable backing store、DComp target、composition
swapchain、layered window 或自定义 compositor。因此 Reader 的背景色/图片 alpha
只能在 Flutter surface 内生效，不能让桌面穿透。

## 2. 生产透明接口审计

在生产 `windows/runner` 和 `lib` 中没有发现 DirectComposition、DComp、DXGI
alpha swapchain、`CreateSwapChainForComposition`、`WS_EX_LAYERED`、
`UpdateLayeredWindow` 或 `SetLayeredWindowAttributes` 的实现。相关名称只存在于
设计文档、native spike 与 `windows_engine_patches` 隔离目录。

能力层的当前行为是保守且正确的：

- `lib/platform/platform_capabilities_adapter.dart`：Windows renderer=`Skia`，
  backend=`ANGLE / D3D11`。
- Windows `desktopTransparency` 为
  `unsupported(rendererUnsupported)`；没有把未知能力伪装成支持。
- Android 的 desktop transparency 为
  `unsupported(unsupportedPlatform)`。

Reader 中可复用的是 Flutter paint 语义：`backgroundImageOpacity` 和背景 overlay
opacity，以及现有 palette/background/text RGB。当前生产模型没有独立持久化并接入
绘制的 `textOpacity`/`ReaderTextOpacity` 字段，不能把设计文档中的字段当成已实现
的桌面文字 alpha。

## 3. Engine checkout、Flutter 版本与 patch

检查结果：

| 项目 | 实际值 |
|---|---|
| Engine checkout | `C:\xaocen-engine\src` |
| Engine HEAD | `69c8c61792f04cc809dfef0c910414fb9afc06cd` |
| Flutter SDK | 3.44.7 stable |
| Framework HEAD | `84fc5cbb223bc12f83d65b647ff8a56caf779ffd` |
| `bin/internal/engine.version` | `69c8c61792f04cc809dfef0c910414fb9afc06cd` |
| Patch manifest framework | `84fc5cbb223` |
| Patch manifest engine | `69c8c61792f04cc809dfef0c910414fb9afc06cd` |

因此 `ENGINE REVISION MATCH = PASS`。

Engine checkout 当前 dirty，状态包括：

- modified：`BUILD.gn`、`egl/manager.cc`、`egl/manager.h`、
  `flutter_windows_engine.cc/.h`、`flutter_windows_view.cc`；
- untracked：`egl/dcomp_window_surface.cc/.h`；
- untracked 实验/恢复目录：`C:\xaocen-engine\src\_bad_scm\...`，父目录
  `C:\xaocen-engine\_bad_scm\src` 也存在。

这些文件均未被本轮触碰。

`windows_engine_patches/` 仍保留 `0001-windows-dcomp-alpha-surface.patch`、
`manifest.json`、`pinned_engine_revision.txt`、`apply.ps1`、`verify.ps1`、
README 与隔离 fixture。manifest 记录：

- `DXGI_FORMAT_B8G8R8A8_UNORM`；
- `DXGI_ALPHA_MODE_PREMULTIPLIED`；
- DComp/D3D11/DXGI libraries；
- `cpuReadback=false`。

Engine worktree 的修改集合与 patch touched-files 对应，故判定
`EXISTING ALPHA PATCH = PRESENT`；但它没有成功的 patched Engine artifact，也没有
生产 Runner 接线，不能判定为集成通过。

另外，`apply.ps1` 对 dirty worktree 的 `_bad_scm` 例外只覆盖特定状态形态；当前
存在嵌套 untracked `_bad_scm/...` 路径。下次重新 apply 应使用 fresh exact checkout
做 verify/apply，不应直接复用此 dirty worktree。

## 4. 之前 alpha patch 的技术边界

现有 patch 只触碰 Windows Engine seam：

```text
shell/platform/windows/BUILD.gn
shell/platform/windows/egl/manager.cc/.h
shell/platform/windows/egl/dcomp_window_surface.cc/.h
shell/platform/windows/flutter_windows_engine.cc/.h
shell/platform/windows/flutter_windows_view.cc
```

目标链路为：

```text
Flutter GPU frame
 → ANGLE/D3D shared texture
 → BGRA8 premultiplied composition swapchain
 → DirectComposition visual/target
 → DWM
```

源码明确没有 CPU readback、每帧 `CopyResource`、`UpdateLayeredWindow`、color key、
桌面截图或 native text overlay，并保留 opaque fallback。但历史 spike 报告同时明确：
patched Engine build blocked，Flutter frame 进入 DComp、Flutter alpha retention、
resize/device-loss、输入/IME/a11y 的运行时验证均未完成。原生 DComp RGBA8/FP16
resource spike 不能替代 Flutter-frame interop gate。

所以当前 `background 0% + text 100%`：

- 对生产 XAOCEN：未实现；
- 对隔离 patch：设计目标存在，但运行时未证明；
- 对原生 DComp spike：只证明 native resource/present 能力，不证明 Flutter frame。

## 5. 最小正式接入边界

### Windows Runner

仅负责标准/无边框模式、能力请求、fallback 状态和窗口生命周期；继续保留 opaque
默认路径。不在 Runner 中复制 Reader layout 或绘制 native text。

### Flutter Windows Engine seam

只在上述八个 Windows 文件内实现 surface factory、shared-handle import、composition
swapchain Present/resize 与失败前回退。不得扩散到 Skia/Impeller common、Dart VM、
framework 或其他平台。

### Dart capability / Reader

Reader Core 只消费 `supportsDesktopReaderTransparency`、fallback reason、
`BackgroundOpacity` 和独立 `TextOpacity`。DComp/Win32 类型留在 platform/Engine
层。当前 text opacity 仍需另行确定存储与 paint-only 合同；不能用整窗 alpha 替代。

## 6. 下一阶段（最多三个独立步骤）

### 8d-2 — Engine environment revalidation

以 exact pinned revision 的 fresh checkout 验证依赖、GN/CIPD bootstrap、vanilla
build/fixture，再 verify/apply patch 并构建 patched Engine。不得以当前 dirty
checkout 直接判定成功；不接 Reader。

出口：`VANILLA_ENGINE_BUILD`、`VANILLA_FIXTURE`、`PATCHED_ENGINE_BUILD`。
任一失败即停止。

### 8d-3 — Flutter alpha-surface interop spike

只用隔离 fixture 验证 RGBA8 premultiplied Flutter frame → ANGLE client buffer →
DComp swapchain，覆盖 first frame、alpha、resize/recreate、DPI、GPU/device loss、
pointer/keyboard/focus/TextField/IME/a11y。远程环境肉眼桌面透出单独记为
`LOCAL VISUAL VALIDATION = DEFERRED`。

出口：可重复的 shared-texture/frame-contract 运行时证据；不接 Reader。

### 8d-4 — XAOCEN capability-gated Reader integration

仅在 8d-3 通过后接入生产。复用 Reader palette/background image 与独立 text paint
alpha；标准窗口关闭桌面透明 UI，无边框按 capability 开放；保留 opaque fallback，
并回归 Locator、Reader Info、Chrome、Tray、Boss Key、DPI/multi-monitor 与性能。

## 7. Stop conditions

若后续需要大范围 fork Flutter、修改 Skia/Impeller common、CPU readback、native
second renderer/layout，或输入/IME/a11y 生命周期不再保持，应立即停止，不用整窗
opacity 伪装成功。

## 最终状态

```text
CURRENT PRODUCTION TRANSPARENCY PATH = opaque Flutter Windows child HWND / ANGLE EGL; no OS desktop transparency
ENGINE CHECKOUT STATUS = exact pinned HEAD, dirty with alpha patch applied; no validated build artifact
ENGINE REVISION MATCH = PASS
EXISTING ALPHA PATCH = PRESENT (applied, build-unverified, not production-integrated)
CURRENT BLOCKER = no validated patched Engine artifact and no runtime Flutter-frame → ANGLE shared texture → DComp proof
MINIMUM INTEGRATION PATH = 8d-2 environment/vanilla+patched build → 8d-3 isolated Flutter interop → 8d-4 Reader integration
```
