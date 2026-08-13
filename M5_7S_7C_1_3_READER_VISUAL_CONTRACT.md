# M5.7s.7c-1.3 Reader Visual Contract Closure

## Scope

This change is limited to Android Reader visual continuity/dividers and the
per-book paragraph alignment preference. Battery, keep-awake, Windows shell,
eyedropper, and Engine/DComp were not changed.

## Status-bar / Reader surface contract

The audit found no second native `statusBarColor` writer after Reader mount:
`MainActivity.setSystemBars` keeps the bar transparent, while the previous
Reader tree painted the full-screen Reader background underneath it and put
the operation Chrome (`ColorScheme.surface`) below the inset. The apparent
second override was therefore a Flutter surface mismatch revealed after the
first frame, not a hidden Android color assignment. The Reader route now owns
the final `SystemUiOverlayStyle` while mounted and wraps its Scaffold in an
`AnnotatedRegion`. The status-bar underlay is a
separate edge-to-edge surface whose color is derived from the same source as
the visible top operation Chrome (`ColorScheme.surface`) or the hidden Reader
surface (`ReaderAppearance.backgroundColor`). This removes the initialization
flash/second-surface mismatch: transparent system bars reveal the intended
surface instead of an App Shell/default Scaffold color. Icon brightness is
derived from that actual top surface, including custom Reader palettes.

## Minimal-info dividers

Production geometry remains:

`TopInfo 鈫?TopDivider 鈫?ReaderBody 鈫?BottomDivider 鈫?BottomInfo`

Dividers are painted only when Chrome is hidden and the corresponding info
region is visible. They reserve geometry independently of visibility and use
at least one logical pixel (and therefore at least one physical pixel) with a
contrast-derived foreground at 42% alpha. Chrome-visible operation borders are
not treated as minimal-info dividers.

### Device visual gate

USB device `ce8df63f` was not present during this run (`adb devices -l`
returned no devices), so the required dark/light screencap gate could not be
executed. This result is **MANUAL REQUIRED**, not an automated visual pass.

`DIVIDER VISUAL = MANUAL REQUIRED`

`STATUS BAR VISUAL = MANUAL REQUIRED`

## Paragraph alignment

`ReaderTextAlignment.left` remains the default for existing and new books.
`ReaderTextAlignment.justify` is exposed in Aa 鈫?鎺掔増甯冨眬 and is consumed by
the shared `ReaderTextBlock`/`ReaderTypographyLayout` path used by both
vertical and paged modes. TextPainter performs paragraph justification; the
normalized UTF-16 source is never modified and the final paragraph line is
not stretched. Alignment participates in `ReaderMetricsSignature`, so changes
use the existing freeze 鈫?relayout/repaginate 鈫?exact Locator restore path.

The per-book value is persisted as `reader_preferences.text_alignment`.
Schema 16 鈫?17 adds the column with `left` as the migration default; no
position, progress, history, session, or ReaderLocator data is changed.

`JUSTIFY = PASS` (automated implementation/tests; visual typography still
benefits from the deferred device check).

## Verification

- `flutter analyze`: PASS
- targeted Reader/page/preferences/migration tests: PASS
- Windows Release: PASS
- Android Debug APK: PASS (built, but USB install/visual capture deferred)
- `git diff --check`: PASS
- full Flutter suite: one unrelated pre-existing/fixture-sensitive widget
  warning/failure remains in the current baseline run; targeted tests above
  pass and this change introduces no ReaderLocator failure.

Artifacts:

- Android APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Windows EXE: `build/windows/x64/runner/Release/xaocen_reader.exe`

