# M5.7s.9c-1 — 青山 TXT Chapter / Locator Diagnostic

## Scope and method

本轮只诊断，未修改生产代码、TXT、数据库、chapter parser、Locator 或 Reader UI。读取的文件是：

`C:\Users\TOM\Desktop\测试\青山(501-809章).txt`

按现有生产链路执行 UTF-8 解码、`TxtNormalizer.normalize`、`TxtTocScanner.scanRaw/scan`，并以 normalized UTF-16 code-unit offset 对照原文行号。现有 `TocEntry` 和数据库查询均保持 parser 产生的顺序。

## Raw / normalized facts

- RAW UTF-8 bytes: `2,916,161`
- RAW decoded UTF-16 code units: `1,007,252`
- NORMALIZED UTF-16 code units: `983,263`
- 原始/规范化差异来自 CRLF → LF（未删除正文字符）
- 原文标题行共 294 个，章节号范围 `474..767`
- 原文真实重复章节号：`496` 两次、`509` 两次
- 原文缺少：`613`、`614`
- 因而该文件实际不是完整的 `501..809`，且标题内容确实存在重复/缺号；不能自动重排。

## Parser result

- raw parser hits: `314`（包含正文重复标题候选）
- deduped TOC entries: `297`（3 volume + 294 chapter）
- chapter entries: `294`
- parser 顺序按扫描到的 normalized 行顺序保留；没有按章节号排序。
- `496`、`509` 的正文重复候选被现有相邻去重规则处理；`509` 的两个独立标题行都保留，因为它们是原文中的两个真实章节标题。

代表性对照（`TOC index` 为全 TOC 平铺索引；volume 不计 chapter index）：

| 位置 | RAW / normalized 标题 | parser chapter index | UTF-16 offset | TOC index |
|---|---|---:|---:|---:|
| 开头 | 第474章 血 | 0 | 48 | 0 |
| 开头 | 第475章 雪中送炭 | 1 | 3,840 | 1 |
| 501 起点 | 第501章 二房余孽 | 28 | 90,435 | 28 |
| 异常附近 | 第509章 盘账 | 36 | 115,971 | 36 |
| 异常附近 | 第509章 盘帐 | 37 | 119,658 | 37 |
| 中间 | 第615章 劝行 | 141 | 472,008 | 142 |
| 中间后 | 第621章 共赴刀山，火海，春秋，冬夏 | 147 | 496,105 | 148 |
| 结尾 | 第765章 不过如此武襄候 | 291 | 973,282 | 294 |
| 结尾 | 第766章 齐头井进 | 292 | 976,308 | 295 |
| 结尾 | 第767章 家书 | 293 | 978,439 | 296 |

`TOC index` 与 chapter index 的差值来自 3 个 volume 项，不代表章节乱序。所有上述 offsets 单调递增。

## Locator / TOC click audit

现有实现将 `TocEntry.startCharacterOffset` 直接写入 `toc_entries`，Repository 查询不排序重排，Reader TOC 点击将该 offset 直接传给 vertical `ReaderController.jumpToOffset` 或 paged `PagedReaderController.jumpToOffset`；没有发现 offset 转换或章节号排序步骤。因此对这些条目：

`expected offset = parser/database startCharacterOffset = actual jump target offset`

本轮静态/离线诊断未发现 expected/actual divergence。点击第 509 章时，两个同号条目仍由标题文本和 offset 区分，不能依据章节号单独判断。

## Gate results

- RAW TXT ORDER = **FAIL（按“501..809 完整连续”标准）**；按“忠实保留原文件顺序”标准为 PASS。原文自身有重复 496/509、缺 613/614、只到 767。
- PARSER ORDER = **PASS** — parser 未重新排序，输出按 normalized 扫描顺序。
- TOC ORDER = **PASS** — database/UI 使用同一 parser order；volume 只增加平铺索引位置。
- UTF16 OFFSET = **PASS** — 标题 offsets 为 normalized UTF-16 code-unit 起点，单调递增。
- TOC LOCATOR = **PASS（静态链路）** — 未发现 offset 被改写；真实设备点击仍建议用同一 TXT 做人工确认。

## ROOT CAUSE

**ROOT CAUSE = 测试 TXT 本身的章节序列/标题存在重复与缺号，非当前 parser 重排或 Locator 偏移错误。**

特别是 `第509章 盘账` 与 `第509章 盘帐` 是原文的两个独立标题；`613/614` 在原文没有匹配标题。XAOCEN 应继续忠实遵循原文件内容顺序，不应自动补章、重编号或排序。
