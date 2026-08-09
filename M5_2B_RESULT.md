# M5.2b Result — Reader progress and current-book bookmarks

Date: 2026-08-09
Branch: `feat/m4-horizontal-reader`
Drift schema: **6**
Status: **COMPLETE**

## Scope delivered

- Reader chrome now derives and displays the current chapter and whole-book
  percentage from the active confirmed `ReaderLocator` and normalized document
  length. Percentage is display-only and is never persisted.
- `CurrentChapterResolver` remains the only chapter-resolution path. It uses the
  last real `chapter` entry whose start is at or before the Locator; volume
  entries and no-chapter TXT resolve to `全文`/no chapter.
- Added a current-book bookmark entry to the Reader toolbar. The panel is a
  responsive bottom sheet on Android and a width-constrained sheet on Windows.
- Bookmarks are created from the active confirmed Locator and retain the
  normalized hash, title snapshot, optional note, and timestamps. Duplicate
  `(collectionId, absoluteCharacterOffset)` creation is idempotent.
- Bookmark rows show dynamically derived chapter and text context, note, and
  creation time. Orphan status is derived from collection/hash/offset state;
  orphan rows are visibly disabled for navigation but remain deletable.
- Vertical bookmark jumps use the existing exact visible-range restore state
  machine. Paged jumps use the existing `jumpToOffset`/PageWindow containment
  contract. Neither path substitutes a page index, scroll pixel, percentage, or
  chapter start for the bookmark offset.
- Opening/closing the panel, creating/deleting bookmarks, and showing progress
  do not write `reading_progress`, ReaderPreferences, history, or sessions.

## Validation

- `flutter analyze`: PASS, 0 issues.
- Full unit/contract/widget suite: **373/373 PASS**.
- Windows integration: **9 files / 12 scenarios PASS**, including all four
  real TXT files. `reader_metrics_real_corpus_test` reported
  `logicalError=0` for every before/middle/after anchor in:
  `因果快递-20260625.txt`, `无章节数字测试.txt`,
  `苟在初圣魔门当人材(1-500章).txt`, and `青山(501-809章).txt`.
- Bookmark-specific tests: duplicate/idempotent creation, A/B isolation,
  delete-without-progress-change, dynamic orphan status, progress/chapter UI,
  create/list/delete UI, and exact vertical jump all PASS. Existing paged
  controller tests continue to verify exact page containment.
- Windows Release: PASS.
- Android Debug: PASS; normal application entry APK rebuilt after tests.
- Android real-device validation: deferred to the M5.2/M5 unified device pass.

## Build artifacts

- Windows: `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android: `build\\app\\outputs\\flutter-apk\\app-debug.apk`

No Drift schema change was required in M5.2b; schema 6 and all M5.2a
foreign-key/migration contracts remain unchanged.
