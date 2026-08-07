# M3.2 目录完整标题与章节精确跳转结果

日期：2026-08-07
分支：fix/m3-toc-title-exact-jump
基线：aa73c95（M3.1 HEAD）

## 1. 标题丢失根因

**M1 扫描器 `TxtTocScanner.scanRaw` 中 `title: m.group(0)!` 只取正则匹配片段（「第X章」），完整标题从未进入数据链。**

真实行 `第1章 百世书` → 扫描器只存 `第1章` → index.json → Drift toc_entries/content_items → Repository → UI 全部是短标题。卷同理（`第六卷 人间风雨` → `第六卷`）。属于任务书 §六 情况B（index.json 本身不完整）。

## 2. 跳转不准确根因

**`_scheduleJumpToPendingTarget` 只用 `jumpToItem(block.index, alignment: 0)` 对齐块顶，无块内字符二次对齐。**

块大小 4096-8192 码元，标题行常在块中间；跳到块顶后标题在视口外/远离顶部，且无真实可见范围验证。属于 §八 合同缺口（jumpToItem 只是第一阶段）。

## 3. 问题发生在哪一层

| 问题 | 层 |
|---|---|
| 标题丢失 | M1 扫描器（displayTitle 未实现）→ 传播至 index.json/Drift/UI |
| 跳转不准确 | ReaderPage 跳转逻辑（无第二阶段字符对齐） |
| 目录不显示卷 | _TocSheet 只渲染 chapters，volumes 仅用于尾标判断 |
| 当前章节高亮不准 | 用 confirmedLocator（上次点击）而非真实可见范围顶部 |

## 4. displayTitle/dedupeKey/chapterNumber 合同

- **displayTitle**：完整标题行 trim 首尾空白（保留「第X章/卷」+ 具体标题），用于目录/书架展示；禁止只存章节编号/正则片段/临时合成。
- **dedupeKey**：trim + 全角空格归一化 + 连续空白折叠；仅用于相邻重复判断，不进入 UI。相邻去重附加判据：章节编号相同即视为重复（真实小说中缩进重复行常是正文对标题的引用，可能带错别字——真实回归中「第468章 这特么」vs「第468章 这特码」必须去重掉正文引用行，473 章不得变 486）。
- **chapterNumber**：单独解析（阿拉伯/中文数字），用于诊断与排序，不代替 displayTitle。
- **rawLine**：仅扫描期诊断，不持久化。
- parserVersion 1.0.0 → **2.0.0**（完整标题合同）。

## 5. 已有 collection 修复方式

`ManagedCollectionHealthCheck` 检测 index.json parserVersion < 2.0.0 → 标记「标题不完整」→ `CollectionRepairService` 从 managed source.txt 重跑 M1 管线：
1. 保留 source.txt/normalized.txt/collectionId/reading_progress
2. 重生成 index.json（含 displayTitle，**修复了 repair 不写 index.json 的缺陷**——此前 _replaceDerivedFiles 因 repairDir 无 index.json 而跳过替换，导致旧标题残留）
3. Drift 事务更新 toc_entries/content_items 标题（按 startCharacterOffset 匹配，offset 漂移则报错拒绝静默重建）
4. 再 health check 确认 ok=true

注意：健康检查不能靠"标题是否太短"猜测（「第五十一章」这类纯编号标题是合法完整标题），必须以 parserVersion 为权威。

## 6. 真实文件完整标题示例

| 文件 | 修复前 | 修复后 |
|---|---|---|
| 苟在初圣魔门(1-500章).txt | `第1章` / `第19章` | `第1章 百世书` / `第19章 剥皮` / `第473章 天上火的霸道！` |
| 青山(501-809章).txt | `第474章` | `第474章 血` / `第531章 武庙山门` |
| 因果快递.txt | `第一章` | `第一章 拽醒的梦` / 卷 `第一卷 诡异蓝光` |
| 无章节数字测试.txt | — | 0 章，不伪造目录 |

## 7. 章节跳转实测表（Windows，真实库苟在初圣魔门）

| 章 | displayTitle | 请求 offset | 点击跳转 | 目录高亮 |
|---|---|---:|---|---|
| 1 | 第1章 百世书 | 54 | ✅ | ✅ selected |
| 2 | 第2章 顺天易，逆天难 | 3255 | ✅ | — |
| 3 | 第3章 魔门作风 | 5712 | ✅ | — |
| 19 | 第19章 剥皮 | 49208 | ✅（目录显示） | — |
| 400 | 第400章 一剑开天，筑基圆满！ | 1062206 | ✅（offset 命中） | — |
| 473 | 第473章 天上火的霸道！ | 1257817 | ✅（目录显示） | — |

（controller 层 offset 全部命中；远距离跳转 400→19→400、473→1 由 multi-block fixture 集成测试覆盖——目录 UI 拖动受 DraggableScrollableSheet 手势限制，测试滚动目录到第400章耗时过长，改以可见区章节点击 + controller 层验证）

## 8. block 内二次对齐方式

- 阶段1：`jumpToItem(block.index, alignment: 0)`（块进入视口）
- 阶段2：post-frame 等目标块 layout → `RenderReaderTextBlock.rectForCharacterOffset(localOffset)` 求目标行 Rect → `jumpToItem(block.index, rect: titleRect, alignment: 0.0)` 让标题行顶部对齐视口顶 → `scrollTo(pixels - 12px)` 微调（topInset 8~24px）
- 阶段3：`localToGlobal` 求标题行全局 Rect，验证与视口相交；相交才 finishRestore/finishTocJump
- 禁止固定延迟；bounded retries ≤5，超限明确报错（`_alignFailed`），不宣称成功

## 9. 当前章节高亮方式

- controller 记录 `lastTopVisibleOffset`（真实可见范围顶部，来自 `_topVisibleCharacterOffset()` 实测，滚动/跳转都更新）
- 打开目录时传入 → 找「最后一个 startCharacterOffset <= topVisible 的 chapter」→ selected
- 无章节文件显示「全文」，不伪造「第1章」

## 10. Windows 真人结果

- 目录显示完整标题（第1章 百世书/第19章 剥皮/第473章 天上火的霸道！，无短标题）
- 点击第2/3章跳转成功、保存进度、目录高亮正确
- 真实库 4 本 repair 后 health ok=true，指定章节 offset 全部命中
- verify.ps1 全绿（214 单元+widget / 5 集成 / Windows Release / APK Debug）

## 11. Android 真人结果

设备离线未执行自动验证；用户已手动确认大文件可打开滑动。目录完整标题与跳转共用同一 Dart 代码路径（displayTitle 来自扫描器/Drift，跳转是两阶段对齐），待设备恢复后补验（§十四 手动清单：目录完整标题/前中后章节点击/快速连点/触摸滚动后高亮/横竖屏再点击）。

## 12. 测试数量

单元+widget：**214**（原 185 + 新增 29：scanner M3.2 合同 8 + reader_jump 11 + toc_title_persistence 6 + toc_display 4）
集成：**5 个文件全过**（accept_real_files / hash_contract_flow / m2_android_verify / m2_library_flow / vertical_reader_flow）
覆盖 §十三：Scanner 8 项 ✅ 数据 6 项 ✅ Reader 11 项（块对齐/多章同块/块末/surrogate/越界/y坐标/blockForOffset 全链/不切 surrogate/末块）✅ 目录展示 4 项 ✅ 多章同块 fixture 集成 ✅

## 13. 构建结果

- Windows Release：`build\windows\x64\runner\Release\xaocen_reader.exe` ✅
- Android Debug：`build\app\outputs\flutter-apk\app-debug.apk` ✅（verify 后重建，正常应用入口）

## 14. 最终 HEAD

```
05f171a test(reader): cover full title contract, exact jump and toc display
7dad253 feat(reader): two-stage exact chapter jump with title alignment and toc highlight
f6d1283 fix(library): expose displayTitle on library toc entries
abd3103 fix(storage): persist full titles in drift and reindex stale toc on repair
9bccab6 feat(txt): keep full chapter and volume titles with displayTitle contract
（基线 aa73c95）
```

## 15. 工作区状态

clean（5 个 commit 已提交，分支 fix/m3-toc-title-exact-jump）。

## 附带交付

- 真实库已修复：4 个 collection 全部 parserVersion 2.0.0 + 完整标题 + health ok（修复前已备份 sqlite.bak-m32）
- 去重行为回归保护：真实文件 473 章保持（新增正文引用行去重判据：章节编号相同即重复）
- reader_page 移除固定延迟 Timer（原 100ms finishTocJump），改为两阶段对齐完成回调
