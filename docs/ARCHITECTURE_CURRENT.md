# ARCHITECTURE_CURRENT.md — XAOCEN Reader v4 当前架构与合同

> 只描述当前代码与合同（HEAD `f965448`，分支 `fix/m3-flat-toc`，M3 冻结点）。
> 不记录历史故事（见 PROJECT_HISTORY.md）；不包含尚未实现的 M4 内容。
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
        toc_entries / import_records / reading_progress)
        ▼
Reader  (NormalizedDocumentLoader → ReaderBlockIndex → virtualized vertical
         list → TextPainter layout → ReaderVisibleRange → ReadingProgress)
```

Key components by layer (all paths under `lib/`):

| Layer | Files |
|---|---|
| domain | `domain/local_txt/` (TextEncoding, TocEntry, TxtIndex, PipelineProgress, LargeFilePolicy), `domain/reader/` (ReaderLocator, ReaderBlock, ReaderVisibleRange), `domain/library/` (entities, import models, NormalizedArtifact, TocIndexLogic) |
| sources | `sources/local_txt/` (gb18030 decoder/index loader/data, encoding detector, normalizer, toc scanner, import service/request/result, index cache, content identity, cancellation) |
| data | `data/database/` (tables, app_database + generated), `data/repositories/` (local_library_repository, library_file_manager, managed_collection_health, collection_repair_service, reading_progress_repository, encoding_index_provider) |
| reader | `reader/` (normalized_document_loader, reader_controller, reader_page, reader_text_block, reader_appearance) |
| app/design | `app/` (bootstrap, app, router, constants, library_page, providers, placeholder_page), `design/` (tokens, theme) |

Layering rules (enforced by structure, not by tooling):
- `domain` never imports Flutter.
- `reader/engine` components never depend on page Widgets.
- UI only reaches data through Repository / Controller (never Drift directly).
- `data` may depend on `domain`; `sources` may depend on `domain` but not pages.

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

Drift tables (schemaVersion 2): `content_sources`, `content_collections`,
`content_items`, `content_documents`, `toc_entries`, `import_records`,
`reading_progress`. Foreign keys ON; body text is NEVER stored in SQLite
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
