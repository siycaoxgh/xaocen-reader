# M5.7s.9c-3 Root Page Header Duplication Cleanup

## Root cause

`AppShellPage` rendered a shared `_ShellHeader` containing the selected root destination icon and title above the root body, while the same destination was already represented by the mobile `NavigationBar` or desktop sidebar. The result was a duplicate Home/Library/Profile identity layer.

## Narrow change

- Removed `_ShellHeader` only from the root `IndexedStack` shell.
- Kept mobile bottom NavigationBar and desktop sidebar as the single root destination indicator.
- Removed the redundant `我的` heading from the profile root body.
- Kept real root actions/content (continue reading, import, settings, history) intact.
- Kept secondary routes and their AppBars unchanged.
- Preserved SafeArea, route selection, selected-tab state, Reader, metadata, theme, and platform window logic.

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: 600 PASS
- `test/widget/app_shell_page_test.dart`: PASS
- `test/widget/reader_settings_responsive_test.dart`: PASS
- Android Debug: PASS
- Windows Release: PASS
- `git diff --check`: PASS (existing line-ending warnings only)

## Result

| Gate | Result |
|---|---|
| HOME ROOT HEADER | PASS |
| LIBRARY ROOT HEADER | PASS |
| PROFILE ROOT HEADER | PASS |
| SECONDARY PAGE HEADER | PASS |
| ROOT NAVIGATION REGRESSION | PASS |

Artifacts:

- Windows: `build/windows/x64/runner/Release/xaocen_reader.exe`
- Android: `build/app/outputs/flutter-apk/app-debug.apk`
