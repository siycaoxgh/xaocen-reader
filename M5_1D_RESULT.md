# M5.1d Result — V3 daily Reader shell

Date: 2026-08-09  
Branch: `feat/m4-horizontal-reader`  
Baseline: `651c7e04a6812ca3ec607ff68082e4d46da5c2fa`  
Status: **COMPLETE**

## Delivered

- Replaced the successful Reader's engineering-style standard AppBar with a
  lightweight overlay top region and responsive bottom reading toolbar.
- Made text the stable full-viewport visual subject. A body tap toggles chrome;
  overlays do not resize or displace vertical or paged content.
- Added Flat TOC, clearly labelled current/toggle mode, Interface/Aa, and More.
  Aa and More are honest preview containers; no sliders or fake TTS were added.
- Mobile uses available width; Windows centers the same visual language in a
  bottom surface capped at 520 logical pixels.
- Existing ColorScheme and Reader appearance contracts provide system/light/dark.

## Contracts preserved

- `ReaderLocator.absoluteCharacterOffset` in normalized TXT UTF-16 code units is
  still the only reading-position source of truth.
- Per-collection `ReaderProgressState` and `readingMode` remain independent.
- Showing/hiding or opening chrome performs zero progress writes.
- No Reader engine, PageWindow, Drift schema 4, ReaderPreferences, TXT pipeline,
  Flat TOC model, or theme persistence contract changed.

## Validation

- `flutter analyze`: PASS (0 issues).
- Unit/widget: **352/352 PASS**.
- Windows integration: **9/9 files, 12/12 scenarios PASS**.
- Real corpus: all 4 TXT under `C:\Users\TOM\Desktop\测试`; 12 metrics anchors,
  logical error 0.
- Responsive widget sizes: 390×844 portrait, 844×390 landscape, 1200×800 desktop.
- Windows manual visual validation: NOT-RUN in this execution because the desktop
  automation runtime could not initialize. Automated Windows UI/integration and
  Release build gates passed; no manual result is inferred from those gates.
- Android real device: **NOT-RUN / deferred to M5.1 final validation**.

## Build artifacts

- Windows: `build\windows\x64\runner\Release\xaocen_reader.exe`
- Android: `build\app\outputs\flutter-apk\app-debug.apk`

The Android APK is rebuilt after every test/integration command so it is the
normal application entry artifact, not an integration-test runner.

## Deferred to M5.1e

Actual font-size, line-height, and body-margin controls. M5.1d stops here.
