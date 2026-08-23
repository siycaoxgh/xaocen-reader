# M5.7s.9c-2 Settings Light/Dark Theme Regression

## 根因

复现前的应用根组件 `lib/app/app.dart` 将 `themeMode` 固定为
`ThemeMode.system`，设置页没有可持久化的 App Shell Light/Dark 状态。因此设置
页面无法真正执行 Light ↔ Dark 的应用级切换；Reader 内的 `ReaderThemeMode`
只属于书籍正文，不能修复 App Settings 的 surface 状态。设置页自身的普通
`Scaffold`、`Card`、按钮和输入控件已使用当前 Material `Theme/ColorScheme`，
问题在于缺少统一的应用主题状态入口，而不是改写 Reader 主题。

## 修复

- 新增独立 `AppThemeMode`（system/light/dark），与 `ReaderThemeMode` 分离。
- 通过现有 `app_settings` 键值表 `app.themeMode` 持久化，无 schema 升级。
- 根 `MaterialApp` 订阅 `appThemeModeProvider`，状态先发布再持久化，当前设置页和
  已打开的 Material overlay 在同一主题树下立即重建。
- “阅读设置”增加“应用主题”控件：跟随系统 / 浅色 / 深色，并明确说明不影响
  Reader Aa 正文主题。
- 未改 ReaderTheme、ReaderPreferences、Locator、分页或其他平台功能。

## 实际 Windows Release 验证

使用正确项目路径构建并启动：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

- Light 启动：设置页 surface、Card、AppBar 一致。
- Light → Dark：当前打开设置页即时变为 dark，无白色残留块；控件同步更新。
- Dark → Light：当前页面即时恢复 light，无 dark surface 残留。
- 连续切换：重复切换后选中态与所有设置 Card/滚动区域跟随当前 Theme。
- 关闭设置再打开：主题状态保持，不要求重启设置页。
- 重启应用：已选择的 Light 状态从 `app.themeMode` 恢复。
- Platform diagnostics、Windows settings 等独立页面在 dark 状态下使用同一 Material
  Theme（截图/Accessibility tree 已确认）。

## 验证结果

| Gate | Result |
|---|---|
| SETTINGS LIGHT | PASS |
| SETTINGS DARK | PASS |
| LIVE THEME SWITCH | PASS |
| OVERLAY THEME | PASS（Material dialog/dropdown/selector 继承根 Theme；无固定 Settings surface） |
| REOPEN SETTINGS | PASS |
| READER THEME REGRESSION | PASS（ReaderThemeMode 链路未修改） |
| `flutter analyze` | PASS |
| 全量 Flutter tests | PASS（599 tests） |
| Windows Release | PASS |
| Android Debug | PASS |
| `git diff --check` | PASS（仅现有 CRLF 转换提示） |

Windows Engine/DComp、透明度、字体、Tray、输入和 Android Reader 均未进入本轮。
