# M5.2c Result — current-book search and exact result jumps

Date: 2026-08-09
Branch: `feat/m4-horizontal-reader`
Drift schema: **6**
Status: **COMPLETE**

## Search architecture

- Search reads only the current collection's loaded `normalized.txt` document;
  `source.txt` and the database are never searched.
- `ReaderSearchService` starts one worker isolate per active query. A new query
  kills the previous worker and increments a generation. Both the service and
  the stateful search sheet reject stale completions, so A → B → C cannot show
  A or B results after C is active.
- The sheet debounces input by 220ms and caps results at 100. Route disposal
  cancels the active worker. No search result is persisted and no schema change
  was required.

## Matching and result contract

- Matching is ordinary contiguous substring matching. Chinese, punctuation, and
  digits match literally. ASCII A–Z is folded to a–z; non-ASCII characters are
  not fuzzily normalized. There is no tokenization, fuzzy matching, or regex.
- Dart String indices are UTF-16 code-unit offsets. Each result contains
  `startOffset`, `endOffset`, safe context bounds, a snippet, and a chapter title
  derived through `CurrentChapterResolver`. Surrogate pairs are kept intact in
  result context.
- Result rows show sequence number, derived chapter, and highlighted context.
  Android uses a bottom sheet; Windows constrains the same panel to a desktop
  width.

## Navigation and validation

- Clicking a result restores `startOffset` through the existing Reader Locator
  contract. Vertical mode waits for visible-range confirmation; paged mode uses
  the containing page and existing chapter-first-page policy. Opening, typing,
  clearing, or closing search does not write `reading_progress`.
- Synthetic tests cover Chinese/English/digits, ASCII case behavior, repeated
  matches, no results, result limits, surrogate offsets, context boundaries,
  chapter derivation, cancellation/generation, A/B isolation, panel debounce,
  highlight, and result tap behavior.
- Real Windows integration searched all four current TXT files at beginning,
  middle, and end anchors; every hit matched the exact UTF-16 substring and
  context bounds. `logicalError = 0`.

## Validation and build artifacts

- `flutter analyze`: PASS, 0 issues.
- Full unit/contract/widget suite: **381/381 PASS**.
- Windows integration: **10 files / 13 scenarios PASS**.
- Windows Release: PASS.
- Android Debug: PASS; final normal-entry APK rebuilt after all tests.
- Android real-device validation: deferred to the later unified device pass.

Artifacts:

- `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- `build\\app\\outputs\\flutter-apk\\app-debug.apk`
