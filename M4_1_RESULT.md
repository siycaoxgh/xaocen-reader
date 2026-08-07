# M4.1_RESULT.md — 横向分页核心（PageRange + PagedLayoutEngine）

> 阶段：M4.1（收窄：只实现分页核心，不接入完整 UI）
> 分支：`feat/m4-horizontal-reader`（基于 main `539ed8d`）
> 版本：`0.1.0-dev.4+4`（pubspec.yaml + lib/app/constants.dart）
> 日期：2026-08-07

---

## 1. 本阶段范围（用户指令）

只实现分页计算能力：

```
document offset
      ↓
PagedLayoutEngine
      ↓
PageRange
```

要求：
1. ReaderLocator 继续作为唯一阅读位置；
2. PageRange 只保存 startOffset / endOffset；
3. 不保存数据库；
4. 不修改 reading_progress；
5. 不影响 VerticalReader。

必须支持：UTF-16 offset、surrogate pair、CRLF normalized text、长段落、
空文本、无章节 TXT。

---

## 2. 交付内容

| 文件 | 职责 |
|---|---|
| `lib/domain/reader/paged_text_range.dart` | **PageRange**（PagedTextRange：startCharacterOffset/endCharacterOffset，[start,end) 合同）+ PagedLayoutSignature（重分页判定 key）+ textStyleMetricsKey（颜色不入 key）+ pagedPolicyVersion |
| `lib/reader/paged_layout_engine.dart` | **PagedLayoutEngine**：layoutForwardPage / layoutPreviousPage / pageContaining；行粒度（getLineBoundary 行尾对齐）；surrogate 保护；确定性 |
| `lib/reader/page_window.dart` | **PageWindow**：有限窗口（prev 2 + next 3），翻页扩展 + 淘汰，Page 对象数与全文页数无关（§十四） |
| `test/unit/paged_layout_engine_test.dart` | 引擎测试 20 项 |
| `test/unit/page_window_test.dart` | 窗口测试 7 项 |

版本：`pubspec.yaml` / `lib/app/constants.dart` / `test/unit/m0_skeleton_test.dart`
→ `0.1.0-dev.4+4`（Drift schema 保持 2，无新增持久化字段，禁止无意义升级）。

---

## 3. PageRange 合同（§七）

```dart
class PagedTextRange {
  final int startCharacterOffset;  // UTF-16 码元偏移，含
  final int endCharacterOffset;    // UTF-16 码元偏移，不含
}
```

- [start, end)：start <= end；不拆 surrogate pair；
- 页面连续（previous.end == current.start）；不重复、不遗漏、不插入、不删除；
- **不写入 Drift / manifest；不修改 normalized.txt**；
- 正文引用 NormalizedDocument（PageRange 只存 offset，不复制大 String，§三十八）。

---

## 4. PagedLayoutEngine 算法（§八/§十一/§十二/§十三）

### 4.1 显示与测量同一参数（§八）

引擎只负责「测量」；页面渲染复用 M3 已验证的 `RenderReaderTextBlock`
（单一 TextPainter 显示+测量）。引擎与渲染共享：
TextStyle / textDirection / contentWidth（= width − 2×horizontalPadding）/
textScale / 行高。禁止分页一套参数、绘制另一套（否则字符 Rect 漂移）。

### 4.2 layoutForwardPage(start)（正向）

1. 候选 = `text[start, min(start+32768, len))`（候选上限与全文页数无关）；
2. 一次 TextPainter 布局；若整体高度 ≤ contentHeight → 整块一页（文档尾）；
3. 否则逐渲染行累计高度，取「放得下的最大完整行集合」；
4. 页尾 = 该集合最后一行行尾（`getLineBoundary` 的 end）→ **视觉连续**：
   每页从行首开始排版，页面间无半行跳变；
5. surrogate 保护 + 空页防御。

### 4.3 layoutPreviousPage(end)（反向，§十三）

1. 候选 = `text[max(0, end-32768), end)`；
2. 从末尾往回累计渲染行，取「放得下的一屏完整行集合」；
3. 页首 = 该集合第一行行首（`getLineBoundary` 的 start）；
4. 返回 `[start, end)` → **保证 previous.end == end**。

对称性由构造保证：forward/backward 用同一文本、同一参数、同一行划分。
专项测试：100 页前进 → 100 页回退完全对称（字符链连续）。

### 4.4 pageContaining(target)（§十一/§十二）

- 用 `ReaderBlockIndex.blockForOffset(target)` 定位附近文本区域（有限安全
  anchor，anchor ≤ target，距离 < 6144 码元）；
- 从 anchor 向后有限次数 layoutForwardPage 直到覆盖 target（循环有界，
  与全文页数无关）；
- **禁止**：全书百分比 / 估算字符每页 / 章节比例 / block 比例；
- 同一 (document, layout signature, target offset) 重复执行结果确定。

---

## 5. PageWindow（§九/§十四/§十五）

- 有限窗口：`previousCount=2 + current + nextCount=3`（≤6 页）；
- 翻页扩展（extendTail/extendHead）+ 淘汰远离当前页的 PageRange；
- `maxObserved` 记录扩展瞬间峰值；
- Page 对象数量与全文总页数无关（红线 §四十九-7 满足）；
- 进程内派生缓存：`PagedLayoutSignature.cacheKey` 变化即失效
  （尺寸 / 字体度量 / textScale / padding / policyVersion；**颜色不入 key**——
  纯颜色变化不重分页，§三十二）。

---

## 6. 测试

### 6.1 新增单元测试（27 项，全部通过）

`test/unit/paged_layout_engine_test.dart`（20 项）：
- forward continuity：纯文本每页 100 字符且连续、无遗漏覆盖全文；
- backward + symmetry：backward.end==传入 end、**100 页前进→100 页回退
  完全对称**、prev/next 反复往返不漂移；
- 边界：document start（previous(0)=null、首页 start=0）、document end
  （末页 end=len、forward(len)=null）、空文本（null/空页）、短文本整块一页；
- 长段落（5000 字符无换行，连续且不切 surrogate）、CR/LF 规范化文本、
  surrogate pair（𠀀）不被页面边界拆开；
- offset→page：pageContaining 覆盖目标（用 blockIndex 锚定，不从 0 逐页）、
  page contains target、exact TOC anchor（页首可早于目标）；
- 确定性 / cache key：同参数结果一致、尺寸/样式变化 key 变化、
  theme color-only 不改变签名、resize 页大小变化、orientation 等价判定。

`test/unit/page_window_test.dart`（7 项）：reset、goNext 连续翻页窗口保持
有限并淘汰远端、goPrevious 向前扩展、atDocumentStart/End、select、
extendTail/extendHead+select 统一 trim、maxObserved、clear。

### 6.2 全量回归

`flutter test` 全量 **313 项通过**（M3 基线 259 + M4.1 核心 27 + 既有 m0 6 +
其余 M3.x 增量）；`flutter analyze` 零问题。

---

## 7. 未交付（M4.2 资产，stash 保留）

以下代码在 M4 完整实现中已写好并通过测试，但按 M4.1 范围**不提交**，
已 `git stash` 保存于 `feat/m4-horizontal-reader`（stash message:
`M4.2 WIP: paged reader controller/view + dual-mode integration`）：

- `lib/reader/paged_reader_controller.dart`（分页模式控制器：锚点保持、
  翻页 settled、防抖保存、relayout、generation）—— 18 项测试已过；
- `lib/reader/paged_reader_view.dart`（PageView + 窗口重建 + 键盘翻页）
  —— 11 项 Widget 测试已过；
- `lib/reader/reader_mode.dart`（ReaderMode + ReaderModeTransitionState）；
- `lib/reader/reader_page.dart` 双模式集成（AppBar 模式菜单、切换状态机、
  LayoutBuilder relayout）；
- `lib/reader/reader_controller.dart` freezeWrites/unfreezeWrites（§21）；
- `lib/reader/reader_text_block.dart` onLayout 可选化；
- 对应测试 `paged_reader_controller_test.dart`、`paged_reader_view_test.dart`。

M4.1 工作区**不包含**上述文件（stash 后还原），保证「只实现分页核心」。

---

## 8. 红线核对（M4 §四十九，仅引擎层适用项）

| 红线 | 状态 |
|---|---|
| ReaderLocator 变成 pageIndex | ✅ 未触（PageRange 纯派生，不进 Locator） |
| 大 TXT 分页打开需要数秒全文排版 | ✅ 未触（惰性 + blockIndex 锚定） |
| 无章节 TXT 生成数千 Page 对象 | ✅ 未触（PageWindow 有限窗口） |
| vertical→paged / paged→vertical 漂移 | ✅ 引擎层无切换（M4.2 接入时验证） |
| 外部 TXT 被修改 | ✅ 未触（引擎只读内存 text） |
| 纵向 Reader 回归 | ✅ 全量 313 测试含 M3 全部回归通过 |

---

## 9. 已知限制（M4.1 范围外，如实记录）

- 未接入 UI：无 PageView、无模式切换入口、无键盘翻页；
- 未做真机/Windows 真人验证（M4.1 只交付计算核心）；
- PageWindow 预填相邻页（供 PageView 滑动）逻辑在 M4.2 控制器中，
  引擎层 window 只提供 reset/extend/select 原语。

---

## 10. 最终状态

- 分支：`feat/m4-horizontal-reader`；起始 HEAD `539ed8d`
- 提交：见 git log（本阶段提交记录）
- 工作区：clean（stash 含 M4.2 WIP）
- 下一步（M4.2，用户确认后）：stash pop → 接入双模式 UI → 完整验收
  （真实文件 / Windows / Android 真机 / verify.ps1 / 长期文档全量更新）
