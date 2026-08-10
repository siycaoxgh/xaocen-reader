# M5.5a App Shell 与一级导航

日期：2026-08-11

## 完成内容

- 根路由进入 `AppShellPage`，一级信息架构为：首页、书架、我的。
- Android 使用响应式 Material `NavigationBar`，保留移动端底部一级导航。
- Windows 宽窗口使用限宽桌面侧栏 + 主内容区；窗口缩放时按 720px 响应断点切换布局。
- 书架沿用现有 `LibraryPage`，以 embedded surface 嵌入 Shell；Reader、阅读历史、阅读设置和按键设置入口均保留。
- Shell 导航使用 `IndexedStack` 保持各一级 surface 的路由状态，切换不会触碰 ReaderLocator 或阅读进度数据。
- `LibraryPage()` 默认构造继续兼容既有直接调用方和集成测试。

## 验证

- `flutter analyze`：PASS
- App Shell widget tests：2 PASS（桌面侧栏、移动底部导航）
- 既有 M0 / Library widget tests：PASS
- Full Flutter suite：453/453 PASS
- Windows integration：11 files / 14 scenarios PASS
- Windows Release：`build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android Debug：`build\\app\\outputs\\flutter-apk\\app-debug.apk`
- `git diff --check`：PASS
- Drift schema：6，未修改
- Reader 数据层与 Windows 原生窗口状态：未修改

## 后续

Reader action hierarchy、阅读历史/设置页面的宽屏细化和外观能力仍按 UI Audit 留给后续 M5.5 阶段。
