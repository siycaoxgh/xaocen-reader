# M5.9a-3 — UserProfile Registry + Local Scope Events

## 状态

本阶段已完成，可冻结。没有账号登录、切换 UI、网络同步或数据库 schema 变更。

## Identity 与 storage boundary

`UserProfile` 是本地/未来账号映射的领域身份：`id`、显示名、可选 `accountId` 和时间戳。它不包含路径、数据库句柄、`DataRoot` 或会话状态。

`DataRoot` 仍然是物理存储作用域：每个 profile 继续使用独立数据库、书库、ReaderPreferences、进度、书签、历史和 outbox。registry 只保存 profile 元数据，位于 profile scope 目录下的 `profile_registry.json`。

## Registry

`UserProfileRegistry`：

- 自动确保当前 `default` profile 存在；默认显示名为“默认用户”。
- 支持本地 profile metadata 的 list/create/update。
- profile id 使用与 DataRoot 兼容的安全字符约束，不进行路径穿越或静默改写。
- 不创建账号、不访问网络、不替换当前数据库。

## Scope switch event

`requestSwitch(profileId)` 只持久化下一次启动要使用的 profile，并发出 `LocalProfileScopeEvent`：

- `selectionPersisted`
- fromProfileId / toProfileId
- `requiresRestart`

当前运行中的 DataRoot、ProviderScope、Reader 和数据库不会被热切换。下一次 bootstrap 读取既有 `active_profile.json` 后才打开目标 profile。这是本阶段的明确生命周期边界。

## 后续预留

未来账号登录可通过 `UserProfile.accountId` 映射；同步仍应在 outbox/sync 层处理，不应把网络会话或云身份塞入 DataRoot 或 Reader。
