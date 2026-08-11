# M5.5g Result — Android edge-to-edge + Reader information layer

状态：COMPLETE
日期：2026-08-11

## 实现

- Reader 在 Android 使用 `SystemUiMode.edgeToEdge`，透明系统栏和基于有效 Reader 亮度
  的系统图标亮度；沉浸模式使用 `immersiveSticky`，离开 Reader 时恢复 edge-to-edge。
- Reader 内容与 app-managed 图片背景继续由全屏 route 绘制；顶部/底部 Chrome 和极简
  信息层使用 `MediaQuery.viewPadding`，不硬编码状态栏高度，覆盖挖孔、刘海、圆角、横屏
  cutout、手势导航和三键导航的 inset 场景。
- 菜单隐藏时提供可选的非交互信息层：顶部章节标题/本章进度，底部时间/全书进度；Paged
  使用 `本章 x / y 页`，Vertical 使用 `本章 xx%`，无章节只显示 `全文` 与全书进度。
- Aa → 阅读行为新增 typed display preferences：顶部信息、底部信息、阅读进度、系统栏
  模式（系统状态栏/阅读器信息栏/隐藏）、时间格式（24 小时/12 小时/不显示）。菜单显示
  时仅显示完整 Reader Chrome，AutoRead 状态条保持独立。
- Display preferences 属于 per-book ReaderPreferences 的 presentation-only 字段，不触发
  metrics relayout、Locator 写入、PageWindow、AutoRead 或 ReadingSession 变化。

## 数据与迁移

- Drift schema 8 → 9；新增五个 display columns，默认值分别为 true/true/true/system/
  twentyFourHour。
- 旧书籍、阅读进度/readingMode、ReaderLocator、排版、Palette 和图片引用均保留。

## 验证

- `flutter analyze`：PASS。
- 全量 Flutter unit/contract/widget：477/477 PASS。
- integration：11 个文件 / 14 个场景 PASS。
- `C:\Users\TOM\Desktop\测试` 当前全部 4 个 TXT：PASS，logical error = 0。
- Windows Release：PASS。
- Android Debug：PASS，普通应用入口 APK。
- `git diff --check`：PASS。
- Android 真机：本轮未执行（NOT-RUN / deferred）。

构建产物：

- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

## 不在本阶段

未修改 ReaderLocator、reading_progress、PageWindow、分页引擎、AutoRead、ReadingSession 或
Windows native 窗口能力；未进行 Android ADB 安装或真机操作。
