# M5.9c-0 — Remote Source Architecture

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 状态

本阶段已完成“远程来源 Domain 契约”设计，可冻结本阶段。没有真实网络请求、没有网络 provider 接线、没有 Reader/Locator/数据库 schema 改动。

参考了 [HapeLee/legado-with-MD3](https://github.com/HapeLee/legado-with-MD3) 中“可配置来源规则、文章与书籍来源分层、净化后进入统一阅读体验”的产品思路；没有复制 Android、WebView、JavaScript 或具体规则执行实现。

## 契约文件

- `lib/domain/remote/remote_source.dart`
  - `RemoteSource` 共享基础接口
  - `StandardFeedSource`
  - `WebArticleSource`
  - `WebBookSource`
  - Header / Cookie / Auth / Request capabilities
  - `RemoteSourceReaderAdapter`
  - `RemoteSourceConfigCodec` 与 `legado-json` 扩展点
- `test/unit/remote_source_contract_test.dart`
  - 三类来源边界
  - 请求计划与安全引用
  - URI/能力拒绝规则
  - Legado JSON codec 扩展点

## 1. 共享 RemoteSource 契约

```text
RemoteSource
  id: RemoteSourceId
  kind: standardFeed | webArticle | webBook
  endpoint: Uri
  requestCapabilities: RemoteRequestCapabilities
  accepts(Uri)
  planRequest(...): RemoteRequestPlan
```

`RemoteSource` 只描述来源身份、语义类别、允许访问的 endpoint 和请求能力。`planRequest` 只生成可验证的 data plan，不执行网络、不打开 WebView、不运行 JS、不读系统 Cookie。

稳定 identity 由 `RemoteSourceId` 表达；密码、Token、Cookie 值均不进入 source descriptor，也不进入 `ReaderContent`。未来 credential store 只通过 `RemoteCredentialRef` / `RemoteCookieJarRef` 引用。

## 2. Header / Cookie / Auth / Request 边界

### Header

`RemoteHeaders` 只承载来源明确允许的普通请求头，名称归一化为小写。`Authorization`、`Cookie`、`Set-Cookie`、`Proxy-Authorization` 等敏感头禁止直接写入，必须使用 credential/cookie 引用。

### Cookie

`RemoteCookieMode` 只有：

- `disabled`
- `session`
- `persistentJar`

来源通过 `RemoteCookieJarRef` 指向未来受控 Cookie jar；本阶段没有 Cookie 存储、导入或跨域共享能力。

### Auth

`RemoteAuthScheme` 目前只登记：Bearer、Basic、API key、Cookie。`RemoteCredentialRef` 只保存 credential id 与 scheme，实际 secret、系统账号和登录会话属于未来平台安全存储边界。

### Request

`RemoteRequestCapabilities` 统一声明：允许的 headers、认证方式、Cookie 模式、重定向策略、响应字节上限和 timeout。`RemoteRequestPlan` 在生成时校验：

- 仅允许 `http` / `https`；
- URI 必须属于来源 endpoint；
- header 必须在 capability 白名单中；
- credential scheme 必须被来源声明；
- Cookie jar 必须与 Cookie mode 一致；
- 响应大小和 timeout 必须为正值。

这些是安全/资源边界，不是网络实现。后续 transport 必须先执行同一 plan，再处理实际请求、缓存、重试和错误。

## 3. 三类 Source 边界

### StandardFeedSource（RSS / Atom）

语义：一个时间序列 Feed，产生多篇独立文章 item。

专属字段：feed format（rss/atom）与 refresh interval。

职责：读取 feed metadata、文章 URL、发布时间、分类和增量条目。文章正文应成为 ReaderContent 的 article item；Feed 本身不是 WebBookSource，也不拥有章节续更语义。

### WebArticleSource（规则文章源）

语义：一个明确的网页文章快照。

专属字段：article URI、canonical URI、ruleSetId。

职责：使用未来规则提取单篇文章 metadata 与正文。规则只属于 source adapter；Reader 不知道 CSS selector、WebView 或 JS。

### WebBookSource（在线书源）

语义：有稳定书籍 identity、章节目录和持续更新的在线书籍。

专属字段：bookKey、ruleSetId、refresh interval。

职责：解析书籍 metadata、章节顺序、章节 identity 和 source revision，支持后续章节增量。不能把文章列表简单拼成 book，也不能把某一网站的规则写入 Reader。

三者边界：

```text
StandardFeedSource ≠ WebArticleSource ≠ WebBookSource
```

它们共享请求能力与 transport boundary，但不共享内容语义、刷新策略或 identity 规则。

## 4. 统一接入 ContentSource → ReaderContent

未来真实接入必须遵循：

```text
RemoteSource
  → transport plan / fetch / cache
  → existing ContentSource identity
  → ContentCollection / ContentItem / ContentDocument persistence
  → existing ReaderContentAdapter
  → Reader
```

远程 adapter 不得直接创建第二个 Reader、第二个 Pagination、第二个 Progress 或第二个 Locator。`RemoteSourceReaderAdapter` 只是未来 adapter 的类型边界；内容持久化后仍通过现有 `ReaderContentAdapter` 投影进入 Reader。

Remote source revision 必须参与内容 identity/完整性检查，但不能替代 absolute UTF-16 Locator。内容更新时，只有在正文版本可映射时才允许保留进度；无法映射必须进入待复核，而不是静默移动位置。

## 5. Legado JSON compatibility

本阶段只提供 `RemoteSourceConfigCodec` 扩展点与 `legado-json` format 标识，不解析、不导入、不执行 Legado JSON。

未来 codec 必须：

- 将外部 JSON 映射为 `RemoteSource` 语义对象，而不是把 JSON 当成 Reader 配置；
- 保留原始 source id、rule set version 和 provenance；
- 将 header/auth/cookie 映射到 capability + credential references；
- 拒绝脚本、任意文件访问、未声明域名和超出资源上限的规则；
- 不把 Android/JavaScript runtime 依赖带入 Domain。

## 6. 当前明确不实现

- HTTP client、WebView、JS engine、真实 RSS/Atom fetch；
- 规则执行、网页净化、翻译、分页或远程封面下载；
- 登录、OAuth、Cookie 导入、账号中心；
- 数据库 schema、RemoteSource UI、网络同步和后台刷新；
- 任何 Reader、Locator、Progress、Pagination 改造。

## 7. 后续任务建议

### M5.9c-1 — Remote Transport Boundary

定义平台中立 transport、缓存、超时、重试、取消、离线快照和网络错误模型；仍不接具体网站。

### M5.9c-2 — Content Transform Contract

定义净化/替换/翻译的 source revision 与 UTF-16 anchor map，保证变换不会破坏 Locator、Bookmark 和 Progress。

### M5.9c-3 — First Offline Fixture Adapter

用本地 fixture 模拟 RSS/Article/Book 三种来源，验证从 ContentSource 持久化到 ReaderContent 的统一链路；仍不启用真实网络和登录。

## 验证

- `flutter analyze --no-pub`：PASS
- `test/unit/remote_source_contract_test.dart`：PASS（4 项）
- 生产网络逻辑、Reader、Locator、数据库 schema：未修改
- `git diff --check`：待最终工作树 Gate 统一执行；当前没有新增 whitespace error

## 阶段结论

**REMOTE SOURCE ARCHITECTURE = PASS / FROZEN**

可以进入 M5.9c-1，但下一阶段仍应先做 transport/transform contract 和离线 fixture，不直接实现真实网络源。
