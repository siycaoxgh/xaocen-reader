# M5.9d-1 — Offline Rule Fixture Validation

项目：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 结论

**OFFLINE RULE FIXTURE VALIDATION = PASS / FROZEN**

本阶段只使用仓库内静态 HTML fixture 和测试层 adapter，未发起 HTTP/HTTPS 请求，未接入真实网站规则，未修改 Reader、Locator、Progress、Pagination 或数据库 schema。

## 修改内容

- `test/fixtures/web_sources/`
  - 文章列表、两篇文章正文
  - 书籍搜索、详情、目录、两章正文
- `test/unit/offline_web_source_fixture_test.dart`
  - fixture HTML 规则提取
  - WebArticle 完整链路
  - WebBook 完整链路
  - Identity、顺序、Transform 与 ReaderContent 投影验证

生产契约没有新增网络实现；fixture adapter 仅用于验证 `WebArticleSourceAdapter` / `WebBookSourceAdapter` 的使用方式。

## WebArticle 验证链路

```text
article_list.html
  → WebArticleListPage
  → WebArticleListItem(article-001 / article-002)
  → article_001.html
  → WebArticleDocument
  → WebSourceBody(CanonicalContent)
  → IdentityContentTransform
  → persisted LibraryCollection / LibraryDocument
  → WebArticle adapter.adapt()
  → ReaderContent(sourceKind = online)
```

验证结果：

- 列表顺序保持 `article-001 → article-002`
- 文章 identity 在重复读取后稳定
- 作者、标题、正文和 `<strong>` 内文本被正确带入 canonical body
- Transform 不改变 canonical text，精确映射仍可携带 UTF-16 Locator
- ReaderContent 使用现有 adapter 投影，不创建新 Reader

## WebBook 验证链路

```text
book_search.html
  → WebBookSearchResult(book-001)
  → book_detail.html
  → WebBookDetail
  → book_toc.html
  → WebBookTableOfContents
  → book_chapter_002.html / book_chapter_001.html
  → WebBookChapter
  → WebSourceBody(CanonicalContent)
  → persisted LibraryCollection / LibraryDocument / LibraryTocEntry
  → WebBook adapter.adapt()
  → ReaderContent(sourceKind = online)
```

验证结果：

- `bookKey`、`chapterKey` 稳定
- 目录原始顺序故意为 `chapter-002 → chapter-001`，adapter 保持该顺序，不隐式排序
- 章节正文 identity 由 `bookKey:chapterKey` 组成
- 详情 metadata、章节正文和现有 `ReaderContent` 投影均可追踪
- 目录和文档的绝对范围仍由现有 Library projection 提供，fixture 不建立第二套位置 truth

## Fixture 覆盖

| 流程 | Fixture | 覆盖 |
|---|---|---|
| Article list | `article_list.html` | 稳定 ID、标题、URI、摘要、发布时间、列表顺序 |
| Article body | `article_001.html`, `article_002.html` | 标题、作者、段落、基础标签文本、规则版本 |
| Book search | `book_search.html` | 书籍 key、详情 URI、作者 |
| Book detail | `book_detail.html` | 标题、作者、简介、规则版本 |
| Book TOC | `book_toc.html` | chapter key、orderIndex、原始顺序 |
| Book chapters | `book_chapter_001.html`, `book_chapter_002.html` | 章节 canonical identity 与正文 |

## Gate

- `flutter analyze --no-pub`：PASS
- 定向测试：`offline_web_source_fixture_test.dart`，PASS（2 项）
- 全量 Flutter tests：PASS（723 项）
- `git diff --check`：PASS；仅有既有工作树的 LF/CRLF 提示，无 whitespace error

## 阶段边界

本阶段没有实现：

- HTTP transport 或真实网页抓取
- WebView、JavaScript、登录、Cookie 导入
- 规则配置 UI
- HTML 净化/翻译服务
- 远程内容数据库持久化

## 后续建议

可以进入下一阶段，但仍建议先保持离线可复现：

1. **M5.9d-2**：为 WebArticle 建立单一 transport + 可审计规则执行器。
2. **M5.9d-3**：为 WebBook 建立搜索、详情、目录、章节的最小运行时。
3. 真实网络接入前增加 fixture 与线上响应快照的差异诊断，不直接以单个网站页面驱动 Reader 重构。
