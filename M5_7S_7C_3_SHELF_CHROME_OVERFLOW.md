# M5.7s.7c-3 — Shelf Surface + Reader TopChrome Overflow

## Scope

本轮只处理 Android 书架主体背景与 Reader TopChrome overflow；ReaderLocator、ReaderBody 正式 geometry、Vertical/Paged 行为及系统栏语义未修改。

## Root causes

- **BOOKSHELF SURFACE**：嵌入 AppShell 的 `LibraryPage` 使用了 `Scaffold` 默认 `scaffoldBackgroundColor`，而 AppShell 主体使用 `ColorScheme.surface`。在深色主题下形成大面积第二种 surface。修复为显式消费当前 `Theme.of(context).colorScheme.surface`；书籍 Card/list item 仍保留独立视觉层次。
- **TOPCHROME OVERFLOW**：`ReaderChrome` 的 top surface/inner container 以固定 78px 高度承载 cutout clearance、标题、阅读模式、章节和进度多行内容。真实 center-cutout clearance 叠加后，RenderFlex 在 surface 下方溢出（人工报告为 36px）。修复使用真实 `topChromeTextClearanceForData`，将 clearance 纳入 bounded surface height，并把 inner chrome 从固定 height 改为约束高度；Vertical/Paged 继续共享同一 TopChrome。

## Tests

- 新增 cutout-aware TopChrome widget test：center cutout + paged metadata 无 Flutter exception/overflow，inner chrome 保持在 top surface bounds 内。
- 新增 bookshelf surface widget test：Scaffold 背景等于当前 App Shell color scheme surface。
- Targeted ReaderPage/ReaderChrome/Library tests：PASS。
- Full Flutter tests (`flutter test --reporter compact`)：PASS。
- `flutter analyze`：PASS。
- `git diff --check`：PASS。

## Emulator evidence

Device: `emulator-5554` (`xaocen_api35_x86_64`), 1080×2400, density 420, `sys.boot_completed=1`.

APK rebuilt and installed with `adb -s emulator-5554 install -r` (no uninstall/clear/wipe).

Saved screenshots:

- `test_output/m57s7c3/01_home_dark.png`
- `test_output/m57s7c3/02_bookshelf_dark.png`
- `test_output/m57s7c3/03_reader_vertical_chrome.png`
- `test_output/m57s7c3/04_reader_vertical_chrome.png`
- `test_output/m57s7c3/05_reader_paged_chrome.png`

The bookshelf screenshot's representative body pixel is `(22,38,43)` and matches the shell surface; the broad body no longer uses the scaffold light/default surface. No `OVERFLOW`, `RenderFlex`, or `FlutterError` was found in the post-install logcat sample. The current emulator session did not provide a reliable automated route to toggle both Reader modes and all cutout settings, so final visual mode-by-mode confirmation remains **MANUAL REQUIRED**.

## Acceptance

- **BOOKSHELF SURFACE**: PASS (code + widget test + emulator screenshot)
- **VERTICAL CHROME OVERFLOW**: PASS (targeted widget test, installed APK/logcat clean; manual screenshot required for all cutout variants)
- **PAGED CHROME OVERFLOW**: PASS (targeted cutout/paged widget test, installed APK/logcat clean; manual screenshot required for all cutout variants)
- **LOCATOR REGRESSION**: PASS (ReaderPage locator/geometry tests and full suite)

Build artifacts:

- Android APK: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
- Windows Release EXE: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
