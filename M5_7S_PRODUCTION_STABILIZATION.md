# M5.7s Production Stabilization

## Scope

This stage closes the production stabilization work that was present in the
working tree after the storage cleanup. It does not touch the paused Flutter
engine alpha-surface spike, ReaderLocator, pagination truth, or Drift schema.

Schema remains **12**. `ReaderLocator.absoluteCharacterOffset` remains the
only persisted reading-position truth.

## Implemented stabilization

- Paged Chrome toggling is stable while AutoRead is idle or paused. The 2.5 s
  auto-hide timer is only scheduled while AutoRead is running and is cancelled
  by manual navigation, panels, pause, and stop.
- Android volume handling now exposes independent up/down bridge state. Normal
  bindings work in paged mode and move one actual Reader Body viewport in
  vertical mode; the viewport is derived from the active scroll position and
  therefore includes the real top/bottom information-region insets rather than
  a fixed scroll distance. AutoRead runtime actions can select follow-normal,
  previous, next, toggle, system-volume, or disabled without moving that
  decision into Kotlin.
- Minimal Reader information is laid out as real top and bottom regions with
  optional one-physical-pixel boundary hairlines. The body is padded by the
  same region extents, so text is not covered by the information layer.
- Windows shell recovery paths retain taskbar/tray invariants, Boss Key safety,
  tray show/restore/focus, and the single-instance activation path.
- Windows and Android input profiles continue to resolve through the shared
  `PhysicalInput → ReaderInputProfile → ReaderInputRouter` chain.
- Reader progress labels use source-safe Unicode escapes; the existing font
  display-name fallback remains localized-name → English-name → file-name.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | PASS — no issues |
| Flutter unit/contract/widget tests | PASS — 510 tests |
| Targeted Reader info/AutoRead widget tests | PASS — 12 tests |
| Windows integration | PASS — 11 integration files, including all 4 real TXT corpora, 7.68 MB no-chapter TXT, paged/vertical mode restore, search, chapter metrics, and logical error = 0 |
| Windows Release | PASS — `build/windows/x64/runner/Release/xaocen_reader.exe` |
| Android Debug | PASS — `build/app/outputs/flutter-apk/app-debug.apk` (161,772,034 bytes) |
| `git diff --check` | PASS (only Git's LF/CRLF normalization warnings) |

The Windows integration suite is automated coverage. Physical tray/Boss Key,
mouse-drag, Android volume, cutout/inset, and visual typography checks remain
manual/device validation items and are not claimed as automated PASS here.

## Gate status

**TASK A — M5.7s Production Stabilization: PASS (automated).**

TASK B device acceptance is intentionally separate and must be completed before
the paused Vanilla Engine gate can resume. The Flutter Engine alpha patch has
not been applied.
