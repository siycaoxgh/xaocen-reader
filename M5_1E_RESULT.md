# M5.1e Result — functional Reader settings

Date: 2026-08-09  
Branch: `feat/m4-horizontal-reader`  
Baseline: `3030ee13f14c3b59a662fec96676db08dc0d751b`  
Drift schema: 5
Status: **COMPLETE**

## Delivered

- Android-style bottom settings sheet and a centered, maximum-560-logical-pixel
  Windows sheet using the same V3 language.
- Functional per-book font size, letter spacing, line height, paragraph spacing,
  first-line indent, four independent paddings, system/light/dark theme,
  scroll/paged mode, and reset defaults.
- Slider motion changes only local draft values. Drag end submits the exact final
  snapshot; a single-flight latest-pending queue bounds Drift work during bursts.
- Metrics immediately reuse M5.1b's exact Locator relayout state machine. Theme is
  paint-only. Mode continues through the M4 per-collection transition state machine.

## Preserved contracts

- ReaderLocator remains normalized TXT UTF-16 code-unit offset and the only
  persisted reading-position truth.
- ReaderPreferences and ReaderProgressState are separate per-collection records.
  ReaderProgressState owns only Locator/mode; ReaderPreferences owns appearance.
- Opening/closing the sheet and theme changes do not write reading_progress.
- TXT pipeline, Flat TOC, Locator contract, and finite PageWindow design unchanged.

## M5.1e.1 P1 correction

- Root cause: ReaderPage started document/Reader layout with defaults before the
  asynchronous preferences watch emitted its saved snapshot. The panel later
  displayed saved values, but the first effective body layout had already used
  defaults.
- Fix: load `ReaderPreferencesRepository.load(collectionId)` before starting the
  Reader, establish the metrics signature and per-book watch, and expose no body
  layout until that initialization barrier completes.
- Schema 4 -> 5 adds `reader_preferences`, keyed by collectionId with cascade
  deletion. Existing books, managed TXT, reading_progress, readingMode, and
  ReaderLocator are preserved. Legacy global values seed every existing book once;
  books are independent after migration.
- Paragraph spacing and first-line indent are visual layout metrics over the
  original normalized string. They never insert whitespace/newlines and never
  alter UTF-16 offsets.

## Validation

- `flutter analyze`: PASS, 0 issues.
- Contracts + unit + widget: **355/355 PASS** (273 unit, 18 contract, 64 widget).
- Windows integration: **9/9 files, 12/12 scenarios PASS**.
- Real corpus: all 4 TXT in `C:\Users\TOM\Desktop\测试`; 12 paged anchors across
  beginning/middle/end, including the 7.68 MB no-TOC file; logical error 0.
- Paged settings widget: non-zero Locator 12 remained contained after repagination.
- Windows manual visual validation: NOT-RUN; Windows automated real-file and UI
  validation plus Release build are reported separately and not called manual.
- Android real device: **NOT-RUN / deferred to M5.1 final validation**.

## Build artifacts

- Windows: `build\windows\x64\runner\Release\xaocen_reader.exe`
- Android: `build\app\outputs\flutter-apk\app-debug.apk`

The Android APK is rebuilt after all tests as the normal application entry.
M5.1e.1 stops here and does not enter M5.1f.

## Final seal

M5.1f completed the full regression, user validation record, and final packaging.
M5.1 is now **COMPLETE**; see `M5_1_FINAL_RESULT.md`.
