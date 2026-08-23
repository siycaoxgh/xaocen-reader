# M5.9c — Remote Content Capability Summary

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 阶段总状态

| 阶段 | 结果 | 说明 |
|---|---|---|
| M5.9c-0 | PASS / FROZEN | RemoteSource、三类来源边界、请求能力与 Legado JSON 扩展点 |
| M5.9c-1 | PASS / FROZEN | Canonical/Derived、UTF-16 position map、变换 provenance |
| M5.9c-2 | PASS / FROZEN | Profile membership、SyncBoundary、SyncOutbox 投影 |
| M5.9c-3 | PASS / FROZEN | 离线 RSS 2.0 / Atom 解析与 ReaderContent 投影 |
| M5.9c-4 | PASS / FROZEN | 统一 HTTP/HTTPS transport、超时、重定向、响应限制、字符集与 RSS 接入 |
| M5.9c-5 | PASS / FROZEN | RSS/Atom 订阅、profile-scoped 持久化、手动刷新与文章去重更新 |
| M5.9c-6 | PASS / FROZEN | RSS/Atom 订阅入口、Feed/文章列表、手动刷新、现有 Reader 打开与响应式 UI；兼容性验收见 c-6.3 |
| M5.9c-6.3 | PASS / FROZEN | 阮一峰、Solidot、GitHub Changelog、少数派、China Daily、小众软件来源边界验收 |

## 阶段报告

- [M5.9c-0 Remote Source Architecture](M5_9C_0_REMOTE_SOURCE_ARCHITECTURE.md)
- [M5.9c-1 Content Transform Contract](M5_9C_1_CONTENT_TRANSFORM_CONTRACT.md)
- [M5.9c-2 Sync Boundary + Profile Membership](M5_9C_2_SYNC_BOUNDARY_PROFILE_MEMBERSHIP.md)
- [M5.9c-3 RSS / Atom Foundation](M5_9C_3_RSS_ATOM_FOUNDATION.md)
- [M5.9c-4 Remote HTTP Transport](M5_9C_4_REMOTE_HTTP_TRANSPORT.md)
- [M5.9c-5 RSS Subscription Persistence + Refresh](M5_9C_5_RSS_SUBSCRIPTION_PERSISTENCE_REFRESH.md)
- [M5.9c-6 RSS Product Loop / UI](M5_9C_6_RSS_PRODUCT_LOOP_UI.md)
- [M5.9c-6.3 RSS Compatibility Acceptance + Freeze](M5_9C_6_3_RSS_COMPATIBILITY_ACCEPTANCE.md)

## 已建立的统一边界

```text
RemoteSource
  ├─ StandardFeedSource (RSS / Atom)
  ├─ WebArticleSource (规则文章，未实现)
  └─ WebBookSource (在线书源，未实现)
          │
          ▼
ContentCollection / Item / Document
          │
          ▼
ReaderContent
          │
          ▼
现有 Reader / Locator / Progress

StandardFeedSource
          │
          ▼
RemoteHttpTransport
          ├─ timeout / redirect / headers / response limit
          └─ charset decode / status boundary
          │
          ▼
StandardFeedParser

FeedSubscriptionRepository
  └─ DataRoot.settings/rss_subscriptions.json

FeedSubscriptionsPage
  ├─ Feed list / add / remove / manual refresh
  └─ FeedArticleListPage
       └─ existing ReaderPage (transient remote article session)
```

- `UserProfile ≠ DataRoot ≠ ContentSource ≠ SyncProvider`。
- Canonical Content 是唯一 ReaderLocator 坐标；Derived Content 只能通过显式 map 使用。
- 净化、替换、翻译属于 Content Transform，不得直接改写 canonical 文本或另建位置真源。
- RSS/Atom 是 feed/item 语义，不与 WebArticleSource、WebBookSource 混用。
- SyncOutbox 只接收 profile-scoped metadata/user state；正文、文件、缓存、密钥和 TTS session 保持本地。

## 修改文件总览

### Domain

- `lib/domain/remote/remote_source.dart`（c-0）
- `lib/domain/reader/content_transform.dart`（c-1）
- `lib/domain/sync/profile_sync_boundary.dart`（c-2）

### Source adapter / parser

- `lib/sources/remote/standard_feed_parser.dart`（c-3）
- `lib/sources/remote/remote_http_transport.dart`（c-4）
- `lib/domain/remote/feed_subscription.dart`（c-5）
- `lib/data/repositories/feed_subscription_repository.dart`（c-5）
- `lib/sources/remote/feed_subscription_service.dart`（c-5）
- `lib/app/feed_subscriptions_page.dart`（c-6）
- `lib/app/feed_article_reader_page.dart`（c-6）
- `lib/app/providers.dart` / `lib/app/router.dart` / `lib/app/app_shell_page.dart`（c-6 wiring）

### Tests

- `test/unit/remote_source_contract_test.dart`
- `test/unit/content_transform_contract_test.dart`
- `test/unit/profile_sync_boundary_test.dart`
- `test/unit/standard_feed_parser_test.dart`
- `test/unit/remote_http_transport_test.dart`
- `test/unit/feed_subscription_test.dart`
- `test/widget/feed_subscriptions_page_test.dart`

### Reports

- `docs/M5_9C_0_REMOTE_SOURCE_ARCHITECTURE.md`
- `docs/M5_9C_1_CONTENT_TRANSFORM_CONTRACT.md`
- `docs/M5_9C_2_SYNC_BOUNDARY_PROFILE_MEMBERSHIP.md`
- `docs/M5_9C_3_RSS_ATOM_FOUNDATION.md`
- `docs/M5_9C_4_REMOTE_HTTP_TRANSPORT.md`
- `docs/M5_9C_5_RSS_SUBSCRIPTION_PERSISTENCE_REFRESH.md`
- `docs/M5_9C_6_RSS_PRODUCT_LOOP_UI.md`

## Gate 汇总

- c-0 full Flutter tests：PASS（680）
- c-1 full Flutter tests：PASS（686）
- c-2 full Flutter tests：PASS（692）
- c-3 full Flutter tests：PASS（697）
- c-4 focused transport tests：PASS（6）
- c-4 full Flutter tests：PASS（703）
- c-5 focused subscription tests：PASS（4）
- c-5 full Flutter tests：PASS（707）
- c-6 focused RSS UI tests：PASS（4）
- c-6 full Flutter tests：PASS（711）
- c-6 live RSS/Atom transport + parser acceptance：PASS（BBC RSS 30 items，GNOME Atom 50 items）
- c-6.3 live compatibility snapshot：PASS（阮一峰 Atom、Solidot RSS、GitHub Changelog RSS）；少数派/China Daily 按 SOURCE LIMITATION 记录；小众软件按 NETWORK/SOURCE AVAILABILITY 记录
- 当前全量 Flutter tests：PASS（717）
- `flutter analyze --no-pub`：各阶段 PASS
- 各阶段定向测试：PASS
- `git diff --check`：各阶段 PASS；仅工作树已有 LF/CRLF 警告，无 whitespace error

## 当前未实现 / 后续建议

1. **M5.9d — Feed Library Projection**：把已持久化的 feed/item 快照接入现有 Library/DataRoot 展示与 Reader 打开；保持不改变 Locator/Progress。c-6 当前文章阅读使用临时会话，正式投影前不应把它当作本地书籍。
2. **M5.9e — Transport Extensions**：在当前 transport 边界上评估取消、缓存、离线快照、重试和认证；逐项增加安全 Gate。
3. **M5.9f — Source Rule Sandbox**：在安全资源限制下评估 WebArticle/WebBook 规则与 Legado JSON compatibility；不把 JS/Android runtime 带进 Domain。

真实账号、云同步、冲突合并、网页全文抓取、翻译服务、脚本和复杂媒体均为后续计划，不标记为失败或完成。

## 冻结结论

M5.9c-0 至 c-6.3 已通过各自 Gate 并冻结。RSS/Atom 的来源限制、网页全文边界和单源网络可用性均已正式记录；不把摘要缺全文或单源超时误判为 Parser 失败。没有修改 Reader 核心、absolute UTF-16 Locator、Pagination、Progress、数据库 schema 或已冻结 Windows/Android 模块。
