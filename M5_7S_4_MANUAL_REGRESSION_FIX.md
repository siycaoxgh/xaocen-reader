# M5.7s.4 Manual Regression Fix

## Scope

M5.7 remains **REOPENED**. The Windows Flutter Engine / DirectComposition
spike remains paused and is not changed by this work.

## Fixes

- Reader information regions reserve stable top/body/bottom geometry while
  Chrome is shown or hidden. Visibility changes do not navigate, repaginate,
  or write a new Locator.
- Windows physical input registry now includes middle mouse and punctuation
  keys (with modifiers preserved in the canonical gesture).
- App-local Boss Key timing accepts left/right mouse presses within 250 ms;
  no global hook is used.
- First-line indentation accepts -2.0..4.0 character units in 0.5-unit
  steps. Negative values are hanging indents and remain metrics-only changes.
- Vertical mouse wheel is continuous scrolling, clamped to roughly three
  current line heights per notch. It is not mapped to PageUp/PageDown.
- Narrow Reader settings tabs support horizontal mouse drag and wheel input
  while retaining click selection.

## Verification

- `flutter analyze`: PASS
- Full Flutter test suite: PASS (531 tests)
- Targeted input, typography, info-region, vertical AutoRead and paged
  AutoRead tests: PASS
- Windows Release: PASS
- Android Debug: PASS
- `git diff --check`: PASS
- Targeted Windows integration: PASS (`accept_real_paged_test.dart`,
  `reader_mode_switch_test.dart`). A first all-directory invocation hit a
  stale `flutter_tester` debug-connection environment failure; retrying after
  terminating that stale process passed the key corpus/mode tests.
- Four real TXT corpus: targeted paged/mode coverage PASS; full corpus sweep
  remains a local acceptance item.

## Build artifacts

- Windows EXE: `build/windows/x64/runner/Release/xaocen_reader.exe`
- Android APK: `build/app/outputs/flutter-apk/app-debug.apk`

## Deferred manual validation

Local physical LMB+RMB Boss Key recognition, tray interaction, and visual
window/reader behavior still require local Windows validation. Android device
validation is not run in this pass.
