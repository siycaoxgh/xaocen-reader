# M5.7s.8d-4-2 — Reader True Transparency Production Path

日期：2026-08-14
项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
Patched Engine：`C:\xaocen-engine\src`

## 范围与实现

本轮只接入已验证的 Windows alpha render path，不增加透明度设置 UI，不修改 ReaderPreferences schema，不进入 8d-4-3/8d-4-4。

```text
Flutter/ANGLE → app-owned B8G8R8A8 texture
→ GPU CopyResource → premultiplied DirectComposition swapchain → Present
```

错误的 `composition swapchain backbuffer → CreateSharedHandle` 路径没有重新使用。Patched Engine 失败时回退官方 opaque ANGLE surface；没有使用 `SetLayeredWindowAttributes` 做整窗透明。

Windows Runner 只有在 `FLUTTER_ENGINE_SWITCH_* = enable-windows-alpha-surface` 时，才在顶层 HWND 创建时加入 `WS_EX_NOREDIRECTIONBITMAP`。普通 Standard 启动不改变。临时验证 seam `XAOCEN_TRUE_TRANSPARENCY_TEST` 只在 Windows 生效、非持久化：`100`=alpha 1.0，`0.5`=alpha 0.5，`0`/`1`=alpha 0；foreground/text 始终保持现有 opaque paint。

根因：之前只在 Engine 创建 surface 之后对 Flutter child HWND/或 root HWND 尝试补设 `WS_EX_NOREDIRECTIONBITMAP`，DWM 已经可能建立 opaque redirection bitmap，因此客户区仍是白/黑不透明块。现在把同一标志前移到 Runner 的顶层 HWND 创建时，DComp surface 才能成为唯一客户区 owner。

## 前置 Gate

来源：`M5_7S_8D_3R_2_DCOMP_INTEROP_PATH.md`、`M5_7S_8D_4_1_PATCHED_ENGINE_PRODUCTION_WIRING.md`、`docs\PRODUCT_BASELINE_FREEZE.md`。

```text
ENGINE REVISION MATCH = PASS       69c8c61792f04cc809dfef0c910414fb9afc06cd
PATCHED ENGINE BUILD = PASS
PATCHED ARTIFACT = VALID
ANGLE → D3D TEXTURE = PASS
D3D TEXTURE → DCOMP = PASS
BG 0 / FG 100 (fixture) = PASS
STANDARD ENGINE BUILD = PASS
STANDARD FALLBACK = PASS
```

## 构建证据

```powershell
cd C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader
.\tool\build_windows_engine.ps1 -Engine Patched -Configuration Debug
```

```text
PATCHED ENGINE REBUILD = PASS
PATCHED XAOCEN BUILD = PASS
PATCHED DLL SOURCE = C:\xaocen-engine\src\engine\src\out\host_debug_unopt\flutter_windows.dll
PATCHED DLL SHA-256 = BC84EF1849EC9852348C548E3566EAF85093BF4E70577CBAA4708D28F84581DB
PATCHED STAGED OUTPUT = C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\patched\Debug
```

```powershell
cd C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader
.\tool\build_windows_engine.ps1 -Engine Standard
```

```text
STANDARD ENGINE BUILD = PASS
STANDARD BUILD OUTPUT = C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\standard\Release
STANDARD LAUNCH = PASS
STANDARD READER SMOKE = PASS
STANDARD FALLBACK = PASS
```

真实 Patched Debug 实例启动并打开已有 TXT Reader；顶层 ex-style 实测为 `0x240100`（含 `WS_EX_NOREDIRECTIONBITMAP`）。Standard 实例为 `0x40100`（不含该标志）。

## 真实 XAOCEN 视觉 Gate

以下均来自 `artifacts\windows\patched\Debug\xaocen_reader.exe` 的真实 Reader，不是 fixture：

- [XAOCEN_BG100_FG100.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/XAOCEN_BG100_FG100.png)
- [XAOCEN_BG50_FG100.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/XAOCEN_BG50_FG100.png)
- [XAOCEN_BG0_FG100.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/XAOCEN_BG0_FG100.png)

BG0 截图中 Reader 客户区能看到后方桌面/其他窗口内容，而正文仍由 Flutter 前景绘制；BG50 同样能看到后方内容；BG100 为不透明背景。

```text
TRUE TRANSPARENCY CAPABILITY = PASS        (真实 BG0 截图)
BG 100 / FG 100 = PASS
BG 50 / FG 100 = PASS
BG 0 / FG 100 = PASS
FOREGROUND OPAQUE = PASS
DARK TRANSPARENCY = PASS
VERTICAL TRANSPARENCY = PASS
```

以下本轮没有足够的真实证据，不能伪造 PASS：

```text
LIGHT TRANSPARENCY = MANUAL REQUIRED
PAGED TRANSPARENCY = MANUAL REQUIRED
LOCATOR REGRESSION = MANUAL REQUIRED
```

分页设置按钮视觉上可切换，但返回 Reader 后仍显示滚动模式；这是已有模式切换验证阻塞，本轮没有改动 Reader 模式逻辑，因此没有把 Paged 透明性或 locator 精确误差写成 PASS。

## 回归与保护

- Standard Engine 不运行 DComp alpha path，保持 opaque Reader。
- 未修改 TXT normalized content、chapter parser、pagination、ReaderProgress、Metadata、Cover、Font、Tray、Shortcut、MouseChord、Eyedropper、Android 或 Reader geometry。
- 当前没有把 capability 暴露为 Dart 产品状态；真实运行能力由截图证明，Dart capability signal 留待后续独立任务。

```text
flutter analyze --no-pub = PASS
flutter test --no-pub = PASS (604 tests)
Patched Windows Debug build = PASS
Standard Windows Release build = PASS
git diff --check = PASS (仅已有 LF/CRLF warnings)
```

## 最终状态

```text
PATCHED ENGINE REBUILD = PASS
PATCHED XAOCEN BUILD = PASS
PATCHED REAL LAUNCH = PASS
TRUE TRANSPARENCY CAPABILITY = PASS
VERTICAL TRANSPARENCY = PASS
PAGED TRANSPARENCY = MANUAL REQUIRED
LIGHT TRANSPARENCY = MANUAL REQUIRED
DARK TRANSPARENCY = PASS
BG 100 / FG 100 = PASS
BG 50 / FG 100 = PASS
BG 0 / FG 100 = PASS
FOREGROUND OPAQUE = PASS
STANDARD ENGINE BUILD = PASS
STANDARD ENGINE LAUNCH = PASS
STANDARD FALLBACK = PASS
LOCATOR REGRESSION = MANUAL REQUIRED
```

本轮到此停止，不进入 `M5.7s.8d-4-3 Background Transparency UI` 或 `M5.7s.8d-4-4 Foreground Transparency UI`。
