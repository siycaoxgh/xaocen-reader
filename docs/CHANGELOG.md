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

### M5.2c — current-book search and exact result jumps (2026-08-09)
- Added normalized.txt-only current-book substring search with a debounced
  worker isolate, cancellation, generation protection, and a 100-result cap.
- Search results use UTF-16 code-unit offsets, safe context bounds, dynamic
  `CurrentChapterResolver` chapter titles, and highlighted snippets.
- Added responsive Android/Windows search panels. Result taps restore the exact
  hit Locator in vertical or paged mode; panel/query operations do not write
  reading progress. Schema remains 6.
- Validation: 381/381 unit/contract/widget tests, 10/10 Windows integration
  files (13 scenarios), all four real TXT anchor searches logical error 0,
  Windows Release PASS, Android Debug PASS.

### M5.2b — Reader progress and current-book bookmarks (2026-08-09)
- Added derived Reader progress display: current chapter plus whole-book
  percentage from the confirmed UTF-16 Locator and normalized length.
- Added current-book bookmark create/list/delete/jump. Bookmark navigation uses
  exact Locator restore in vertical mode and page containment in paged mode.
- Bookmark chapter/context text is derived dynamically. Orphan rows are clearly
  non-navigable but remain deletable; duplicate collection+offset creation is
  idempotent.
- Panel operations do not write reading progress, ReaderPreferences, history, or
  sessions. Schema remains 6.
- Validation: 373/373 unit/contract/widget tests, 9/9 Windows integration files
  (12 scenarios), all 4 real TXT logical error 0, Windows Release PASS, Android
  Debug PASS.

### M5.2a — history, bookmarks, and session persistence (2026-08-09)
- Added schema 6 with `reader_bookmarks`, `reading_history`, and
  `reading_sessions`.
- Bookmark orphan state is derived from collection linkage, normalized hash, and
  UTF-16 offset bounds; no `isOrphan` column is persisted.
- ReadingSession is the sole source for aggregate reading duration and session
  count. History stores book/time/display snapshots only.
- Collection removal detaches history and bookmarks with `ON DELETE SET NULL`;
  deleting a history entry cascades its sessions.
- Added CurrentChapterResolver, which recognizes chapter entries only and
  returns null for volumes/no-chapter TXT.
- Validation: analyze clean, targeted M5.2a tests 7/7, real SQLite FK PRAGMA and
  schema 5→6 migration checks PASS.

### Reader input and chapter pagination policy (2026-08-09)
- Added the physical-input → `InputBinding` → `ReaderCommand` → Reader action
  boundary. Default commands are `previousPage` and `nextPage`; keyboard,
  Windows wheel, and Android volume inputs share the same Dart binding layer.
- Android host input only reports `volumeUp` / `volumeDown` while paged Reader is
  active; it does not decide the resulting Reader command.
- Paged mode now starts every real TOC chapter at a new page, while preserving
  UTF-16 offsets, contiguous `previous.end == next.start`, and continuous
  no-chapter pagination. `pagedPolicyVersion` is now 2.
- Validation so far: analyze, full unit/widget suite, targeted wheel tests,
  Windows real-corpus chapter checks for all 4 TXT, and Windows Release PASS.
  Android volume-key device validation is pending reconnection of the wireless
  ADB target.

### M5.1e — functional Reader settings panel (2026-08-09)
- Connected the V3 Interface/Aa entry to persisted font size, line height,
  horizontal/vertical body padding, system/light/dark theme, and per-book mode.
- Slider movement remains local draft state; only drag-end snapshots are applied.
  Persistence uses a single-flight latest-pending queue to avoid write storms.
- Metrics reuse the M5.1b freeze/capture/relayout/exact-confirm/unfreeze contract;
  theme remains paint-only and reading mode remains per collection.
- Added responsive mobile/desktop sheet, reset-to-defaults, and zero-progress-write
  coverage for panel open/close and theme changes.
- Validation: analyze clean; 356/356 unit/widget; 9/9 Windows integration files
  (12 scenarios); all 4 real TXT / 12 anchors logical error 0.
- Android device: NOT-RUN / deferred to M5.1 final validation.

### M5.1d — V3 daily Reader shell (2026-08-09)
- Replaced the engineering-style successful Reader `AppBar` with stable overlay
  chrome: a light top action region and a responsive bottom reading toolbar.
- Added Directory, current scroll/paged mode, Interface/Aa, and More entry points.
  Aa/More are honest preview containers; no M5.1e controls or fake TTS action.
- Reader content remains the full stable viewport beneath the overlays. Showing or
  hiding chrome does not relayout text, restore a Locator, or write progress.
- Kept the vertical/paged engines, Flat TOC, per-book mode/progress, schema 4,
  ReaderPreferences, and theme contracts unchanged.
- Validation: analyze clean; 352/352 unit/widget; 9/9 Windows integration files
  (12 scenarios); all 4 real TXT; Windows Release and Android Debug builds PASS.
- Android device validation: NOT-RUN / deferred to M5.1 final validation.

### P1 — paged → vertical exact Locator restore (2026-08-09)
- Fixed the latent M4 mode-state ordering bug that skipped vertical restore while paged was still active.
- Writes remain frozen until the real visible range contains the captured non-zero Locator and confirmation succeeds.
- Added non-zero bidirectional/rapid-generation regressions and repeated per-collection isolation checks.
- Replaced unreliable integration popup coordinate taps with the typed mode-selection callback.
- Validation: analyze clean; 349/349 unit/widget; 9/9 Windows integration files; all 4 real TXT;
  Windows Release and final normal-entry Android Debug builds PASS (device deferred).

### M5.1c — three-state theme + paint-only Reader updates (2026-08-09)
- Connected persisted ReaderThemeMode system/light/dark to MaterialApp in real time.
- Reader vertical/paged colors continue through ReaderResolvedAppearance/ColorScheme.
- Theme-only changes preserve ReaderLocator, ReaderBlockIndex, metrics signature,
  PageWindow and pagination, with zero reading_progress writes.
- Validation: analyze clean; 346 unit/widget PASS; 9/9 Windows integration PASS;
  Windows Release and final normal-entry Android Debug builds PASS.
- Android device validation: NOT-RUN / deferred to M5.1 final validation.

### M5.1b — metrics-preserving Reader relayout (2026-08-08)
- Connected persisted ReaderPreferences metrics to vertical and paged Reader layout.
- Added metrics signatures, operation generations, symmetric write freeze, exact
  ReaderLocator restore/containment confirmation, and finite PageWindow invalidation.
- Added 18→20→24→22 stale-generation coverage; no page index, pixels, percentage,
  or chapter-relative position is persisted.
- Validation: analyze clean; 342 unit/widget PASS; Windows real corpus PASS for all
  4 TXT / 12 anchors with logical error 0; Android debug APK build PASS.
- Android device corpus validation remains pending because no Android device was connected.

### M5.1a — ReaderPreferences contract + Drift persistence (2026-08-08)
- Added strong `ReaderPreferences` / `ReaderThemeMode` domain contracts with
  explicit defaults and valid ranges for font size, line height, horizontal
  padding, vertical padding, and system/light/dark theme mode.
- Added metrics-vs-paint change classification. M5.1a defines the contract only;
  Reader UI and live relayout are intentionally not connected yet.
- Added `ReaderPreferencesRepository` (`load`, `watch`, `update`,
  `resetToDefaults`). Storage key/value strings remain private to the
  repository/database layer.
- Drift schema 3 → 4 adds `app_settings`; migration is additive and preserves
  library rows, reading_progress, readingMode, ReaderLocator, and managed TXT.
- Invalid/missing/unparseable stored values fall back per field without crash.
- Fixed direct schema 1 → latest migration so current-table creation does not
  add `readingMode` twice during a multi-hop upgrade.
- Validation: 338 unit/widget tests PASS (11 new M5.1a tests), 8/8 existing
  integration files PASS on Windows when run separately; analyze clean.

### Planned
- Reader settings UI/live relayout, search, bookmarks, TTS, RSS, network sources,
  EPUB/PDF (all deferred, see KNOWN_ISSUES.md).

---

## 0.1.0-dev.4+4 — M4.2 (2026-08-08)

**Data generation:** `v4-local-1` (unchanged).
**Drift schema:** 3 (upgraded from 2; reading mode persisted without data loss).
**Breaking internal changes:** none.

### Added
- Horizontal paged reader UI (`PagedReaderView` + built-in `PageView`/`PageController`):
  lazy PageWindow (prev2 + current + next3), no full-document pre-pagination,
  no fake total page count.
- Dual-mode switch: vertical ↔ paged, with transition state machine
  (`ReaderModeTransitionState`), freeze/unfreeze progress writes, operation
  generation to reject stale async results; switchAnchor is the real visible
  top offset, never silently replaced by page.start; switching back without
  turning a page restores the exact anchor (0 UTF-16 error).
- Paged TOC jump: chapter.startCharacterOffset → pageContaining → title
  visible → confirmed = exact target; user page turns update confirmed to
  new page.start with 400ms debounce; resize/orientation re-pagination keeps
  ReaderLocator unchanged; theme color-only changes repaint without re-pagination.
- Windows keyboard paging (Left/Right/PageUp/PageDown); Android swipe paging.

### Fixed
- `PagedLayoutEngine` page boundary iteration: `getLineBoundary` zero-width at LF
  (skip LF when advancing), page end stays before LF (no trailing-LF extra empty
  row → render height never exceeds viewport constraints), backward candidate
  start rewinds to line start (lastIndexOf LF) for symmetry; `TextScaler.noScaling`
  on both measure and render paths.
- PagedReaderView window-trim race: single persistent PageController +
  `_followWindow` (jumpToPage when shown page != currentIndex); relayout happens
  silently inside LayoutBuilder (no setState-in-build); `_prefillWindow` fills
  prev2/next3 after open/jump/relayout so fling never hits a missing page.
- v→p→v zero-write contract: removed unconditional `paged.flush()` on
  switch-to-vertical (un-turned pages must not write progress).

### M4 P1 fix (2026-08-08): mode + locator persistence closed loop
- `ReaderProgressState` (collectionId + absoluteCharacterOffset + readingMode +
  itemIdHint + updatedAt); readingMode is display state, never a locator.
- Drift schema 2 → 3: `reading_progress.readingMode` TEXT DEFAULT 'vertical';
  old rows migrate to vertical; no data loss.
- Only the active reader mode may commit position: dispose/lifecycle flush
  routes to the active controller (paged.flush() vs vertical flush), never an
  unconditional vertical flush that would overwrite paged progress.
- Reopen restores mode + locator: `_start` reads ReaderProgressState, auto
  switches to paged after vertical restore when saved mode is paged (anchor
  unchanged); paged-mode guards skip vertical jump/align/finishRestore to
  avoid spurious state=failed.
- Also fixed: `removeCollection` explicitly deletes reading_progress; table
  now uses customConstraint for a real `REFERENCES ... ON DELETE CASCADE`
  (Drift `references()` was not emitting FK).
### Known boundary (see KNOWN_ISSUES.md)
- backward page-start drift ≤ 2 screens / 100 pages (end chain strictly
  continuous; confirmed locator zero-error).

### Validation
- 327 unit+widget tests PASS; 8 integration tests PASS (incl. real-file
  acceptance for 4 real TXT, paged flow, mode-switch); Android real-device
  (Redmi K60) reader_mode_switch 2/2 + paged_reader_flow 1/1 PASS; Windows
  Release build, APK debug build, git diff --check — VERIFY PASSED.
- Post-P1 user validation PASS on Windows and Android: all three mode/locator
  reopen scenarios, Windows full exit/reopen, Android force-stop/reopen, and
  schema 2→3 upgrade-install data retention. Existing bookshelf/managed TXT,
  all 4 current real TXT, Flat TOC, chapter jumps, and dark mode showed no
  obvious regression.
- **M4 status: COMPLETE.**
- Details: `M4_RESULT.md` (two-tier report: synthetic / real corpus).

---

## 0.1.0-dev.4+4 — M4.1 (2026-08-07)

**Data generation:** `v4-local-1` (unchanged).
**Drift schema:** 2 (unchanged — no new persisted fields this round).
**Breaking internal changes:** none (engine is a new derived layer).

### M4.1 — Horizontal paging core (feat/m4-horizontal-reader)

Scope: paging computation only (`document offset → PagedLayoutEngine →
PageRange`). No UI integration in this round.

#### Added
- `PagedTextRange` (PageRange): start/end UTF-16 code-unit offsets,
  [start, end) contract; derived structure — never written to Drift /
  manifest, never changes normalized.txt, never enters ReaderLocator.
- `PagedLayoutEngine`: lazy forward/backward pagination at rendering-line
  granularity (`getLineBoundary` line-end alignment → visually continuous
  pages, no half-line jumps); `pageContaining(offset)` anchored by
  ReaderBlockIndex (bounded iterations, never full-book pre-pagination,
  deterministic per (document, layout signature, target offset)).
- Backward pagination contract: `previous.end == current.start`
  (symmetry by construction; verified by a 100-page round-trip test).
- `PageWindow`: finite window (prev 2 + current + next 3), eviction of
  far pages; Page object count independent of total page count.
- `PagedLayoutSignature` cache key: size / text metrics / textScale /
  padding / policyVersion; color-only changes do NOT invalidate (no
  repagination on theme color switch).
- Surrogate-pair protection at every page boundary; empty / short / long
  paragraph / CRLF-normalized text / chapter-less TXT all supported at
  engine level.

#### Changed
- App version `0.1.0-dev.3+3` → `0.1.0-dev.4+4` (pubspec + constants).

#### Fixed
- (During M4.2 staging, engine-adjacent) PageView needs a pre-filled window
  to swipe: window prefill of adjacent pages added in the staged controller
  (kept in stash; reported for transparency).

#### Validation
- New unit tests: engine 20 + window 7 (all pass).
- Full `flutter test` regression: 313 pass; `flutter analyze` clean.
- NOT performed this round (scope): UI integration, real-file acceptance,
  Windows manual, Android device, verify.ps1 — deferred to M4.2.

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
# M5.1e.1 — per-book ReaderPreferences and reopen-layout P1 (2026-08-09)

- Changed ReaderPreferences from global app_settings state to per-collection typed
  persistence in schema 5.
- Added letter spacing, paragraph spacing, first-line indent, and independent top,
  bottom, left, and right body padding.
- Fixed reopen using defaults for the body's first layout despite saved panel values;
  saved per-book preferences now gate Reader startup.
- Preserved normalized TXT UTF-16 ReaderLocator as the only position truth;
  typography never mutates normalized text.
- 355 contracts/unit/widget and 9 integration suites (12 scenarios) pass; all four
  real TXT files pass typography relayout with logical error 0.
# M5.1 COMPLETE — final regression and seal (2026-08-09)

- Sealed M5.1 as “Reader UI + per-book Reading Preferences”.
- Final regression: analyze clean; 355 contracts/unit/widget and 9 integration
  suites (12 scenarios) pass.
- All four current real TXT files pass at beginning/middle/end anchors; metrics
  relayout logical error is 0 for all 12 anchors.
- Recorded Windows user human validation as PASS and Android user initial human
  validation separately from Codex's unavailable final device session.
- Rebuilt final Windows Release and normal-entry Android Debug APK.
