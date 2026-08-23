# M5.7s.9c-6 — Windows Eyedropper Picking UX

## Scope

本轮只修改 Windows 取色模式的即时反馈与清理路径。正确项目目录为：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

未修改 DesktopColorSampler 的采样算法、物理屏幕坐标、RGB/HEX truth、
ReaderPreferences、Android 或其他 Reader 功能。

## Implementation

- `windows/runner/windows_eyedropper_native.*`
  - Picking 开始后使用 Windows `IDC_CROSS` cursor；确认、Esc、右键、窗口销毁和 controller dispose 都走同一个 `Stop()` 清理并恢复 cursor。
  - 增加短生命周期的 topmost、non-activating、hit-test-transparent 原生预览窗口。窗口跟随当前物理鼠标坐标，显示色块、HEX 和操作提示，不抢焦点、不吞掉其他程序输入。
  - 预览窗口由宿主 `WM_TIMER` 在 `startPicking` method-channel 回调返回后创建，避免同步创建窗口导致 native window/Flutter callback 重入崩溃。
  - 预览移动只更新临时采样；确认时才由现有 Dart 目标区分逻辑写入文字色或背景色。
- `windows/runner/CMakeLists.txt`
  - 仅补充原生 GDI 绘制所需的 `gdi32.lib`。

## Root cause found during validation

初版同步调用 `CreatePreviewWindow()` 位于 `startPicking` 的 Flutter platform-channel 回调内部。Windows Release 实测点击吸管后进程退出，Application Error 指向 `flutter_windows.dll` callback exception。将预览窗口创建推迟到 owner timer（回调返回后）后，Release 进程稳定，跨应用取色恢复正常。

## Validation

| Contract | Result | Evidence |
|---|---|---|
| PICKING CURSOR | PASS | Native `IDC_CROSS` 设置、timer/mouse-move 维持、统一 Stop 恢复；Release 实测进入/退出 10 次无残留状态。|
| FLOATING PREVIEW | PASS | Notepad 跨应用实测可见 topmost 预览浮层；不激活、不拦截底层窗口。|
| LIVE COLOR PREVIEW | PASS | 33 ms owner timer 持续采样并更新色块/HEX；移动到 Notepad 后预览仍更新。|
| CONFIRM | PASS | 在 Notepad 白色区域左键确认，XAOCEN 返回且文字色更新为采样值；只触发一次。|
| CANCEL | PASS | Esc 与右键均取消且原色不变；浮层/临时监听清理。|
| LISTENER CLEANUP | PASS | Native hooks/timer/preview window 在 Stop；Dart controller dispose 保持原有清理路径；重复进入/退出 10 次通过。|
| SAMPLER REGRESSION | PASS | 既有 `desktop_color_sampler_test.dart` 通过；采样算法和 physical coordinate 未改。|

### Commands

- `flutter analyze --no-pub` — PASS, no issues
- `flutter test --no-pub` — PASS, **603 tests passed**
- `flutter build windows --release` — PASS
- `git diff --check` — PASS（仅已有 CRLF normalization warnings）

Release 产物：

`C:\Users\TOM\Desktop\xaocen-reader-v4\aocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

## Manual/remote note

本机 Windows 远程控制已验证：XAOCEN → 吸管 → Notepad 的跨应用浮层、左键确认、Esc/右键取消、重复清理和进程稳定性。Sky 截图不包含系统鼠标指针的独立光标层，因此 cursor 的具体光栅外观仍以本地桌面人工目视为最终验收；native cursor contract 已由 Release build 和实际状态转换覆盖。

## Protected baseline

未修改 DesktopColorSampler sampling algorithm、DPI physical coordinate conversion、ReaderPreferences、Reader Theme、Android、Tray、Shortcut、Metadata 或 Transparency。
