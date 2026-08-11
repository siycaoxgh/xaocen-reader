# M5.7 Cross-Platform Foundation — Desktop Transparency Product Contract

日期：2026-08-12  
基线 HEAD：`e6fdb0ec900dd9e4d3e252ba068cc9aef1f4b24d`  
Drift schema：12

本文件是对 `M5_7_PLATFORM_RENDERING_PACKAGING_ANALYSIS.md` 的产品层修正与跨平台扩展。它只定义能力边界和后续架构方向，不修改 Reader engine、数据库或任何平台实现。

## 1. 正式产品边界

“桌面背景透明”不是全平台统一能力，而是 **Desktop Reader 专属能力**。

### 支持 Desktop Transparency 的目标平台

- Windows
- macOS
- Linux
- HarmonyOS PC / Desktop（未来独立适配）

### 不提供 Desktop Transparency 的平台

- Android
- iOS

Android 与 iOS 仍提供普通 Reader 外观能力：Palette、背景色、背景图片、遮罩、字体颜色，以及产品保留时的正文文字透明度；但不透出系统桌面，也不显示 Desktop compositor 相关设置。

移动端不应显示以下项目：

- 窗口背景透明度
- 透出桌面
- Desktop Reader Transparency
- Desktop compositor/backend 调试或能力设置

不支持的平台应隐藏相关 UI，而不是显示一个无法工作的 disabled slider。

## 2. 统一 Reader Appearance 语义

Reader Core 只定义与绘制语义有关的值：

```text
ReaderBackgroundOpacity  // 0%..100%，Reader 背景 paint alpha
ReaderTextOpacity        // 0%..100%，正文 text alpha，RGB 不变
PlatformCapability       // 当前平台是否支持桌面透出
```

其中：

```text
supportsDesktopReaderTransparency: bool
```

是平台能力，不是每本书的位置、分页或主题真源。

核心层不能把 `backgroundOpacity = 0` 解释成“必然透出操作系统桌面”。它只表示 Reader 背景 paint 可以为透明；是否继续透出到 OS desktop/background content，由平台 adapter 的 capability 和 renderer 决定。

## 3. Desktop 端合同

Windows、macOS、Linux、HarmonyOS Desktop 在 capability 为 true 时遵守同一产品合同：

- Background Opacity：0%–100%
- Text Opacity：0%–100%
- 两者完全独立
- 必须允许 `Background = 0% + Text = 100%`
- 此状态下 OS desktop/background content 完全透出，Reader 正文保持完全不透明
- Text opacity 只改变 alpha，不改变字体 RGB、metrics、layout、Locator 或 pagination truth
- Background opacity 不应改变文字 alpha

如果平台 capability 为 false，Reader 仍可保留背景 paint alpha 的安全 fallback（例如回到不透明窗口背景），但不能把它标记为 Desktop Transparency，也不能让 UI 暗示桌面一定可见。

## 4. 平台 Adapter / Renderer 边界

统一架构为：

```text
Reader Core
  ├─ BackgroundOpacity / TextOpacity
  ├─ Palette / image background
  └─ PlatformCapability contract
       ↓
Platform Desktop Adapter
  ├─ supportsDesktopReaderTransparency
  ├─ applyReaderSurfaceAlpha(...)
  └─ capability/fallback diagnostics
       ↓
Platform Renderer / compositor backend
```

Reader Core 不认识 DirectComposition、NSWindow、X11、Wayland、Metal 或 HarmonyOS native compositor 名称。各平台 adapter 负责将 Reader surface 与本机 compositor 连接，并在不可用时报告 capability false / fallback。

这样可以保持：

- Locator、PageWindow、AutoRead、ReadingSession 与平台透明实现完全解耦；
- Reader appearance 语义可跨端复用；
- 平台 renderer 可以独立演进，不将 Windows API 污染 Core。

## 5. Windows

Windows 继续沿用 M5.7 审计确定的研究路线：

- DirectComposition visual tree；
- alpha-capable composition swapchain；
- premultiplied alpha；
- 未来以 FP16/scRGB 兼容 HDR/Advanced Color；
- 标准带边框窗口可禁用 Desktop Transparency，优先在 borderless Reader mode 开放。

Windows 专属实现只能位于：

```text
platform/windows/
windows/runner/
Windows compositor adapter
```

不得在 `Reader Core`、PagedLayoutEngine、ReaderLocator、ReaderPreferences domain 中加入 DirectComposition 类型或 Windows-specific branch。

## 6. macOS

macOS 未来使用本机能力独立实现：

- `NSWindow`/window backing configuration；
- Metal/CA compositor surface；
- macOS 自己的 alpha、display capability 与 fallback 检测。

不得为了与 Windows 复用而引入 DirectComposition 概念。共享的只能是 capability contract、opacity 语义与测试合同；renderer/backend 必须保持平台原生。

## 7. Linux

Linux 必须运行时 capability-based：

- X11 与 Wayland 不假定透明语义相同；
- 具体 compositor、窗口类型、GPU backend 可能改变 per-pixel alpha 行为；
- adapter 启动时或窗口 backend 确认后返回 capability；
- 支持则开放 0%–100% Background Opacity；不支持则隐藏桌面透明设置并使用普通 Reader 背景 fallback；
- 不允许仅凭“Linux”平台名推断透明可用。

## 8. HarmonyOS PC / Desktop

HarmonyOS Desktop 是未来独立 Desktop Platform Adapter。产品合同要求其最终支持 Desktop Transparency，但当前不能假定 Windows、macOS 或 Linux 实现可以直接复用。

当前只保留：

- `supportsDesktopReaderTransparency` capability 接口；
- 平台 renderer abstraction；
- opacity 独立性和 `Background=0% + Text=100%` 验收合同；
- capability false 时的隐藏/fallback 行为。

HarmonyOS native compositor、窗口 API、DPI/HDR 适配在独立平台 milestone 中研究，不在本轮推断。

## 9. Android / iOS 行为

Android 与 iOS 的 Reader Appearance 仍可包含：

- Palette、背景色、背景图片、遮罩；
- ReaderBackgroundOpacity 作为 Reader paint 语义（如保留）；
- ReaderTextOpacity 作为独立文字 alpha（如产品保留）。

但两端均不得：

- 将 Reader 背景 alpha 连接到 OS desktop transparency；
- 暴露窗口背景透明度或 Desktop compositor 设置；
- 为 Desktop Transparency 修改 Android/iOS rendering pipeline；
- 用 disabled slider 暗示未来能力已可用。

Android/iOS 的 system bars、cutout、safe area 仍按各自平台 UI 合同处理，与桌面窗口透出是不同能力。

## 10. 数据与持久化边界

本修正不要求 schema 变化。现有 per-book Reader appearance 数据可以继续保存 Reader 的颜色、图片引用和 opacity；平台 capability 是运行时派生值，不应为每个平台重复存储一套“是否支持透明”。

建议 resolver 形态：

```text
ReaderAppearanceResolver(
  preferences,
  effectivePalette,
  platformCapability,
) -> ResolvedReaderAppearance
```

`ResolvedReaderAppearance` 应明确区分：

- Reader background paint alpha；
- Reader text paint alpha；
- desktop surface alpha request（仅当 capability 为 true 时产生）；
- fallback/reason（unsupported、backend unavailable、standard window 等）。

任何 opacity 变化仍属于 paint/compositor presentation 层，不得成为 ReaderLocator、pageIndex、scrollPixels 或 ReadingSession 数据。

## 11. 后续 milestone 规划

1. **Cross-platform capability contract**：定义 `DesktopReaderTransparencyCapability`、fallback reason 和测试 doubles，不接真实 native compositor。
2. **Windows adapter**：在 `platform/windows` 隔离 DirectComposition/alpha swapchain spike；完成 `Background=0% + Text=100%`、resize、DPI、multi-monitor、tray/Boss Key、截图和性能验证。
3. **macOS adapter**：以 NSWindow/Metal/本机 compositor 独立实现，复用 Core contract，不复用 Windows native code。
4. **Linux adapter**：分别验证 X11/Wayland/compositor capability，支持则开放，不支持则隐藏并 fallback。
5. **HarmonyOS Desktop adapter**：单独评估 native compositor 和平台生命周期。
6. **Mobile appearance audit**：只验证普通 Palette/background/text opacity 与 safe-area，不加入 desktop transparency。

## 12. 最终产品决策

```text
DesktopReaderTransparency
  ≠ WindowsTransparency

DesktopReaderTransparency
  = Reader appearance semantics
  + platform capability
  + platform-specific renderer/backend
```

Reader Core 只认识 `BackgroundOpacity`、`TextOpacity` 和 `PlatformCapability`；桌面透出完全由 Windows、macOS、Linux、HarmonyOS Desktop 各自实现。Android/iOS 永远不显示 Desktop Transparency 设置，也不因该能力改变其 rendering pipeline。

本文件只完成产品合同修正和后续规划；本轮未改代码、未升级 schema、未进入 TTS/EPUB/RSS。
