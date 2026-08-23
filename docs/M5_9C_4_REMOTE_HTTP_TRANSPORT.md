# M5.9c-4 — Remote HTTP Transport

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 结论

**PASS / FROZEN**。本阶段增加了一个统一、受约束的 HTTP/HTTPS 传输层，
将现有 `StandardFeedSource` 的请求计划交给传输层执行，再把响应交给既有
RSS/Atom parser。没有修改 Reader、absolute UTF-16 Locator、Progress、数据库
schema 或已冻结平台模块。

## 修改文件

- `lib/sources/remote/remote_http_transport.dart`
  - `RemoteHttpTransport`
  - `RemoteHttpResponse`
  - `RemoteHttpException` / `RemoteHttpFailureKind`
  - `RemoteFeedFetchResult`
  - UTF-8、UTF-16、ASCII、Latin-1/Windows-1252 解码
- `test/unit/remote_http_transport_test.dart`
  - 本地 loopback HTTP 服务器定向测试

## 请求链路

```text
StandardFeedSource.planRequest(...)
        ↓
RemoteHttpTransport.execute(RemoteRequestPlan)
        ├─ HTTP/HTTPS 校验（由 request plan 保证）
        ├─ timeout
        ├─ declared headers
        ├─ redirect policy + max redirect count
        ├─ response byte limit
        └─ status / final URI / response headers
        ↓
RemoteHttpResponse.decodeText()
        ├─ Content-Type charset
        └─ BOM fallback
        ↓
StandardFeedParser.parse(...)
        ↓
RemoteFeedFetchResult (response + parsed feed)
        ↓
现有 ReaderContent 投影边界
```

`fetchStandardFeed` 只接受 2xx 响应，并在允许重定向时再次检查最终 URI
仍属于该 `StandardFeedSource` 的 host/subdomain 范围，避免把 feed 请求静默
带到不属于来源的站点。

## 能力与边界

- 支持 `GET` 等由 `RemoteRequestPlan` 指定的方法、声明过的普通 headers、
  timeout、状态码、最终 URI 和有限重定向。
- 每个响应受 `maxResponseBytes` 限制；超限、超时、网络异常和非 2xx feed
  响应均转换为明确的 `RemoteHttpException` 类型。
- 按响应 `Content-Type` 的 `charset` 解码；无 charset 时依据 BOM，否则使用
  UTF-8。当前安全支持 UTF-8、UTF-16 LE/BE、ASCII、Latin-1/Windows-1252；
  未支持的字符集会显式报错，不猜测编码。
- 认证和 Cookie 仍只保留 c-0 的 capability/reference 边界；本阶段不实现
  credential store、Cookie jar、登录、复杂重试、缓存、WebView 或后台刷新。
- 注入的 `HttpClient` 由调用方所有；默认 client 由 transport 创建并在
  `close()` 释放，避免长期持有连接。

## 定向测试

本阶段新增 6 项测试，覆盖：

1. 普通请求、声明 header、状态码、响应 header 与 UTF-8。
2. followRedirects 开关和最终 URI。
3. HTTP transport 到 RSS parser 的完整连接。
4. 响应大小上限与 timeout。
5. UTF-16 解码及不支持字符集的显式失败。
6. 503 等非成功状态的明确错误。

## Gate

- `flutter analyze --no-pub`：PASS
- `flutter test test/unit/remote_http_transport_test.dart`：PASS（6）
- 全量 `flutter test`：PASS（703）
- `git diff --check`：PASS（exit 0；工作树既有 LF/CRLF 提示，无 whitespace error）

## 冻结范围

本阶段可冻结为统一 HTTP/HTTPS transport 基线。后续若要实现 feed 刷新、
缓存/离线快照、认证或 WebArticle/WebBook 请求，需在该 transport 边界上另立
阶段和定向 Gate，不应把平台网络实现泄漏到 Reader 或 Domain。
