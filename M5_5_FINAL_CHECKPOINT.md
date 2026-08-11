# M5.5 Final Checkpoint

状态：COMPLETE
日期：2026-08-11
HEAD：f7c10ca0ab4076a1a84dd3fa593492b5ce9ef0cb
Drift schema：9

## 已完成能力

- V3 App Shell：Android 一级底部导航、Windows 桌面侧栏、首页/书架/我的分工。
- Reader：vertical / paged、Flat TOC、书签、搜索、阅读历史、ReadingSession、AutoRead。
- 每书 ReaderLocator、readingMode、ReaderPreferences 与 Palette/背景图片引用。
- 精确保位 metrics relayout、chapter-first-page、bounded PageWindow 与 gesture-tail 修复。
- Reader 输入绑定：Windows 单键/组合键/wheel，Android Volume Up/Down 合同。
- Aa：排版布局、阅读外观、阅读行为、高级设置；字体/颜色/Palette/图片背景能力。
- M5.5g：Android edge-to-edge、cutout/inset 安全区、极简阅读信息栏和状态栏模式。
- M5.5h：统一视觉 tokens、卡片/按钮/分隔线/导航表面、品牌标记、反馈状态和空状态。

## 核心架构合同

- `ReaderLocator.absoluteCharacterOffset`（normalized.txt UTF-16 code-unit offset）是唯一
  阅读位置真源。
- `reading_progress` 只保存 Locator 与每书 readingMode；pageIndex、scrollPixels、百分比、
  chapter page metrics 均为 transient derived state。
- ReaderPreferences、Palette、显示偏好按书保存；AppSettings/Input profile/AutoRead 偏好
  属于应用级设置，字符串 key 只停留在 repository/storage 层。
- metrics 改动必须 freeze → relayout/repaginate → exact Locator restore → confirm；paint-only
  和显示偏好不得触发重排或额外 progress 写入。
- PageWindow 保持 bounded；touch/keyboard/wheel/volume/AutoRead 共用分页 Controller ensure
  链路；旧 generation 不得覆盖新 layout 或 Locator。

## 验证基线

- Flutter analyze：PASS。
- 全量 unit/contract/widget：477/477 PASS。
- integration：11 文件 / 14 场景 PASS。
- `C:\Users\TOM\Desktop\测试` 当前全部 4 个 TXT：PASS，logical error = 0。
- Windows Release：PASS。
- Android Debug：PASS（普通应用入口 APK）。
- `git diff --check`：PASS。
- Android 真机：本阶段未执行，NOT-RUN / deferred。

## Known Issues / deferred

- Windows 原生透明窗口、鼠标穿透、DPI/GPU 合成仍未实现。
- 系统字体枚举与 TTF/OTF/TTC 导入未实现；Reader 使用系统默认字体和 fallback。
- Android cutout/导航模式/图片背景/Palette 的物理设备截图验收待后续设备在线时执行。
- TTS、EPUB、RSS、网络书源和其它 M5.6+ 产品能力不在 M5.5。

## 下一阶段建议

先进行 Android 物理设备视觉验收与 Windows/Android 截图回归；随后再单独立项窗口透明、
字体导入或 TTS，避免把这些高风险能力混入 Reader 位置/分页合同。
