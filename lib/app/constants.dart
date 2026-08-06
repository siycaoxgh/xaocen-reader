/// XAOCEN Reader v4 — 应用版本与数据代际常量。
///
/// M0 只定义常量，不创建正式数据库迁移。
library;

/// 应用内部版本。全新版本代际，不沿用旧项目 0.14.x。
/// M3：纵向滚动 Reader + 精确位置恢复。
const String appVersion = '0.1.0-dev.3+3';

/// 数据代际标识。新项目不兼容旧 XAOCEN 运行数据，也不提供迁移入口。
const String dataEpoch = 'v4-local-1';

/// 数据库文件名（M1 起使用）。
const String databaseFileName = 'xaocen_v4_local.sqlite';
