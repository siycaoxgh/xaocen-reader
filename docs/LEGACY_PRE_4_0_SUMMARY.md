# Pre-4.0 legacy summary

The former checkout `C:\Users\TOM\Desktop\xaocen-reader` is archived at
`archive\legacy_pre_4_0_20260816\xaocen-reader`. It is not a build root and
its package/artifact versions must not be used for releases.

## What the legacy checkout contains

The old line (0.12–0.14 development releases) established the first offline
TXT loop: local import, SQLite/Drift experiments, UTF-8/UTF-16 decoding,
chapter parsing, reading progress, themes, smooth AutoRead, and the first
Windows/Android platform experiments. It also contains old V3 migration notes,
early Reader/Book compatibility layers, and prototype platform code.

## What carried forward

- A normalized local TXT source and chapter/index pipeline.
- UTF-16 absolute Locator as the reading-position contract.
- Drift-backed Reader progress, preferences, bookmarks, and history.
- Vertical and paged Reader modes with migration tests.
- Platform capability boundaries for Windows and Android.

## What is obsolete

- All 0.x package/version numbers and release APK/EXE files.
- The legacy project root and its generated `build`, `.dart_tool`, `dist`,
  and Flutter ephemeral output.
- Old sidecar database/import strategies that are not part of the current data
  root migration contract.
- Old UI prototypes, pre-V3 model names, and historical screenshots.

## Current source of truth

Use only the active root:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

Use its current `README.md`, `docs/PRODUCT_BASELINE_FREEZE.md`,
`M5_7_PRODUCT_CONSOLIDATED_STATUS.md`, and
`docs/ARCHITECTURE_CURRENT.md` for current behavior. This summary prevents
the archived changelog from being mistaken for current product status.
