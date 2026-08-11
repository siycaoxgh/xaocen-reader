# M5.6e Result — Reader Font System

Status: complete.

## Font contract

- `ReaderPreferences.fontId` is per-book and nullable; null means the
  platform/system default. It is included in the existing metrics signature,
  so changing a font uses the established freeze → Locator capture →
  relayout/repaginate → exact restore → visible confirm flow.
- Imported TTF and OTF files are copied into the DataRoot-managed `fonts/`
  directory. The content SHA-256 is both the deduplication key and imported
  font id. No absolute path or font bytes are persisted in SQLite.
- Missing or checksum-invalid assets fall back to systemDefault. Deleting an
  asset clears every per-book reference before removing its managed file.
- TTC is explicitly deferred because this Flutter/Skia path does not expose a
  reliable multi-face selection contract yet.

## Platform capability and UI

- Windows enumerates installed font families through the native registry
  channel; Android reports public system font assets when the platform exposes
  them and otherwise safely offers systemDefault.
- `Aa → 排版布局 → Font` shows the current font, available system families,
  imported assets, import TTF/OTF, and remove/manage actions.
- Runtime imported fonts are loaded with `FontLoader` under a stable generated
  family name. System font ids are namespaced and contain no runtime objects.

## Migration and validation

- Drift schema 11 → 12 adds `reader_font_asset_rows` and nullable
  `reader_preferences.font_id`; a unique content-hash index is created. A
  real SQLite migration test verifies existing reading progress survives.
- Full Flutter unit/contract/widget suite: **506 PASS**.
- Font repository + schema migration tests: **5 PASS**; malformed/TTC input,
  SHA-256 deduplication, delete fallback, and per-book persistence covered.
- Windows Release: PASS —
  `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`.
- Android Debug: PASS —
  `build\\app\\outputs\\flutter-apk\\app-debug.apk`.
- Four real TXT corpus, vertical/paged/chapter-first/no-chapter logical
  location contracts: PASS / logical error 0 (existing integration suite).
- Android physical-device validation: deferred; no ADB run in this coding
  pass.

ReaderLocator, normalized TXT, PageWindow, chapter policy, AutoRead,
ReadingSession, and reading-progress position storage remain unchanged.

## M5.6e.1 Font UI and Windows shell closure

- Windows borderless mode was confirmed as already implemented in the native
  runner and existing Windows settings page (native drag/resize, maximize,
  monitor/DPI recovery). The settings page now also states the independent
  background/window opacity and text-opacity status explicitly.
- The earlier M5.6c.3 transparency spike remains deferred: the current Flutter
  Windows child surface is opaque, so a safe independent alpha path is not
  available. No whole-window alpha workaround was shipped.
- Platform and imported fonts now share `ReaderFontDescriptor` metadata. The
  Windows/Android channels provide display/family names, while imported SFNT
  name tables prefer Chinese localized family names and fall back to English
  metadata or the source name.
- Font browsing is candidate-only: preview sample → apply or cancel. Only
  Apply commits the per-book `fontId` and starts the existing metrics-safe
  relayout; browsing never changes Reader正文.
