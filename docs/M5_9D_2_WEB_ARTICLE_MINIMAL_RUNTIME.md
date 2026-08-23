# M5.9d-2 — WebArticleSource Minimal Runtime

## 范围

本阶段只实现单篇公开网页文章的最小运行时链路，不实现 JavaScript/WebView、登录与复杂 Cookie、反爬绕过或 WebBookSource。

## 抓取链路

```text
WebArticleSource + WebArticleListItem
        ↓ planRequest (现有 RemoteSource contract)
RemoteHttpTransport (HTTP/HTTPS, timeout, redirect, status, charset, size limit)
        ↓
WebArticleHttpRuntime
        ↓ bounded HTML extraction rules
FeedHtmlNormalizer
        ↓
CanonicalContent (UTF-16 Locator coordinate space)
        ↓ Identity/ContentTransform boundary
ReaderContent projection
```

运行时只执行一次 GET。规则集是数据配置（标题、正文区域、作者、摘要、canonical link），不执行脚本、不发起二次网页请求。默认 POC 规则按 `article → main → body` 顺序选择正文区域。

## POC 网站

使用公开的 RFC Editor 文章页进行真实 HTTP 验证：

`XAOCEN_LIVE_SOURCE_URL`（仅通过本地环境变量传入）

该页面在运行时成功返回 HTML，并被转换为可供 Reader 使用的纯文本正文；实时验证通过后不把网络测试纳入默认全量测试，避免公网波动影响本地 Gate。

## 净化结果

- `<script>`、`<style>`、模板等非正文块被移除。
- 标题、段落、换行、基础链接被转换为文本；HTML entity 解码。
- 图片不下载、不执行远程资源，仅保留 `[图片]` 或 `[图片：alt]` 占位，避免引入第二套内容/坐标来源。
- 正文为空或只剩脚本/空白时返回“文章未提供可读正文”。
- 原文净化结果写入 `CanonicalContent`；`IdentityContentTransform` 可验证精确保留 canonical UTF-16 坐标。

## ReaderContent 接入

`WebArticleHttpRuntime.toReaderContent` 生成现有 `ReaderContent`、`LibraryDocument` 和单条导航投影。它不写数据库、不持有阅读进度、不创建新的 Locator；持久化层可以在后续阶段把同一投影写入现有 Library/DataRoot，再由现有 Reader 打开。

## 失败降级

安全 API `tryFetch` 将失败转换为明确结果，不把网络/解析异常抛到 Reader：

- HTTP 非 2xx → `http`，保留 status code。
- 超时、连接失败、字符集或响应大小限制 → `transport`，保留 transport 原因。
- 重定向离开来源 → `redirectOutsideSource`。
- 无可读正文 → `emptyBody`。
- 规则提取异常 → `extraction`。

这为后续 UI 提供“网络失败 / HTTP 状态 / 内容源未提供正文”等可理解提示；本阶段不抓取“查看全文”链接。

## 修改文件

- `lib/sources/remote/web_article_runtime.dart`
- `test/unit/web_article_runtime_test.dart`
- `test/manual/web_article_public_poc_test.dart`
- `docs/M5_9D_2_WEB_ARTICLE_MINIMAL_RUNTIME.md`

## Gate

- `flutter analyze --no-pub`：PASS
- 定向测试 `test/unit/web_article_runtime_test.dart`：4 tests PASS
- 真实公网 POC（RFC Editor）：PASS
- 全量 Flutter tests：727 passed，1 skipped（PASS）
- `git diff --check`：PASS（仅报告现有工作树的 LF/CRLF 转换提示）

## 冻结判断

最小 WebArticle runtime 已具备独立可验证的抓取、净化、失败降级与 ReaderContent 投影边界。本阶段可以冻结；真实站点规则扩展、登录/Cookie、JS/WebView 与全文链接抓取留在后续阶段。
