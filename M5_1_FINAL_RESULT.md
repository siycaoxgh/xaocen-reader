# M5.1 Final Result — Reader UI + per-book Reading Preferences

Date: 2026-08-09  
Branch: `feat/m4-horizontal-reader`  
Baseline: `a01e137515ca42aec8dc537a536154993e3253cb`  
Drift schema: 5  
Status: **COMPLETE**

## Final capability

M5.1 delivers the V3 Reader shell, vertical and paged reading, per-book
ReaderLocator, per-book readingMode, per-book ReaderPreferences, font size, letter
spacing, line height, paragraph spacing, first-line indent, independent top/bottom/
left/right padding, system/light/dark appearance, exact-locator metrics relayout,
persistent settings, and Flat TOC.

ReaderLocator remains the normalized.txt UTF-16 code-unit offset and the only
reading-position truth. ReaderProgressState and ReaderPreferences are separate
per-collection records and cannot overwrite each other.

## Automated final regression

- `flutter analyze`: PASS, 0 issues.
- Contracts + unit + widget: 355/355 PASS (18 + 273 + 64).
- Integration: 9/9 suites, 12/12 scenarios PASS on Windows.
- `git diff --check`: PASS.
- Covered per-book Locator/mode/preferences isolation, A/B reopen, non-zero mode
  switching, metrics changes, visual-only indent/paragraph spacing, asymmetric
  padding, paint-only theme, current-book-only reset, Flat TOC, Aa panel, resize,
  and latest-generation-wins.

## Real corpus

All four TXT files currently present in `C:\Users\TOM\Desktop\测试` passed.
Beginning, middle, and end anchors were checked for every file. The metrics pass
changed font size, letter spacing, line height, paragraph spacing, first-line
indent, and all four paddings. All 12 before/after anchors retained the exact
ReaderLocator: **logical error = 0**. Vertical, paged, TOC, restore, and large
no-chapter coverage also passed.

## Human validation

### Windows

User-performed human validation is PASS: multiple books retain independent
ReaderPreferences; all typography controls, four paddings, themes, vertical/paged,
and same-book exit/reopen restore behave correctly; no obvious issue was found.
The final Release was additionally launched successfully by Codex. Automated UI
coverage separately passed TOC, Aa panel, theme, mode, route reopen, and resize.
Codex did not claim its failed UI-control session as human validation.

### Android

The user's prior/initial human validation found no obvious issue. During this final
Final Android device validation completed on Xiaomi 23013RK75C (mondrian), Android
15 / API 35 over Wireless ADB: **PASS**. Portrait/landscape checks passed in both
vertical and paged modes; multi-book state isolation, ReaderPreferences reopen,
force-stop recovery, and logcat checks passed. No Reader, Drift, SQLite, Flutter,
or pagination crash was observed. Multi-book settings, non-zero restore, modes,
typography, theme, TOC/Aa, orientation, force-stop/reopen, and app restart all
passed the final-device checklist.

## Builds

- Windows Release: `build\windows\x64\runner\Release\xaocen_reader.exe`
- Android Debug: `build\app\outputs\flutter-apk\app-debug.apk`

The Android APK is rebuilt after every test/integration command and after the final
Windows Release build, ensuring a normal application entry rather than test runner.

M5.1 is sealed as COMPLETE. M5.2 has not started.
