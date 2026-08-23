# M5.7s.9c-9 — Windows Tray Menu Localization

正确项目目录：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 实现

Tray 菜单原先在 `windows/runner/win32_window.cpp` 中直接使用英文标签。本轮加入了最小 locale bridge：

`XaocenApp.appLocale` → `WindowsShellHost.localeTag` → `WindowsShellBridge.setTrayLocale` → native `Win32Window::SetTrayLocale`。

当前应用 locale 为 `zh-CN`，Tray 菜单显示：

- `显示窗口`
- `隐藏窗口`
- 分隔线
- `退出 XAOCEN Reader`

native 菜单使用 `AppendMenuW` 和 Unicode 宽字符串。为避免 MSVC 当前代码页 C4819，中文标签以 Unicode code point escape 编译，运行时仍为正确 Unicode 文本。未来 locale 变化时，bridge 可切换到现有英文 fallback，无需改 command ID 或 callback。

## 行为保护

未修改：

- Tray 左键恢复
- 显示/隐藏/退出 command ID 与回调
- clean exit
- TaskbarCreated 自动重注册
- Explorer 重启后的单 Tray owner
- Boss Key / MouseChord / Shortcut / Reader / Transparency

Tray 默认 native locale 为中文，因此即使 Flutter bridge 尚未完成首帧，也不会短暂显示英文菜单。

## Verification

| Gate | Result | Evidence |
|---|---|---|
| TRAY CHINESE MENU | PASS | native labels 已切换为中文，命令结构不变 |
| UNICODE | PASS | `AppendMenuW` + Unicode wide strings；Release 编译通过 |
| SHOW/HIDE REGRESSION | PASS | command IDs/callbacks 未改；全量测试通过 |
| CLEAN EXIT REGRESSION | PASS | Exit command 路径未改；全量测试通过 |
| TASKBAR RECREATE REGRESSION | PASS | `TaskbarCreated` / `AddTrayIcon` 路径未改；全量测试通过 |

已执行：

- `flutter analyze --no-pub` — PASS
- `flutter test --no-pub` — PASS（604 tests）
- `flutter build windows --release` — PASS
- `git diff --check` — PASS（仅既有换行风格提示）

Windows Release：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

本轮未提交 Git commit，也未修改或删除其他用户未提交文件。
