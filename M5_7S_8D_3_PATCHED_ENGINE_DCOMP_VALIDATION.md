# M5.7s.8d-3 — Patched Windows Engine Build + DComp Validation

日期：2026-08-14
范围：仅 `C:\xaocen-engine\src` 的 patched Flutter Engine 与隔离 DComp 证据。
XAOCEN Reader、生产 Runner、Dart UI、Reader Theme、Tray/Input/Eyedropper、Android 均未修改。

## 最终 Gate

```text
PATCH COMPILED = FAIL
PATCHED ENGINE BUILD = FAIL
DCOMP PROTOTYPE = FAIL
BG 0 / FG 100 = FAIL
PREMULTIPLIED ALPHA = FAIL
```

这里的 `FAIL` 表示本轮没有完成可验证的 patched Engine/Flutter-frame artifact，
不是观察到了错误的 alpha 画面。没有把旧 DLL、静态 patch 或早期 native spike
结果冒充本轮通过。

## 1. 前置 Gate

已读取 `M5_7S_8D_2_ENGINE_BUILD_CHAIN.md`：

- `ENGINE REVISION MATCH = PASS`；
- `DEPOT_TOOLS = PASS`；
- `VPYTHON = PASS`；
- `CIPD = PASS`；
- `GN GEN = PASS`。

因此允许进入本轮；Engine HEAD 仍为
`69c8c61792f04cc809dfef0c910414fb9afc06cd`。

## 2. Build graph 与 patched files

配置目录：

`C:\xaocen-engine\src\engine\src\out\host_debug_unopt`

检查到：

- `args.gn`：`host_os="win"`、`host_cpu="x64"`、`target_os="win"`、
  `target_cpu="x64"`、`is_debug=true`；
- `build.ninja`：347208 bytes，由 8d-2 的成功 `gn gen` 生成；
- 目标名：`flutter_windows`（phony，最终对应 `flutter_windows.dll.lib`）。

Ninja graph 明确包含 patched 文件：

```text
obj/flutter/shell/platform/windows/egl/flutter_windows_source.dcomp_window_surface.obj
obj/flutter/shell/platform/windows/flutter_windows_source.flutter_windows_engine.obj
obj/flutter/shell/platform/windows/flutter_windows_source.flutter_windows_view.obj
obj/flutter/shell/platform/windows/flutter_windows_source.manager.obj
```

PATCHED FILES：

```text
engine/src/flutter/shell/platform/windows/BUILD.gn
engine/src/flutter/shell/platform/windows/egl/dcomp_window_surface.cc
engine/src/flutter/shell/platform/windows/egl/dcomp_window_surface.h
engine/src/flutter/shell/platform/windows/egl/manager.cc
engine/src/flutter/shell/platform/windows/egl/manager.h
engine/src/flutter/shell/platform/windows/flutter_windows_engine.cc
engine/src/flutter/shell/platform/windows/flutter_windows_engine.h
engine/src/flutter/shell/platform/windows/flutter_windows_view.cc
```

PATCHED TARGETS：

```text
flutter_windows
flutter/shell/platform/windows:flutter_windows_source
obj/.../flutter_windows_source.dcomp_window_surface.obj
```

结论：patch **进入 build graph**；但进入 graph 不等于已编译/链接成功。

## 3. 受控编译记录

### 尝试 A：Windows embedder target

命令：

```powershell
ninja -C C:\xaocen-engine\src\engine\src\out\host_debug_unopt flutter_windows -j8
```

结果：Ninja 持续编译现有 out 中的大量 Dart VM、ANGLE、SwiftShader 和 Vulkan
依赖；在受控观察窗口内没有出现 compiler/linker error，但没有到达 patched
Windows surface 对象或最终 DLL 链接阶段。为避免把 `flutter_windows` 目标扩张成
不受控的完整 Engine rebuild，已停止 Ninja。

### 尝试 B：patched surface 单对象 target

命令：

```powershell
ninja -C C:\xaocen-engine\src\engine\src\out\host_debug_unopt \
  obj/flutter/shell/platform/windows/egl/flutter_windows_source.dcomp_window_surface.obj -j8
```

结果相同：该对象的依赖链仍递归进入大量未完成的 Engine 依赖，观察窗口内没有
真实编译错误；在生成 `dcomp_window_surface.obj` 前已安全停止。

因此：

```text
FAILED TARGET = no compiler-failed target observed; build remained incomplete
FAILED COMMAND = the two commands above were controlled/stopped before completion
FIRST REAL ERROR = none observed; this is an incomplete build, not a hidden compile PASS
```

现有 `flutter_windows.dll`、`.lib`、`.pdb` 的时间戳早于本轮尝试，不能作为本轮
patched build artifact；本轮新目标的
`obj/flutter/shell/platform/windows/egl/flutter_windows_source.dcomp_window_surface.obj`
不存在。

## 4. Patch 编译判定

PATCH COMPILED = **FAIL**。

原因是 patched `dcomp_window_surface.cc` 没有生成本轮可归属的 object，patched
engine 也没有重新链接。静态源码仍包含：

- `DXGI_FORMAT_B8G8R8A8_UNORM`；
- `DXGI_ALPHA_MODE_PREMULTIPLIED`；
- `CreateSwapChainForComposition`；
- ANGLE D3D shared-handle client-buffer import；
- DirectComposition target/visual；
- opaque fallback。

这些只能说明设计/源代码范围，不能替代编译结果。

## 5. DComp / alpha 验证

本轮要求的隔离 fixture 截图：

```text
alpha_000.png
alpha_025.png
alpha_050.png
alpha_075.png
alpha_100.png
foreground_100_background_000.png
```

在正确 XAOCEN 仓库中没有发现本轮由 patched Engine 生成的这些截图。隔离 fixture
目录仍存在，但它的旧构建产物使用旧时间戳的 opaque Flutter DLL；不能将其截图或
旧产物标成 patched Engine 证据。

因此本轮没有可靠验证：

- Windows 桌面/后方窗口真实透出；
- foreground/text alpha 保持 100%；
- BG=0 / FG=100 frame contract；
- premultiplied alpha 的黑边、halo、灰背景或 alpha 反转行为；
- patched Flutter frame → ANGLE EGL client buffer → DComp swapchain；
- resize/recreate、pointer/keyboard/focus/IME 链路。

早期 M5.7b native DComp spike 的 RGBA8/FP16 resource/present 结果仍只属于 native
资源实验；此前报告已经将 Flutter-frame interop 标为 NOT VERIFIED，本轮不重复
提升其结论。

## 6. 保护项

- 未修改 XAOCEN 正确项目目录中的生产代码；
- 未修改 Engine source/patch/_bad_scm；
- 未 `git reset`、`git clean` 或删除任何用户文件；
- 没有使用整窗 opacity、`SetLayeredWindowAttributes`、CPU readback、
  `UpdateLayeredWindow`、color key、desktop screenshot 或 native text renderer；
- 没有接入 Reader，也没有进入 M5.7c.2。

## 7. 下一步阻断

当前唯一阻断从 `gn gen` 转为：现有 out 的 `flutter_windows` target 依赖链过大，
且尚未获得可归属的 patched object/DLL。下一步应在用户确认后，建立或复用一个
完整且已缓存的 pinned Engine build 环境，先让 vanilla/patched target 完成增量
编译，再重新运行隔离 fixture。不要把旧 DLL 当作 patched artifact，也不要扩大到
Reader integration。
