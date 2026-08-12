# M5.7s.3 Reader Interaction Polish

状态：完成自动化回归，等待人工 Windows/Android 体验验收。M5.7 仍保持 `REOPENED`；Windows Engine/DComp/alpha integration 继续暂停。

## 本轮修正

### 翻页与 Chrome

- PageUp/PageDown、方向键、鼠标滚轮、Volume 以及章节导航只执行 Reader navigation。
- 这些路径只会在 AutoRead running 时 pause(manualNavigation)，不会显示、切换或重置 Chrome。
- PagedReaderView 仅在真实拖拽产生 ScrollUpdate 后通知手动导航；中央点击不会触发导航通知或 AutoRead pause。
- Chrome 的显示/隐藏仍只由用户中央点击及显式面板操作负责。

### Windows 输入绑定

稳定 registry 新增并接通：

- 主键盘 A-Z、0-9
- Numpad 0-9（与主键盘数字保持不同 ID）
- Numpad +、-、*、/
- F1-F12
- 原有 Arrow、PageUp/PageDown、Home/End、Space、Enter、wheel

捕获、JSON repository、profile hot reload 和 ReaderInputRouter 继续使用同一 `ReaderInputGesture`/`PhysicalInputId` 链路，未保存 Flutter runtime key 对象。

### AutoRead 速度

- Vertical canonical velocity：2–100 px/s，1 px/s 步进；预设为 2/10/25/50/100（极慢/慢/中/快/极快）。
- Paged canonical interval：5–120 秒/页，1 秒步进；预设为 120/60/30/15/5 秒。
- 滑杆实时更新 driver；repository 写入使用 250ms debounce，并在 Reader dispose 时刷入最后待写值。
- 旧 v1 preset 迁移保留原有效速度：18/28/40/56/76，不清除已有用户设置。
- UI 状态显示实际数值和单位，不把 preset 与 canonical value 作为两个真源。

### 阅读外观与字体预览

- 文本色、背景色均提供预览色块和统一“取色”入口。
- Picker 支持可视 HSV 调节、`#RRGGBB`、`rgb(r,g,b)`、当前预览、确认/取消及恢复方案默认色。
- 颜色选择仍是 paint-only；低对比只警告，不替换用户选择。
- 字体预览卡片使用 `width: double.infinity`，随设置内容区从 360 到桌面宽度响应。

### Reader 信息栏分隔线

生产 Reader 使用固定布局：

`TopInfoRegion → TopDivider → ReaderBody → BottomDivider → BottomInfoRegion`

- 顶部、底部分隔线独立控制。
- 线条为 1 physical pixel；关闭时仅改为透明色，不改变区域和正文 geometry。
- SafeArea/system inset 仍由 ReaderInfoScaffold 处理。

## 数据与 schema

Drift schema 从 12 正规升级到 13：

- `reader_preferences.show_top_info_divider`
- `reader_preferences.show_bottom_info_divider`

旧 `show_info_divider` 在 migration 中复制到上下两项，已有书籍的显示选择不丢失；ReaderLocator、reading_progress、ReaderPreferences 位置合同、PageWindow、AutoRead driver、ReadingSession 均未改变。新增字段不保存 pageIndex、scrollPixels 或任何位置真源。

## 验证

- `flutter analyze`：PASS
- 全量 Flutter tests：PASS，527 tests
- Windows integration：PASS，全部 11 个 integration 场景
- 真实语料：4 个 TXT；章节、无章节 7.68MB、分页/纵向、搜索、章节页 metrics、模式切换均通过；logical error = 0
- `git diff --check`：PASS（仅 Git 的 LF→CRLF 提示）
- Windows Release：PASS
- Android Debug：PASS；设备未连接，本轮不执行 ADB

## 构建产物

- Windows EXE：`build/windows/x64/runner/Release/xaocen_reader.exe`
- Android APK：`build/app/outputs/flutter-apk/app-debug.apk`

## 后续人工确认

需要在本地 Windows/Android 上确认实际手感：翻页不弹 Chrome、Numpad/F 键、字体预览宽度、取色器、上下分隔线和窄窗口布局。未恢复 Engine Spike，也未宣称桌面透明或设备级验证通过。
