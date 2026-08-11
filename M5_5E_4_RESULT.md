# M5.5e.4 Result — Reader 主题与配色模型

状态：COMPLETE  
日期：2026-08-11

## 完成内容

- 建立 `ReaderPalette` / `ReaderPaletteResolver`，统一解析 Reader 的 system、light、dark
  语义和成套阅读配色。
- 提供纸白、暖黄、青绿、青蓝、浅灰、墨黑六组 palette；每组分别定义浅色与深色
  的字体色和背景色。
- `ReaderPreferences` 按书保存 palette 选择，以及浅色/深色两套可选字体色、背景色覆盖。
  preset 与 custom 是互斥的显式选择状态；只有选中 custom 时才使用颜色覆盖值。
- 颜色输入继续支持 `#RRGGBB`、`rgb(r,g,b)` 和可视色板；非法值只显示错误，不保存。
- 用户明确选择的字体色始终传入正文 `TextStyle` 实际绘制；低对比度只产生警告，
  不再由 `ensureReadableTextColor` 静默替换为黑/白。
- 浅色/深色切换同时驱动 Reader 有效主题和正文 palette；图片背景、透明度和遮罩合同保持不变。
  所有这些变化仍属于 paint-only，不触发 relayout、分页、Locator restore 或 progress 写入。

## 持久化与迁移

- Drift schema：7 → 8。
- `reader_preferences` 新增 palette identity 与四个亮度独立颜色字段；schema 7 的旧单套颜色
  迁移时复制到浅色和深色两套，保留旧书的颜色、图片、排版与 reading_progress。
- 真实 SQLite 迁移测试验证 schema 7→8、旧颜色/图片、阅读进度和书籍仍存在；schema 仍不保存
  任何派生页码、章节进度或 Locator 替代值。

## 验证

- `flutter analyze`：PASS。
- 全量 Flutter unit/contract/widget：465/465 PASS。
- integration：11 个文件 / 14 个场景 PASS。
- `C:\Users\TOM\Desktop\测试` 全部 4 个 TXT：PASS，logical error = 0。
- Windows Release：PASS。
- Android Debug：PASS。
- `git diff --check`：PASS。

构建产物：

- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

Android 真机本轮未执行；仅完成 Debug APK 构建。

## M5.5e.4.1 修正

- 修复 preset/custom 颜色源未明确分离导致的主题或 Palette 点击无明显变化。
- 旧 schema 7 单套颜色迁移为 `custom` 状态并复制到浅色/深色覆盖；选择 preset
  时保留覆盖值但不参与绘制，重新选择 custom 即可继续使用。
- 预设“夜间”更名为“浅灰”。
- Windows Aa 设置页按 Windows 平台使用固定桌面外层宽度、固定分类栏和填充式内容区，
  切换分类不再改变面板宽度。
- 本修正不升级 Drift，schema 保持 8。
