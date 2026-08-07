# XAOCEN Reader v4 — 文档索引

本目录存放工程内文档。

## 权威输入（工程外，位于仓库父目录 `xaocen-reader-v4/`）

| 文件 | 说明 |
|---|---|
| `AAA/产品定义.txt` | 产品定义 |
| `AAA/V3 XAOCEN Reader-统一原型.html` | V3 统一 UI 原型 |
| `AAA/xaocen-v3-design-constraints.html` | V3 设计与技术约束（33 条已确认决策） |
| `../README_ENGINE_DECISION.md` | 引擎决策（12 项，Pre-M0 审计） |
| `../SPIKE_RESULT.md` | Spike 验证结果（3 Spike + Android 真机 8/8） |

> 三份权威规范（产品定义/原型/约束）不得被任何脚本修改。

## 阶段原始报告（仓库根目录，作为历史证据保留，勿修改）

| 文件 | 说明 |
|---|---|
| `M0_RESULT.md` | M0 工程骨架（0.1.0-dev.1+1） |
| `M1_RESULT.md` | M1 TXT 标准化与索引管线（0.1.0-dev.1+1） |
| `M2_RESULT.md` | M2 本地书库 / Drift 四层（0.1.0-dev.2+2） |
| `M3_RESULT.md` | M3 纵向 Reader + 精确恢复（0.1.0-dev.3+3, schema 2） |
| `M3_1_HASH_FIX_RESULT.md` | M3.1 normalizedHash P1 修复 |
| `M3_2_TOC_JUMP_RESULT.md` | M3.2 目录完整标题 + 精确跳转（parserVersion 2.0.0） |
| `M3_3_TOC_SCROLL_RESULT.md` | M3.3 目录自动定位 + 深色可读性 |
| `M3_4_FLAT_TOC_RESULT.md` | M3.4 平铺目录 + Android 真机 13/13 |
| `PROJECT_AUDIT_RESULT.md` | M3 阶段封存审计报告（本目录） |

## 长期文档（本目录，M3 封存起维护）

| 文件 | 说明 |
|---|---|
| `CHANGELOG.md` | 按版本的变更记录（Keep a Changelog 风格） |
| `PROJECT_HISTORY.md` | 完整工程时间线（含失败与修复；含版本/schema 历史表） |
| `ARCHITECTURE_CURRENT.md` | 当前架构与合同（含 Non-negotiable invariants） |
| `ENGINEERING_LESSONS.md` | 永久踩坑簿（统一格式 23 条 + 附录） |
| `KNOWN_ISSUES.md` | 已知问题 / 限制 / 延后 / 回归敏感项 |
| `TEST_VALIDATION_MATRIX.md` | 验证矩阵（自动 vs 真人，Win vs Android） |
| `CONTENT_NAVIGATION_CONTRACT.md` | 全局内容导航合同（长期产品规则） |
