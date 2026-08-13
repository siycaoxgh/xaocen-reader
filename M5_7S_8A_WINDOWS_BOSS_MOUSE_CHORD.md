# M5.7s.8a — Windows Boss Mouse Chord Fix

基线：`6a6594dbed191e00ba840cd9cb91017bac027904`

## 根因

`WindowsBossKeyGesture` 本身已经把 `mouseChord` 与 `keyboard` 分成不同的 JSON/类型分支；源码中没有把鼠标事件主动转换为 `V`。问题出在输入捕获边界：老板键设置页只在 `PointerDown` 采样当前按钮状态，顺序双键或部分 Windows pointing driver 事件无法建立完整的鼠标 chord 状态，随后同一捕获焦点仍可把合成的 `LogicalKeyboardKey.keyV` 当作键盘候选。运行时 tracker 还复用了一个 `_triggered` 门闩，键盘与鼠标状态可能互相污染。

因此表现为“LMB+RMB 显示成 V”，而不是产品合同要求的独立鼠标手势。

## 修复

- `BossKeyTracker` 分离 `_mouseTriggered` 与 `_keyboardTriggered`，鼠标释放周期和键盘释放周期互不影响。
- tracker 支持注入时钟，严格使用 250ms chord window；LMB→RMB、RMB→LMB 均可触发，每个完整 press cycle 只触发一次，双键全部释放后才能再次触发。
- 鼠标按键状态期间，键盘 tracker/capture 明确拒绝合成键，鼠标 chord 不可能写入 `WindowsShellKey.keyV` 或 Reader keyboard binding。
- Windows shell host 与老板键捕获面板只处理真实鼠标设备，并监听 down/move/up/cancel，保持普通单击、右键、拖动及键盘 V 合同。
- 未修改 Android、Reader 导航、Reader UI、Tray native 实现或 schema。

## 定向验证

- 键盘 V gesture 独立保持、一次按下只触发一次，释放后可再次触发。
- LMB-only/RMB-only 不触发 Boss。
- LMB→RMB、RMB→LMB 各触发一次。
- 长按不重复，释放后可重新触发。
- 超过 250ms 的组合不触发。
- 鼠标 gesture JSON 类型为 `mouseChord`，无 primary keyboard key，不会表示为 V。

## 验收状态

`KEYBOARD BOSS = PASS`（Dart contract/unit coverage；Windows 实机按键仍建议人工复核）

`LMB+RMB CHORD = PASS`（Dart contract/unit coverage；Windows 实机鼠标仍建议人工复核）

`MOUSE→V FALSE MAPPING = FIXED`

Windows Release、Windows integration 与人工 A–E 操作清单应在本阶段构建完成后复核；Android 本阶段只执行 build smoke，不安装、不修改设备数据。
