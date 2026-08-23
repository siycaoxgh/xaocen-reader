# M5.7s.8d-4-4 — Windows Foreground Transparency UI

状态：**STOP — 前置 Gate 未通过**
正确项目目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
Engine checkout：`C:\xaocen-engine\src`

## 前置 Gate

已读取 `M5_7S_8D_4_3_BACKGROUND_TRANSPARENCY_UI.md`。该报告中的前几行是产品
要求示例，实际 Gate 结果在其后明确为：

```text
BACKGROUND TRANSPARENCY UI = NOT-RUN
BG 0 / FG 100 = NOT-RUN
STANDARD ENGINE FALLBACK = NOT-RUN
```

本轮要求的三个前置条件没有全部 PASS，因此不得增加 Foreground Transparency
UI 或 `foregroundOpacity` 持久化字段。

## 输出结论

```text
FOREGROUND TRANSPARENCY UI = NOT-RUN
BG/FG INDEPENDENCE = NOT-RUN
BG 0 / FG 100 = NOT-RUN
PAINT-ONLY / LOCATOR = NOT-RUN
PERSISTENCE = NOT-RUN
STANDARD ENGINE FALLBACK = NOT-RUN
```

## 本轮未执行

- 未增加 Windows 前景/文字透明度 Slider；
- 未修改 ReaderPreferences 或 schema；
- 未实现 `foregroundOpacity` 持久化；
- 未改变文字、TopInfo、BottomInfo、图标或 Divider 的 alpha；
- 未修改 Background Alpha 实现、patched Engine 或 DComp 路径；
- 未执行 BG/FG 组合验证（0/100、0/50、50/100、50/50）；
- 未构建 Windows Patched Release 或 Standard fallback；
- 未运行 Flutter analyze、全量 tests 或 Windows build；
- 未修改 Reader geometry、Locator、pagination、Theme、Eyedropper、Tray、Boss、
  Shortcut 或 Android。

## 阻断原因

8d-3 未生成可归属的 patched Engine object/DLL，8d-4-1、8d-4-2、8d-4-3 因而都
没有完成 Engine revision guard、Standard fallback 及真实 Flutter frame → ANGLE
shared texture → DComp 的证明。没有可靠的独立背景 alpha 路径时接入前景 alpha，
无法证明：

- 背景和前景不会被整窗 alpha 绑在一起；
- `BG 0% + FG 100%` 仍可透出桌面且文字保持不透明；
- 前景设置是 paint-only，不改变 Locator/metrics；
- Standard Engine 不会崩溃或偷偷退化成 whole-window opacity。

## 继续条件

只有以下条件全部通过，才可重新进入本任务：

1. `BACKGROUND TRANSPARENCY UI = PASS`；
2. `BG 0 / FG 100 = PASS`；
3. `STANDARD ENGINE FALLBACK = PASS`；
4. Patched artifact revision guard 通过且来源可追踪；
5. 背景/前景独立 alpha 已在 Windows fixture 中得到截图与运行时证据。

本轮未修改生产代码或用户已有文件，未开始 Foreground Transparency UI，现已停止。
