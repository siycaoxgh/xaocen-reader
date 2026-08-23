# M5.9d-8 — WebBook Search / Add to Library UI

## 目标与边界

本阶段完成 WebBook 的最小产品闭环：书源管理 → 使用已启用书源搜索（或打开无搜索端点的默认书籍）→ 书籍详情/目录 → 加入现有书架 → 使用现有 Reader 阅读。

本阶段没有实现 Legado 兼容、JS/WebView、复杂登录或反爬，也没有修改 Reader、Locator、Progress、分页逻辑或数据库 schema。

## 用户流程

```text
首页
  → 在线书源
    → 导入 / 启用 / 禁用 / 导出 / 删除书源
    → 输入关键词，搜索所有已启用书源
    → 搜索结果
    → 书籍详情 + 目录预览
    → 加入书架
    → 现有书架 / LibraryPage
    → 现有 ReaderPage
```

没有 `searchEndpoint` 的静态书源（例如本阶段的 Sudugu 配置）不会被伪装成可搜索源，而是在书源卡片提供“打开默认书籍”入口，沿用同一详情、目录和入库流程。

## 书源管理

复用 M5.9d-7 的 `WebBookSourceRegistry`，作用域仍是当前 Profile/DataRoot：

- 导入并校验 XAOCEN WebBook JSON
- 启用/禁用只影响搜索与默认入口
- 单个书源导出
- 删除注册项不删除已有书架书籍
- 不把 Cookie、Header、Auth 或其他秘密值写入导出 JSON

入口位于首页的“在线书源”卡片，并通过 `/web-books` 路由打开。

## 搜索与详情

`WebBookPage` 只对启用书源调用现有 `WebBookHttpRuntime`。请求、HTTP 状态、解析错误按书源分别显示；一个书源失败不会阻止其他书源显示结果。

详情页展示书名、作者、简介、来源和章节数，并按 runtime 返回的原始 TOC 顺序显示章节预览。没有按章节号重新排序，也没有建立第二套章节或阅读进度。

## 加入书架与持久化

选择“加入书架”后，页面按 TOC 原顺序获取章节正文，交给现有 `ReaderContent` 投影，再通过 `LocalLibraryRepository.importWebBook` 写入已有 Drift 表：

```text
WebBookChapter
  → CanonicalContent / normalized.txt + manifest.json
  → contentSources / contentCollections / contentItems / contentDocuments
  → tocEntries / importRecords
  → LibraryPage
  → ReaderPage
```

WebBook 内容文件使用当前 DataRoot 的：

```text
library/web_book/<sha256(collectionId)>/normalized.txt
```

身份规则：

- `collectionId = web-book:<sourceId>:<bookKey>`
- `sourceId = web-book-source:<sourceId>:<bookKey>`
- 目录与文档 identity 来自源的稳定 key/URI；源顺序保留
- 重复加入同一本书返回既有 collection，不重复生成
- 移除 WebBook collection 时同时删除其受 XAOCEN 管理的快照目录

这样现有 Reader 继续从 `LibraryPage` 打开，并继续使用既有 UTF-16 Locator、Progress、Bookmarks、History 和 ReaderPreferences。

## 修改文件

- `lib/app/web_book_page.dart`
- `lib/app/app_shell_page.dart`
- `lib/app/router.dart`
- `lib/app/providers.dart`
- `lib/data/repositories/library_file_manager.dart`
- `lib/data/repositories/local_library_repository.dart`
- `lib/domain/library/library_import_models.dart`
- `lib/domain/reader/reader_content.dart`
- `test/unit/web_book_library_import_test.dart`
- `test/widget/web_book_page_test.dart`
- `test/manual/sudugu_web_book_poc_test.dart`

## 测试与 Gate

- `flutter analyze --no-pub`：PASS（No issues found）
- WebBook Registry / definition / library import / page 定向测试：PASS（全部通过）
- 全量 Flutter tests：PASS（739 passed，2 项按现有规则 skipped）
- `git diff --check`：PASS（退出码 0；仅有既有 LF/CRLF 换行提示）

## Sudugu 真实验收

使用真实公开《青山》页面验证 detail → TOC → chapter → CanonicalContent → ReaderContent：

- 配置的公开 WebBook 来源：PASS（真实地址不写入仓库）
- 书名、作者、简介：PASS
- 原始目录顺序：PASS（运行时返回 700+ 条目，保留网站自身请假/卷总结/重复章号）
- 首章、中间章节、最新章节：PASS
- 正文净化：PASS（段落已转换，未把 `<p>` 等原始标签传入 ReaderContent）
- ReaderContent 投影：PASS

测试来源发生跨域重定向时，现有 RemoteSource 安全策略不会无条件跨域跟随；这是来源可用性问题，不是通用 WebBook parser 问题。真实 host 只通过本地环境变量配置，未向通用 runtime 加入站点特判。

自动化真实 POC 命令：

```text
flutter test --dart-define=XAOCEN_SUDUGU_POC=1 --dart-define=XAOCEN_LIVE_SOURCE_URL=$env:XAOCEN_LIVE_SOURCE_URL test/manual/sudugu_web_book_poc_test.dart
```

结果：PASS。

## 结论

WebBook 最小产品闭环及自动化 Gate 已通过，代码范围可以冻结（PASS）。Sudugu 的原始旧域名重定向属于来源配置/可用性提示；若要在真实设备上继续验收首页入口、搜索、详情和加入书架的视觉体验，仍需执行 Windows/Android 人工 UI 验收（MANUAL REQUIRED），不影响本阶段架构与自动化冻结。
