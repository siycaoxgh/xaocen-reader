# M5.9 Data Root Storage Foundation

## 本阶段状态

- 固定 Windows 内部数据键：`XAOCEN\\Reader`
- Windows 标准数据根：`%LOCALAPPDATA%\\XAOCEN\\Reader\\profiles\\default`
- 显式便携数据根：`<exe>\\user_data\\profiles\\default`
- Flutter `<exe>\\data` 保留为运行时资源目录
- Android 继续使用应用私有目录，并增加 `profiles\\default` 范围
- 旧 Roaming 数据根只读发现并安全复制，源目录不删除
- `profileId` 已加入 DataRoot 元数据，默认值为 `default`
- active profile 指针支持 `--profile=<id>`、`XAOCEN_PROFILE` 和持久化 `active_profile.json`
- profile 列表只读取已初始化目录，不打开其他 profile 的数据库
- profile 导出/导入复用哈希 manifest + staged restore，并记录 `sourceProfileId`
- 本地 sync outbox 已建立，但不联网、不复制正文、不替代本地数据库

## 迁移合同

迁移会识别旧的 `com.xaocen`、旧品牌 ProductName 目录和旧的
root-level `library/` + SQLite 布局。复制前会进入 sibling staging 目录，
复制内容包括 SQLite 主文件、`-wal`、`-shm`、managed books、fonts、settings
和 backups。任何现有目标数据库都不会被自动覆盖。
正式运行只扫描已知的 XAOCEN 历史路径；“传入目录作为旧根”的兼容入口仅在测试/迁移工具中启用，避免误触其他应用数据。

## 验证

| Gate | Result |
|---|---|
| 固定产品键路径 | PASS |
| 标准 / 便携路径分离 | PASS |
| 便携模式显式启用 | PASS |
| 旧 root-level library 迁移 | PASS |
| DataRoot 定向测试 | PASS（9 tests） |
| `flutter analyze --no-pub` | PASS |
| 迁移边界审计 | PASS |
| active profile 定向测试 | PASS |
| profile 导出/导入 manifest | PASS |
| sync outbox 定向测试 | PASS（3 tests） |
| 全量 Flutter tests | PASS（650 tests） |

## 已实现的调用边界

- 启动参数：`--profile=<id>`
- 环境变量：`XAOCEN_PROFILE=<id>`
- 便携模式下可用 `DataRoot.setActiveProfile(...)` 写入下一次启动使用的 profile。
- `DataRootBackupService.exportProfile/importProfile` 是完整 profile 传输入口。
- `SyncOutbox` 只接收元数据变更信封；网络上传、账号认证和冲突解决仍未接入。

## 后续待规划

1. 设置页中的 profile 切换 UI（切换时安全关闭当前数据库并重启作用域）。
2. 导出/导入 UI 与冲突预览。
3. 账号认证、远端同步和冲突解决策略。
