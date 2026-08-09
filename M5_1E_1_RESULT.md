# M5.1e.1 Result — per-book ReaderPreferences and reopen-layout P1

Date: 2026-08-09  
Baseline: `e3dba3da623cbf32b706f496cde9987b49c0d5cc`  
Branch: `feat/m4-horizontal-reader`  
Drift schema: **5**  
Status: **COMPLETE**

## P1 root cause and fix

ReaderPage previously began its first Reader layout with
`ReaderPreferences.defaults` while the repository watch's first saved emission was
still pending. That produced a split state after reopen: the panel eventually showed
saved values, while the body had already laid out with defaults.

Reader startup now has a preferences initialization barrier:

1. load the current collection's saved ReaderPreferences;
2. establish its metrics signature and subscribe to that collection only;
3. start the Reader and allow the first effective body layout.

No default-layout frame is exposed for a book with saved preferences.

## Per-book architecture and migration

- `reader_preferences.collection_id` is the primary key and a cascading foreign
  key to `content_collections.id`.
- Typed repository API: `load(collectionId)`, `watch(collectionId)`,
  `update(collectionId, preferences)`, `resetToDefaults(collectionId)`.
- ReaderProgressState remains separate and owns only the per-book Locator,
  readingMode, and timestamp.
- Schema 4 -> 5 is additive. Existing global M5.1 values are copied once into each
  existing collection; new typography fields receive defaults. Library rows,
  reading_progress, managed TXT, readingMode, and UTF-16 Locator are untouched.
- Invalid, missing, non-finite, or out-of-range values fall back field-by-field.

## Parameters

| Setting | Range | Step | Default | Class |
|---|---:|---:|---:|---|
| fontSize | 12–32 | 1 | 17 | Metrics |
| letterSpacing | -0.5–1.0 | 0.05 | 0 | Metrics |
| lineHeight | 1.2–2.4 | 0.1 | 1.7 | Metrics |
| paragraphSpacing | 0–32 | 1 | 0 | Metrics |
| firstLineIndent | 0–4 em | 0.5 em | 0 | Metrics |
| paddingTop / paddingBottom | 0–48 | 2 | 8 | Metrics |
| paddingLeft / paddingRight | 0–64 | 2 | 16 | Metrics |
| themeMode | system/light/dark | discrete | system | Paint |

Numeric controls use slider draft state plus visible value and +/- fine adjustment.
Only committed snapshots are persisted; the latest generation wins.

## Validation

- `flutter analyze`: PASS, 0 issues.
- Contracts + unit + widget: 355/355 PASS.
- Windows integration: 9/9 suites, 12/12 scenarios PASS.
- All four current TXT files in `C:\Users\TOM\Desktop\测试`: PASS.
- Twelve beginning/middle/end paged anchors after letter spacing, line height,
  paragraph spacing, indent, and asymmetric four-padding changes: logical error 0.
- Android real device: NOT-RUN / deferred to M5.1 final validation.

Build and final commit identifiers are recorded after final packaging.
