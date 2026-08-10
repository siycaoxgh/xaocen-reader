# M5.3.2 Result — Paged Chapter Page Progress

Date: 2026-08-10
Drift schema: **6**
Status: **IMPLEMENTED / VALIDATED**

## Delivered

- Added transient `ChapterPageMetrics` and `ChapterPageMetricsResolver`.
- Chapter ranges are obtained from the shared `ChapterBoundaryResolver`; only
  `kind == chapter` entries participate and volume entries remain ignored.
- The current chapter is paginated from `chapter.startOffset` to its next
  chapter start (or normalized document length for the final chapter). The
  calculation never expands `PageWindow` and never paginates the whole book.
- Current page is derived from the confirmed UTF-16 `ReaderLocator`; page
  number is 1-based and exact chapter starts resolve to page 1.
- Added a bounded three-entry LRU cache keyed by collection, normalized hash,
  chapter interval, and the existing `PagedLayoutSignature`. Cache counters are
  observable in tests; theme-only changes do not alter the signature.
- Pagination is deferred until after the first frame and yields every eight
  pages. A layout/request generation and controller layout generation guard
  discard stale metrics after relayout, resize, mode changes, jumps, or dispose.
- Paged Reader chrome now displays `本章 x / y 页` and `全书 z%`. No-chapter
  documents display `全文` and whole-book progress only.

## Contracts

`ReaderLocator.absoluteCharacterOffset` remains the only persisted position
truth. Chapter page numbers, page ranges, layout signatures, cache entries,
PageController indices, and PageWindow indices are transient only. No Drift
schema or persistence model changed.

## Validation

- Unit/widget tests cover chapter first/middle/final pages, cache hit/miss,
  stale generation, no-chapter behavior, and the paged chrome.
- The real-corpus integration test exercised all four TXT files under
  `C:\Users\TOM\Desktop\测试`, including chaptered files and the no-chapter
  large TXT. Chapter samples produced page counts from 10–16 pages and
  midpoint samples resolved to the expected page; no-chapter returned no
  chapter metrics. Observed cache misses were 31–72 ms; cache hits were below
  1 ms. No first-frame blocking or logical-location error was observed.
- `PageWindow` remained bounded (the metrics resolver does not mutate it).
- Android device validation is deferred for this coding pass.

- Full unit/contract/widget suite: **424/424 PASS**.
- Windows integration: **11 files / 14 scenarios PASS**.
- `flutter analyze`: PASS; `git diff --check`: PASS.
- Windows Release: PASS — `build\windows\x64\runner\Release\xaocen_reader.exe`.
- Android Debug: PASS — `build\app\outputs\flutter-apk\app-debug.apk`.

No Drift migration was required; schema remains **6**.
