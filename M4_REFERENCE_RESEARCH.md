# M4_REFERENCE_RESEARCH.md — 分页行为参考研究

> 阶段：M4 编码暂停期（用户指令：先参考成熟项目，再独立实现）
> 研究对象：binbyu/Reader（C++/Win32/GDI）、legado-with-MD3（Kotlin/Android）
> 依据：两仓库实际源码（`research/Reader-master`、`research/legado-with-MD3-main`）、
>       `READER_ENGINE_DECISION.md`（§3/§4/§8/§14）、`SPIKE_RESULT.md`
> 许可证约束：binbyu 自定义许可严禁商用、legado GPL-3.0 —— 只参考行为/算法思想，
>       不复制任何受限源码。

---

## 1. 两个项目分别如何处理分页

### binbyu/Reader（Windows，C++/GDI）

- **分页单位**：段落 → 行。`GetNextParagraph(start, max_len)` 按 `\n`/`\r\n`
  找段落边界（返回段落长度 + crlf_len 换行长度），段内 `ParagraphToLines`
  用 GDI `GetTextExtentPoint32` 逐字符测量、按行宽拆渲染行。
- **页生成**：`CalcPageDown`（向下翻页）从当前字符索引 `m_Index` 开始，
  循环取下一段落 → 拆行 → 逐行累计高度（`h -= line.cy`），直到剩余高度
  放不下下一段的第一行 → 当前页 = 已填行集合（`page_info_t{start, length, lines}`）。
- **页边界**：渲染行级（段落内部可以跨页）；页尾段落**包含换行符**
  （crlf_len 计入），下一页从内容行开始。
- **不做预分页**：每次翻页/重绘实时 `CalcPageDown/CalcPageUp` 重排当前页；
  `m_PageLength`（当前页字符数）是排完后的结果。
- **空行处理**：`NO_BLANS_LINE` 选项可压缩连续空行（跳过并累计 remain_blank_length）。
- 特殊：`m_Index`（宏 = cache 中 item.index）为当前页首字符偏移，绘制/翻页
  全部围绕它。

### legado-with-MD3（Android，Kotlin）

- **分页单位**：章节。每章一个 `TextChapter`，章内 `pages: List<TextPage>`。
- **页生成**：`TextChapterLayout` 用 Android `StaticLayout` 排版整章，
  协程异步逐页生成（`onLayoutPageCompleted` 回调），`isCompleted` 标志；
  `TextMeasure` 缓存字符宽度（中文常用宽 + ASCII + codepoint 三级缓存）。
- **页实体**：`TextPage{ index, text, lines, chapterIndex, chapterPosition,
  charSize }` —— `chapterPosition` = 页内**首行在章内的字符位置**，
  `charSize` = 页字符数。页是纯派生结构。
- **页边界**：StaticLayout 渲染行级；页与页连续（前一页尾 = 后一页首）。
- **懒排版**：未排完的章返回标题占位页；翻页时若页未生成则等待/占位。
- **跨章**：页索引在章内，章尾/章首翻页走 `moveToNextChapter/moveToPrevChapter`。

---

## 2. 如何处理前后翻页

| | binbyu | legado | XAOCEN M4（当前） |
|---|---|---|---|
| 下一页 | `m_Index += m_PageLength` → CalcPageDown 重排 | 页索引 +1（`getPage(pageIndex+1)`），章尾跨章 | `layoutForwardPage(page.end)` 即时生成 + 窗口扩展 |
| 上一页 | `m_Index - 1` 往回 `GetPrevParagraph` 填满一屏 | 页索引 -1，章首跨章 | `layoutPreviousPage(page.start)` 即时生成 + 窗口扩展 |
| 语义 | 上一页 = 从当前页首-1 往回排一屏（prev.end == current.start） | 页列表索引移动 | 同 binbyu：prev.end == current.start（构造对称，100 页往返测试） |
| 边界 | IsFirstPage/IsLastPage | hasPrev/hasNext + moveToFirst/Last | atDocumentStart/atDocumentEnd + startReached/endReached |

**结论**：我的前后翻页语义与 binbyu 完全一致（即时排版、prev.end==current.start、
字符链连续）；legado 的页列表索引移动依赖整章预排，未被采用（章节不是我的分页单位）。

---

## 3. 如何处理阅读位置

| | binbyu | legado | XAOCEN M4 |
|---|---|---|---|
| 坐标 | 全局 **UTF-16 字符偏移**（wchar_t 下标），页首 m_Index | **章节索引 + 章内 UTF-16 字符偏移**（durChapterPos） | 全局 UTF-16 码元偏移（ReaderLocator.absoluteCharacterOffset） |
| 保存 | 实时保存（ENABLE_REALTIME_SAVE）+ WM_DESTROY 保存 m_Index | 保存章节 url + 章内字符位置 | confirmed locator（防抖 400ms + 生命周期 flush） |
| 恢复 | 读 m_Index → 从该偏移 CalcPageDown | 读章节 + durChapterPos → 排章 → getPageIndexByCharIndex 定位页 | 读 offset → blockForOffset → 两阶段精确恢复 |
| 字体/窗口变化 | **m_Index 不变**，每次绘制按新 HDC 实时重算分页 → 位置稳定 | metrics 变化 → 章重排，durChapterPos 不变 → 重定位页 | 同 binbyu：capture locator → 新 signature → pageContaining 重定位，offset 不变 |
| 进度显示 | GetProgress = (m_Index + m_PageLength)*100 / m_Length（百分比，仅显示） | 章内位置 + 章节 | 不显示页数（§十：禁止虚假总页数） |

**结论**：坐标体系与 binbyu 的 Primary 决策一致（全局 UTF-16 偏移）；
「位置不变、重排重定位」的字体/窗口变化处理与两个项目一致；
我的 confirmed 语义（程序化锚点精确保持 vs 用户翻页后取页首）比参考更精确。

---

## 4. 如何处理大文件

| | binbyu | legado | XAOCEN M4 |
|---|---|---|---|
| 内存 | **全文一次性解码驻留**（wchar_t*，8MB TXT ≈ 16MB+ UTF-16 + 索引） | 章节级加载 + `txtBufferSize=8MB` 分块缓存 | 全文载入 Dart String（≤50MB 设计内） |
| 预分页 | **不预分页**（实时排当前页） | **整章预排**（章是分页单位） | **不预分页**（PageWindow prev2+next3 惰性窗口） |
| 任意位置进入 | 章节 index 定位 → m_Index = 章节 start → CalcPageDown | 读位置 → 排章 → 页定位 | pageContaining：ReaderBlockIndex 锚定 + 有限次 forward |
| 大文件翻页 | 每页一次 GetMaxPageLength + 逐段测量 | 页列表内存访问（排版后） | 每页一次 TextPainter 布局（候选 ≤32768 码元） |

**结论**：我的「全文内存 + 不预分页 + 惰性窗口」与 binbyu 同构
（它连窗口都没有，每次只排一页；我多缓存前后 5 页做滑动缓存），
吸收 legado 的「有限候选 + 分块」思想（候选上限 + blockIndex 锚定）。

---

## 5. 对 XAOCEN Reader 可借鉴点

1. **位置不变、重排重定位**（两项目共识）：字体/窗口变化时阅读 offset 是锚，
   只重排页面结构——我的 relayout 已按此实现 ✓。
2. **页 = 派生结构**（legado TextPage 明确 chapterPosition/charSize 派生；
   binbyu page_info_t 含 start/length）：页范围只存 offset，不进持久化 ✓。
3. **即时排版 + 字符链连续**（binbyu）：prev.end == current.start 构造保证 ✓。
4. **段落优先的分页**（binbyu GetNextParagraph）：页尾段落含换行、下一页从
   内容行开始——我的「页面含 LF」修复已对齐此语义 ✓。
5. **空行压缩选项**（binbyu NO_BLANS_LINE）：可作未来阅读设置项，本轮不做。
6. **懒排版进度回调**（legado onLayoutPageCompleted）：大章分页的异步友好性，
   我目前同步即时排版（性能足够），未来大文件可借鉴。
7. **二分定位页**（legado fastBinarySearchBy chapterPosition）：页列表有序时
   二分定位 offset→页——我的 pageContaining 用 blockIndex 锚定 + 顺序前进，
   未来若需要页列表缓存可改二分。
8. **字符宽度缓存**（legado TextMeasure）：TextPainter 单次布局已足够，不引入。

---

## 6. 哪些不能直接采用

1. **binbyu 的 GDI 分页/绘制**：平台绑定（HDC/HFONT/GetTextExtentPoint32），
   不可跨平台；且其自定义许可禁止商用——只参考行为。
2. **binbyu 的每次整页重排**（连窗口缓存都没有）：性能上 TextPainter 布局
   成本高于 GDI 逐字符测量，保留 PageWindow 折中，不照搬「一次一页」。
3. **binbyu 的 GetProgress 百分比**：任务书红线——百分比不得作为位置真源
   （仅显示也禁止，M4 §十：不显示虚假总页数）。
4. **legado 的按章节分页**：它因网络书源按章加载；我的本地 TXT 全文在内存，
   章节不是分页单位（分页单位是全文），跨章翻页无成本——不采用章内页模型。
5. **legado 的整章预排版**：大文件（473 章 126 万字符）整章预排违背
   「不预分页全文」红线；且同步排版会阻塞。
6. **legado 的占位页**（未排完显示标题页）：我的页面即时生成，无需占位。
7. **legado 的 GPL-3.0 源码**（任何 Kotlin 代码、TextPage/TextChapter 结构
   逐字复制）：许可证传染，禁止。
8. **binbyu 的全局 m_Index 单页模型**（无窗口）：PageView 滑动需要相邻页
   存在（fling 目标页必须在窗口内）——这是 M4.2 发现的真实约束。

---

## 7. 当前 M4 实现与参考方案相比是否走偏

### 结论：核心没有走偏，发现 3 处自行假设导致的偏差（2 处已修，1 处待修）

**与参考一致（可保留）**：
- 坐标体系：全局 UTF-16 偏移唯一真源（= binbyu Primary 决策）✓
- 分页粒度：渲染行级、页尾段落含 LF（= binbyu 段落→行）✓（已修复对齐）
- 前后翻页：即时排版、prev.end == current.start（= binbyu）✓
- 位置恢复：offset 锚 + 重排重定位（= 两项目共识）✓
- 不预分页：惰性窗口（介于 binbyu 一次一页与 legado 整章预排之间的合理折中）✓
- 页 = 派生结构（= legado TextPage 语义）✓

**发现的偏差（自行假设，参考项目无此问题）**：
1. **[已修] 引擎与渲染 textScaler 不一致**：我最初引擎用
   `TextScaler.linear(1.0)`、渲染 `RenderReaderTextBlock` 用 `noScaling`，
   导致同文本测量高度不一致 → 页面渲染超 viewport 约束
   （RenderReaderTextBlock does not meet its constraints）。
   已统一为 noScaling。
2. **[已修] 页面高度累计 ε 容差**：累计允许超 contentHeight 0.5px，
   渲染严格约束 → 超界断言。已改为严格 ≤ contentHeight。
3. **[待修] PageView 窗口重建竞态（真实 bug）**：我自行假设「窗口变化时
   dispose 旧 PageController + 重建 PageView（key 变）」→ 集成测试暴露
   `RenderReaderTextBlock DISPOSED` 在 dispose 后仍被布局（performLayout
   断言失败）。参考项目不存在此问题（binbyu 直接重绘、legado 固定页容器）。
   **修复方向（已设计未实施）**：不重建 PageView，单一 PageController +
   `jumpToPage(currentIndex)` 跟随窗口；itemCount 随窗口扩展自然 rebuild。
   （同时保留 `rawIndex == currentIndex` 忽略初始回调的判断。）

**其他确认（无偏差）**：
- getLineBoundary 零宽行（position 落在 LF 上返回 [x,x)）是 Flutter 特有
  行为，参考项目用 GDI/StaticLayout 无此问题——已加防御 + LF 归属方案，
  属平台适配而非设计偏差。

---

## 8. 当前 M4 代码保留 / 调整清单

### 保留（与参考一致，测试通过）

| 文件 | 状态 |
|---|---|
| `lib/domain/reader/paged_text_range.dart`（PageRange + 布局签名） | ✅ 保留（M4.1 已提交） |
| `lib/reader/paged_layout_engine.dart` | ✅ 保留（行粒度/对称/pageContaining；含 3 处已修偏差） |
| `lib/reader/page_window.dart`（有限窗口） | ✅ 保留（M4.1 已提交） |
| `lib/reader/paged_reader_controller.dart`（confirmed/防抖/generation/relayout） | ✅ 保留（逻辑层，45 项单元测试通过） |
| `lib/reader/reader_mode.dart` | ✅ 保留 |
| `reader_page.dart` 双模式切换（freeze → anchor → pageContaining → unfreeze） | ✅ 保留（符合 §十七/§十八/§二十/§二十一） |
| `reader_controller.dart` freezeWrites | ✅ 保留 |
| `reader_text_block.dart` onLayout 可选化 | ✅ 保留 |

### 需调整（1 项，等确认后实施）

| 项 | 现状 | 调整 |
|---|---|---|
| `lib/reader/paged_reader_view.dart` 窗口重建 | dispose 旧 PageController + PageView key 重建 → DISPOSED render object 竞态（集成测试环境暴露） | 单一 PageController + `jumpToPage(currentIndex)` 跟随窗口；移除 PageView key 重建；保留 rawIndex==currentIndex 忽略逻辑 |

### 测试状态（截至本报告）

- Synthetic（自制 fixture）：引擎 20 + 窗口 7 + 控制器 18 + widget 11 =
  **54 项全过**；全量单元+widget **313 项全过**；analyze 干净。
- Real corpus（真实文件，引擎层）：`accept_real_paged_test` 2/2 通过
  （473 章 9 章 offset 覆盖 + 100 页往返对称 + 无章节 7.68MB 前/中/后定位）。
- Real corpus（UI 层）：`paged_reader_flow_test` / `reader_mode_switch_test` 修复
  PageView 窗口竞态（单一 PageController + _followWindow + _prefillWindow 预填 prev2/next3、
  relayoutSilently 消除 setState-in-build）后**全部通过**（2 项切换专项 + 主流程）。

---

## 9. 真实文件 M4 验收矩阵（C:\Users\TOM\Desktop\测试，全部只读）

| 文件 | 大小 | 编码 | 章节 | chapterCount | normalized length | sourceHash | normalizedHash |
|---|---|---|---|---|---|---|---|
| 因果快递-20260625.txt | 657,901 B | UTF-8 | 有（1 卷） | 53 | 223,593 | 6160f6a4… | 6160f6a4… |
| 无章节数字测试.txt | 8,054,340 B | UTF-8 | 无 | 0（whole） | 2,739,888 | 12b6e8af… | 130bb02f… |
| 苟在初圣魔门当人材(1-500章).txt | 3,707,874 B | UTF-8 | 有 | 473 | 1,261,383 | 9ace0b9b… | 02a0f06d… |
| 青山(501-809章).txt | 2,916,161 B | UTF-8 | 有（3 卷） | 294 | 983,263 | 2528925c… | d37db97a… |

（另有 3 个旧 `.xaocen-index.json` 遗留文件，只读不动；4 个 TXT 均已导入
managed collection，外部文件未被修改，hash 与导入时一致。）

### M4 分页验收计划（修复 PageView 竞态后执行）

1. 正常导入 / 使用已有 managed collection（4 个文件）；
2. 纵向打开；
3. 从实际阅读中间位置切分页；
4. 下一页 / 上一页；
5. 分页 → 纵向；
6. 退出重开；
7. 远距离章节跳转（有章节文件：前段第1/19章、中段第112/195/258章、
   后段第400/473章；青山第31章 @192296）；
8. 无章节大文件中段定位（25%/50%/75%，仅测试用）；
9. Windows 实际运行（Release 冒烟 + 集成测试）；
10. Android 真机实际运行（无线 adb，覆盖安装）。

---

## 10. 结论

当前 M4 实现与两个参考项目的分页行为模型**核心一致**（全局 UTF-16 偏移 +
即时排版 + 位置不变重排 + 不预分页 + 页为派生），未走偏；发现的 3 处偏差全部修复
（textScaler 统一 noScaling、ε 容差移除、PageView 窗口竞态 → 单一 controller +
预填窗口 + relayoutSilently）。真实文件 UI 层验收通过（8 个集成测试全 PASS，
含 4 真实 TXT 分页验收），M4.2 已收尾。已知边界：backward 页首 ≤2 屏/100 页
漂移（end 链严格连续，confirmed locator 零误差，见 KNOWN_ISSUES.md）。
