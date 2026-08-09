# ARCHITECTURE_CURRENT.md — XAOCEN Reader v4 当前架构与合同

> 只描述当前代码与合同（`feat/m4-horizontal-reader`，M5.1d 完成点）。
> 不记录历史故事（见 PROJECT_HISTORY.md）。
> 代码位置均以本仓库实际文件为准。

---

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
| data | `data/database/` (tables, app_database + generated), `data/repositories/` (local_library_repository, library_file_manager, managed_collection_health, collection_repair_service, reading_progress_repository, reader_preferences_repository, encoding_index_provider) |
| reader | `reader/` (normalized_document_loader, reader_controller, reader_page, reader_chrome, reader_text_block, reader_appearance) |
| app/design | `app/` (bootstrap, app, router, constants, library_page, providers, placeholder_page), `design/` (tokens, theme) |

Layering rules (enforced by structure, not by tooling):
- `domain` never imports Flutter.
- `reader/engine` components never depend on page Widgets.
- UI only reaches data through Repository / Controller (never Drift directly).
- `data` may depend on `domain`; `sources` may depend on `domain` but not pages.

### Reader shell contract (M5.1d)

- `ReaderPage` owns Reader engine lifecycle; `ReaderChrome` owns only transient
  top/bottom controls and typed entry callbacks.
- Chrome is layered over a full stable Reader viewport with `Stack`. Visibility
  changes must not alter metrics, invoke Locator restore, or write progress.
- The toolbar exposes Flat TOC, current per-book mode, Interface/Aa, and More.
  Aa/More are preview containers until M5.1e; TTS is not exposed as enabled.
- Below 720 logical pixels the toolbar follows available width; on wider Windows
  layouts it is centered and capped at 520 logical pixels.
- Colors reuse `ColorScheme`/`ReaderResolvedAppearance`; theme remains paint-only.

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

Drift tables (schemaVersion 4): `content_sources`, `content_collections`,
`content_items`, `content_documents`, `toc_entries`, `import_records`,
`reading_progress`, `app_settings`. Foreign keys ON; body text is NEVER stored in SQLite
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
