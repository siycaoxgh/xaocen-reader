# M5.7s.9c-2 Reader Aa Theme Surface Follow-up

## Scope

This follow-up addresses the Reader `Aa` settings bottom sheet shown in the
manual screenshot. It does not change the App Shell theme selector, Reader
preferences schema, Reader layout metrics, pagination, or Locator behavior.

## Root cause

`ReaderSettingsSheet` already rebuilt its inner controls using the selected
`ReaderThemeMode`, but the `showModalBottomSheet` route still owned an opaque
surface from the surrounding App Shell theme. Consequently, switching to dark
could make the controls dark while the large sheet surface stayed light.

## Narrow fix

In `lib/reader/reader_chrome.dart`:

- make the modal route background transparent;
- give the sheet one explicit `Material` surface derived from the current
  Reader theme's `scaffoldBackgroundColor`;
- disable Material surface tint on that owner;
- keep the existing `ValueListenableBuilder`, `ReaderPreferences` commit path,
  and `ReaderThemeMode` persistence unchanged.

The App Shell theme button remains a separate persisted `AppThemeMode`; it is
not mixed with the per-book Reader theme selection.

## Verification

- ADB device: `emulator-5554` (API 35, online)
- Debug APK installed with `adb install -r`
- Reader Aa sheet was opened on the emulator and switched dark/light.
- Pixel sampling of the final screenshots shows the sheet surface changes from
  the light surface `(244,247,248)` to the dark surface `(15,26,30)` while
  foreground controls remain readable.
- Screenshots:
  - `test_output/m57s9c2_aa_light.png`
  - `test_output/m57s9c2_aa_dark.png`
- Added widget regression: `Reader Aa sheet surface follows the selected
  Reader theme`.

## Results

| Gate | Result |
|---|---|
| Reader Aa outer surface follows Light/Dark | PASS |
| Existing Reader theme persistence path | PASS |
| Locator/layout path changed | NO |
| `flutter analyze` | PASS |
| Full Flutter tests (600) | PASS |
| Android Debug build | PASS |
| Windows Release build | PASS |
| `git diff --check` | PASS (existing line-ending warnings only) |

## Artifacts

- Windows Release: `build/windows/x64/runner/Release/xaocen_reader.exe`
- Android Debug: `build/app/outputs/flutter-apk/app-debug.apk`
