# M5.6b — Reader 极简信息层

状态：完成（代码、迁移与自动回归通过）

## 信息槽模型

`ReaderInfoSlot` 只允许六个固定槽位：

- `topLeft` / `topCenter` / `topRight`
- `bottomLeft` / `bottomCenter` / `bottomRight`

每本书的 `ReaderPreferences` 保存章节、章节进度、时间、全书进度、分隔线的显示开关和槽位。没有自由像素坐标，也没有位置真源字段。

默认布局：章节→顶部左侧，本章进度→顶部右侧，时间→底部左侧，全书进度→底部右侧；分隔线默认关闭。

## 显示行为

Chrome 隐藏时，信息层使用透明背景、纯文字和可读性阴影，不再使用浮窗/玻璃卡片。信息层使用 `SafeArea` 与真实窗口 inset，覆盖 Android cutout、圆角、横屏和底部导航/手势区域；Windows 复用同一槽位语义。

时间支持隐藏、12 小时和 24 小时格式，并在信息层存活期间定时刷新。系统状态栏设置不再阻断用户明确开启的 Reader 信息层时间显示。

## 配色提示

Aa 阅读外观显示当前编辑的浅色/深色方案、当前实际生效来源（预设/自定义）、有效亮度，并对低对比度仅给出警告。颜色解析继续由 `ReaderPaletteResolver` 负责。

## 数据与迁移

信息槽属于 per-book display preference，因此 Drift 正式升级到 schema 10。schema 9→10 新增固定槽位与逐项显示字段；旧 `showProgressInfo` 会同步到章节/全书进度开关，其他字段使用明确默认值。书籍、ReaderLocator、reading_progress、readingMode、ReaderPreferences 既有排版/配色/背景数据均保留。

## 验证

- `flutter analyze`：PASS
- 全量 Flutter unit/contract/widget：482 PASS
- schema 9→10 SQLite migration test：PASS
- Windows integration：11 文件 / 14 场景 PASS；4 个真实 TXT，logical error = 0
- Windows Release：PASS
- Android Debug：PASS
- `git diff --check`：PASS
- Android 真机：本阶段未执行，按阶段策略 deferred

构建产物：

- Windows：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
