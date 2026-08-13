# M5.7s.7c-1.2 Android Visual Reality Gate

## Scope

This gate corrected the visual contract after device review. It does not
change battery, ReaderInfo slots, Chrome/Locator, system-bar semantics,
orientation, Windows, Engine/DComp, or keep-awake behavior.

## Corrected product contract

- The top operation Chrome and bottom operation Chrome are the same operation
  surface. The top surface must not be replaced by the Reader body palette.
- Reader dividers are not operation-Chrome borders. They belong only to the
  minimal ReaderInfo layout while Chrome is hidden:

  `TopInfo -> TopDivider -> ReaderBody -> BottomDivider -> BottomInfo`

  They are independent visibility switches, reserve geometry whether visible
  or hidden, and are not InfoItems or slots.

## Root cause found

The earlier change used `readerBackgroundColor` for the top operation Chrome,
while the bottom operation Chrome continued to use `colorScheme.surface`.
That made the top and bottom Chrome inconsistent and conflated two surfaces.
The top Chrome now uses the same `colorScheme.surface.withValues(alpha: .97)`
contract as the bottom Chrome.

The production `ReaderInfoScaffold` always reserves the two boundary slots so
Chrome show/hide cannot change the Reader body geometry. Its divider paint is
now gated by `showInfoContent`: when the operation Chrome is visible, the
reserved divider is transparent; when the Chrome is hidden and minimal info is
actually painted, the configured top/bottom divider is painted. This prevents
an operation-Chrome border from being mistaken for a minimal-info divider.

The Android window itself is full-screen/edge-to-edge (`fmt=TRANSLUCENT`,
`layoutInDisplayCutoutMode=always` in the device window dump), and system bar
colors remain transparent. The screenshot still shows the body Reader palette
separately from the operation Chrome by design; this is not an OS status-bar
transparency failure.

## Device evidence

Device: `23013RK75C`, Android 15/API 35, USB serial `ce8df63f`.

Final APK was rebuilt and installed non-destructively:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

No `uninstall`, `pm clear`, database deletion, or book deletion was used.

Captured artifacts are under:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\m5_7s_7c_1_2\`

- `reader_chrome.png`: operation Chrome visible; top and bottom are separate
  layers, with the top operation surface rendered using the same Chrome color
  contract as the bottom operation surface.
- `minimal_after_fix.png` / `final_reader.png`: Chrome hidden; minimal top and
  bottom information is laid out in the body, with the Reader body remaining
  at its own palette.
- `both_on_minimal.png`: Chrome-hidden device capture after the settings
  interaction; this capture did not provide a reliable pixel-isolated divider
  measurement, so it is not claimed as a visual PASS.

The device window dump reported the XAOCEN activity at full frame
`Rect(0,0-1440,3200)` with transparent format and cutout mode `always`.

## Verification

- `flutter analyze`: PASS
- targeted ReaderInfo/ReaderPage widget tests: PASS (31 tests)
- full Flutter tests: PASS (549 tests)
- `flutter build apk --debug`: PASS
- `adb -s ce8df63f install -r`: PASS
- `flutter build windows --release` smoke: PASS
- `git diff --check`: PASS

The existing widget tests continue to verify divider geometry, independent
switches, non-transparent computed paint color, and unchanged Reader body
geometry. The on-device screenshot review is intentionally not upgraded to a
visual PASS without a clean, pixel-isolated capture of both configured
minimal-layer dividers.

## Gate result

- Operation Chrome color contract: **AUTOMATED PASS**
- Divider layout/visibility gating: **AUTOMATED PASS**
- Device visual divider proof: **MANUAL REQUIRED**
- Local visual review of every status-bar/background combination:
  **MANUAL REQUIRED**

The remaining manual item is an acceptance limitation, not a claim that a
screenshot has proven a visual PASS. No Reader position contract or schema was
changed.
