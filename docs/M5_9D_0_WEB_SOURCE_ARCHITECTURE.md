# M5.9d-0 — WebArticleSource / WebBookSource Architecture

项目：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 结论

**WEB SOURCE ARCHITECTURE = PASS / FROZEN（仅契约）**

本阶段只补齐网页文章源和在线书源的领域契约，没有 HTTP 抓取、WebView、JavaScript、登录或数据库改动。Reader、Locator、Progress、Pagination 和已冻结的 Windows 真透明路径均未修改。

参考了 [HapeLee/legado-with-MD3](https://github.com/HapeLee/legado-with-MD3) 所体现的“来源规则与阅读界面分层、净化后进入统一阅读体验”的思路；没有复制 Android、Compose、WebView、JavaScript 或平台实现。

## 修改文件

- `lib/domain/remote/web_source_contracts.dart`
  - 新增文章流/书籍流的阶段模型、不可变数据对象和 adapter 接口。
- `lib/domain/remote/remote_source.dart`
  - `WebArticleSource` 增加可选 `listUri`，并允许 endpoint、列表入口和文章入口分别通过来源 URI 校验；仍然只生成 request plan，不执行请求。
- `test/unit/web_source_contract_test.dart`
  - 以内存 fixture 覆盖两条流程、规则边界、源顺序和 ReaderContent 投影。

## 共享层

现有 `RemoteSource` 继续是唯一共享来源基础：

```text
RemoteSource
├─ StandardFeedSource       RSS / Atom
├─ WebArticleSource         规则文章源
└─ WebBookSource            在线书源
```

Header、Cookie、Auth、timeout、redirect、响应上限仍只由 `RemoteRequestCapabilities` 和 `RemoteRequestPlan` 描述。敏感值只能通过 credential/cookie 引用，不能进入 source descriptor 或日志数据。契约不包含 HTTP client、WebView 或脚本执行。

## WebArticleSource 边界

文章源是“文章列表中的独立文章”语义，阶段固定为：

```text
list(uri, pageToken)
  → WebArticleListPage / WebArticleListItem
  → open(item)
  → WebArticleDocument
  → WebSourceBody(CanonicalContent)
  → 现有 ContentSource 持久化
  → ReaderContentAdapter
  → Reader
```

`WebArticleListItem` 保存稳定 article identity、标题、文章 URI、摘要和发布时间；`WebArticleDocument` 保存作者/简介、canonical URI、规则版本和正文。文章规则只能解释一篇文章，不产生章节目录，也不能被当作在线书源。

## WebBookSource 边界

书源是“可搜索、可选书、带有序章节目录并可增量更新”的语义，阶段固定为：

```text
search(query, page)
  → WebBookSearchResult
  → openDetail(result)
  → WebBookDetail
  → loadTableOfContents(detail)
  → WebBookTableOfContents（保持源 orderIndex，不隐式排序）
  → openChapter(detail, entry)
  → WebBookChapter
  → WebSourceBody(CanonicalContent)
  → 现有 ContentSource 持久化
  → ReaderContentAdapter
  → Reader
```

书籍 identity 使用 `bookKey`，章节 identity 使用 `chapterKey`；目录顺序是来源数据，adapter 不擅自重排。书源不能把文章列表简单拼成书，也不能把网站规则写进 Reader。

## Transform / Locator 边界

`WebSourceBody` 只持有 `CanonicalContent`。净化、替换、翻译等未来能力必须显式调用现有 `ContentTransform`，得到临时 `DerivedContent` 和 `ContentPositionMap`：

```text
canonical source text (UTF-16 Locator truth)
       │ explicit ContentTransform
       ▼
derived view + position map (disposable/cacheable)
```

Derived text 不是第二套进度或 Locator truth。只有 `exact` 映射才可安全携带精确位置；`coarse/unavailable` 必须交给未来策略处理，不能静默改写书签、进度或当前位置。

## ReaderContent 接入

两个 adapter 都实现现有 `RemoteSourceReaderAdapter`，因此必须通过现有 `ReaderContentAdapter` 的 persisted `LibraryCollection / LibraryDocument / LibraryTocEntry` 投影进入 Reader。网页源不得直接创建新的 Reader、分页器、进度仓库或 Locator。

本阶段没有新增数据库表/字段，也没有把网页快照写入数据库；真正的 persistence、缓存和 source revision 合并留给后续阶段。

## Legado / 未来扩展

现有 `RemoteSourceConfigCodec` 与 `RemoteSourceConfigFormats.legadoJson` 继续作为扩展点。未来 codec 只能把外部规则映射到上述 source/adapter 契约，并保留 provenance、规则版本和 capability 限制；本阶段不解析或执行 Legado JSON。

## 验证

- `flutter analyze --no-pub`：PASS
- 定向测试：`web_source_contract_test.dart`、`remote_source_contract_test.dart`、`content_transform_contract_test.dart`：PASS（14 项）
- 全量 Flutter tests：PASS（721 项）
- `git diff --check`：PASS；仅有现有工作树的 LF/CRLF 提示，无 whitespace error
- 数据库 schema、Reader、Locator、Progress：未修改

## 后续建议（最多 3 步）

1. **M5.9d-1 — Offline Rule Fixtures**：使用本地 fixture 验证 list/detail/TOC/chapter 到现有 persistence projection 的链路，不接真实网站。
2. **M5.9d-2 — Article Adapter Runtime**：在 capability/transport gate 下实现单一 WebArticle 规则执行和净化，先保持手动触发与可审计错误。
3. **M5.9d-3 — Book Adapter Runtime**：实现搜索、详情、目录和章节的最小运行时，并验证 source order、identity 与增量更新；评审通过后再考虑 UI。

以上步骤均不得改变 Reader / Locator / Progress 合同；任一步遇到无法精确映射内容位置的情况，应停止并报告，而不是重写 Reader Core。
