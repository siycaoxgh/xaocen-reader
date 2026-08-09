# M5.2d Result — Recent Reading, Reading History, and Sessions

Date: 2026-08-09  
Branch: `feat/m4-horizontal-reader`  
Drift schema: **6**  
Status: **COMPLETE**

## Delivered

- 首页最近阅读由 `reading_history` 派生：只取仍在书架且存在有效
  `reading_sessions` 的 collection，按 `lastReadAt DESC` 限制 2 条；不新增
  RecentRead 真源。
- “阅读历史”页面显示书名快照、首次/最后阅读时间、session 聚合时长与次数、
  最后章节/进度快照及当前是否仍在书架。仍在书架的记录可继续阅读；已删除书籍
  只保留文字/统计并标记“已移出书架”。
- Reader 在首次有效 visible/page confirm 后创建一个 ReadingSession；foreground
  active 累计，inactive/paused 暂停，resume 继续，route pop/dispose 结束。模式切换、
  设置、搜索、TOC、书签不会创建额外 session。
- 历史章节和百分比字段仅为展示快照；真实位置仍来自
  `ReaderLocator.absoluteCharacterOffset` / `reading_progress`。
- 删除书籍由 schema 6 FK 将 history/bookmark collectionId 置空并保留 sessions；
  删除历史记录只删除 history 并级联 sessions，不影响书架、progress 或 preferences。

## Validation

- `flutter analyze`: PASS, 0 issues。
- Full unit/contract/widget suite: **382/382 PASS**。
- M5.2d persistence test: duration/count aggregation, recent filtering, detach,
  history deletion cascade: PASS。
- Existing Windows integration suites remain individually runnable and pass; the
  directory-wide command is not used because Flutter Windows integration runners
  cannot launch multiple app instances concurrently. M5.2c baseline remains 10
  files / 13 scenarios.
- All four current TXT files (`C:\Users\TOM\Desktop\测试`) retain the existing
  Reader/metrics/search checks with `logicalError = 0`。
- Drift schema remains **6**; no migration required。

Artifacts:

- `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- `build\\app\\outputs\\flutter-apk\\app-debug.apk`

Android real-device validation remains deferred to the unified final device pass.
