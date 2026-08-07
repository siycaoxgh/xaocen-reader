# M3.4 目录平铺展示调整 — 结果报告

- 分支：`fix/m3-flat-toc`
- 基线：`ce2ff98`（M3.3 HEAD）
- 版本：`0.1.0-dev.3+3`（M3.4 未升版本）
- 日期：2026-08-07

## 1. 删除了哪些折叠状态（§四）

`_TocSheetState` 中彻底移除（无死代码）：
- `_collapsed`（折叠卷 id 集合）、`_toggleVolume`、`_autoExpandParents`（含 initState 调用）
- `TocIndexLogic.parentVolumeIdsOf`、`TocIndexLogic.visibleEntries`（折叠可见列表生成）
- 折叠图标（expand_more/expand_less）、volume 点击折叠行为
- 展开后重新计算 visibleIndex 的 `visibleIndexFor`（重命名为 flat 语义的 `displayIndexFor`）
- `visibleTocEntries` getter（改为 `_flatEntries` = 原始 toc）

## 2. flatTocEntries 如何生成（§三/§五）

- `_flatEntries => widget.toc`：collection 所有真实 TocEntry **按原顺序**（orderIndex 排序，与正文 startCharacterOffset 顺序一致）直接渲染，**不经过任何层级过滤**。
- volume 视觉：稍高字重（w600）+ 轻量「卷」badge（22×22 secondaryContainer 圆角标签）+ 上方 14px 间距；**无展开箭头**；点击跳转 `volume.startCharacterOffset`。
- chapter：完整 `displayTitle` + 当前章节高亮 + 轻微一级缩进（left 28，不按 parentId 多层加深）；避免树形文件管理器风格。
- 数据模型完全未动：kind/parentId/level/orderIndex/start/endCharacterOffset/displayTitle 保留，volume/chapter 语义保留。

## 3. 层级数据如何继续保留（§十一红线）

- 未删除 parentId / volume；未将 volume 转 chapter；未修改章节 offset、parser、scanner、hash 合同、Drift schema。
- **正式合同**：`TOC hierarchy is advisory; source order is authoritative.` 层级仅影响视觉表现，不影响目录项是否可见。

## 4. 当前章节自动定位如何简化（§六）

1. `currentTopOffset`（ReaderVisibleRange 顶部实测）→ `currentChapterFor`（最后一个 `startCharacterOffset <= topVisible` 的 chapter，遍历全表不提前 break，容忍异常乱序；volume 不算当前章节）
2. flat 列表中 `displayIndexFor` 直接得下标（不再查父卷/展开/重建列表）
3. 阶段一索引级 jumpTo（extent 未稳定 bounded 重试 ≤10；scroll 未 attach 也 bounded 重试——本轮修复）
4. 目标 Widget 构建后 `ensureVisible` 对齐视口 35%（ctx 未构建时用实测行高重算，bounded ≤8）
5. 保留：每次打开最多一次、用户滚动后不自动拉回、「定位当前章节」按钮（`_locatePressed`）、关闭再打开重新定位
6. 位置在第一章前：不高亮 chapter 或高亮第一项（合同允许）；无章节显示「全文」

## 5. 异常层级 fixture 结果（§八/§九）

故意异常 fixture：第一卷 / 第1章 / 第2章 / 第二卷 / 第三卷 / 第1章 / 第2章（幽灵 parentId）/ 第四部 / 第99章 / 番外（无 parent）。
- 全部 10 项平铺可见（滚动遍历确认头部/中部/尾部）✅
- 幽灵 parentId 不隐藏 chapter ✅
- 连续 volume、卷/部混用按 orderIndex 稳定显示 ✅
- 无崩溃、点击可跳 ✅

## 6. 测试

- 单元 `toc_index_test` 10 项（currentChapterFor 5 + 容错 2 + displayIndexFor 3）全过
- Widget `toc_scroll_test` 12 项（平铺可见/无折叠按钮/卷内章节直接可见/258·473 定位/异常 fixture 4 项/滚动不拉回/定位按钮/无章节全文）全过
- **全量 251 项单元+widget 全过**；5 个保留集成测试全过；verify.ps1 全绿（pub get/format/analyze/test/集成/Windows Release/APK Debug/diff --check）
- 修复真实缺陷：`_locateToCurrent` 在 scroll 未 attach 时无重试直接返回（加 bounded retry）；`_userScrolled` 置位未触发 setState（按钮不显示，加 `_markUserScrolled`）；ScrollUpdate + dragDetails 也识别为用户滚动

## 7. Windows 真实文件结果（真实库 4 collection，一次性验收测试已删除）

| collection | 章节 | 卷 | 结果 |
|---|---|---|---|
| 苟在初圣魔门当人材(1-500章) | 473 | 0 | ✅ 平铺/高亮/跳转/不拉回 |
| 青山(501-809章) | 294 | 3 | ✅ 平铺（3 卷全显）/卷点击跳转/高亮 |
| 因果快递20260625 | 53 | 1 | ✅ 平铺/卷跳转/高亮 |
| 无章节数字测试 | 0 | 0 | ✅ 目录显示「全文」 |

验证覆盖：所有章可见（滚动遍历到尾部）/ volume 无折叠箭头 / 当前章打开目录自动定位高亮 / 点击 chapter 正文跳转 / 点击 volume 跳卷首 / 浏览目录不拉回。

## 8. Android 结果

**待设备连接后补做**（无线调试未开启，设备离线）。验证项同 §十：安装覆盖 / 书架数据存留 / 打开已导入书 / 目录平铺无折叠箭头 / 当前章自动定位 / 点击 chapter·volume 跳转 / 浏览不拉回 / 0 crash。

## 9. 最终 HEAD / 工作区状态

- HEAD 见 git log（提交后更新）
- 工作区 clean（提交后）
- M3.4 完成，不自动进入 M4。
