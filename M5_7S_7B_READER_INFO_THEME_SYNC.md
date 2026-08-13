# M5.7s.7b Reader Info / System Bar / Theme Live Sync

Date: 2026-08-13  
Base: `a3a2d282f75d9445f2887d4fe90f485051f35d17`  
Schema: **14** (migration from 13)

## Reader information and Android system status bar

Reader information is now independent from Android's OS status bar:

- `showTopInfoBar` controls the top Reader information region.
- `showBottomInfoBar` controls the bottom Reader information region.
- `showSystemStatusBar` controls only the Android OS status bar.

The four combinations are valid. Windows does not expose the Android-only
system-status-bar switch.

Production Reader layout is a real sibling layout:

```text
TopInfoRegion
TopDivider
ReaderBody
BottomDivider
BottomInfoRegion
```

The body receives the remaining viewport; information is not positioned over
the body. Turning an information region off releases its reserved height.
Turning a divider off only makes the hairline transparent and does not change
region geometry.

## Legacy migration

Schema 13 → 14 adds `show_system_status_bar` and maps the legacy enum without
discarding the old intent:

| Legacy `status_bar_mode` | `showSystemStatusBar` | Reader info |
| --- | ---: | --- |
| `system` | `true` | existing top/bottom settings |
| `readerInfo` | `false` | existing top/bottom settings |
| `hidden` | `false` | top and bottom disabled |

No Locator, progress, history, session, layout, or book data is changed.

## Theme live synchronization

`ReaderPage` publishes the current `ReaderPreferences` through a single
`ValueNotifier`. The open Reader settings sheet subscribes to that notifier
and wraps its content in the same effective Reader theme (`system`, `light`,
or `dark`) used by the Reader body. Palette/theme changes therefore rebuild
the body and the currently open Aa sheet in the same state update; no route
replacement or re-entry is required.

## Chrome visibility regression fixed

The earlier implementation replaced each reserved information region with a
different subtree when Chrome was toggled. That could cause the vertical
visible-range pipeline to re-confirm the first block even though no navigation
command was issued. Regions now keep a stable `SizedBox` and retained info
subtree (`Visibility` with maintained state/size/animation). Chrome show/hide
is paint-only and does not change the Reader body geometry or Locator.

Regression coverage seeds a non-zero Locator and asserts it remains unchanged
after show → hide → show. The same contract is exercised by the production
Android build; a USB device run remained on chapter 198 before and after three
center taps.

## Verification

- `flutter analyze`: **PASS**
- Full Flutter tests: **PASS (544 tests)**
- Targeted Reader info/theme/migration tests: **PASS**
- Android debug APK: **PASS**, ordinary application APK
- Windows Release: **PASS**
- `git diff --check`: pending final clean check before commit

USB device used for the final install: `ce8df63f` / `23013RK75C` / Android 15
/ arm64-v8a. Install used `adb -s ce8df63f install -r`; no uninstall or data
clear was performed. Startup logcat had no app fatal, Flutter, SQLite, or
migration errors. Existing recent-reading data was visible (chapter 198).

Manual physical confirmation of all four settings combinations and live theme
changes inside every possible nested dialog remains **MANUAL REQUIRED**; the
automated/widget contract and startup/device smoke are passing.

## Final artifacts

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/windows/x64/runner/Release/xaocen_reader.exe`
