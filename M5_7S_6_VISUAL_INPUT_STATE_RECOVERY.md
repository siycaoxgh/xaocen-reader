# M5.7s.6 Visual + Input State Recovery

## Automated changes and checks

- Search result highlights now use a 20% accent wash with the normal Reader
  foreground, instead of painting the accent foreground on an accent container.
  This keeps hits readable across light, dark, and custom Reader palettes.
- Divider paint derives from Reader foreground/on-surface and the actual Reader
  background. Low-luminance differences are strengthened; enabled dividers are
  non-transparent, non-background-identical hairlines without changing region
  geometry. Existing widget coverage verifies both independent sides and final
  color visibility.
- Platform diagnostics are user-facing Chinese labels and statuses. Raw
  fallback reason codes are translated (for example, “当前平台不支持” and
  “当前渲染器不支持”); `supportsDesktopReaderTransparency` is shown as
  “桌面阅读透明能力”.
- The unified ReaderInputRouter remains the only semantic dispatch boundary.
  The active Reader paths already ignore `KeyRepeatEvent`; the new regression
  coverage and existing gesture tests preserve one command per key-down.

## Android physical acceptance

USB device `ce8df63f` (`23013RK75C`, Android 15) was online. The latest APK was
rebuilt and installed with `adb -s ce8df63f install -r`, and the application
launched successfully. No fatal exception, FlutterError, PlatformException,
Drift, or SQLite error appeared in the smoke log.

The following require human interaction/visual confirmation and are not
represented as automated PASS: real TXT navigation, volume mappings, system
volume passthrough, divider visibility, SafeArea/orientation, color contrast,
font preview, and long-press behavior. Mark these **MANUAL PASS / DEFERRED**
until the device is exercised with the requested checklist.

## Build status

- `flutter analyze`: PASS
- targeted platform/search/divider tests: PASS
- full Flutter tests: PASS (540 tests)
- Windows Release: PASS
- Android Debug: PASS
- Engine/DComp: still paused

The full `integration_test` suite was attempted against the USB device but did
not complete within the unattended timeout. This is recorded as DEFERRED, not
as a product PASS. The requested visual, physical-volume, and long-press
checks remain manual device acceptance items.
