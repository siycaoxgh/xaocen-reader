# M5.9d-3 — WebBookSource Minimal Runtime

## 范围

本阶段实现静态 HTML 小说源的最小运行时：搜索、详情、目录、章节正文和统一 ReaderContent 投影。不实现 JavaScript/WebView、登录与复杂 Cookie、反爬、通用书源导入或 WebArticleSource 扩展。

## 链路

```text
WebBookSource + WebBookSearchRequest
        ↓
RemoteHttpTransport（现有 HTTP/HTTPS、状态、超时、重定向、字符集边界）
        ↓
WebBookHttpRuntime
        ├─ search → WebBookSearchResult
        ├─ openDetail → WebBookDetail
        ├─ loadTableOfContents → WebBookTableOfContents
        └─ openChapter → WebBookChapter
                 ↓
          FeedHtmlNormalizer
                 ↓
          CanonicalContent（每章独立 UTF-16 坐标）
                 ↓
          WebBookReaderContentProjection → ReaderContent
```

运行时只解析静态 HTML。规则集为可替换的数据配置，默认按约定的 `data-book-key`、`data-chapter-key`、`article/main/body` 等区域提取；搜索请求使用普通 `q/page/pageSize` 查询参数，不执行脚本、打开 WebView 或从正文链接发起隐式请求。

## 顺序与 identity

- 搜索结果按 HTML 出现顺序返回。
- 目录条目按 HTML 出现顺序返回，不按显示章节号重排；`orderIndex` 是运行时看到的源顺序索引。
- `bookKey` 来自搜索/详情稳定标识；章节优先使用 `data-chapter-key`，缺失时由 canonical URI + 标题生成稳定 hash。
- ReaderContent 投影按传入目录顺序拼接章节，生成连续文档范围和导航，不改变现有 Locator、分页或进度语义。

## HTML 净化

复用 `FeedHtmlNormalizer`：移除脚本/样式，保留标题、段落和换行，解码 HTML entity，链接转为可读文本，图片转为占位文本。章节正文为空时返回明确的“章节未提供可读正文”。

## 失败降级

`trySearch`、`tryOpenDetail`、`tryLoadTableOfContents`、`tryOpenChapter` 返回 `WebBookRuntimeResult`，不把网络或解析异常直接传入 Reader：

- HTTP 非 2xx：`http`，保留 status code。
- 超时/网络/字符集/响应大小限制：`transport`。
- 重定向离开来源：`redirectOutsideSource`。
- 搜索、详情、目录、章节缺失：分别返回可区分的 `emptySearch`、`detailNotFound`、`emptyToc`、`emptyChapter`。
- HTML 规则不匹配或 identity 不一致：`extraction`。

## 测试覆盖

`test/unit/web_book_runtime_test.dart` 使用本地静态 HTML HTTP server 覆盖：

- 搜索返回多个稳定书籍 identity。
- 详情 metadata 与规则来源。
- 目录非顺序显示编号仍保持 HTML 顺序。
- 章节正文净化、entity 解码、脚本移除。
- CanonicalContent → IdentityContentTransform → ReaderContent 投影。
- HTTP 失败与空章节安全降级。

本地 fixture 是确定性静态 HTTP 验证，不依赖真实站点可用性；本阶段没有硬编码某个小说网站或通用书源规则。

## 修改文件

- `lib/sources/remote/web_book_runtime.dart`
- `test/unit/web_book_runtime_test.dart`
- `docs/M5_9D_3_WEB_BOOK_MINIMAL_RUNTIME.md`

## 冻结判断

本轮 Gate 已完成：

- `flutter analyze --no-pub`：PASS
- 定向测试 `test/unit/web_book_runtime_test.dart`：3 PASS
- 全量 Flutter tests：730 PASS，1 项按现有测试标记跳过
- `git diff --check`：PASS

结论：本阶段可冻结。真实站点规则、分页搜索、独立目录 endpoint、登录/Cookie、JS/WebView 和通用书源导入留给后续阶段。
