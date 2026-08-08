# M4_RESULT.md — 横向分页 Reader 与双模式精确切换（0.1.0-dev.4+4）

> 阶段：M4（M4.1 核心引擎 + M4.2 UI 集成与双模式切换）
> 分支：`feat/m4-horizontal-reader`（基线 = M3 冻结点，ff 合并后）
> 核心合同：唯一位置真源 = normalized.txt → Dart String 的 **UTF-16 码元偏移**
> （ReaderLocator.absoluteCharacterOffset）；Page/pageIndex/PageView index/scroll pixels
> 全部只是**派生状态**，不落库、不进 manifest、不改 normalized.txt。
> 引擎核心细节另见 `M4_1_RESULT.md`；参考项目研究另见 `M4_REFERENCE_RESEARCH.md`。
> **P1 修复（2026-08-08）**：模式 + Locator 持久化闭环——退出/重开保持
> 「上次阅读模式 + 最后 confirmed Locator」（见 §10）。
> **最终状态：COMPLETE**。P1 修复后的 Windows + Android 真人验证已由用户完成，暂未发现明显问题。

---

## 1. 交付范围（对照 M4 任务书 §五）

已实现：
1. 横向分页 Reader（`PagedReaderView` + `PageView`，固定有限页窗口）；
2. TextPainter 分页引擎（`PagedLayoutEngine`：行粒度、惰性、确定性）；
3. 惰性 PageWindow（prev2 + current + next3，`_trim` 淘汰远离页）；
4. 下一页 / 上一页（字符链连续：`prev.end == current.start`）；
5. Windows 键盘翻页（Left/Right/PageUp/PageDown → 上/下一页）；
6. Android 左右滑动翻页（PageView 原生，fling/回弹/settle 由框架处理）；
7. 纵向 → 分页精确模式切换（freeze → 真实 anchor → pageContaining → 显示 → unfreeze）；
8. 分页 → 纵向精确模式切换（freeze → confirmed locator → M3 精确恢复 → unfreeze）；
9. 横向目录跳转（chapter.startCharacterOffset → pageContaining → 标题可见 → confirmed = 精确 target）；
10. 横向模式阅读进度保存（用户翻页防抖 400ms + 目录跳转立即防抖 + dispose flush）；
11. resize 重新分页（窗口变化 capture locator → 新 signature → pageContaining 重定位）；
12. Android 横竖屏重新分页（同 resize 路径）；
13. Theme 变化兼容（仅颜色变化不重分页，只 repaint）；
14. 大型无章节 TXT 分页（7.68MB 中段定位、100 页往返）；
15. M3 完整回归（313 项单元+widget + 7 个集成测试全过）。

未实现（任务书明确排除）：EPUB/PDF/RSS/TTS/搜索/书签/注释/自定义字体/背景图片/
完整阅读设置/仿真翻页/3D 翻页/覆盖翻页/全书总页数/全书预分页缓存/完整 V3 UI 重构。

---

## 2. 分页引擎最终设计（多轮迭代定案）

### 2.1 页面边界（行粒度）

- **forward(start)**：候选 `[start, start+32768)` 一次 TextPainter 布局 →
  `computeLineMetrics` 逐行累计高度（**严格 ≤ contentHeight，无 ε 容差**）→
  `getLineBoundary` 求每行行尾 → **LF 归下一页**（页面 end = 行尾 LF 前，
  无 trailing LF → 渲染不超约束；下一行 lineStart 遇 LF 跳过 +1）→
  零宽防御（`lineEnd <= lineStart` 时 `end = lineStart + 1`）。
- **backward(end)**：候选起点回退行首（lastIndexOf LF → start=lf+1；无 LF 保持原起点）→
  `getLineBoundary` 往回数渲染行（与 forward 行划分同构）→ 页首减 1 检查
  （行首前是 LF 时对齐到 LF 位置，与 forward 页 start 语义一致）。
- **textScaler 必须 `TextScaler.noScaling`**（与 RenderReaderTextBlock 显示端完全一致；
  `linear(1.0)` 在部分字体有微小度量差 → 渲染超约束）。

### 2.2 对称性与已知边界（重要，记录 KNOWN_ISSUES）

- **end 链严格连续**：`backward(e).end == e`（传入值）——翻页字符链**不重不漏**，100 页往返 end 全等。
- **页首漂移**：Flutter `getLineBoundary` 在 LF/wrap 边界的行首定位存在系统性偏差
  （~0.35 行/页，100 页往返页首差实测最大 729 字符 ≈ 35 行 ≈ 1.7 屏）。
  成因：backward 候选起点（LF 回退）与 forward 页首（前一页 end = LF）的行划分
  在个别边界不严格同构。**影响仅翻回时页面起始行略偏移**；confirmed locator
  （UTF-16 offset 真源）不受影响，模式切换/进度保存零误差。已接受并记录。

### 2.3 惰性与确定性

- `pageContaining(target)`：ReaderBlockIndex（6144 码元块）锚定附近 → 有限次 forward
  （guard ≤64）——**禁止从 0 逐页排、禁止比例估算**；重复执行确定性结果。
- PageWindow：`[P-2][P-1][P][P+1][P+2][P+3]`，向后翻窗口后移、向前翻前移，
  远离页淘汰；**Page 对象数与全文总页数无关**。实测：打开时 ~6 页，稳态 ~6 页。
- 进程内缓存 key：document identity + normalizedHash + viewport w/h + TextStyle
  metrics signature + textScale + padding + paginationPolicyVersion；
  窗口尺寸/横竖屏/metrics 变化 → invalidate；**仅颜色变化不重分页**。
- 不显示总页数（§十：禁止虚假总页数）；调试模式可显示 page start/end offset。

### 2.4 双模式切换状态机（§二十一）

`ReaderModeTransitionState`：idle / verticalToPaged / pagedToVertical；
- 切换前 freezeWrites（`ReaderController.freezeWrites(true)`）——切换期间
  纵向 scroll notification / PageView initial callback / 旧组件一律不写进度；
- 切换后 unfreeze；operation generation 拒绝过期异步结果；无固定延迟等待。
- **v→p**：`switchAnchor = _controller.lastTopVisibleOffset`（真实可见范围顶部）→
  新建 PagedReaderController → `open(anchor)` → assert(anchor ∈ 当前页) →
  **不把 anchor 静默改成 page.start**。
- **p→v**：capture `paged.confirmedLocator` →（不调用 paged.flush——未翻页时
  零写入合同）→ `_controller.jumpToOffset(locator.offset, itemIdHint:)` 走 M3
  精确恢复链 → 验证 locator ∈ 真实 ReaderVisibleRange → 完成。
- **未翻页立即切回**：confirmed 保持原 anchor X（不被 page.start 覆盖）✓（专项测试）。
- **用户翻页后**：confirmed = 新页 page.start（防抖 400ms 落盘）；
- **目录跳转后**：confirmed = 精确 target offset（立即防抖保存），
  只有之后用户主动翻页才用 page.start 覆盖。

---

## 3. 测试报告（两层分明，用户要求）

### A. Synthetic tests（自制 fixture，共 313 项单元+widget 全过）

| 文件 | 项数 | 覆盖 |
|---|---|---|
| `test/unit/paged_layout_engine_test.dart` | 20 | forward 连续/全覆盖；backward end 对称 + 100 页 Ahem 往返精确；首/末页边界；空/短文本；超长段；CR/LF；surrogate 不拆；pageContaining 锚定；确定性；cache key（尺寸/样式/颜色-only 变化）|
| `test/unit/page_window_test.dart` | 7 | 窗口扩展/淘汰/统计 |
| `test/unit/paged_reader_controller_test.dart` | 18 | open/jump/翻页/保存/generation/relayout |
| `test/widget/paged_reader_view_test.dart` | 11 | PageView 渲染/滑动手势/末页 endReached/首页 startReached/深浅背景/resize 原位/快速连翻/dispose |
| M3 回归（M0-M3.4 全部既有） | 257 | 零回归破坏 |

### B. Real corpus validation（真实 TXT，4 文件只读验收）

真实文件：`C:\Users\TOM\Desktop\测试\` 下**当前存在的全部** 4 个 .txt
（另 3 个旧 `.xaocen-index.json` 只读不动；全程只读，外部文件 hash 前后不变）：

| 文件 | 大小 | 编码 | 章节 | normLen | sourceHash |
|---|---|---|---|---|---|
| 因果快递-20260625.txt | 657,901 B | UTF-8 | 53（1 卷） | 223,593 | 6160f6a4… |
| 无章节数字测试.txt | 8,054,340 B | UTF-8 | 0（whole） | 2,739,888 | 12b6e8af… |
| 苟在初圣魔门当人材(1-500章).txt | 3,707,874 B | UTF-8 | 473 | 1,261,383 | 9ace0b9b… |
| 青山(501-809章).txt | 2,916,161 B | UTF-8 | 294（3 卷） | 983,263 | 2528925c… |

`integration_test/accept_real_paged_test.dart`（真实 Repository/Drift/文件链路）：
- **有章节**（苟在初圣魔门）：9 个合同 offset 全部被 pageContaining 覆盖
  （#1=54、#19=49208、#42=108790、#112=298039、#195=516559、#258=685040、
  #300=795861、#400=1062206、#473=1257817）；从第 400 章 offset 打开 → 前后页连续；
  100 页往返：**end 链严格连续** + 页首差 ≤ 2 屏（记录 KNOWN_ISSUES）。
- **无章节**（7.68MB）：pageContaining 中段定位不跳末尾、前/后页连续。
- 2/2 PASS。

### C. UI 集成测试（Windows，真实链路）

7 个集成测试全 PASS（verify.ps1 逐文件）：
`accept_real_files` / `accept_real_paged` / `hash_contract_flow` /
`m2_android_verify` / `m2_library_flow` / `paged_reader_flow` / `reader_mode_switch` /
`vertical_reader_flow`。
- `paged_reader_flow_test`：导入→纵向→切分页→翻页→切回→重开→目录远跳第 30 章→重启验证。
- `reader_mode_switch_test`：① v→p→v 未翻页保精确 anchor + **零写入**；② 翻页后
  confirmed 更新 + 目录远跳保存精确 target。

### D. Windows 实际运行

- Release 构建成功（`build\windows\x64\runner\Release\xaocen_reader.exe`，36.5s）；
- 冒烟启动 6s 无崩溃（此前 M4.2 阶段验证）；
- P1 修复后真人验证通过：vertical A → paged → 不翻页 → 完全退出/重开 = paged + A；
  vertical A → paged → 翻页到 B → 完全退出/重开 = paged + B；
  paged B → vertical → 滚动到 C → 完全退出/重开 = vertical + C；
- 4 个实际存在的真实 TXT、原有书架与 managed TXT、Flat TOC、章节跳转、深色模式均未发现明显回归。

### E. Android 真机（Redmi K60 / Android 15 / 无线 adb，2026-08-08）

- `flutter test integration_test/reader_mode_switch_test.dart -d <device>`：**2/2 通过**
  （v→p→v 未翻页保精确 anchor + 零写入；翻页后 confirmed 更新 + 目录远跳保存精确 target）；
- `flutter test integration_test/paged_reader_flow_test.dart -d <device>`：**1/1 通过**
  （导入→纵向→切分页→翻页→切回→重开→目录远跳→重启恢复全链路）；
- 用户手动导入 4 本真实 TXT（因果快递/无章节/青山/苟在初圣魔门）正常，分页阅读可用；
- P1 修复后真人复验通过：三组模式/位置持久化场景均符合预期；force-stop 后重开保持最后模式与位置；
- 覆盖安装完成 schema 2→3 迁移，原有书架、managed TXT 与阅读数据保留；
- 4 个实际存在的真实 TXT、Flat TOC、章节跳转、深色模式均未发现明显回归；
- 数据持久性说明：`flutter test` 集成测试结束后会卸载测试 APK 导致 app 数据被清
  （外部 TXT 不受影响），属测试框架副作用，非应用缺陷；重新导入即可恢复。

---

## 4. 真实文件验收矩阵（对照任务书 §三十三/§三十四）

| 验收项 | 状态 |
|---|---|
| 有章节文件导入/打开 | ✅（473 章 9 锚点全覆盖） |
| 纵向打开 → 中间位置切分页 | ✅（switchAnchor 精确，误差 0 UTF-16） |
| 上下页连续 | ✅（end 链严格连续） |
| 分页 → 纵向（未翻页立即切回） | ✅（anchor X 原样恢复，不被 page.start 覆盖） |
| 退出重开 | ✅（paged_reader_flow 重启验证） |
| 远距离章节跳转（1/19/42/112/195/258/300/400/473） | ✅（pageContaining + 标题可见 + confirmed 精确 target） |
| 无章节大文件中段定位 | ✅（25%/50%/75% 仅测试用，生产无百分比定位） |
| Windows 实际运行 | ✅（Release 构建 + 冒烟 + 全部集成测试） |
| Android 真机实际运行 | ✅（P1 修复后真人验证：三组模式+位置持久化、force-stop 重开、覆盖安装 schema 2→3、书架/managed TXT/4 个真实 TXT 数据保留；Flat TOC、章节跳转、深色模式无明显回归） |

---

## 5. 依赖准入

- **未引入新分页依赖**：PageView/PageController 为 Flutter 内置；
  `super_sliver_list`（M3 已准入，0.4.1，MIT）仅纵向模式使用，分页模式不依赖。

## 6. 版本与数据

- 版本 `0.1.0-dev.4+4`（M4.1 已 bump）；Drift schema 由 2 升至 3；
  数据代际 `v4-local-1` 不变。
- reading_progress 新增 readingMode；ReaderLocator 的 absoluteCharacterOffset 仍是唯一位置真源。

## 7. 已知问题（详见 KNOWN_ISSUES.md）

1. **backward 页首漂移**（≤ 2 屏/100 页，end 链严格连续；confirmed locator 零误差）。
2. Android 分页模式下系统返回边缘手势与左右滑动共存（未强占；真人验证暂未发现明显问题）。
3. 真实文件 UI 层目录远跳：集成测试用 drag 目录列表（scrollUntilVisible 在
   DraggableScrollableSheet 手势下不稳定，测试侧规避）。

## 8. 后续建议（M5 候选）

- 页列表二分定位（legado fastBinarySearchBy 思想，未来若需页缓存）；
- 空行压缩选项（binbyu NO_BLANS_LINE，可作阅读设置）；
- 懒排版进度回调（legado onLayoutPageCompleted，超大文件异步友好）；
- 完整阅读设置页、主题化分页样式。

---

## 9. 真机验证补充说明

- 核心真机验证通过集成测试完成（上述 E 段）；手动滑动翻页手感、横竖屏旋转等
  交互体验由用户手动确认（app 已保留在真机，正常入口版）。
- 集成测试会清空 app 数据（测试框架卸载副作用）：如需保留书架数据，
  请勿在验证后依赖集成测试产生的数据，重新导入外部 TXT 即可。

---

*M4 停止条件达成：工作区 clean、verify.ps1 全绿、Android 真机验证完成。*


---

## 10. P1 修复：模式 + Locator 持久化闭环（2026-08-08）

### 10.1 用户报告的问题
纵向 → 切分页 → 翻到新位置 → 退出 Reader/App → 重开：
1. 阅读模式恢复成纵向（不是分页）；
2. 位置恢复成之前纵向的位置（不是分页最新位置）。

### 10.2 根因（诊断确认，非猜测）
1. **P0 覆盖竞态**：`ReaderPage.dispose()` 顺序为 `paged.flush()`（保存分页 B）
   之后**无条件 `_controller.flush()`（纵向）**——纵向 `_confirmedLocator` 还是切换前的
   旧位置 A → **覆盖 B**。`didChangeAppLifecycleState`（App 后台）同样无条件调纵向 flush。
2. **P0 mode 未持久化**：`_mode = ReaderMode.vertical` 硬编码（session state），
   reading_progress 表无 readingMode 列（schema 2）→ 重开永远纵向。
3. **无 active-mode 约束**：两个 controller 各自保存，无「只有激活模式可提交」。

### 10.3 修复（正式合同）
- **`ReaderProgressState`** = collectionId + absoluteCharacterOffset（唯一位置真源）
  + readingMode（表现状态，绝不替代 Locator）+ itemIdHint + updatedAt；
- **Drift schema 2→3**：reading_progress 新增 `readingMode` 列（默认 'vertical'），
  旧数据迁移默认 vertical，不删任何现有数据；
- **只有「当前激活的 Reader 模式」允许提交位置**：
  - dispose：`_mode == paged ? paged.flush() : _controller.flush()`（不再无条件纵向 flush）；
  - lifecycle（inactive/paused/detached）：同样只 flush active 模式；
  - `_switchToPaged`/`_switchToVertical` 切换本身零写入（§二十一），
    mode=paged 的持久化由退出时的 paged.flush() 自然落盘；
- **重开恢复**：ReaderPage._start 读 ReaderProgressState（含 mode）→ 纵向 open
  恢复位置 → postFrame 若 mode==paged 自动 `_switchToPaged()`（anchor = 恢复位置，
  不改变 offset）；
- **paged 模式下纵向恢复确认跳过**：`_scheduleJumpToPendingTarget`/`_scheduleSecondStageAlign`/
  `_alignFailed`/`_finishRestore` 在 `_mode == paged` 时直接标记完成并返回，
  避免 visibleRange 测量失败误设 state=failed（错误页）；
- **顺带修复**：`removeCollection` 显式删除 reading_progress + ReadingProgress 表
  用 customConstraint 生成真正的 `REFERENCES ... ON DELETE CASCADE`
  （Drift `references()` 在本项目生成器下未产出 FK，删书残留进度 bug）。

### 10.4 验证（全部通过）
- **327 项单元+widget**（新增 14 项：ReaderProgressState 合同 3、Repository mode 4、
  schema 2→3 迁移 1、mode+locator 合同 4、widget 层 3：覆盖竞态/重开恢复 paged/纵向 dispose）；
- **8 个集成测试全过**（含 paged_reader_flow、reader_mode_switch 零写入、真实文件）；
- verify.ps1 全绿（含 Windows Release + APK Debug + git diff --check）；
- 关键场景（合同语义，仓库层 + widget 层验证）：
  1. vertical A → 切 paged → 不翻页立即退出 → 重开 = **paged + A**；
  2. vertical A → 切 paged → 翻 5 页到 B → 退出 → 重开 = **paged + B**；
  3. paged B → 切 vertical → 滚动到 C → 退出 → 重开 = **vertical + C**；
  4. route pop / App 后台 / force-stop（lifecycle flush active）/ dispose 均只写激活模式；
  5. page swipe 未 settle 时退出只保存最后 confirmed 位置；
  6. inactive Reader 不覆盖 active Reader 状态（最后一次提交为准）。

---

## 11. 最终封存（2026-08-08）

- **M4 P1（模式 + Locator 持久化）已修复并提交**（b389a6a~3d0fba5），
  自动化验证全绿（327 单元+widget + 8 集成 + verify.ps1）；
- P1 修复后的 Windows + Android 真人验证已完成：三组模式/位置持久化场景、
  Windows 完全退出重开、Android force-stop 重开、覆盖安装 schema 2→3 与数据保留均通过；
- 4 个真实 TXT、原有书架与 managed TXT、Flat TOC、章节跳转、深色模式暂未发现明显问题；
- **M4 状态：COMPLETE。** 不在本次封存中启动 M5。
