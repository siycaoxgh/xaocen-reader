# KNOWN_ISSUES.md — XAOCEN Reader v4 已知问题清单

> 状态截至 M5.5e.5（`feat/m4-horizontal-reader`，Drift schema 8）。Android 真机按阶段策略另行复核。
> 已解决的问题不在此列为 open；「Resolved but regression-sensitive」列出需要持续盯防的已修复项。

---

## Current open issues

## M5.5e.5 status (2026-08-11)

- Aa category labels, color-mode wording, dual light/dark palette expression, and active
  custom-scheme preview were aligned across Windows and Android. No new P1/P2 issue was found;
  schema remains 8 and Reader engine contracts are unchanged.
- Android real-device validation was not run in this coding pass; Android Debug build passed.

## M5.5e.4.1 status (2026-08-11)

- Preset/custom paint-source precedence and Windows Aa width were corrected. No new P1/P2
  issue was found; schema remains 8. Android Debug passed, while Android real-device validation
  was not run in this coding pass.

## M5.5e.4.2 status (2026-08-11)

- Palette selection and repaint flow were confirmed correct. Preset colors were strengthened
  for visible contrast; `墨黑` is black in both brightnesses and `浅灰` is explicitly gray.
  No new P1/P2 issue or icon/logo resource error was found. Android Debug passed; real-device
  validation was not run in this coding pass.

## M5.5e.4 status (2026-08-11)

- No new Reader P1/P2 issue was found. Reader palettes now resolve through a
  single typed resolver with separate light/dark per-book overrides; explicit
  custom text colors are never silently replaced. Low contrast is surfaced as a
  warning for the user.
- Drift schema 7→8 migration passed against real SQLite and retained legacy
  colors, managed image references, typography, books, and reading_progress.
- Android real-device validation was not run in this coding pass; Android
  Debug build passed. Windows Release and all four real TXT logical-error-zero
  checks passed.

## M5.3.1.1 status (2026-08-10)

- The reproducible Android paged-swipe stall at a bounded PageWindow tail is
  resolved. PageWindow tail is no longer treated as document EOF; Controller
  prefetch and pointer-edge fallback now share the volume/keyboard page-turn
  path. Regression coverage passes with logical error 0.
- Android targeted ADB verification was not repeated in this coding pass.

## M5.3.1 status (2026-08-10)

- No new Reader P1/P2 issue was found. Vertical chapter percentage is now
  available as transient derived UI state; paged chapter page totals remain
  intentionally deferred.
- Android real-device validation was not repeated in this coding pass. The
  Android Debug artifact builds successfully.

## M5.2a status (2026-08-09)

- No new Reader P1/P2 issue was found in the M5.2a persistence foundation.
- Cross-book search, search history, and FTS5 remain intentionally deferred to
  later M5.2 stages; current-book search, Recent Reading, and Reading History
  are delivered in M5.2c/d.
- Reading-history snapshots are display-only. They must never be used to restore
  a deleted book or replace `reading_progress` as the Locator source.

- Reader input/chapter-policy follow-up is implemented, but Android volume-key
  validation is pending because the previously confirmed Wireless ADB target is
  currently offline. No APK reinstall or data reset is being used to bypass
  this device-state issue.

（截至 M4 最终封存，无已知的 open bug。M4 P1 已解决并从已知问题中移除；以下均为验证覆盖的边界行为或工具性限制，见 Known limitations / Deferred。）

- M5.1e 未发现新的 Reader engine P1/P2；字号、行距、双向边距、主题、
  每书阅读模式和恢复默认均已接入。
- M5.1c/d/e Android 真机验收为 NOT-RUN，按既定策略延后到 M5.1 最终统一验收；
  各子阶段仍要求 Android Debug 构建通过。

---

## Known limitations（当前版本的能力边界）

| 限制 | 说明 |
|---|---|
| 仅支持 TXT | EPUB/PDF/Markdown/HTML 未实现（见 Deferred） |
| >20MB 需确认 | 导入前提示，用户确认后后台扫描 |
| >50MB 0.1.x 暂不支持 | 明确提示，不尝试打开（阈值集中定义于 large_file_policy.dart，可调） |
| Reader 双模式 | 纵向滚动 + 横向分页（M4 已交付，v0.1.0-dev.4+4）；位置真源始终为 UTF-16 偏移，页码为派生 |
| 文件选择依赖系统对话框 | file_picker 调起系统选择器（Android 上需手动配合） |
| Android 调试依赖无线调试 | USB 直连被 Windows 驱动签名阻塞，需设备开启无线调试 |
| 调试 APK 内存占用高 | Debug 构建 PSS ~281MB（JIT/引擎常驻）；Release 会显著下降 |
| 12px 顶部安全区 | 恢复/跳转后顶部可能显示上一章尾部（合同行为：标题行对齐 topInset+8~24px；目录高亮允许 ±1 章） |
| 目录 UI 长距离滚动受限 | DraggableScrollableSheet 手势会吞掉长距离 drag；远跳能力由 controller 层 + 集成测试保证，UI 层点到即达 |
| normalized.txt 全文载入内存 | ≤50MB 文件全量加载为 Dart String（设计内）；>50MB 惰性读取未承诺 |
| 分页 backward 页首漂移 | Flutter getLineBoundary 在 LF/wrap 边界行首定位偏差：≤2 屏/100 页（end 链严格连续，字符链不重不漏；confirmed locator 零误差，仅翻回时起始行略偏移） |

---

## Deferred（已排期/延后，未开始）

| 项 | 说明 |
|---|---|
| 搜索 | FTS5 未建 |
| 书内书签 | M5.2b 已实现；跨书历史入口仍未实现 |
| Reader V3 壳层/设置 UI | M5.1d/e 已实现；更完整的后续信息架构仍未做 |
| M5.1 Android 最终真机验证 | M5.1c/d/e 开发阶段仅要求 Debug build；真人/真实语料统一在 M5.1 收尾执行 |
| TTS | 未引入 flutter_tts |
| RSS / 网络书源 | webfeed/JSON Feed 调研过但未引入；RSS 属 v2.0 范围 |
| EPUB / PDF | 未实现 |
| 更完整的信息架构 UI | 当前 Reader 已有 V3 壳层、进度和书签；最近阅读/历史/搜索入口未做 |
| 云同步 / 账号 | 未做 |
| 多设备同步 | 未做 |

---

## Resolved but regression-sensitive（已修复，需持续盯防）

| 项 | 为何敏感 | 防护 |
|---|---|---|
| normalizedHash 合同 | M3.1 P1：Drift 曾存 sourceHash 导致大文件 hash_mismatch；任何写入路径改动都可能复发 | hash_contract_test + repair_service_test + 集成 hash_contract_flow_test；Loader 以 manifest 为权威 |
| parser 完整标题 | M3.2：group(0) 曾丢标题；任何扫描器改动可能复发 | scanner 完整标题 8 项 + toc_title_persistence 6 项；真实库 4 本 parserVersion 2.0.0 |
| 目录自动定位/当前章高亮 | M3.3：block 级近似曾差 34 章 | toc_scroll_test 12 项；真实文件 6 章 ±1 |
| 深色可读性 | M3.3 P1：硬编码深字曾致黑底不可读 | reader_dark_mode_test 8 项（≥4.5:1） |
| progress 恢复冻结 | M3：恢复未确认前写入会污染位置 | reader_controller_test 冻结/防抖用例 |
| 外部 TXT 不可修改 | 全阶段红线：repair/删除不得触碰外部文件 | 验收测试断言外部 hash 不变；删除级联测试 |
| 473 章去重 | M3.2：正文引用行（错别字）曾致 486 章 | 章节编号相同即相邻重复；真实文件 473 断言 |
| Android APK 正常入口 | flutter test 会覆盖为 test-runner 版 | 测试后必须重新 build apk --debug |

---

## 记录但未修复的观察（文档审计发现）

以下为本任务（M3 封存审计）中观察到、按任务书仅记录不修改的事项：

1. **M2 遗留 storagePath 语义**：`content_documents.storage_path` 存 `library/local_txt/<hash>/normalized.txt`（相对 `<support>`），而 `LibraryFileManager.libraryRoot` 即 `<support>/library` —— M3 已用 `resolveStoragePath` 去前缀修复（loader 与 manifest 读取），但数据中保留 `library/` 前缀的语义仍属冗余，未来 schema 变更时可考虑清理。
2. **`test/fixtures/txt/` 大文件 fixture**（20MB/50MB 共 4 个，~146MB）已由 git 压缩存储（pack 很小），但克隆体积仍会因 worktree 展开而变大；如未来仓库分发受限可改为运行时生成。
3. **`integration_test/vertical_reader_flow_test.dart` 内嵌大 fixture 数组**（74,593 行，~676KB）—— 为保证格式门禁，行尾已统一 LF；该文件体量较大，未来可改为运行时生成 fixture。
4. **`tool/inspect_managed_txt.dart`** 依赖 `sqlite3` 直接依赖（pubspec 显式加入，原为传递依赖）—— 属工具链用途，勿移除。
5. **父目录 `m1_cache/`、`m1_cache_notoc/`** 是 M1 阶段 inspect 工具的缓存产物（管理目录，不在仓库内），非外部 TXT 旁缓存。
6. **`docs/README.md` 的权威文档索引**未列 M1–M3.4 报告（本任务新增 6 份长期文档后应同步更新索引——见最终交付说明）。
## M5.2b status update (2026-08-09)

- No new Reader P1/P2 issue was found. Progress/chapter display and current-book
  bookmark CRUD/navigation are implemented with exact Locator contracts.
- Bookmark orphan status is explicit and dynamic; orphan navigation is disabled,
  while deletion remains available. Four real TXT files reported logical error 0.

## M5.2c status update (2026-08-09)

- No new Reader P1/P2 issue was found. Current-book normalized.txt search uses
  transient UTF-16 results, cancellable worker isolates, and generation checks.
- Cross-book search, FTS5 indexing, and search history remain intentionally
  deferred. Recent Reading and Reading History are implemented in M5.2d.

## M5.1e.1 status update (2026-08-09)

- The P1 “saved panel values but default body layout after reopen” is resolved by
  gating Reader startup on the current collection's saved preferences.
- ReaderPreferences is now per book in schema 5; no known cross-book preference
  contamination remains.
- Android device validation remains NOT-RUN / deferred to M5.1 final validation.

## M5.2d status update (2026-08-09)

- Recent Reading, Reading History, and Reader session lifecycle are implemented.
- No new P1/P2 issue was found in the persistence or lifecycle regression tests.
- Cross-book search, FTS5, search history, RSS/EPUB/TTS remain deferred.

## M5.3a+b status update (2026-08-09)

- Typed platform input profiles and repository persistence are complete with no
  new P1/P2 issue found.
- Input capture, physical-event routing to the new bindings, and custom-binding
  settings UI remain intentionally deferred to M5.3c. Existing default Reader
  input behavior is unchanged.

## M5.3c+d status update (2026-08-10)

- Unified routing and Android capture bridge are complete; no new P1/P2 issue
  was found in automated or Windows integration validation.
- Custom-binding settings UI, conflict confirmation, and user-facing capture
  flow remain intentionally deferred to M5.3e.
- Android physical-device validation remains NOT-RUN / deferred; Android Debug
  build passed.
## M5.1 final seal (2026-08-09)

- No new M5.1 P1/P2 Reader issue was found in final automated or Windows user
  validation. M5.1 is COMPLETE.
- Android final Codex device validation was NOT-RUN because no device was connected.
  The user's initial human test found no obvious issue; the formal checklist remains
  recorded in `M5_1_FINAL_RESULT.md` for the next available device session.
- Existing documented limitations outside M5.1 remain unchanged; no M5.2 work began.

## M5.3e status update (2026-08-10)

- Reader input settings UI, supported-input capture, conflict confirmation,
  explicit null disable, and platform-scoped reset are complete. No new P1/P2
  issue was found; 401 automated tests remain green.
- Android real-device validation for the settings page remains NOT-RUN /
  deferred to the unified device pass. Windows Release and Android Debug builds
  passed.

## M5.3e.1 status update (2026-08-10)

- The Windows keyboard-capture P1 is resolved. The cause was focus remaining on
  the add button; capture now requests a dedicated FocusNode and visibly holds
  a candidate until confirmation.
- Android ADB validation is intentionally not part of this correction pass.

## M5.3e.2 status update (2026-08-10)

- Reading History `Instance of ...` output is resolved and regression-covered.
- Windows keyboard capture now supports the documented single-key range plus
  Ctrl/Alt/Shift gestures. Candidate input is never persisted before confirm.
- No new Reader P1/P2 issue was found. Android ADB was explicitly excluded;
  Android Debug build passed.

## M5.3 final contract closure (2026-08-10)

- Android Volume bindings are intentionally limited to previous page, next
  page, or disabled. Chapter/control/TOC bindings remain Windows/domain-only;
  legacy Android values are normalized back to platform defaults.
- Android targeted ADB was not run in this sealing pass because no device was
  connected. Windows and automated Android Debug build validation passed.
- At the M5.3 final-contract checkpoint, paged chapter page totals were still
  deferred; M5.3.2 now supplies them transiently for the active chapter only.

## M5.3.2 status update (2026-08-10)

- Paged chapter page totals are now available transiently for the active
  chapter only. No full-book page total is intentionally shown, especially for
  large or no-chapter TXT.
- Android real-device visual validation of the new page indicator remains
  deferred; Windows and automated four-file corpus validation passed.

The initial paged label mojibake discovered during manual review is resolved;
the remaining Android item is visual device validation only.

## M5.4d status update (2026-08-11)

- AutoRead UI sealing passed automated, Windows Release, and Android Debug
  validation. Android keep-awake is implemented through the host Activity;
  Windows/test hosts currently degrade safely to no-op until a native desktop
  keep-awake adapter is justified.
- No new ReaderLocator, progress, session, or Android Volume issue was found.
## M5.4e status update (2026-08-11)

- M5.4 AutoRead final regression is complete. The currently listed Android
  target was offline, so targeted device actions remain deferred; this does
  not affect the passing Android Debug build or the completed Windows/Flutter
  validation.
## M5.5a status

The responsive App Shell and first-level navigation are complete. Remaining UI
audit items (wide layouts for history/settings and Reader action hierarchy) are
planned follow-ups; no new P0/P1 data or Reader issue was introduced.
## M5.5b status

Home and Shelf responsibilities are now separated. Remaining audit work is
limited to later Reader/Me/settings visual refinement; no new P0/P1 data or
navigation issue was introduced.
## M5.5c status

Reader operation hierarchy is aligned and responsive. Remaining UI audit items
are appearance and later Me/settings refinements; no new Reader contract issue
was introduced.

## M5.5e status

Reader custom colors and managed image backgrounds are complete with schema 7
migration and paint-only regression coverage. No new P0/P1/P2 Reader issue was
found. Whole-book deletion does not yet garbage-collect every superseded image
left in that book's managed background folder; current replacement/removal/reset
paths do clean their referenced file. Windows native window transparency remains
a separate later capability.

## M5.5e.1 status

The Reader settings surface and primary action hierarchy are complete. No new
P0/P1/P2 issue was found. The remaining known follow-up is the previously
documented managed-background garbage collection for superseded assets after
whole-book deletion; it does not affect current appearance or Reader data.

## M5.5e.3 status

Reader operation hierarchy and AutoRead status controls are complete with no new
P0/P1/P2 issue found. Android real-device validation for this UI change was not
run in this phase; existing Android validation records remain authoritative.
## M5.5d status

Me, Reading History, Reader Settings, and platform input settings now have
separate responsibilities and responsive containers. Remaining visual audit
items are appearance-only follow-ups; no history, input, or Reader data issue
was introduced.
