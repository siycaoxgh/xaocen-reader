# M5.5b 首页 / 书架 V3 对齐

日期：2026-08-11

## 首页

- 仅展示由 `reading_history` 派生的最近阅读（最多 2 条）。
- 支持继续阅读；仍使用现有 collection、ReaderLocator、readingMode、Preferences 和 Session 合同。
- 无记录时显示明确空状态和进入书架的入口。
- 不再展示完整书籍列表，避免与书架重复。

## 书架

- 继续展示当前全部 collection，并负责导入、打开、删除和状态反馈。
- Android 使用紧凑列表；Windows 宽窗口使用有界卡片网格，避免机械放大手机列表。
- 嵌入 App Shell 时隐藏历史/最近阅读重复区；直接构造 `LibraryPage()` 的既有调用保持兼容。

## 合同与验证

- 删除 collection 仍不删除阅读历史；首页会立即隐藏已不在书架的最近阅读项。
- ReaderLocator、ReadingHistory、ReadingSession、Drift schema 6 未修改。
- `flutter analyze`：PASS
- Flutter tests：454/454 PASS
- Windows integration：11 files / 14 scenarios PASS
- Windows Release：`build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android Debug：`build\\app\\outputs\\flutter-apk\\app-debug.apk`
- `git diff --check`：PASS
