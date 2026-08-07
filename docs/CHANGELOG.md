# Changelog

All notable changes to XAOCEN Reader v4 are recorded here, per milestone.

Format follows [Keep a Changelog](https://keepachangelog.com/) adapted to the
current development stage. Version numbers are taken from `pubspec.yaml` at
each milestone (`git show <commit>:pubspec.yaml`).

Legend for validation columns:
- **Win** = Windows manual / integration verification
- **Droid** = Android real-device verification (Redmi K60, Android 15)

---

## Unreleased

### Planned
- M4 horizontal paged reader (not started; M3 is the current freeze point).
- Search, bookmarks, full reader settings, TTS, RSS, network sources,
  EPUB/PDF (all deferred, see KNOWN_ISSUES.md).

---

## 0.1.0-dev.3+3 — M3 / M3.1 / M3.2 / M3.3 / M3.4 (2026-08-07)

**Data generation:** `v4-local-1` (unchanged since M0).
**Breaking internal changes:** Drift schema 1 → 2 (added `reading_progress`);
parserVersion 1.0.0 → 2.0.0 (full-title contract).

### M3 — Vertical Reader + exact restore (feat/m3-vertical-reader)

#### Added
- Vertical scrolling Reader: `ReaderPage`, virtualized list via
  `super_sliver_list 0.4.1` (admission-verified in Spike 5).
- `ReaderLocator` (collectionId + absoluteCharacterOffset + optional
  itemIdHint); UTF-16 code-unit offset in normalized text is the **only**
  persisted position source of truth.
- `ReaderBlock` / `ReaderBlockIndex` (derived, 4096–8192 code units,
  deterministic, never persisted).
- `ReaderVisibleRange` measured from actually laid-out blocks (no ratio
  estimation).
- `reading_progress` table (schema 2) + `ReadingProgressRepository`.
- Restore state machine with zero DB writes until confirmed
  (`loadingDocument → … → completed/failed`).
- Save strategy: user drag/wheel/scrollbar (400ms debounce + scroll-end
  flush), lifecycle flush (pop/inactive/paused/detached), programmatic
  toc-jump saves after confirmation, programmatic restore writes nothing.
- Bookshelf entries open the real Reader (replaced M2 placeholder).
- `super_sliver_list 0.4.1` added (MIT).

#### Fixed
- `NormalizedDocumentLoader` now resolves M2 `storagePath` `library/` prefix
  duplication (latent M2 bug, first consumed in M3).
- Reader page could stay stuck in `jumpingToBlock` before list attach; fixed
  with post-frame retry; `open()` sets state to ready after locating block.
- Android build: dependencyResolutionManagement prefers google() and excludes
  androidx.test from download.flutter.io (dynamic `1.2+` version metadata 404).

#### Validation
- Unit + widget: **160** passed. Integration: 4 files passed (Windows).
- Windows Release + Android Debug APK build green; verify.ps1 all green.
- Android real device: 9/9 items verified (user manual + integration tests):
  install/upgrade, data retention, schema migration, open imported book,
  touch scroll, back/reopen, force-stop/reopen, chapter-400 jump,
  orientation, 0 crash. Commit `ab866d7` waits for pop animation on device.

### M3.1 — normalizedHash contract fix (P1, fix/m3-normalized-hash-contract)

#### Fixed
- **P1 data-consistency bug**: `content_documents.content_hash` stored
  `sourceHash` but the Reader validated `normalized.txt` bytes against it →
  `hash_mismatch` on every real large TXT (CRLF normalization changes bytes;
  small ASCII files passed by coincidence).
- `normalizedHash` contract now: **SHA-256 of the final on-disk normalized.txt
  (BOM-less UTF-8) bytes**. Same value in manifest / Drift / Loader / import /
  repair. Shared `NormalizedArtifact` type introduced.
- Correct write order (tmp → flush → close → hash from disk → re-decode
  length check → atomic rename → manifest → Drift transaction → final re-read
  verification).
- `ManagedCollectionHealthCheck` + `CollectionRepairService`: repair from
  managed source.txt without touching external TXT; preserves collectionId,
  offsets, reading_progress.
- `alreadyImported` now health-aware: healthy → alreadyImported; unhealthy
  but source valid → repairedExisting; source invalid → corruptedManagedCopy.
- Reader error page for hash_mismatch: "书籍文件需要修复" with
  [返回书架] [修复并重试].
- New read-only diagnostic tool `tool/inspect_managed_txt.dart`.

#### Validation
- Unit + widget: **185** passed (25 new). Integration: 5 files passed.
- Real library repaired on Windows: 3 large collections + 821 document rows
  updated; external TXT hashes unchanged; Reader opens all books.
- Android: device offline at the time; user later manually confirmed large
  TXT opens, continuous scrolling, hash error gone.

### M3.2 — Full TOC titles + exact chapter jump (fix/m3-toc-title-exact-jump)

#### Added
- Title contract: `displayTitle` (full title line, trimmed), `dedupeKey`
  (normalized, never shown in UI), `chapterNumber` (parsed separately).
- `TocEntry` extended; scanner keeps full titles (was `m.group(0)` only).
- Two-stage exact jump: block-level `jumpToItem` → post-frame
  `rectForCharacterOffset` character-level alignment (title aligned to
  topInset + 8–24px, viewport intersection verified, bounded retries ≤5,
  no fixed delays).
- Current-chapter highlight from real visible-range top offset.
- ParserVersion 1.0.0 → 2.0.0; repair reindexes stale collections
  (also fixed repair not writing index.json).

#### Fixed
- Regression: adjacent duplicate detection now also dedupes when chapter
  numbers match (body-reference lines with typos, e.g. 第468章 这特么 vs
  这特码) — real file stays at 473 chapters (was drifting to 486).
- Removed fixed 100ms `finishTocJump` timer.

#### Validation
- Unit + widget: **214** passed. Integration: 5 files passed.
- Real library: 4 collections repaired to parserVersion 2.0.0, full titles
  (第1章 百世书 / 第19章 剥皮 / 第473章 天上火的霸道！), all 9 spec offsets hit.
- Android: device offline; shared Dart code path; user manual checks passed
  earlier (M3.4 cycle).

### M3.3 — TOC open auto-locates current chapter + dark readability (P1)

#### Added
- `TocIndexLogic` (pure logic): `currentChapterFor` (last chapter with
  startCharacterOffset ≤ top visible), `parentVolumeIdsOf`, `visibleIndexFor`.
- `_TocSheet` becomes StatefulWidget: volume collapse (current chapter's
  parent volume forced open), auto-locate on open (once per open), two-phase
  positioning (estimated jumpTo → ensureVisible at 35% viewport), bounded
  retries (extent unstable ≤10, measured item extent ≤8), "定位当前章节" button
  after user scroll, no pull-back on user scroll.
- `ReaderResolvedAppearance` contract (bg=surface, text=onSurface, secondary
  =onSurfaceVariant, heading, selection, baseTextStyle) + WCAG contrast ≥4.5:1.
- `AppTheme.light()` + system mode.
- `RenderReaderTextBlock` style setter: metric changes → markNeedsLayout;
  color-only changes → repaint (same TextPainter for display & measure).

#### Fixed
- `_visibleRangeForScroll` upgraded from block-level approximation to
  **real character-level** top/bottom (characterOffsetAtLocalY), with safe
  fallback during layout.
- Theme switch re-paints only; never rebuilds block index, never writes
  progress, never changes ReaderLocator.

#### Validation
- Unit + widget: **250** passed (12 TOC scroll + 8 dark mode + 16 unit).
  Integration: 5 files passed.
- Real large TXT: chapters 1/19/112/258/400/473 auto-located (±1 chapter,
  12px safety inset is contract behavior).
- Android: device offline at the time; completed in M3.4 cycle.

### M3.4 — Flat TOC (fix/m3-flat-toc)

#### Changed
- **Volume collapse removed entirely** (user product decision): TOC always
  flat. Volume = Section Header (font weight + badge + spacing, no arrow,
  tap jumps to volume start); chapters always visible with highlight and
  light indent.
- `TocIndexLogic` simplified to flat semantics (`displayIndexFor`), removed
  `parentVolumeIdsOf` / `visibleEntries`.
- **Global product contract** (applies to all future content sources):
  *Content hierarchy is semantic, not interactive. Source order is
  authoritative; navigable entries remain visible.* (层级负责表达关系，顺序负责
  导航，折叠不参与内容可见性。) Codified in
  `docs/CONTENT_NAVIGATION_CONTRACT.md` + contract tests.

#### Fixed
- `_locateToCurrent` returned without retry when scroll not attached;
  `_userScrolled` flag had no setState (button never appeared).

#### Validation
- Unit + widget: **251** passed (+8 contract tests later = **259**).
  Integration: 5 files passed. verify.ps1 green.
- Windows real library: 4 collections (473章/294章 3卷/53章 1卷/无章节全文).
- **Android real device (Redmi K60 / Android 15): 13/13 items passed** —
  overlay install with data retention, open+restore (43章/548章), flat TOC
  without arrows, auto-locate + highlight (42章 @39%), chapter tap jump
  (548→530), volume tap jump, no pull-back, scroll save/restore, force-stop,
  process exit/reopen, orientation, 0 crash (same pid).

---

## 0.1.0-dev.2+2 — M2 Local library (feat/m2-local-library, 2026-08-06)

**Data generation:** `v4-local-1`. **Breaking internal changes:** Drift
schema 1 created (6 tables). No user data migration (fresh epoch).

#### Added
- TXT pick → size pre-check → copy original → M1 indexing → normalized text →
  Drift four-layer model → minimal bookshelf → restart persistence → delete.
- Managed layout `<support>/library/local_txt/<contentHash>/` with
  source.txt / normalized.txt / index.json / manifest.json.
- Atomic import (13 steps, two-phase commit
  prepared → filesCommitted → databaseCommitted → completed).
- Content SHA-256 stable identity; deterministic IDs
  (`local-txt-source:<hash>`, `local-txt:<hash>`, `:whole`, `:chapter:<off>`,
  `:document:<off>`); duplicate import → `alreadyImported`, never overwrites
  progress; same name + different content imports separately.
- Drift schema 1: content_sources / content_collections / content_items /
  content_documents / toc_entries / import_records (FKs, transactions,
  unique constraints, 6 indexes). Body text never stored in SQLite.
- `LocalLibraryRepository` (importTxt / listCollections / getCollection /
  getItems / getToc / removeCollection / findByContentHash).
- EncodingIndexProvider abstraction: FlutterAsset / File / Memory.
- Minimal UI: import button, bookshelf list, progress (10 phases) + cancel,
  large-file confirmation (>20MB), reject >50MB.
- file_picker, path_provider, flutter_riverpod, drift added.

#### Fixed
- Windows `Directory.uri.pathSegments` trailing empty segment broke delete
  safety check → filter non-empty segments.
- AGP 9.0.1 template + file_picker Kotlin conflict → AGP 8.7.3 + classic KGP.
- sqlite3 native-assets hook downloaded from github.com (blocked) → ghproxy
  mirror via `hooks.user_defines.sqlite3.url_pattern`.
- Integration fixtures embedded as byte constants (Android cwd is sandbox).

#### Validation
- Unit + widget: **109** passed. Integration: 2 files passed on Windows and
  **Android real device (9/9)**: install, AssetBundle (23940/209), dual
  encoding import, shelf display, restart persistence, delete cascade +
  external file preserved, alreadyImported, cancel leaves no half-finished
  artifacts, GB18030 4-byte char 𠀀.
- Real files: 473 chapters (all 9 offsets), 0 chapters not faked; external
  hashes unchanged.

---

## 0.1.0-dev.1+1 — M0 + M1 (2026-08-06)

**Data generation:** `v4-local-1` (new epoch; old XAOCEN data not compatible,
no migration entry).

### M0 — Engineering skeleton

#### Added
- Single Flutter project, single pubspec.yaml; git initialized.
- Minimal layout: lib/app, lib/design, docs, assets/encoding, test, tool.
- Placeholder page (explicitly not final UI); theme entry; empty router.
- `tool/verify.ps1` gate: pub get / format / analyze / test / build windows
  release / build apk debug / git diff --check.
- Dependencies: flutter_riverpod, drift, sqlite3_flutter_libs, path.
- Version 0.1.0-dev.1+1; dataEpoch v4-local-1.

#### Fixed
- Windows Release build failed twice: sqlite3_flutter_libs FetchContent
  reinitialized `project()` during configure and reset
  `CMAKE_INSTALL_PREFIX` to `C:/Program Files/xaocen_reader` (admin needed);
  fixed by unconditionally pointing install prefix at the build dir.
- verify.ps1 initial UTF-8 Chinese comments broke PowerShell 5.1 parsing →
  ASCII-only comments; flutter.bat full path.

#### Validation
- 6/6 skeleton tests; Windows Release + APK Debug build; exe smoke 6s.

### M1 — TXT normalization + indexing pipeline (feat/m1-local-txt-pipeline)

#### Added
- Pure-Dart **GB18030 decoder** (WHATWG index + 209 anchors; 64MB/s;
  replace/strict modes; cross-platform identical; 0x80 → U+FFFD).
- `assets/encoding/gb18030_index.bin` (97,446 B) + meta.json + deterministic
  generator (`tool/generate_gb18030_index.dart`); lazy load, process cache.
- Encoding detection: BOM → strict UTF-8 → GB18030 candidate → unknown
  (never by extension).
- Normalization: only remove BOM + CRLF/CR → LF; O(n); lineStarts output.
- O(n) chapter/volume scanner in background Isolate: full TOC, atomic index
  cache (size/hash/encoding/parser/normalization/indexFormat versions; no
  mtime dependency), dedupe (adjacent only, keep line-start, no global
  dedupe), volume—chapter two-level, volumes not counted in chapter count.
- 12-phase progress model with cancel; no half-finished cache.
- Large-file tiers: ≤20MB normal, >20MB–50MB confirm, >50MB unsupported
  (thresholds centralized).
- `tool/inspect_txt.dart` read-only diagnostics.

#### Validation
- Unit + contract: **82** passed.
- Real files: `苟在初圣魔门当人材(1-500章).txt` → UTF-8, **473 chapters**,
  all 9 spec offsets exact; first scan **251ms** (vs ~7s Spike O(n²), 28×
  faster), cache hit 63–127ms. `无章节数字测试.txt` → 0 chapters, no fake
  TOC, 368ms/127ms.
- Windows Release + APK Debug; verify.ps1 green.

---

## Pre-M0 — Research, audit & spikes (2026-08-06)

Not a release; recorded for completeness.

- Competitor research (Legado / Readest / Follow+RSSHub / ReadYou /
  Miniflux / FreshRSS / Koodo / Thorium / Tachiyomi).
- Reader-engine feasibility audit: binbyu/Reader (C++, custom restrictive
  license, no commercial use) + legado-with-MD3 (GPL-3.0). **Both source
  trees not copyable**; only behavior reference; algorithms rewritten in Dart.
- Decisions: keep **Flutter** (not Tauri); **UTF-16 code-unit offset** as the
  only persisted position source of truth; **TextPainter** for layout
  (validated); **self-built pure-Dart GB18030 decoder** (no viable pure-Dart
  Dart-3 GBK package exists on pub.dev).
- Spike 1: GB18030 decode — 6/6 + strict mode (64MB/s, 100% correct).
- Spike 2: chapter scan — 473 chapters, notice line excluded, far same-name
  kept; O(n²) → O(n) requirement identified.
- Spike 3: TextPainter pagination — 7/7 + 4/4; first screen 22–29ms;
  offsets stable across font/size/orientation changes.
- Android real-device spike (Redmi K60 / Android 15): **8/8 passed** —
  including 23940-entry table, 4-byte chars, offset stability across font
  size / orientation / re-layout (Android pages differ from Windows due to
  font metrics; offsets identical).
