/// XAOCEN Reader v4 — 应用版本与数据代际常量。
///
/// M0 只定义常量，不创建正式数据库迁移。
library;

/// 用户可见版本统一为 4.5.8；+5 是持续递增的内部 build number。
const String appVersion = '4.5.8+5';
const String appVisibleVersion = '4.5.8';

/// 数据代际标识。新项目不兼容旧 XAOCEN 运行数据，也不提供迁移入口。
const String dataEpoch = 'v4-local-1';

/// 数据库文件名（M1 起使用）。
const String databaseFileName = 'xaocen_v4_local.sqlite';
