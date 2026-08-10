# ARCHITECTURE_CURRENT.md — XAOCEN Reader v4 当前架构与合同

> 只描述当前代码与合同（`feat/m4-horizontal-reader`，M5.2d 完成点）。
> 不记录历史故事（见 PROJECT_HISTORY.md）。
> 代码位置均以本仓库实际文件为准。

---

## M5.3.1 chapter boundary and vertical progress contract

`ChapterBoundaryResolver` is the shared chapter interval source for Reader
chapter display and current-chapter resolution. It accepts TOC entries plus
the normalized document UTF-16 length, keeps only `kind == chapter`, filters
invalid offsets, sorts by start offset, and keeps the first source-order entry
for duplicates. A boundary ends at the next chapter start or document length;
volumes never define a boundary.

`CurrentChapterProgressResolver` derives a clamped transient fraction from the
confirmed `ReaderLocator` and the active boundary. It is display-only and must
not be persisted or used as a restore anchor. Vertical Reader chrome shows
chapter title/number, chapter percentage, and the existing whole-book
percentage. No-chapter documents show `全文`; paged layout and schema 6 are
unchanged.

## 1. Runtime content chain

```
external TXT (user's file, NEVER modified)
        │  read bytes (read-only)
        ▼
managed source.txt   <support>/library/local_txt/<contentHash>/source.txt
        │  byte-identical copy of the external file (BOM/CRLF preserved)
        ▼
decode  (encoding detect: BOM → strict UTF-8 → GB18030 candidate → unknown;
         pure-Dart GB18030 decoder with 23940-entry table + 209 anchors)
        ▼
normalize  (ONLY: remove BOM, CRLF/CR → LF; O(n); lineStarts built)
        │
        ▼
normalized.txt   <support>/library/local_txt/<contentHash>/normalized.txt
        │  BOM-less UTF-8; THE reader body source of truth
        ▼
TOC index  (background Isolate O(n) scan → volume/chapter tree → dedupe →
            UTF-16 offsets) → index.json (atomic write)
        ▼
Drift four-layer model (content_sources / collections / items / documents /
        toc_entries / import_records / reading_progress / app_settings)
        ▼
Reader  (NormalizedDocumentLoader → ReaderBlockIndex → virtualized vertical
         list → TextPainter layout → ReaderVisibleRange → ReadingProgress)
```

Key components by layer (all paths under `lib/`):

| Layer | Files |
|---|---|
| domain | `domain/local_txt/` (TextEncoding, TocEntry, TxtIndex, PipelineProgress, LargeFilePolicy), `domain/reader/` (ReaderLocator, ReaderBlock, ReaderVisibleRange, ReaderPreferences), `domain/library/` (entities, import models, NormalizedArtifact, TocIndexLogic) |
| sources | `sources/local_txt/` (gb18030 decoder/index loader/data, encoding detector, normalizer, toc scanner, import service/request/result, index cache, content identity, cancellation) |
| data | `data/database/` (tables, app_database + generated), `data/repositories/` (local_library_repository, library_file_manager, managed_collection_health, collection_repair_service, reading_progress_repository, reader_preferences_repository, reader_bookmark_repository, reading_history_repository, reading_session_repository, auto_read_preferences_repository, encoding_index_provider) |
| reader | `reader/` (normalized_document_loader, reader_controller, vertical_auto_read_driver, reader_page, reader_chrome, reader_text_block, reader_appearance) |
| app/design | `app/` (bootstrap, app, router, constants, library_page, providers, placeholder_page), `design/` (tokens, theme) |

Layering rules (enforced by structure, not by tooling):
- `domain` never imports Flutter.
- `reader/engine` components never depend on page Widgets.
- UI only reaches data through Repository / Controller (never Drift directly).
- `data` may depend on `domain`; `sources` may depend on `domain` but not pages.

### Reader shell and settings contract (M5.1d–e)

- `ReaderPage` owns Reader engine lifecycle; `ReaderChrome` owns only transient
  top/bottom controls and typed entry callbacks.
- Chrome is layered over a full stable Reader viewport with `Stack`. Visibility
  changes must not alter metrics, invoke Locator restore, or write progress.
- The toolbar exposes Flat TOC, current per-book mode, Interface/Aa, and More.
  Interface/Aa opens the functional settings sheet; TTS is not exposed as enabled.
- Below 720 logical pixels the toolbar follows available width; on wider Windows
  layouts it is centered and capped at 520 logical pixels.
- Colors reuse `ColorScheme`/`ReaderResolvedAppearance`; theme remains paint-only.
- Slider `onChanged` changes only sheet-local draft values. `onChangeEnd` submits a
  complete strong `ReaderPreferences` snapshot. `ReaderPage` immediately applies it
  and serializes repository writes through a single-flight/latest-pending queue.
- Font size, line height, and both paddings enter the existing M5.1b metrics state
  machine. Theme never enters that state machine. Mode selection calls the existing
  per-collection M4 transition and never enters `ReaderPreferences`.
- Reset deletes only Reader-owned AppSettings keys and immediately reapplies the
  strong default snapshot; it does not alter per-book mode or Locator.

### Reader progress and bookmarks (M5.2b)

- Reader progress is display-only: the active confirmed `ReaderLocator` divided
  by normalized UTF-16 document length produces the percentage. It is never a
  persisted progress field.
- `CurrentChapterResolver` is the sole UI chapter resolver. It selects the last
  real `chapter` entry with `startCharacterOffset <= Locator`; volumes and
  chapter-less TXT do not become chapters.
- `ReaderBookmarkRepository` scopes rows by `collectionId`. A bookmark stores
  the absolute UTF-16 offset, normalized hash-at-creation, title snapshot,
  optional note, and timestamps. Duplicate collection+offset creation is
  idempotent.
- Orphan state is derived at display/navigation time from collection linkage,
  normalized-hash mismatch, or offset bounds. It is not persisted; orphan rows
  remain deletable and cannot be navigated.
- Bookmark jumps call the existing Reader Locator restore contract: vertical
  waits for visible-range confirmation, while paged resolves the containing
  page. Panels and progress display never write `reading_progress`.

### Current-book search (M5.2c)

- `ReaderSearchService` receives only the active normalized document text and
  scans ordinary contiguous substrings in a worker isolate. The worker is
  cancellable; a monotonically increasing generation rejects stale results.
- Matching folds ASCII case only; Chinese, digits, punctuation, and surrogate
  code units remain literal. Results are capped at 100 and contain UTF-16
  start/end/context offsets plus a snippet. Chapter titles are filled by
  `CurrentChapterResolver` after the isolate returns.
- Search results are transient. No result, query, page index, percentage, or
  search history is stored in Drift. The Reader search sheet debounces input,
  highlights the hit context, and uses the existing exact vertical/paged Locator
  restore path when a row is tapped.

### Reader input bindings (M5.3a+b)

- `ReaderCommand` is the semantic command contract; physical events are
  represented by stable `PhysicalInputId` strings. Neither Flutter key objects,
  Android key codes, nor host runtime objects are persisted.
- `ReaderInputProfile` is platform-scoped (`windows` or `android`) and contains
  versioned typed bindings plus `updatedAt`. It is distinct from per-book
  `ReaderPreferences` and `ReaderProgressState`.
- `ReaderInputBindingsRepository` is the only layer that knows the private
  `app_settings` keys and JSON format. `load/watch/bind/unbind/update/reset`
  expose only typed profiles. Unknown rows are ignored, explicit null disables
  an input, malformed platform data falls back only that platform, and older
  versions merge missing inputs from defaults.
- M5.3a+b intentionally leaves the existing route, Android capture bridge, and
  binding settings UI unchanged; M5.3c will consume this contract.

### Reader input routing and capture (M5.3c+d)

- `ReaderInputRouter` is the only Reader input-to-action dispatcher. It watches
  the current platform profile, maps stable physical IDs to the six semantic
  commands, and invokes ReaderPage callbacks. Pagination and Locator code do
  not know about physical keys.
- Page actions are guarded by paged mode. Chapter actions select only real TOC
  chapter entries and call the existing exact Locator restore path in vertical
  or paged mode. Toggle-controls and open-TOC reuse existing callbacks without
  progress or session writes.
- Router generations invalidate queued events on profile/mode/metrics changes,
  lifecycle interruption, capture transitions, and dispose. Profile timestamps
  reject late stale watch events.
- `ReaderInputCapture` consumes one physical input, reports it to the caller,
  and never dispatches a `ReaderCommand`; cancellation/disposal clears it.
- Android `MainActivity` translates volume key-down events to stable IDs and
  intercepts them only while paged Reader or capture is active.

---

## 2. Four-layer content model

```
ContentSource → ContentCollection → ContentItem → ContentDocument
```

| Entity | TXT mapping | Stable ID |
|---|---|---|
| ContentSource | one per imported TXT (localTxt) | `local-txt-source:<contentHash>` |
| ContentCollection | one book | `local-txt:<contentHash>` |
| ContentItem | chapter (volume is NOT an item) or `whole` | `local-txt:<hash>:chapter:<startCharacterOffset>` / `...:whole` |
| ContentDocument | a range of normalized.txt (all items of a book reference the SAME normalized.txt) | `local-txt:<hash>:document:<startCharacterOffset>` |

Drift tables (schemaVersion 6): `content_sources`, `content_collections`,
`content_items`, `content_documents`, `toc_entries`, `import_records`,
`reading_progress`, `app_settings`, `reader_bookmarks`, `reading_history`,
`reading_sessions`. Foreign keys ON; body text is NEVER stored in SQLite
(only paths + offsets). Collection delete cascades items/documents/toc/
progress and cleans the managed directory; external TXT is never deleted.

Volume—chapter hierarchy lives in `toc_entries` (kind volume/chapter,
parentId/level/orderIndex). Volumes do NOT count toward chapter count.
A chapter-less file yields exactly one `whole` item spanning
`0..normalizedCharacterLength`; physical paging blocks are never items.

---

## 3. Text contract

- **source.txt** = byte-exact copy of the external TXT (BOM and CRLF
  preserved; SHA-256 identical to the external file). It is the original
  bytes source of truth and the repair source.
- **normalized.txt** = BOM-less UTF-8, the reader body source of truth.
- Normalization is restricted to:
  1. remove BOM;
  2. CRLF → LF;
  3. CR → LF.
- Forbidden before indexing: stripping leading whitespace, collapsing blank
  lines, deleting characters, reordering paragraphs. (Display-level
  indentation/blank-line treatment is a rendering concern and must never
  change normalized character coordinates.)
- Files per content: `source.txt`, `normalized.txt`, `index.json`,
  `manifest.json` (manifestVersion/contentHash/originalFileName/sourceSize/
  sourceHash/normalizedHash/normalizedUtf8ByteLength/detectedEncoding/
  normalizedCharacterLength/parserVersion/normalizationVersion/
  indexFormatVersion/importedAt).

---

## 4. Coordinate contract

- **The only persisted reading-position source of truth** is the UTF-16
  code-unit offset in the normalized text (`ReaderLocator`: collectionId +
  absoluteCharacterOffset + optional itemIdHint).
- Forbidden as persisted truth: page numbers, scroll pixels, blockIndex,
  chapter ratio, percent. Page/block are derived render structures.
- `clampLocatorOffset`: clamps to `[0, len]` and never splits a surrogate
  pair (steps back one code unit from a low surrogate).
- Chapter boundaries, bookmarks, search, progress all use this coordinate.

---

## 5. Hash contract

Two distinct hashes, distinct duties:

| Hash | Object | Used by |
|---|---|---|
| sourceHash | SHA-256 of external TXT bytes = managed source.txt bytes = content identity = managed directory name | import identity, alreadyImported, repair decision |
| normalizedHash | **SHA-256 of the final on-disk normalized.txt (BOM-less UTF-8) bytes** | manifest.normalizedHash, Drift content_documents.content_hash, NormalizedDocumentLoader verification, import completion check, repair completion check |

- All positions consume the SAME value via the shared strong type
  `NormalizedArtifact` (filePath / utf8ByteLength / utf16CharacterLength /
  sha256 / normalizationVersion). Never derive independently.
- Forbidden: String.hashCode, UTF-16-code-unit→bytes hashing, source.txt
  hash as normalized hash, in-memory alternative encoding, index.json hash,
  per-range content hash.
- Write order (import & repair): generate normalized text → write
  `normalized.tmp` → flush → close → **hash from on-disk bytes** →
  re-decode to verify UTF-16 length → atomic rename to normalized.txt →
  write manifest from the same artifact → Drift transaction with same
  hash/length → final re-read full verification → completed.
- Loader authority: **manifest.normalizedHash** (manifest is written
  atomically with the file); `expectedHash` is only a fallback when the
  manifest is missing. ReaderPage passes expectedLength only.
- Repair: `ManagedCollectionHealthCheck` (source hash / normalized hash /
  UTF-16 length / versions / Drift↔manifest consistency) + 
  `CollectionRepairService` (re-runs the M1 pipeline from managed
  source.txt into a repair temp dir, verifies, atomically replaces,
  Drift transaction, re-checks). External TXT is never modified; on failure
  the old files are kept and a clear error is shown.

---

## 6. Reader contract

- **NormalizedDocumentLoader**: resolve storagePath (via
  LibraryFileManager.resolveStoragePath, handles `library/` prefix), verify
  existence / BOM-less / strict UTF-8 / normalizedHash (manifest) /
  UTF-16 length; ≤50MB loaded fully into a Dart String.
- **ReaderBlock / ReaderBlockIndex**: derived; 4096–8192 code units (default
  6144), split preferably at LF, never split surrogate pairs; contiguous,
  non-overlapping, first starts at 0, last ends at full length;
  deterministic rebuild (policyVersion=1); never persisted; unchanged by
  font/window changes. `blockForOffset` binary search; out-of-range clamps.
- **Virtualized list**: `super_sliver_list 0.4.1` (MIT, admission-verified).
  No full-text single widget, no pre-layout of the whole book, no ratio
  estimation. Only first screen / restore page / neighbors are laid out;
  others are built on demand.
- **RenderReaderTextBlock**: ONE TextPainter for both display and measure;
  exposes local offset→glyph Rect (`rectForCharacterOffset`), local
  y→TextPosition, actual height, layout-completed state, onLayout callback.
  Body text: zero insertion, zero deletion (no auto indent, no blank-line
  removal, no title rewriting).
- **ReaderVisibleRange**: measured from actually laid-out active blocks
  (GlobalKey.currentContext non-null); top/bottom computed at character
  level via `characterOffsetAtLocalY` (safe block-level fallback while
  layout is in progress / not attached). No ratio estimation.
- **ReadingProgress**: one row per collection; saves the CONFIRMED
  ReaderLocator. Save classification:
  - programmatic restore → zero writes until confirmed;
  - programmatic TOC jump → save after visible-range confirmation;
  - user drag/wheel/scrollbar → real measured top char + 400ms debounce;
  - scroll end / lifecycle (pop/inactive/paused/detached/window close) →
    immediate flush.
- **Restore state machine**: loadingDocument → buildingBlockIndex →
  locatingTargetBlock → jumpingToBlock → resolvingTargetCharacter →
  confirmingVisibleRange → completed/failed. End condition: requested
  offset inside the real visible range. No fixed delays; bounded frame
  retries only.

---

## 7. TOC contract

- `displayTitle`: full title line, trimmed of leading/trailing whitespace
  (keeps 「第X章」 + actual name, punctuation untouched). Shown in TOC.
- `dedupeKey`: whitespace-normalized (full/half-width space folding), used
  ONLY for adjacent-duplicate decisions; never rendered. Adjacent dedupe
  also triggers when chapter numbers match (body-reference lines may have
  typos, e.g. 第468章 这特么 vs 这特码) — keeps real files at 473 chapters.
  No global same-name dedupe; far same-name entries are kept.
- `chapterNumber`: parsed separately (Arabic / Chinese numerals), for
  diagnostics/ordering, never replaces displayTitle.
- volume/chapter: kind, parentId, level, orderIndex preserved in data
  model; volumes excluded from chapter counts.
- **Navigation contract (global, all content sources)**:
  *Content hierarchy is semantic, not interactive. Source order is
  authoritative; navigable entries remain visible.*
  (层级负责表达关系，顺序负责导航，折叠不参与内容可见性。)
  - hierarchy retained in Domain/Data for semantics/grouping/search/export;
  - no collapse/expand interaction derived from hierarchy; no collapsed
    state persisted; no function-less arrows;
  - volume/part/category render as Section Headers only;
  - all navigable entries always visible even with abnormal hierarchy
    (wrong parentId, missing parent, consecutive volumes, mixed 卷/部);
  - long lists solved by auto-locate/highlight/search/filter/index.
  Codified in `docs/CONTENT_NAVIGATION_CONTRACT.md` + contract tests.
- Flat display: `TocIndexLogic.currentChapterFor(topVisibleOffset, toc)`
  (last chapter with startCharacterOffset ≤ top visible; tolerates disorder;
  volumes never "current chapter"; returns null → show 全文), and
  `displayIndexFor` for flat indexing. TOC opens auto-locating the current
  chapter once per open (jumpTo → ensureVisible 35%, bounded retries,
  no pull-back on user scroll, explicit 定位当前章节 button).
- Chapter-less files show 全文 (never a fake 第1章).

---

## 8. Theme contract (ReaderResolvedAppearance)

- Reader colors resolved from `Theme.of(context).colorScheme`:
  backgroundColor=surface, textColor=onSurface,
  secondaryTextColor=onSurfaceVariant, headingColor=onSurface,
  selectionColor=primaryContainer, baseTextStyle.
- No hardcoded Colors.black/white/fixed dark grays in the reader body.
- Display and measure use the SAME complete TextStyle; TextSpan carries the
  resolved color explicitly (no reliance on DefaultTextStyle).
- Color-only changes → markNeedsPaint; metric changes → markNeedsLayout.
- Theme switch: repaint only; never rebuilds block index, never writes
  progress, never changes ReaderLocator.
- Contrast: body/heading ≥ 4.5:1 (WCAG relative luminance utility).
- App: system mode with `AppTheme.light()` + `AppTheme.dark()`.

---

## 9. Cache contract

- **TXT index cache** (`<cache>/index.json` via atomic tmp→serialize→flush→
  verify→rename): hit validation = sourceSize + contentHash + encoding +
  parserVersion + normalizationVersion + indexFormatVersion (mtime NOT
  trusted). Corrupt cache → miss (reason=corrupt) → pipeline rescans.
  Cache stores structure/offsets only, NEVER body text.
- **Managed artifacts** (`<support>/library/local_txt/<hash>/`): source.txt
  / normalized.txt / index.json / manifest.json; import via two-phase commit
  (prepared → filesCommitted → databaseCommitted → completed); startup
  cleans stale `importing/` jobs; no half-finished artifacts shown.
- **Repair**: see §5. Repair never modifies external TXT; failure preserves
  valid source.txt and old files, shows clear error, allows retry or
  record deletion.

---

## 10. Platform

- **Windows**: Release build via `flutter build windows --release`
  (`build\windows\x64\runner\Release\xaocen_reader.exe`). CMake note:
  `windows/CMakeLists.txt` installs unconditionally into the build dir
  (sqlite3_flutter_libs FetchContent re-runs `project()` and would reset
  CMAKE_INSTALL_PREFIX to Program Files otherwise). Mouse wheel / scrollbar
  / window resize supported by the virtualized list.
- **Android**: Debug build via `flutter build apk --debug`
  (`build\app\outputs\flutter-apk\app-debug.apk`). applicationId
  `com.xaocen.xaocen_reader`. `android/settings.gradle.kts` prefers google()
  and excludes androidx.test from download.flutter.io (dynamic-version
  metadata 404). sqlite3 native assets download via ghproxy mirror
  (`hooks.user_defines.sqlite3.url_pattern`).
- **ADB strategy**: wireless debugging (mDNS; USB blocked by Windows
  driver-signing). After ANY `flutter test`/integration run, the APK in
  build/ is a test-runner build — **always re-run `flutter build apk
  --debug` before manual install**.
- Large-file policy: ≤20MB normal; >20MB–50MB requires confirmation;
  >50MB unsupported in 0.1.x (thresholds centralized in
  `lib/domain/local_txt/large_file_policy.dart`).

---

## 11. Non-negotiable invariants

1. External TXT files are never modified.
2. source.txt preserves original bytes (BOM/CRLF intact).
3. The Reader reads normalized.txt only (never re-detects source.txt).
4. normalizedHash represents ONLY the on-disk normalized.txt UTF-8 bytes.
5. UTF-16 code-unit offset is the only reading-position source of truth.
6. page/block/scroll-pixel are never persisted positions.
7. Programmatic restore writes nothing until confirmed.
8. Hierarchy never decides content visibility.
9. Navigable content is always visible.
10. UI never accesses Drift directly (Repository/Controller only).
11. Reader engine does not depend on business pages.
12. Restricted reference-project code is never copied
    (binbyu/Reader custom license; legado GPL-3.0); behavior-only reuse.
13. The archived old XAOCEN Reader is never reintroduced.
14. M4 must not break the M3 vertical Reader (M3 is the freeze baseline).
15. AppSettings storage keys/values never cross the Repository boundary.
16. ReaderPreferences never contains readingMode or a reading position.


---

## 分页 Reader 架构（M4，0.1.0-dev.4+4）

### 分层（lib/reader/ + lib/domain/reader/）

```
ReaderPage（双模式容器）
 ├─ 纵向：ReaderController + SuperListView + RenderReaderTextBlock（M3 不变）
 └─ 分页：PagedReaderController + PagedReaderView(PageView)
           ├─ PagedLayoutEngine（PagedTextRange 行粒度排版，惰性/确定性）
           └─ PageWindow（prev2+current+next3 有限窗口，淘汰远离页）
模式切换：ReaderModeTransitionState（idle/v2p/p2v）+ freezeWrites + generation
```

### 位置真源合同（M4 §六，与 M3 一致）

- `ReaderLocator.absoluteCharacterOffset` = normalized.txt → Dart String 的 UTF-16 码元偏移；
- Page/pageIndex/PageView index/scroll pixels/chapterPage/blockIndex/百分比 **全部禁止**作为持久位置；
- reading_progress 结构不变（collectionId + offset + itemIdHint + locatorVersion + normalizationVersion）。

### 分页引擎合同

- 显示与分页测量共用同一 TextPainter 参数集（fontSize/height/letterSpacing/textDirection/
  width/height/padding/`TextScaler.noScaling`），页面绘制不得用第二套参数；
- `layoutForwardPage(start)` / `layoutPreviousPage(end)`：`prev.end == current.start` 构造对称，
  end 链严格连续（字符链不重不漏）；LF 归下一页（页尾无 trailing LF → 渲染不超约束）；
- `pageContaining(target)`：ReaderBlockIndex 锚定 + 有限 forward（禁止 0 逐页/比例估算）；
- 惰性：打开时只生成当前页 + 前后有限页（prefill prev2/next3），Page 数与全文总页数无关；
- 进程内缓存 key = document identity + normalizedHash + viewport w/h + metrics signature +
  textScale + padding + paginationPolicyVersion；尺寸/横竖屏/metrics 变化 invalidate；
  仅颜色变化不重分页（只 repaint）；
- 已知边界：backward 页首 ≤2 屏/100 页漂移（end 链连续；confirmed 零误差）→ KNOWN_ISSUES.md。

### 双模式切换合同

- v→p：switchAnchor = 纵向真实可见范围顶部 offset → pageContaining → 显示；
  **anchor 不得被 page.start 静默覆盖**（未翻页立即切回仍恢复 X）；
- p→v：confirmed locator → M3 精确恢复链 → 验证 locator ∈ 真实 ReaderVisibleRange；
- 切换期间 freezeWrites（旧组件零写入）；generation 拒绝过期异步结果；无固定延迟；
- 目录跳转：chapter/volume.startCharacterOffset → pageContaining → 标题可见 →
  confirmed = 精确 target（立即防抖保存）；用户主动翻页后才用 page.start 覆盖。
- p→v 状态顺序不可交换：capture paged confirmed X → freeze → generation → target active=vertical
  → 两阶段 restore X → real visible range contains X → finishRestore confirms X → idle → unfreeze last。
  程序化滚动通知在完成边界前被抑制，不得伪装成用户滚动写入 progress。
- ReaderPreferences 是全局外观；ReaderProgressState 以 collectionId 为主键按书保存
  absoluteCharacterOffset + readingMode。两套状态不得互相读取、覆盖或合并。


---

## 进度持久化合同（M4 P1，schema 3）

### ReaderProgressState
```
collectionId
absoluteCharacterOffset   ← 唯一位置真源（UTF-16 码元偏移）
readingMode               ← 阅读表现状态（vertical/paged），绝不替代 Locator
itemIdHint / updatedAt
```

### 只有 active 模式可提交
- dispose / lifecycle（inactive/paused/detached）按 `_mode` 路由：
  `paged → paged.flush()`；`vertical → _controller.flush()`；
  不再无条件纵向 flush（覆盖竞态已修）。
- 切换本身零写入（§二十一）；mode 的持久化由退出时 active flush 落盘。
- 重开：读 ReaderProgressState → 纵向恢复 → mode==paged 时自动切 paged（anchor 不变）。
- paged 模式下纵向跳转/对齐/finishRestore 全部跳过（防误设 failed）。

### schema 3 迁移
reading_progress 新增 readingMode TEXT DEFAULT 'vertical'；旧数据默认 vertical；
删除 collection 时进度级联删除（应用层显式删 + DB CASCADE 双保险）。

---

## ReaderPreferences 设置合同（M5.1a，schema 4）

### 强类型边界

`ReaderPreferences` 是全局阅读外观设置，首版字段：

| 字段 | 默认值 | 合法范围 | 变化类别 |
|---|---:|---:|---|
| fontSize | 17 | 12–32 | Metrics |
| lineHeight | 1.7 | 1.2–2.4 | Metrics |
| horizontalPadding | 16 | 0–64 | Metrics |
| verticalPadding | 8 | 0–48 | Metrics |
| themeMode | system | system/light/dark | Paint |

- 缺失、解析失败、NaN/Infinity、越界值按字段回退默认值；不得导致 Reader crash。
- `readingMode` 不属于 ReaderPreferences，仍按书保存在 ReaderProgressState。
- ReaderLocator 不变，absoluteCharacterOffset 仍是 normalized.txt UTF-16 唯一位置真源。
- 本阶段只定义 Metrics/Paint 分类，尚未把设置接入 Reader 或实现 relayout。
- M5.1b 已把 Metrics 接入 Reader；M5.1c 已把 themeMode 作为 paint-only 接入 App/Reader。

### Metrics 保位重排合同（M5.1b）

`ReaderMetricsSignature` 仅由字号、行高、水平/垂直边距组成。签名变化时必须按
freeze → capture active confirmed locator → apply → invalidate → restore → contains
校验 → confirm → unfreeze 执行。纵向复用 M3 字符级恢复；分页只重建 locator 附近的
有限 PageWindow。generation 拒绝旧代结果；模式切换、生命周期、route pop、resize 与
dispose 不得允许旧 Reader 写 progress。

### Theme paint-only 合同（M5.1c）

`readerPreferencesProvider` 监听 Repository 强类型流，App 根节点把 system/light/dark 映射
为 Material ThemeMode。Reader 仅从当前 ColorScheme 重新解析 ReaderResolvedAppearance。
theme-only 变化不得改变 ReaderMetricsSignature、ReaderBlockIndex、PageWindow、分页结果、
ReaderLocator 或 reading_progress；vertical/paged 只更新颜色绘制。

### 持久化边界

- schema 4 新增 `app_settings(key, value, updatedAt)`，schema 3→4 只增表不改旧数据；
- 字符串 key/value 只允许 `ReaderPreferencesRepository` 与数据库生成层解释；
- 上层只使用 `load()` / `watch()` / `update(ReaderPreferences)` /
  `resetToDefaults()` 强类型 API；
- update 以事务写入完整快照；reset 只删除 Reader 拥有的 keys，不影响其他 AppSettings。
## ReaderPreferences per-collection contract (M5.1e.1, schema 5)

- ReaderPreferences is reading appearance for one collection, not application-global
  state. ReaderProgressState remains a separate per-collection record for Locator and
  readingMode; neither model reads or overwrites the other.
- Persistence is `reader_preferences` keyed by collectionId. Only the typed repository
  accepts collectionId; UI and Reader never read storage keys or Drift rows directly.
- Reader startup must load saved preferences before its first effective body layout.
  A repository watch is installed for the same collection after the initial snapshot.
- Metrics: fontSize, letterSpacing, lineHeight, paragraphSpacing, firstLineIndent,
  paddingTop/Bottom/Left/Right. Paint: themeMode.
- Metrics changes retain the existing freeze/capture/relayout/exact restore/visible
  confirm/unfreeze state machine. Theme remains paint-only.
- Paragraph spacing and first-line indent are visual coordinates over unchanged
  normalized text. Every layout line retains its original UTF-16 start/end range.
- Schema 4 -> 5 is additive and seeds legacy global settings per existing collection.
## M5.1 sealed capability (COMPLETE)

M5.1 is the production Reader UI and per-book reading-preferences layer. Its stable
surface is V3 Reader chrome, vertical/paged engines, per-book ReaderLocator,
per-book readingMode, per-book ReaderPreferences, complete basic typography,
four-direction padding, system/light/dark, exact-locator relayout, persistence,
and Flat TOC. Schema remains 5. No M5.2 capability is included.

## Reader input and paged chapter policy (follow-up, 2026-08-09)

Physical input is intentionally separated from Reader actions:
`PhysicalInput -> InputBinding -> ReaderCommand -> Reader action`. The default
binding maps arrows, PageUp/PageDown, and paged Windows wheel events to
`previousPage`/`nextPage`. Android's host bridge reports only `volumeUp` or
`volumeDown` while paged Reader is active; Dart owns the command mapping. The
bridge is inactive for vertical Reader and all non-Reader screens.

Paged pagination uses `pagedPolicyVersion = 2`. Real TOC chapter start offsets
are boundary anchors: a chapter title starts a new page, while the previous page
may end early. Page ranges remain contiguous and preserve UTF-16 offsets. A
no-chapter document keeps continuous pagination, and vertical layout is unchanged.

## M5.2a history, bookmarks, and sessions (schema 6)

`reading_history` is an aggregate book record, not a second position source. It
stores nullable `collectionId`, title/author/hash snapshots, first/last read
timestamps, and last chapter/progress display snapshots. Duration and session
count are derived exclusively from `reading_sessions` using SUM and COUNT.

`reading_sessions` starts after the first real visible-range/page confirmation,
accumulates only while Reader is foreground-active, pauses on inactive/paused,
resumes on foreground, and ends on route pop/dispose. Idle timeout is not part of
the first contract.

`reader_bookmarks` stores only the normalized UTF-16 offset plus book/hash/note
snapshots. Orphan status is derived when read: collection missing, normalized
hash mismatch, or offset out of bounds. There is no persisted `isOrphan` column.

Collection deletion uses `ON DELETE SET NULL` for history and bookmarks, while
history deletion cascades its sessions. Home recent-reading is derived from
history rows whose collection still exists, ordered by `lastReadAt`, limited to
one or two items. `CurrentChapterResolver` recognizes chapter TOC entries only;
volumes and no-chapter TXT return null.

## M5.2d application surfaces and lifecycle wiring

`LibraryPage` presents a derived Recent Reading section and a Reading History
entry point. `ReadingHistoryPage` loads history rows through repositories,
derives duration/count from `reading_sessions`, resolves whether a collection is
still present, and never uses snapshots as a Locator. Existing collections open
through the normal `ReaderLaunchContext`; detached rows are display-only.

`ReaderPage` receives history/session repositories through its launch context.
After the first confirmed visible/page restore it creates one
`ReadingSessionLifecycle`; app inactive/paused calls `pause`, resume calls
`resume`, and route disposal calls `end`. Locator changes update only the
display snapshots (`lastChapterTitleSnapshot` / `lastProgressSnapshot`); the
canonical position remains `reading_progress`.

## M5.3e Reader input settings UI

`LibraryPage` exposes `我的 → 阅读设置 → 按键与操作`. The settings page selects
the current platform profile and renders only supported `PhysicalInputId` values
grouped by the six `ReaderCommand` semantics. It consumes the typed
`ReaderInputBindingsRepository`; storage keys and JSON remain private to that
repository.

Capture uses the existing `ReaderInputRouter`/`ReaderInputCapture` boundary. The
first supported keyboard, wheel, or Android volume input is consumed without
dispatching a Reader action. Conflicts are confirmed before replacing the one
map entry, clear writes explicit null, and reset deletes only the active
platform profile so defaults are reconstructed without affecting the other
platform. Settings, capture, and conflict dialogs do not touch Locator,
reading progress, ReaderPreferences, or ReadingSession.
### M5.3e.1 capture correction

Windows capture owns and requests a dedicated `FocusNode` after add/retry;
button focus cannot consume the keyboard event. The stable registry now covers
letters, digits, arrows, paging, Home/End, Space, and Enter. A capture is held
as a typed candidate (`idle → capturing → candidate → confirm → persist`);
repository writes occur only from explicit confirmation. Escape remains a
cancel-only control, and the registry is shared by vertical and paged Reader
keyboard routing.

### M5.3e.2 shortcut gesture contract

Windows bindings now use `ReaderInputGesture(primaryInput, modifiers)` rather
than a plain input ID. Ctrl/Alt/Shift are canonical ordered modifiers; the
primary remains a stable XAOCEN `PhysicalInputId`. Profile format 2 stores a
structured gesture list and migrates format-1 single-key maps to gestures with
no modifiers. The app_settings key remains platform scoped and Drift schema
remains 6. Reader routing consumes gestures; Android volume and mouse wheel are
plain gestures through the same contract.

### M5.3 final input contract closure

Android is intentionally narrower than Windows. Its settings page is
physical-input-centric and exposes only Volume Up and Volume Down with the
choices previous page, next page, or disabled. The Android profile repository
filters legacy chapter/control/TOC commands back to platform defaults while
preserving explicit null disables. Windows retains all six ReaderCommands,
keyboard modifiers, and wheel bindings. The profile format remains v2 and
Drift schema remains 6.

Android host interception is active only for paged Reader or capture. Vertical
Reader and non-Reader routes leave volume handling to Android. Capture consumes
volume input without dispatching a Reader command.

Chapter navigation has its own operation generation. It freezes active-mode
progress writes, restores the real chapter start from the confirmed Locator,
requires visible/page confirmation, and flushes only the current generation.
Mode/metrics/lifecycle/dispose transitions invalidate pending chapter operations.
No chapter index, page index, scroll pixel, percentage, or chapter ratio is
persisted.

## M5.3.1.1 bounded paged gesture window

`PageWindow` tail is not document EOF. `PagedReaderController` is the single
owner of page availability and settle operations for touch, keyboard, volume,
and future automatic navigation. `ensureNextPageAvailable` and
`ensurePreviousPageAvailable` maintain the bounded prev2/current/next3 window;
they append only while the tail/head still has document content and trim after
selection. `PagedReaderView` never calls the layout engine directly.

PageView gesture callbacks are validated against the active layout generation,
window generation, current bounds, and pending programmatic target. A real
pointer attempt at a non-EOF edge uses the same Controller page-turn fallback,
so a missing child cannot permanently disable forward/backward swipes. Open,
locator jumps, metrics relayout, resize/orientation rebuilds, and dispose all
invalidate the layout generation. Old callbacks cannot append to or overwrite a
new window.

The page window remains bounded at the normal six-page steady state. Page and
scroll indices remain transient; `ReaderLocator.absoluteCharacterOffset` is
still the only persisted position source. Chapter-first-page policy and
`previous.endOffset == next.startOffset` continuity are unchanged. Schema stays
6. Paged chapter page metrics and automatic reading remain deferred.

## M5.3.2 paged chapter page progress

`ChapterPageMetricsResolver` derives the current chapter's 1-based page number
and total page count from the confirmed UTF-16 `ReaderLocator`, the shared
`ChapterBoundaryResolver`, and the active `PagedLayoutEngine`. It paginates
only `[chapter.startOffset, chapter.endOffset)` and never mutates the bounded
`PageWindow`. A three-entry LRU cache is keyed by collection/hash, chapter
interval, and the existing `PagedLayoutSignature`; theme-only paint changes do
not invalidate it.

The computation is deferred after the first frame and yields every eight pages.
Reader and controller layout generations are checked before, during, and after
the calculation, so resize, metrics relayout, mode/book/chapter changes, or
dispose cannot publish stale `x / y` values. Chapter page metrics are transient
display state only: they are not in Drift, `reading_progress`, history
snapshots, or any restore anchor. No-chapter documents continue to show `全文`
and whole-book Locator progress without a chapter page count. Schema remains 6.

Progress labels are centralized in `ReaderProgressLabels` so Vertical, Paged,
and no-chapter chrome share the same UTF-8 UI text. The label correction does
not alter metrics, pagination, or position persistence.

## M5.4a — AutoRead domain contract

AutoRead is currently a domain-only capability. `AutoReadController` owns the
transient `idle/running/paused/stoppedAtEnd` state, typed pause reasons, domain
events, and an operation generation for invalidating future stale ticks. It
does not know about Reader controllers and does not affect `ReadingSession`:
foreground Reader activity remains the session timing source regardless of
AutoRead state.

`invalidate(reason)` can advance that generation without changing state, which
lets future drivers reject work from mode/lifecycle/route interruptions even
when AutoRead is already paused or idle.

`AutoReadPreferences` is app-global and contains only the canonical vertical
speed preset and paged interval (plus version/timestamp). Runtime vertical
velocity is derived from the preset. `AutoReadPreferencesRepository` is the
typed boundary around its private `app_settings` JSON key, with per-profile
fallback and version normalization. No running state, timer remainder,
page/scroll index, Locator, or chapter progress is persisted. Drift schema
remains 6.

## M5.4b — Vertical AutoRead

`VerticalAutoReadDriver` is the first Reader adapter for the M5.4 domain
contract. A Flutter `Ticker` advances the existing vertical `ScrollController`
at the selected runtime-derived velocity. It reports every guarded frame via
the existing visible-range/`ReaderController.reportUserScroll` path; no
scroll-pixel or second progress writer is introduced. A manual drag or wheel
notification pauses running AutoRead, while guarded ticker notifications do
not pause it. Pause/stop/EOF confirm and flush the final Locator.

The driver uses the AutoRead generation as its stale-tick token and invalidates
it for interruption, relayout, mode switch, lifecycle, and dispose. Real scroll
extent transitions to `stoppedAtEnd` without looping. No-chapter documents use
the same Locator path. ReadingSession remains governed solely by Reader
foreground lifecycle. Global AutoReadPreferences are loaded/watched through
the typed app-settings repository; schema remains 6. Paged AutoRead remains
deferred.

### M5.4b.1 — Vertical AutoRead UI

The Reader bottom chrome exposes a compact vertical AutoRead sheet backed only
by the existing `AutoReadController` and `VerticalAutoReadDriver`. It provides
start, pause/resume, stop, and the five vertical speed presets. State labels
are derived from the controller, and speed changes update the active driver
immediately and persist through `AutoReadPreferencesRepository`. Paged mode
does not start an automatic paging driver. No position, progress, session, or
schema contract changed.

### M5.4b.2 — Fine vertical speed

`AutoReadPreferences` now stores one canonical integer
`verticalVelocityPixelsPerSecond` in the typed app-settings repository. The
five presets remain UI mappings, while non-preset values are displayed as
custom speeds. Legacy version-1 `verticalSpeedPreset` JSON is migrated on
read; new JSON does not duplicate the preset field. The Reader applies slider
changes immediately and debounces persistence. Schema remains 6 and speed
changes do not affect ReaderLocator, layout, progress, or ReadingSession.

## M5.4c — Paged AutoRead

`PagedAutoReadDriver` is the timer-driven adapter for paged automatic reading.
It owns pacing, lifecycle interruption, and operation serialization. Each tick
calls only the existing `PagedReaderController.nextPage()`; it never touches
PageView/PageController indices or introduces a page-index position source.
Bounded PageWindow expansion, chapter-first-page policy, gesture-tail recovery,
pagination generation, and Locator confirmation remain controller-owned.

The driver uses the typed global paged interval (3/5/8/10/15 seconds, default
5). One-shot timers are scheduled only after navigation and visible/page
confirmation finish, so concurrent navigation cannot occur. Generation checks
reject stale work after preference, manual-navigation, mode/lifecycle, or
dispose interruptions. Manual input pauses without auto-resume; a real
`endReached` result becomes `stoppedAtEnd` without looping. No persistence or
schema change is introduced.

## M5.4d — AutoRead UI

Vertical and Paged AutoRead now share one Reader control sheet backed by the
existing AutoReadController and drivers. Vertical exposes the five presets and
the canonical 12–120 px/s slider; Paged exposes the canonical 3/5/8/10/15 second
intervals. Opening Aa/TOC/Bookmark/Search pauses without auto-resume, while
chrome visibility alone does not pause. Windows has the semantic
`toggleAutoRead` command with no default binding; Android Volume remains limited
to its existing page/disabled contract. `ReaderKeepAwake` is a best-effort
platform abstraction (Android host flag implemented, desktop/test no-op), and
schema remains 6.

## Windows shell window state

The Windows runner persists normal window bounds and maximized state in the
user registry under `HKCU\\Software\\XAOCEN\\xaocen_reader\\WindowState`.
Minimized state is never persisted. Startup restores validated normal bounds,
clamps them to the nearest visible monitor work area, then applies maximized
presentation if needed. The runner continues to use the OS per-monitor DPI
message path; no Drift table or Reader data model is involved. There is no
application-defined minimum window size: only the native Windows tracking
minimum and the existing 1280x720 first-run default apply.

## M5.4e — AutoRead final regression

The complete AutoRead regression passed: vertical Ticker behavior and custom
speed mapping, paged interval driving through the bounded controller, manual
pause/lifecycle/mode/dispose invalidation, real EOF/no-chapter handling, and
ReadingSession/Locator isolation. All four real TXT corpora report logical
error 0. Android targeted ADB was deferred because the currently listed device
was offline; the Android Debug APK build passed. M5.4 is COMPLETE and schema 6
is unchanged.
