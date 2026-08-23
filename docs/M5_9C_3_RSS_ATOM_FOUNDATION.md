# M5.9c-3 — RSS / Atom Foundation

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 阶段结论

**RSS / ATOM FOUNDATION = PASS / FROZEN**

本阶段完成离线 RSS 2.0 / Atom XML 解析与统一 `ReaderContent` 投影。没有 HTTP 请求、后台刷新、通知、全文网页抓取、订阅 UI、WebArticleSource、WebBookSource 或云同步。

## 修改文件

- `lib/sources/remote/standard_feed_parser.dart`
  - `StandardFeedParser`：RSS 2.0 与 Atom 核心字段解析。
  - `StandardFeedParseResult` / `StandardFeedItem`：feed 与 item 领域投影。
  - 稳定 source/item identity：优先使用 source id、guid/Atom id，其次 link，再用标题与发布时间组合 hash。
  - `toReaderContent`：产生现有 `LibraryCollection`、`LibraryDocument`、`LibraryTocEntry` 与统一 `ReaderContent`。
  - `StandardFeedReaderContentProjection`：在未来持久化前保存文档文本与 ReaderContent 的对应关系。
- `test/unit/standard_feed_parser_test.dart`
  - RSS、Atom、顺序/identity、ReaderContent 投影和非法 root 测试。

## 解析链路

```text
StandardFeedSource (c-0 descriptor)
        │ supplied XML fixture
        ▼
StandardFeedParser
        ▼
StandardFeedParseResult / Item
        ▼
LibraryCollection + Document + TOC projection
        ▼
ReaderContent (sourceKind = rss)
```

RSS 支持 channel title/description、item title/guid/link/pubDate、creator/author、description 与 `content:encoded`。Atom 支持 feed/entry title、author/name、id、published/updated、alternate link、summary/content。输入顺序完全保留。

每个 item 的正文范围使用同一份拼接文本的 UTF-16 `String.length`，TOC 与 document range 直接指向该 canonical 文本；没有新建分页、进度或 Locator。

## 兼容边界

- 当前是本地 XML fixture/parser，不是网络客户端。
- HTML 清洗、脚本、远程资源、全文抓取、图片/媒体、分页和订阅刷新均未实现。
- `documentTextById` 是未来导入/缓存层的临时投影；正式打开 Reader 前仍需由现有 Library persistence 写入受管存储。
- RSS/Atom 保持 `StandardFeedSource` 语义，不与 `WebArticleSource` 或 `WebBookSource` 混合。

## 验证

- `flutter analyze --no-pub`：PASS
- `test/unit/standard_feed_parser_test.dart`：PASS（5 项）
- 全量 Flutter tests：PASS（697 项）
- `git diff --check`：PASS（仅现有换行格式提示，无 whitespace error）

## 是否可冻结

本阶段不需要稳定 Reader/数据库大改；本阶段可冻结。真实网络 transport、订阅刷新和导入持久化应作为后续独立阶段。
