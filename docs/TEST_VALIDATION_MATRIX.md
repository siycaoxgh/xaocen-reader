# TEST_VALIDATION_MATRIX.md — XAOCEN Reader v4 验证矩阵

> 状态：M5.2d COMPLETE（`feat/m4-horizontal-reader`）；Android 真机继续按后续统一复核安排。
> 自动测试与真人测试分开记录。**Android Debug 构建 PASS ≠ Android 真机 PASS**，两者分别列出。
> 真人环境：Windows（本机，用户 + 自动化集成测试）；Android 真机 Redmi K60（23013RK75C / mondrian，Android 15 / API 35，无线 adb）。

图例：✅ 通过 · ✅* 通过（用户手动确认） · ➖ 不适用/未执行 · 🔒 回归敏感

---

## M5.3.1 — ChapterBoundaryResolver / vertical chapter progress (2026-08-10)

| Validation | Result |
|---|---|
| Shared chapter-only boundary normalization | PASS |
| Invalid offsets, duplicate starts, volumes, malformed TOC | PASS |
| Chapter start/next start/last chapter/zero-length handling | PASS |
| UTF-16 surrogate-pair offsets | PASS |
| No-chapter `全文` behavior | PASS |
| Vertical chapter + whole-book progress labels | PASS |
| Locator/persistence side effects | PASS, none |
| Unit/contract/widget | 415/415 PASS |
| Windows integration | 10 files / 13 scenarios PASS |
| Four real TXT corpus / logical error | PASS / 0 |
| Windows Release / Android Debug | PASS / PASS |
| Drift schema | 6, unchanged |

## M5.3.2 label correction (2026-08-10)

| Gate | Result |
|---|---|
| Vertical exact labels | PASS: `本章 68%` / `全书 37%` |
| Paged exact labels | PASS: `本章 7 / 12 页` / `全书 37%` |
| No-chapter exact labels | PASS: `全文` / `全书 37%` |
| Full unit/contract/widget | 424/424 PASS |
| Windows integration | 11 files / 14 scenarios PASS |
| Windows Release / Android Debug | PASS / PASS |
| Android real device | NOT-RUN / deferred |
| Android real device | Not run in this coding pass |

## M5.3.1.1 — Paged Reader gesture window-tail fix (2026-08-10)

| Validation | Result |
|---|---|
| Controller-owned ensure/prefetch/settle path | PASS |
| True PageView continuous swipe across window tail | PASS (widget: 30-page progression) |
| One-item edge fallback generates the missing page | PASS |
| Window boundedness | PASS (steady state <= 6 pages) |
| No-chapter and chaptered pagination continuity | PASS |
| EOF distinction (tail != document end) | PASS |
| Generation/rebase/stale callback guards | PASS |
| Gesture/volume/keyboard shared page-turn contract | PASS |
| Full unit/contract/widget | 419/419 PASS |
| Windows integration | 10 files / 13 scenarios PASS |
| Four real TXT corpus / logical error | PASS / 0 |
| Windows Release / Android Debug | PASS / PASS |
| Drift schema | 6, unchanged |
| Android targeted device test | NOT-RUN in this coding pass |

## A. 自动测试（当前全绿）

**单元 + Widget：382 项**（`flutter test`，Windows VM）：
- M1 系：gb18030_decoder（含全表 23940/锚点 209/四字节/非法/跨块）、txt_encoding_detector、txt_normalizer、txt_toc_scanner（24）、txt_index_cache、large_file_policy
- M2 系：local_library_test（20）、library_page_test（8）、m0_skeleton_test（6→更新）
- M3 系：reader_block（9）、reader_locator（10）、reading_progress_repository（8）、reader_controller（12）、normalized_document_loader（9）、reader_page_test（6）、reader_jump（11）、toc_title_persistence（6）、toc_display（4）
- M3.1 系：hash_contract（11）、repair_service（12）
- M3.3 系：toc_index（10）、reader_appearance（7）、toc_scroll（12）、reader_dark_mode（8）
- 合同：txt_pipeline_contract（10）、content_navigation_contract（8）
- M4 系：paged_layout_engine（20）、page_window（7）、paged_reader_controller（18）、paged_reader_view（11）
- M4 P1 系：reader_progress_state（3+1 迁移）、mode_persistence_contract（4）、mode_persistence_widget（6，含非零双向与快速 generation）
- M5.1a 系：reader_preferences（11：强类型合同/分类/持久化/watch/reset/fallback/迁移/隔离）
- M5.1b 系：metrics signature、分页 window invalidation、快速 generation、纵向 widget 保位
- M5.1c 系：App 三态主题、重建持久化、vertical/paged paint-only、零 progress 写入
- M5.1d 系：V3 overlay chrome、显隐零写入、目录/Aa/更多入口、手机横竖屏与 Windows 限宽响应式
- M5.1e 系：四类 metrics 设置、theme/mode、draft→commit、latest pending、reset、paged 非零 Locator
- M5.2b 系：confirmed Locator 进度/章节显示、书签重复合同、A/B 隔离、动态 orphan、创建/列表/删除、vertical 精确跳转
- M5.2c 系：UTF-16 搜索匹配、surrogate/context、章节派生、generation/cancellation、搜索面板 debounce/highlight/结果点击
- M5.2d 系：ReadingSession visible-confirm/lifecycle、SUM/COUNT 聚合、最近阅读派生、历史 detach/delete、A/B 历史隔离

**集成测试：10 个文件 / 13 个测试场景**（Windows 逐文件）：
`accept_real_files_test` · `accept_real_paged_test` · `hash_contract_flow_test` · `m2_android_verify_test` · `m2_library_flow_test` · `paged_reader_flow_test` · `reader_mode_switch_test` · `vertical_reader_flow_test`
· `reader_metrics_real_corpus_test`
· `reader_search_real_corpus_test`

**构建门禁**：`tool/verify.ps1` 全绿（pub get / format / analyze / test / integration / Windows Release / APK Debug / git diff --check）。

---

## B. 能力验证矩阵

| Capability | Unit | Widget | Integration | Windows manual | Android real device |
|---|---|---|---|---|---|
| UTF-8 编码检测 | ✅ | — | ✅ | ✅ | ✅ |
| GBK/GB18030 解码（23940 表+209 锚点+四字节𠀀） | ✅ | — | ✅ | ✅ | ✅*（A1 + M2 真机 9/9） |
| 章节 473（真实文件） | ✅ | — | ✅ accept_real | ✅ | ✅*（用户打开大 TXT） |
| 无章节（0 章不伪造目录） | ✅ | — | ✅ accept_real | ✅ | ✅*（用户滚动） |
| 相邻重复标题去重（错别字正文引用行） | ✅ | — | ✅ | ✅（473 保持） | — |
| 卷层级（卷章/卷一/卷后重编号/卷不计章数） | ✅ | — | ✅ | ✅ | ✅（因果快递 1 卷） |
| 大文件阈值（20MB/20+1/50/50+1） | ✅ | ✅ 确认 UI | — | ✅ | — |
| 导入（原子两阶段/取消无残留/alreadyImported） | ✅ | ✅ | ✅ m2_flow | ✅ | ✅ 9/9 |
| managed 文件（source/normalized/index/manifest） | ✅ | — | ✅ | ✅ | ✅（数据存留） |
| hash 合同（manifest 权威/落盘字节） | ✅ 11 | — | ✅ hash_contract_flow | ✅ | ✅*（错误消失） |
| repair（损坏→自 source 重建/不改外部 TXT） | ✅ 12 | — | ✅ | ✅（真实库 3 本+821 行） | — |
| Reader 打开 | ✅ | ✅ | ✅ | ✅ | ✅（4 本书） |
| Reader 进度百分比（Locator/normalized length 派生） | ✅ | ✅ | ✅ real corpus | ✅ | ⏳ 后续统一真机复核 |
| CurrentChapterResolver（chapter-only；volume/no-chapter 不伪造） | ✅ | ✅ | ✅ | ✅ | ⏳ 后续统一真机复核 |
| 当前书书签 create/list/delete | ✅ | ✅ | — | ✅ | ⏳ 后续统一真机复核 |
| 书签 vertical exact jump | ✅ | ✅ | — | ✅ | ⏳ 后续统一真机复核 |
| 书签 paged containing-page jump | ✅ | ✅*（控制器合同） | ✅*（现有分页链路） | ✅ | ⏳ 后续统一真机复核 |
| 书签 orphan 动态状态/禁止错误跳转/可删除 | ✅ | ✅ | — | ✅ | ⏳ 后续统一真机复核 |
| 书签面板开关/删除零 progress 写入 | ✅ | ✅ | — | ✅ | ⏳ 后续统一真机复核 |
| 当前书 normalized.txt 普通搜索 | ✅ | ✅ | ✅ real corpus | ✅ | ⏳ 后续统一真机复核 |
| 中文/英文/数字/大小写/重复匹配 | ✅ | ✅ | ✅ | ✅ | ⏳ 后续统一真机复核 |
| UTF-16 surrogate 与 context 边界 | ✅ | ✅ | ✅ | ✅ | ⏳ 后续统一真机复核 |
| 搜索结果 CurrentChapterResolver 章节派生 | ✅ | ✅ | ✅ | ✅ | ⏳ 后续统一真机复核 |
| vertical/paged 搜索结果精确跳转 | ✅ | ✅*（现有分页 containment 合同） | ✅ | ✅ | ⏳ 后续统一真机复核 |
| debounce / isolate cancellation / generation | ✅ | ✅ | ✅ | ✅ | ⏳ 后续统一真机复核 |
| 清空/关闭搜索零 progress 写入 | ✅ | ✅ | — | ✅ | ⏳ 后续统一真机复核 |
| 最近阅读（仍在书架、有效 session、lastReadAt 排序、limit 2） | ✅ | ✅ | — | ✅ | ⏳ 后续统一真机复核 |
| 阅读历史快照/时长/session 次数/继续阅读 | ✅ | ✅ | — | ✅ | ⏳ 后续统一真机复核 |
| 删除书籍后历史保留、最近阅读消失 | ✅ | ✅ | — | ✅ | ⏳ 后续统一真机复核 |
| 删除历史级联 sessions 且不影响书架/progress/preferences | ✅ | ✅ | — | ✅ | ⏳ 后续统一真机复核 |
| Reader session 首次 confirm、pause/resume、route end、不重复创建 | ✅ | ✅ | ✅ | ✅ | ⏳ 后续统一真机复核 |
| 滚动（滚轮/滚动条/触摸） | — | ✅ | ✅ vertical_flow | ✅ | ✅ |
| restore（位置恢复/防抖/零写入/生命周期） | ✅ | ✅ | ✅ | ✅（八月初七中段） | ✅（43/548 章恢复） |
| force-stop 重启 | — | — | ✅ | — | ✅*（最后模式+位置、书架数据保留） |
| TOC 完整标题（displayTitle） | ✅ | ✅ | ✅ | ✅（第1章 百世书…） | ✅（目录平铺） |
| TOC 精确跳转（两阶段字符对齐） | ✅ 11 | ✅ | ✅ | ✅（9 章 offset） | ✅（548→530） |
| 当前章目录定位（35% 视口/不拉回/定位按钮） | ✅ | ✅ 12 | ✅ | ✅（±1 章） | ✅（42 章 @39%） |
| 平铺目录（无折叠/异常层级可见/卷跳转） | ✅ | ✅ | ✅ | ✅（4 collection） | ✅（13/13） |
| 深色/浅色可读（≥4.5:1） | ✅ | ✅ 8 | — | ✅ | ✅*（用户确认深色可读） |
| 横竖屏旋转 | — | — | ✅ | — | ✅（渲染正常位置连续） |
| 外部文件保留（删除/repair/导入均不改外部 TXT） | ✅ | ✅ | ✅ | ✅（hash 不变） | ✅ |
| 分页引擎（行粒度/LF 边界/end 链连续/surrogate 不拆） | ✅ 20 | ✅ 11 | ✅ accept_real_paged | ✅* | ✅* |
| 分页惰性窗口（prev2+next3，Page 数与总页数无关） | ✅ 7 | ✅ | ✅ paged_flow | ✅* | ✅* |
| 双模式切换（v↔p 精确 anchor/零写入/generation） | ✅ 18 | ✅ 11 | ✅ mode_switch | ✅* | ✅* |
| paged→vertical 非零 X：visible confirm 后才解冻 | ✅ | ✅ | ✅ mode_switch（X=1200） | ✅ 自动 | NOT-RUN（M5.1 收尾） |
| A/B 每书独立 mode+Locator，多轮交叉读取不串书 | ✅ | ✅ | ✅ real corpus（全部 4 TXT） | ✅ 自动 | NOT-RUN（M5.1 收尾） |
| 分页目录跳转（精确 target/标题可见） | ✅ | ✅ | ✅ paged_flow | ✅* | ✅* |
| 键盘翻页 / 滑动翻页（Win / Android） | — | ✅ | ✅ paged_flow | ✅* | ✅* |
| 100 页往返（end 链严格连续，页首 ≤2 屏漂移） | ✅ 20 | — | ✅ accept_real_paged | ✅ | ✅*（实际翻页无明显问题） |
| 模式+位置持久化（重开 = 上次模式 + 最后 Locator） | ✅ 11 | ✅ 3 | ✅ mode_switch | ✅*（A/B/C 三场景） | ✅*（A/B/C 三场景） |
| 退出只 flush active 模式（覆盖竞态修复） | ✅ 4 | ✅ 3 | ✅ mode_switch | ✅*（完全退出） | ✅*（force-stop） |
| schema 2→3 迁移（旧数据默认 vertical） | ✅ 1 | — | — | ✅ | ✅（覆盖安装） |
| ReaderPreferences 默认值/范围/强类型 API | ✅ | — | — | — | — |
| Metrics/Paint 变化分类合同 | ✅ | — | — | — | — |
| AppSettings 保存/读取/watch/reset/重启持久 | ✅ | — | — | — | — |
| 非法设置值逐字段 fallback | ✅ | — | — | — | — |
| schema 3→4 保留书库/progress/mode/Locator/managed TXT | ✅ | — | — | — | ⏳ 待未来覆盖安装真人验证 |
| storage key 不泄漏 UI/Controller/Reader | ✅ | — | — | — | — |
| vertical 字号/行距变化后 locator 精确恢复 | ✅ | ✅ | — | ✅ Windows | ⏳ 无设备 |
| paged 字号/边距变化后新页包含 locator | ✅ | ✅ | ✅ real corpus | ✅ 4 TXT / 12 anchors | ⏳ 无设备 |
| 快速 18→20→24→22 仅最终 generation 生效 | ✅ | ✅ | — | ✅ | ⏳ 无设备 |
| metrics 重排 logical error | 0 | 0 | 0 | 0 | ⏳ 无设备 |
| system/light/dark 实时切换与重启恢复 | ✅ | ✅ | — | ✅ | NOT-RUN（M5.1 收尾） |
| vertical theme paint-only / Locator 不变 / 零写入 | ✅ | ✅ | — | ✅ | NOT-RUN（M5.1 收尾） |
| paged theme 不失效 PageWindow / 不重分页 | ✅ | ✅ | — | ✅ | NOT-RUN（M5.1 收尾） |
| Windows Release / Android Debug 正常入口构建 | — | — | — | ✅ | ✅ build |
| V3 Reader chrome（顶部/底部显隐不改变正文 viewport） | — | ✅ | ✅ Reader flows | ✅ 自动 | NOT-RUN（M5.1 收尾） |
| 目录 / Aa / 更多入口；未实现 TTS 不伪装可用 | — | ✅ | ✅ TOC flows | ✅ 自动 | NOT-RUN（M5.1 收尾） |
| portrait/landscape + Windows responsive toolbar | — | ✅ | ✅ Windows resize path | ✅ 自动 | NOT-RUN（M5.1 收尾） |
| Aa 设置面板四类 metrics 即时应用与持久化 | ✅ | ✅ | ✅ real corpus | ✅ 自动 | NOT-RUN（M5.1 收尾） |
| 滑块 draft / drag-end commit / latest generation | ✅ | ✅ | — | ✅ 自动 | NOT-RUN（M5.1 收尾） |
| 设置面板 reset defaults | ✅ | ✅ | — | ✅ 自动 | NOT-RUN（M5.1 收尾） |
| 设置面板 per-book vertical/paged（不进入全局 preferences） | ✅ | ✅ | ✅ mode_switch | ✅ 自动 | NOT-RUN（M5.1 收尾） |

---

## C. Android 真机专项（Redmi K60 / Android 15）

### Spike 4 受控 Spike（2026-08-06）— 8/8
GB18030 解码输出 · 有章节首屏 · 无章节 7.68MB 首屏 · 真实内存（PSS 281MB/RSS 431MB Debug）· 字号变化偏移稳定 · 横竖屏偏移稳定 · 后台恢复偏移保持 · 字体度量差异（Android 3993 页 vs Windows 373/390px，偏移语义一致）

### M2（2026-08-06）— 9/9
安装启动 · AssetBundle（23940/209 并发去重）· 双编码小文件导入 · 书架显示 · 重启持久 · 删除级联+外部保留 · alreadyImported · 取消无残留 · GB18030 𠀀

### M3（2026-08-07 用户 + 自动化）— 9/9
覆盖安装数据存留 · schema 迁移 · 打开已导入书 · 触摸滚动 · 返回重开 · force-stop 重开 · 第 400 章跳转 · 无章节大文件滚动 · 横竖屏仍可见 · 0 crash（含返回动画等待修复 ab866d7）

### M3.4（2026-08-07 自动化）— 13/13
覆盖安装数据存留 · 恢复位置（43/548 章）· 平铺目录无箭头 · 自动定位高亮（42 章 @39%）· 点章节跳转（548→530）· 点卷跳转 · 目录滚动不拉回 · 正文滚动保存恢复 · force-stop · 进程退出重进 · 横竖屏 · 0 crash（pid 23606 全程不变）· 无章节「全文」（Windows 真库验证）

### M4 P1 最终真人验证（2026-08-08）— PASS
vertical A → paged → 不翻页 → 重开 = paged + A · vertical A → paged → 翻页到 B → 重开 = paged + B · paged B → vertical → 滚动到 C → 重开 = vertical + C · force-stop 重开 · 覆盖安装 schema 2→3 数据保留 · 原有书架/managed TXT 保留 · 4 个真实 TXT 正常 · Flat TOC/章节跳转/深色模式无明显回归

---

## D. Windows 真人/验收

- 真实库 4 collection 全链（M3.4）：苟在初圣魔门 473 章 / 青山 294 章 3 卷 / 因果快递 53 章 1 卷 / 无章节数字测试 → 平铺、高亮、跳转、不拉回、全文。
- M3.2：真实库 4 本 repair → parserVersion 2.0.0、完整标题、9 章 offset 命中、第 31 章 @192296 跳转。
- M3.1：真实库 3 大文件 repair + 821 行更新、外部 hash 不变、Reader 打开成功。
- M1/M2：真实文件 473/0 章、9 个指定 offset、二次 cacheHit、外部 hash 不变。
- 构建：Windows Release exe 可启动（冒烟 6s）；App 日常使用由用户确认。
- M4 P1：三组模式/位置持久化场景通过；完全退出后重开正常；4 个真实 TXT、
  原有书架/managed TXT、Flat TOC、章节跳转、深色模式无明显回归。

---

## E. 测试缺口（诚实记录）

| 项 | 状态 |
|---|---|
| >50MB 文件真机打开路径 | 未验证（策略为拒绝，仅阈值单测） |
| EPUB/RSS 等非 TXT 源 | 未实现，无测试 |
| FTS5/跨书搜索/搜索历史/TTS | 未实现，无测试 |
| Release 版 Android 内存实测 | 未测（PSS 281MB 为 Debug 值） |
| 多用户/多设备 | 未做 |
| Android 12 以下版本 | 未测（真机为 Android 15；minSdk 21） |
| Windows 低 DPI/高 DPI 缩放 | 未专项验证 |
| M5.1a Reader 设置 UI/实时重排 | 本阶段明确未实现，属于 M5.1b 及后续 |
## M5.1e.1 validation

| Area | Result |
|---|---|
| Schema 4 -> 5, legacy settings seed, books/progress preserved | PASS |
| Per-book save/load/watch/restart and A/B isolation | PASS |
| Reset defaults affects current book only | PASS |
| Reopen first effective body layout uses saved current-book values | PASS |
| Invalid/non-finite/out-of-range values fallback per field | PASS |
| Letter/line/paragraph/indent/four-padding metrics preserve Locator | PASS, logical error 0 |
| Theme remains paint-only | PASS |
| Contracts + unit + widget | 355/355 PASS |
| Windows integration | 9/9 suites, 12/12 scenarios PASS |
| Real corpus (`C:\Users\TOM\Desktop\测试`, all 4 TXT, 12 anchors) | PASS, logical error 0 |
| Android real device | NOT-RUN / deferred to M5.1 final validation |
## M5.1 final validation (COMPLETE)

| Validation | Final result |
|---|---|
| flutter analyze | PASS, 0 issues |
| Contract + unit + widget | 355/355 PASS |
| Integration | 9/9 suites, 12/12 scenarios PASS |
| Real corpus, all four current TXT | PASS |
| Beginning/middle/end metrics anchors | 12/12, logical error 0 |
| Per-book Locator / mode / preferences, A/B isolation, restart | PASS |
| Non-zero vertical/paged switching and latest generation | PASS |
| Typography does not mutate normalized.txt | PASS |
| Theme paint-only / current-book reset / Flat TOC / Aa / resize | PASS |
| Windows user human validation | PASS, no obvious issue reported |
| Android user initial human validation | PASS, no obvious issue reported |
| Android Codex final device session | NOT-RUN, no device connected |
| Windows Release / Android Debug | PASS / PASS |

## Reader input and chapter pagination follow-up (2026-08-09)

| Validation | Result |
|---|---|
| PhysicalInput -> InputBinding -> ReaderCommand defaults | PASS |
| Arrow / PageUp / PageDown mapping | PASS |
| Windows paged wheel mapping and throttle | PASS, targeted widget coverage |
| Vertical wheel behavior remains scroll input | PASS, targeted widget coverage |
| Chapter starts force a fresh paged page; title at page start | PASS |
| Forward/backward continuity (`previous.endOffset == next.startOffset`) | PASS |
| TOC chapter offset resolves to chapter first page | PASS |
| No-chapter continuous pagination | PASS |
| All four real TXT files, chapter/anchor continuity, logical error | PASS, 0 |
| Android volume-key device validation | NOT-RUN, wireless ADB target offline |

## M5.2a persistence foundation (2026-08-09)

| Validation | Result |
|---|---|
| Drift schema 5 -> 6 migration | PASS |
| Existing reading_progress and non-zero mode preserved through migration | PASS |
| `PRAGMA foreign_keys` enabled | PASS |
| history.collectionId `ON DELETE SET NULL` | PASS, real PRAGMA + delete test |
| bookmarks.collectionId `ON DELETE SET NULL` | PASS, real PRAGMA + delete test |
| sessions.historyEntryId `ON DELETE CASCADE` | PASS, real PRAGMA + delete test |
| Bookmark orphan derived without persisted `isOrphan` | PASS |
| ReadingSession SUM/COUNT aggregate | PASS |
| Visible-confirm / pause / resume / route-end lifecycle contract | PASS |
| CurrentChapterResolver chapter-only and no-chapter behavior | PASS |
| M5.2a targeted unit/migration tests | 7/7 PASS |

## M5.2d final validation (2026-08-09)

| Validation | Result |
|---|---|
| Full unit/contract/widget | 382/382 PASS |
| M5.2d history/session persistence coverage | PASS |
| Existing Windows integration baseline | 10 files / 13 scenarios PASS when run individually |
| Four real TXT regression / logical error | PASS, 0 |
| Windows Release / Android Debug | PASS |
| Android real device | Deferred to unified final device pass |

## M5.3c+d input routing and capture (2026-08-10)

| Validation | Result |
|---|---|
| Profile-driven Windows keyboard and wheel routing | PASS |
| Profile-driven Android volume routing contract | PASS |
| Custom page command and explicit null binding | PASS |
| Previous/next chapter uses real chapter offsets | PASS, exact Locator path |
| Vertical chapter restore / paged chapter restore | PASS |
| Toggle controls / open TOC side-effect contract | PASS |
| Profile watch hot reload | PASS |
| Capture consumes first input and does not dispatch | PASS |
| Capture cancel / mode generation / dispose invalidation | PASS |
| Android paged/capture host state bridge | PASS, Debug build |
| Full unit/contract/widget | 401/401 PASS |
| Windows integration | 10 files / 13 scenarios PASS |
| Windows Release / Android Debug | PASS / PASS |
| Four real TXT logical error | PASS, 0 |
| Android real device | NOT-RUN / deferred |

## M5.3.2 paged chapter page progress (2026-08-10)

| Gate | Result |
|---|---|
| Chapter first/middle/final page derivation | PASS |
| Chapter-first-page and next-chapter boundary | PASS |
| Shared boundary / volume exclusion / malformed offsets | PASS |
| No-chapter TXT avoids chapter page calculation | PASS |
| Cache hit/miss and bounded cache | PASS |
| Stale generation after layout change | PASS |
| Paged chrome `本章 x / y 页` + `全书 z%` | PASS |
| Four real TXT corpus | PASS; logical error 0 |
| Windows Release / Android Debug | PASS / PASS |
| Android real device | NOT-RUN / deferred |
| Drift schema | 6, unchanged |

## M5.3e.2 correction (2026-08-10)

| Gate | Result |
|---|---|
| ReadingHistory values/null handling | PASS |
| Plain keys + Ctrl/Alt/Shift canonical gestures | PASS |
| candidate/retry/cancel/confirm/conflict contracts | PASS |
| old single-key profile migration | PASS; schema 6 |
| Full unit/contract/widget | 408/408 PASS |
| Windows integration | 10 files / 13 scenarios PASS |
| Real four-TXT corpus | PASS; logical error 0 |
| Windows Release / Android Debug | PASS / PASS |
| Android ADB | NOT-RUN (explicit scope boundary) |

## M5.3e.1 keyboard capture correction (2026-08-10)

| Validation | Result |
|---|---|
| Windows capture FocusNode receives ArrowLeft/Right and PageUp/Down | PASS, routed through stable IDs |
| Stable A–Z / 0–9 / arrows / paging / Home/End / Space / Enter registry | PASS |
| Candidate held before persistence | PASS |
| Retry and cancel discard candidate | PASS |
| Explicit confirmation persists binding | PASS |
| Conflict cancel / replacement contract | PASS |
| Capture first input does not dispatch ReaderCommand | PASS |
| Schema | 6, unchanged |

## M5.3 final contract closure (2026-08-10)

| Validation | Result |
|---|---|
| Android physical-input UI | PASS by code/test inspection; Volume Up/Down only |
| Android supported actions | PASS; previous page / next page / disabled |
| Unsupported Android profile migration | PASS; legacy command falls back to platform default |
| Windows six-command regression | PASS; single-key, modifier, wheel, chapter routing |
| Chapter navigation generation / cancellation | PASS; stale operations cannot commit |
| Locator / progress persistence contract | PASS; no page/chapter index or pixel source added |
| Full unit/contract/widget | **410/410 PASS** |
| Windows integration | **10 files / 13 scenarios PASS** |
| Four real TXT corpus | PASS; logical error 0 |
| Windows Release / Android Debug | PASS / PASS |
| Android targeted ADB | NOT-RUN; no device connected |

## M5.3a+b input binding contract (2026-08-09)

| Validation | Result |
|---|---|
| Typed ReaderCommand and stable PhysicalInputId contract | PASS |
| Windows default profile | PASS |
| Android default profile | PASS |
| bind / unbind with explicit null / reset defaults | PASS |
| App restart persistence | PASS |
| Windows / Android profile isolation | PASS |
| Whole JSON fallback and platform isolation | PASS |
| Unknown input/command rows ignored; valid/null rows retained | PASS |
| Older profile version migration fills missing defaults | PASS |
| ReaderPreferences unaffected; schema remains 6 | PASS |
| Targeted domain/repository tests | 9/9 PASS |
| `flutter analyze` / `git diff --check` | PASS |

## M5.3e Reader input settings UI (2026-08-10)

| Validation | Result |
|---|---|
| `我的 → 阅读设置 → 按键与操作` route | PASS, Windows/Android platform-aware UI |
| Current platform supported-input filtering | PASS |
| Six command groups and current binding display | PASS |
| Capture overlay consumes first supported input | PASS, existing capture contract |
| Conflict replace / cancel behavior | PASS, typed repository path |
| Clear binding persists explicit null | PASS |
| Reset defaults affects only active platform | PASS |
| Dark/light/system readability contract | PASS, shared Material theme |
| Locator / reading_progress / ReaderPreferences / session side effects | PASS, none |
| Full unit/contract/widget | 401/401 PASS |
| Windows Release / Android Debug | PASS / PASS |
| Android real device | NOT-RUN / deferred |

## M5.4a AutoRead domain contract (2026-08-10)

| Validation | Result |
|---|---|
| Idle/running/paused/stoppedAtEnd transitions | PASS |
| Idempotent start/pause/resume/stop and EOF handling | PASS |
| Pause reasons and typed domain events | PASS |
| Generation invalidation and dispose safety | PASS |
| Default speed/interval and velocity mapping | PASS |
| Valid update, watch, reset, and app-restart persistence | PASS |
| Corrupt JSON, invalid values, and version fallback | PASS |
| AutoRead vs ReaderPreferences/InputProfile isolation | PASS |
| Full Flutter test suite | 435/435 PASS |
| Drift schema | 6, unchanged |
| Reader drivers/UI/keep-awake/shortcuts | Deferred to M5.4b |
