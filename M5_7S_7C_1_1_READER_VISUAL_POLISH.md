# M5.7s.7c-1.1 Reader System Bar Visual Polish

## Scope

This slice changes only Android Reader presentation: the edge-to-edge surface,
the optional device-battery ReaderInfo item, and the physical visibility of
the two independent dividers. Locator, ReaderBody geometry contracts, system
bar/cutout switches, orientation restore, AutoRead, and the Windows/Engine
work remain unchanged.

## Implementation

- The production Reader `Scaffold` paints its background behind the system
  bars (`extendBody` and `extendBodyBehindAppBar`) while `ReaderInfoScaffold`
  continues to reserve dynamic status/navigation/cutout insets for content.
  Android status/navigation bars are transparent and icon brightness follows
  the effective Reader palette.
- Added `deviceBattery` to the existing ReaderInfo slot model. Android reads
  `BatteryManager` through the existing window channel (no dangerous
  permission); unsupported platforms provide no fabricated value. The
  displayed form is `85%`, or `85% ⚡` while charging. New preferences default
  to bottom-center; schema-15 users migrate with the item hidden so their
  existing layout is not changed unexpectedly.
- Divider geometry remains reserved regardless of visibility. Its logical
  extent is at least `1.0` (and never less than `1 / devicePixelRatio`) so the
  rasterized line is at least one physical pixel. The paint color is derived
  from the Reader foreground and strengthened against the actual background
  when needed; disabled dividers remain transparent without changing layout.

## Persistence

Drift schema 15 → 16 adds `show_battery_info` and `battery_info_slot` with a
formal migration. Existing chapter/progress/time/book slots are preserved.
All chapter/location/progress/session tables remain untouched.

## Verification

- `flutter analyze`: PASS
- Full Flutter test suite: PASS (549 tests)
- Divider geometry/color and battery text widget tests: PASS
- Schema migration tests, including 15 → 16 and older migrations: PASS
- Android Debug APK: PASS, installed with `adb -s ce8df63f install -r`
- Windows Release build: PASS
- `git diff --check`: PASS
- Android startup smoke after install: package launched; no matching
  `FATAL EXCEPTION`, `AndroidRuntime`, `FlutterError`, `PlatformException`,
  SQLite/Drift errors in the captured logcat window.

## Device / artifacts

- Android: 23013RK75C, Android 15/API 35, USB serial `ce8df63f`
- APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Windows EXE: `build/windows/x64/runner/Release/xaocen_reader.exe`

Actual edge-to-edge blending, divider visibility, and charging glyph were
automatically covered at the widget/native-contract level; final physical
screen appearance remains a manual device check.
