# M5.7s.9c-7 — Windows Shortcut Support Truth + Static Keyboard Guide

## Scope

本轮只处理 Windows 快捷键能力真值、未支持按键反馈和静态键盘说明入口。未修改 Reader 导航、MouseChord、Boss 命令、Tray、Eyedropper、字体、Metadata、Reader Theme 或 Android 行为。

正确项目根目录：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 实现结果

### SupportedShortcutKeyRegistry

`SupportedShortcutKeyRegistry` 现在是新快捷键录入与帮助文案共同使用的唯一能力真值：

- 字母 A-Z
- 主键盘数字 0-9
- F1-F12
- Arrow、PageUp、PageDown、Home、End
- Space、Enter
- Numpad 0-9
- Numpad +、-、*、/（Numpad Enter 继续复用既有 Enter identity）
- Ctrl / Alt / Shift 作为修饰键组合，仍由既有捕获逻辑读取

常用 OEM/标点键（`-`、`=`、`[`、`]`、`\\`、`;`、`'`、`` ` ``、`,`、`.`、`/`）仍可被底层事件映射，但本轮不再进入“已验证支持”集合，避免把只有 KeyEvent 到达、却没有完整 Capture → Save → Runtime Trigger 证据的键展示为可用。

鼠标中键以及左右键同时按下是独立鼠标输入，不进入 Keyboard Registry。LMB+RMB 继续使用现有 MouseChord。

### Capture feedback

Windows 老板键捕获与 Reader 快捷键捕获都改为只接受物理键 Registry：

- 不再从逻辑键回退接受不可靠按键；
- 不支持的键不保存，保持 capture 状态；
- 统一提示：`该按键暂不支持作为 XAOCEN 快捷键`；
- Esc 仍取消当前捕获；
- KeyRepeat/KeyUp 不会重复保存。

### Static guide

用户提供的静态说明图已复制为正式资源：

`assets/shortcuts/xc-jpkjjsyt.png`

并登记到 `pubspec.yaml`。设置中的“查看支持的按键”入口打开响应式 Dialog，显示原始比例图片、当前 Registry 支持类别、鼠标手势说明和不支持按键提示。图片只用于帮助说明，不参与运行时判断；小窗口使用 `BoxFit.contain` 和纵向滚动，不依赖用户桌面路径。

## 实际支持类别

`SUPPORTED KEY CATEGORIES =`

字母 A-Z；主键盘数字 0-9；F1-F12；Arrow / PageUp / PageDown / Home / End / Space / Enter；Numpad 数字与四则运算；Ctrl / Alt / Shift 组合。

`UNSUPPORTED / RESERVED KEY CATEGORIES =`

当前未完成完整 Capture → Save → Runtime Trigger 证明的常用 OEM/标点键；单独修饰键；未映射或系统保留键；鼠标手势（鼠标手势不是 Keyboard Shortcut）。

## Verification

| Gate | Result | Evidence |
|---|---|---|
| SUPPORTED REGISTRY TRUTH | PASS | Registry 只暴露已验证类别；OEM/标点被拒绝；定向 Registry 测试通过 |
| UNSUPPORTED KEY FEEDBACK | PASS | 两个 Windows 捕获入口统一提示且不保存；不支持键定向测试通过 |
| STATIC KEYBOARD GUIDE | PASS | 正式 asset、Dialog 入口、说明文案和图片加载测试通过 |
| RESPONSIVE IMAGE | PASS | 360 / 800 宽度 Widget 测试无异常，保持原始比例并可滚动 |
| PAGEUP/PAGEDOWN REGRESSION | PASS | 全量 Flutter tests 通过 |
| NUMPAD REGRESSION | PASS | 全量 Flutter tests 通过 |
| BOSS KEY REGRESSION | PASS | 本轮未修改 Boss runtime；全量 Flutter tests 通过 |
| MOUSE CHORD REGRESSION | PASS | 本轮未修改 MouseChord；全量 Flutter tests 通过 |

已执行：

- `flutter analyze --no-pub` — PASS
- `flutter test --no-pub` — PASS（604 tests）
- `flutter build windows --release` — PASS
- `git diff --check` — PASS（仅已有工作区的换行风格提示）

Windows Release 产物：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

本轮未提交 Git commit，保留工作区中用户已有的其他未提交文件。
