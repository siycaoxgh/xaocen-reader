# M5.5e Result — Reader 阅读外观

状态：COMPLETE  
日期：2026-08-11

## 完成范围

- `ReaderPreferences` 新增每书独立的字体色、阅读背景色、托管图片背景引用、图片透明度与遮罩强度。
- 自定义颜色覆盖当前 system/light/dark Reader 主题；“恢复默认外观”后重新跟随现有主题。
- Aa 面板新增“阅读外观”分组，Windows 使用原有限宽面板，Android 使用移动 bottom sheet。
- 图片导入先复制到 `<applicationSupport>/library/reader_backgrounds/<collection>/`；数据库只保存 app-managed 相对路径，不保存 BLOB，也不依赖原始文件。
- Vertical/Paged 共用同一背景层；图片和遮罩位于正文布局后方，不参与 TextPainter、PageWindow 或章节进度计算。
- 自定义颜色、图片和遮罩全部归类为 paint-only；不触发 metrics relayout、Locator restore 或 reading_progress 写入。
- 低对比文字/背景组合只显示警告，用户明确选择的字体色仍由正文实际绘制；图片遮罩默认 45%，可在 0–100% 调整。

## 持久化与迁移

- Drift schema：6 → 7（M5.5e），随后 7 → 8（M5.5e.4）。
- schema 8 在 `reader_preferences` 新增 palette identity 与浅/深色独立自定义颜色；旧 schema 7 颜色迁移到两套亮度覆盖。
- 真实 SQLite schema 7→8 migration test 通过；旧书、旧排版参数、图片、reading_progress 与 Reader 状态保留。
- `ReaderLocator.absoluteCharacterOffset`、readingMode、ReadingSession、ChapterPageMetrics 与 normalized.txt 合同均未改变。

## 验证

- `flutter analyze`：PASS。
- unit/contract/widget：465/465 PASS。
- integration：11 files / 14 scenarios PASS。
- 全部 4 个真实 TXT：PASS，metrics corpus logical error = 0。
- Windows Release：PASS。
- Android Debug：PASS。
- `git diff --check`：PASS。

## 已知后续项

- 删除整本书时，历史上已替换且不再被偏好引用的托管背景图片目前不做全目录垃圾回收；替换、移除与恢复默认会删除当前引用文件。这是存储清理项，不影响当前背景可用性或 Reader 数据安全。
- Windows 原生窗口透明、桌面穿透仍不在本阶段范围。
