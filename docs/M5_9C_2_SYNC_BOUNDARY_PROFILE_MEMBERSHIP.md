# M5.9c-2 — Sync Boundary + Profile Membership

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 阶段结论

**SYNC BOUNDARY + PROFILE MEMBERSHIP = PASS / FROZEN**

本阶段只补齐本地 Profile 与未来同步的边界，没有账号登录、服务器、网络 provider、数据库 schema 或现有 Reader 模块改动。

## 修改文件

- `lib/domain/sync/profile_sync_boundary.dart`
  - `ProfileDataScope`：profileId 与 rootId 的显式本地 scope。
  - `ProfileMembership`：Profile 与书架/订阅/来源规则的 membership 关系。
  - `SyncEntityType`、`SyncDisposition`、`SyncBoundary`：唯一同步分类 truth。
  - `SyncOutboxSpec`：与现有 `SyncOutbox.enqueue` 字段一致的 domain-to-data 边界。
  - `SyncProvider`：未来传输 provider 的最小接口，不含网络实现。
- `test/unit/profile_sync_boundary_test.dart`
  - scope/identity 分离、membership stable key、同步分类、Outbox 投影和 local-only 拒绝。

## 身份与 membership

```text
UserProfile (用户域身份)
        │ membership
        ▼
Library / Collection / Subscription / SourceRule
        │ local storage
        ▼
DataRoot (物理数据 scope)
```

`UserProfile` 不包含目录；`DataRoot` 不代表账号；`ContentSource` 仍是内容来源身份；`SyncProvider` 只是未来传输能力。Profile 切换仍遵循现有重启/重新 bootstrap 边界，不热替换正在运行的数据库或 Reader。

## 当前同步边界

### 未来可同步（profile-scoped）

- 书架 membership
- collection metadata
- Reader progress
- bookmarks
- history
- subscriptions
- source rules
- Reader/App preferences

### 必须本地保留

- canonical/normalized/raw content 与本地文件
- cover file 本体
- cache
- auth secret / cookie 等敏感凭据
- TTS transient session

### 待账号/冲突策略后再决定

- Profile identity 本身

以上分类集中在 `SyncBoundary.classify`，不由 UI、数据库表或某个 provider 各自猜测。

## SyncOutbox 对接

`SyncBoundary.outboxSpec` 只允许 `syncable` entity 生成 `SyncOutboxSpec`，字段直接对应现有 `SyncOutbox.enqueue` 的 `profileId/rootId/entityType/entityId/operation/payload`。它不写磁盘；现有 `SyncOutbox` 仍是唯一 append-only 本地 outbox 实现。

normalized 文本、文件和密钥即使存在本地变更，也不能通过该边界伪装成可同步 metadata。

## 验证

- `flutter analyze --no-pub`：PASS
- `test/unit/profile_sync_boundary_test.dart`：PASS（6 项）
- 全量 Flutter tests：PASS（692 项）
- `git diff --check`：PASS（仅现有换行格式提示，无 whitespace error）

## 是否可冻结

契约不需要稳定模块重构；本阶段可冻结并进入 M5.9c-3。真实账号、服务器和冲突合并仍明确属于后续阶段。
