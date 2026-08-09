# M5.1e Result — functional Reader settings

Date: 2026-08-09  
Branch: `feat/m4-horizontal-reader`  
Baseline: `3030ee13f14c3b59a662fec96676db08dc0d751b`  
Drift schema: 4 (unchanged)  
Status: **COMPLETE**

## Delivered

- Android-style bottom settings sheet and a centered, maximum-560-logical-pixel
  Windows sheet using the same V3 language.
- Functional font size, line height, horizontal padding, vertical padding,
  system/light/dark theme, per-book scroll/paged mode, and reset defaults.
- Slider motion changes only local draft values. Drag end submits the exact final
  snapshot; a single-flight latest-pending queue bounds Drift work during bursts.
- Metrics immediately reuse M5.1b's exact Locator relayout state machine. Theme is
  paint-only. Mode continues through the M4 per-collection transition state machine.

## Preserved contracts

- ReaderLocator remains normalized TXT UTF-16 code-unit offset and the only
  persisted reading-position truth.
- ReaderPreferences remains global appearance only; readingMode remains in each
  collection's ReaderProgressState.
- Opening/closing the sheet and theme changes do not write reading_progress.
- Schema 4, TXT pipeline, Flat TOC, Reader engines, and PageWindow design unchanged.

## Validation

- `flutter analyze`: PASS, 0 issues.
- Unit/widget: **356/356 PASS**.
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
M5.1e stops here and does not enter M5.1f.
