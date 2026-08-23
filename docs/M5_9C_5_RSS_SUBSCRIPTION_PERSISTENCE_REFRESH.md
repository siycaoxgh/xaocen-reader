# M5.9c-5 — RSS Subscription Persistence + Refresh

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 结论

**PASS / FROZEN**。RSS/Atom 现已具备显式订阅、删除、profile-scoped 持久化与
手动刷新能力。实现复用 c-4 HTTP transport 和 c-3 parser，没有修改 Reader、
absolute UTF-16 Locator、Progress 或 Drift schema。

## 持久化/刷新链路

```text
StandardFeedSource
        ↓ addSubscription
FeedSubscriptionService
        ↓
FeedSubscriptionRepository
        ↓
DataRoot.settings/rss_subscriptions.json

refresh(sourceId)
        ↓ 从当前 profile 读取订阅
StandardFeedSource.toSource()
        ↓
RemoteHttpTransport.fetchStandardFeed()
        ↓
StandardFeedParser.parse()
        ↓
FeedSubscriptionRepository.saveRefresh()
        ↓
更新 Feed metadata + upsert 文章快照
```

存储文件属于当前 `DataRoot`，并写入 `profileId`、`rootId` scope 标记；读取时
会拒绝属于其他 profile 或 DataRoot 的副本。写入采用临时文件 + 原子替换。
删除订阅会同时删除该订阅及其持久化文章快照，不触碰 Reader 内容、进度或书签。

## 去重与更新规则

- 订阅 identity：`StandardFeedSource.id.value`；重复添加同一 source id 是幂等
  更新，不会产生第二条订阅。
- 文章 identity：复用 parser 生成的稳定 `guid/id → link → title+publishedAt`
  规则，最终带 source id 前缀。
- 刷新按文章 identity upsert：已有文章更新标题、正文、摘要、作者、链接和
  发布时间，保留 `firstSeenAt`；新文章追加一次。
- 同一响应内重复 identity 只保留一条。
- 本次 feed 未返回的既有文章仍保留，避免 RSS 窗口缩短造成静默丢失。
- Feed 标题、作者、描述、endpoint 和最后刷新时间随刷新更新。

## 能力边界

- 支持添加、删除、列出订阅和显式手动刷新。
- 不包含后台刷新、通知、账号、云同步、复杂 Cookie/登录或 WebView。
- 当前没有新增 Drift 表；JSON 文件是 profile-scoped subscription snapshot，
  不是 Reader/Library 数据库的第二套进度或 Locator truth。
- 未来同步仍可沿用 c-2 的 `SyncEntityType.subscription` 边界；本阶段不写
  SyncOutbox，也不启动网络同步。

## 修改文件

- `lib/domain/remote/feed_subscription.dart`
- `lib/data/repositories/feed_subscription_repository.dart`
- `lib/sources/remote/feed_subscription_service.dart`
- `test/unit/feed_subscription_test.dart`

## Gate

- `flutter analyze --no-pub`：PASS
- `flutter test test/unit/feed_subscription_test.dart`：PASS（4）
- 全量 `flutter test`：PASS（707）
- `git diff --check`：PASS（exit 0；仅工作树既有 LF/CRLF 提示）

## 冻结结论

本阶段可以冻结。下一阶段若要做订阅 UI、刷新错误状态、离线快照或同步，
应继续沿用本阶段的 profile/DataRoot 与 stable identity 边界，不应把订阅内容
写入 ReaderProgress 或另建 Reader 实现。
