# M5.7 Pre-Compositor Production Baseline Device Acceptance

Date: 2026-08-12

## Scope

The Windows Flutter alpha-engine spike is paused at the Vanilla Engine linker
gate (`LNK1285` generated PDB corruption). No alpha patch was applied, no PDBs
were cleaned, and no Reader/compositor integration was attempted.

Production repository used for this baseline:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

HEAD: `4e2b91dcd1d92174b3705ad8fa4a304b5f1f66da`
Branch: `feat/m4-horizontal-reader`
Drift schema: 12

## Automated pass

- `flutter analyze`: PASS (no issues)
- Full Flutter unit/contract/widget suite: PASS (510 tests; `All tests passed`)
- Windows integration suite: PASS (11 integration files)
- Real corpus integration: PASS for all four TXT files
- Logical error: PASS / 0 in typography relayout and mode/paged corpus checks
- Windows Release: PASS
  - `build/windows/x64/runner/Release/xaocen_reader.exe`
- Android Debug: PASS
  - `build/app/outputs/flutter-apk/app-debug.apk`
- `git diff --check`: PASS

The intended sibling path `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
is an Engine-report directory without `.git`; it was not initialized or used as
the production repository.

## USB device

- Serial: `ce8df63f`
- Manufacturer/model: Xiaomi 23013RK75C
- Android: 15 / API 35
- ABI: arm64-v8a
- Physical display: 1440x3200
- Density: 560 dpi
- Refresh setting: 60 Hz
- EGL/Vulkan properties: Adreno (`ro.hardware.egl=adreno`,
  `ro.hardware.vulkan=adreno`)

Final APK was installed with `adb -s ce8df63f install -r`; no uninstall, data
clear, database deletion, or book deletion was performed.

## Device automated/semi-automated smoke

- Package installed and resolved to normal launcher activity:
  `com.xaocen.xaocen_reader/.MainActivity`: PASS
- Launch / resumed activity: PASS
- Home, bookshelf, and Mine navigation: PASS
- Existing four-book library remained visible: PASS
- Reader opened an existing book: PASS
- Reader UI exposed vertical mode, chapter/book progress, TOC, bookmarks,
  Aa, search, and More entries in the accessibility dump: PASS / presence only
- Aa Reading Settings and Reading Behavior panels opened: PASS
- Force-stop + launcher reopen returned to the app/home without crash: PASS
- Logcat scan after smoke: no FlutterError, FATAL EXCEPTION, Drift/SQLite,
  Reader restore, or pagination error observed: PASS

## Manual/device checklist

The following require physical interaction or visual judgment and are not
claimed as automated PASS:

- Opening all four TXT files manually and reading long ranges: MANUAL CHECK
- Chapter TOC jumps and exact visual position: MANUAL CHECK
- Vertical/paged touch gestures and Android volume bindings: MANUAL CHECK
- Font/size/line/paragraph spacing visual change: MANUAL CHECK
- Locator restore visual confirmation: MANUAL CHECK
- Minimal information layer visual layout: MANUAL CHECK
- 12/24-hour clock visual rendering: MANUAL CHECK
- AutoRead start/pause/stop and Chrome auto-hide timing: MANUAL CHECK
- Portrait/landscape, cutout/SafeArea/gesture navigation visual behavior:
  MANUAL CHECK
- Background/foreground transition visual behavior: MANUAL CHECK
- Absence of mojibake in rendered UI: MANUAL CHECK (accessibility dump contains
  encoded text in this environment, so no visual claim is made)

## Classification

- **AUTOMATED PASS:** static analysis, full Flutter tests, Windows integration,
  four-corpus logical checks, Windows Release, Android Debug build/install,
  package/launcher, non-destructive launch/navigation/reopen smoke, and logcat
  crash scan.
- **DEVICE PASS:** USB connection, device identity/properties, APK install,
  launch, data retention, basic navigation/Reader opening, force-stop reopen.
- **MANUAL PASS:** none newly claimed in this unattended baseline.
- **DEFERRED:** physical key/gesture behavior, visual typography/colors, full
  four-book reading flow, orientation/SafeArea visual validation, AutoRead
  interaction, clock visual check, and Windows compositor transparency.
- **FAIL:** none in production Reader baseline.

## Conclusion

`M5.7 PRE-COMPOSITOR PRODUCTION BASELINE = PASS`

This PASS is limited to the production baseline. The Windows alpha compositor
spike remains paused and is not included in this acceptance.
