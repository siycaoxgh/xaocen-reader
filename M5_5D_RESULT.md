# M5.5d 我的 / 阅读历史 / 设置结构

日期：2026-08-11

## 我的

- 分为“阅读信息”和“应用设置”两组。
- 阅读历史单独入口；阅读设置单独入口。
- 明确提示每书排版/主题继续在 Reader Aa 中保存，避免与应用级按键配置混淆。
- Windows 使用有界桌面内容区，Android 保持移动列表布局。

## 阅读历史

- 独立页面保留现有历史聚合、继续阅读、删除历史和 orphan/已移出书架展示。
- 桌面使用最大宽度 900 的内容区；移动端使用全宽列表。
- 空历史显示图标、说明和稳定空状态，不改变历史数据合同。

## 阅读设置 / 按键与操作

- 阅读设置增加清晰的输入与操作、阅读外观说明分组。
- 按键页面继续按平台显示 Windows keyboard/wheel 或 Android Volume 能力，profile persistence 不变。
- ReaderLocator、ReadingHistory、ReadingSession、Drift schema 6 未修改。

## 验证

- `flutter analyze`：PASS
- 针对性 Shell/历史显示测试：PASS
- Flutter tests：455/455 PASS
- Windows integration：11 files / 14 scenarios PASS
- Windows Release：`build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android Debug：`build\\app\\outputs\\flutter-apk\\app-debug.apk`
- `git diff --check`：PASS
