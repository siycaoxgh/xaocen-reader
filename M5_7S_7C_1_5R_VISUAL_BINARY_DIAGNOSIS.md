# M5.7s.7c-1.5R — Visual Binary Diagnosis

Date: 2026-08-13

Baseline HEAD before commit: `5fe180b4f5915ac578096b8c6dc0af4046a450a3`

Device: `emulator-5554`, 1080 × 2400, Android API 35
Scope: Android status-bar/Chrome surface continuity and minimal-reader-info dividers only.

## Method

The existing emulator data was preserved. No `wipe-data`, `pm clear`, or uninstall was used. Every visual gate used a normal APK installed with `adb install -r` and an actual `adb screencap` PNG. Temporary diagnostic builds used compile-time-only extreme colors; all diagnostic branches and colors were removed before the final build.

Evidence is stored under `test_output/m5_7s_7c_1_5r/`:

- `before_top.png`
- `diagnostic_top.png`
- `after_top.png`
- `before_divider.png`
- `diagnostic_divider.png`
- `after_divider.png`

## TOP STRIP

### Before

In `before_top.png`, row-major pixel analysis found:

- `y=0..99`: `RGB(22,38,43)` — top operation surface.
- `y=100..135`: `RGB(22,50,60)` — unexpected 36-physical-pixel reader-background band.
- `y=136..337`: `RGB(22,38,43)` — top Chrome surface.

### Diagnostic ownership proof

The temporary build painted the status/root underlay red, Reader root green, Chrome content blue, and info regions magenta. `diagnostic_top.png` showed:

- `y=0..135`: red underlay.
- `y=136..337`: blue Chrome.

The former band therefore came from the transparent inset created by `ReaderChrome`'s top `SafeArea`, not from the Android status bar, PageView, or Reader body. A `SafeArea` offsets its child but does not paint the offset. The exact owner was:

`lib/reader/reader_chrome.dart` → `ReaderChrome.build` → top `Align` → `SafeArea` outside `readerTopChromeKey`.

### Fix and after result

The operation surface is now painted by a `ColoredBox` outside the top `SafeArea`. The status-bar inset and Chrome content therefore share exactly `colorScheme.surface`; insets move controls only and no longer introduce a third surface.

In `after_top.png`, `RGB(22,38,43)` is continuous through the former `y=100..135` interval. The only later full-width color change is the intentional Chrome/body border at `y=338..340` (`RGB(72,92,99)`).

**TOP SURFACE = PASS (screenshot/pixel gate)**

## DIVIDER

### Before

The settings automation and UI hierarchy confirmed TopInfo, BottomInfo, TopDivider, and BottomDivider were all enabled. In `before_divider.png`, however, every relevant row was dominated by the reader background `RGB(22,50,60)`; neither divider produced a full-width pixel.

### Diagnostic ownership proof

The temporary build forced both dividers to 4 logical px and opaque yellow. `diagnostic_divider.png` showed:

- TopDivider: `y=100..109`, 10 physical px, `ARGB(255,255,255,0)`.
- BottomDivider: `y=2227..2236`, 10 physical px, `ARGB(255,255,255,0)`.

This proves state, tree, clip, and layer paths were valid. The production root cause was layout: the paint-only `SizedBox` had height but no explicit width. As a loose non-flex child of `Column`, its `ColoredBox` could resolve to zero intrinsic width, so enabled/color-correct dividers still painted no visible pixels.

### Fix and after result

Both dividers now use `width: double.infinity` while preserving the existing fixed 1-logical-px geometry. The enable switches still select between the derived color and transparent; disabling a divider therefore does not change ReaderBody geometry.

In `after_divider.png`:

- TopDivider expected/actual: `y=100..101`, 2 physical px, `ARGB(255,110,126,132)`.
- BottomDivider expected/actual: `y=2235..2236`, 2 physical px, `ARGB(255,110,126,132)`.
- Reader background: `ARGB(255,22,50,60)`.

Both lines are full-width, opaque, and pixel-distinct from the reader background.

**DIVIDER = PASS (screenshot/pixel gate)**

## Protected contracts

- No ReaderLocator, navigation, ReaderInfo slot, battery, orientation, or system/navigation/cutout semantics were changed.
- Chrome and divider fixes are paint/layout-constraint changes only.
- Divider visibility remains geometry-neutral.
- No schema change.

## Cross-platform Reader color ownership

The Reader route installs one `_effectiveReaderTheme()` around the complete platform-neutral Reader subtree on both Android and Windows. The final ownership contract is:

- **ANDROID READER COLOR OWNER** = `ReaderPage` effective Reader theme + resolved per-book `ReaderResolvedAppearance`; Android owns only system-bar/inset behavior.
- **WINDOWS READER COLOR OWNER** = the same `ReaderPage` effective Reader theme + resolved per-book `ReaderResolvedAppearance`; Windows owns only native window/shell behavior.
- **TOPINFO COLOR OWNER** = `ReaderInfoScaffold.regionBackgroundColor`, supplied from the resolved Reader appearance when Chrome is hidden; text comes from `ReaderResolvedAppearance.textColor`.
- **BOTTOMINFO COLOR OWNER** = the same Reader Info contract as TopInfo.
- **CHROME COLOR OWNER** = the effective Reader theme `ColorScheme.surface` for both top and bottom operation Chrome.
- **READER BODY COLOR OWNER** = `ReaderResolvedAppearance.backgroundColor` and `.textColor`.

There is no Android/Windows color branch and no hard-coded white Info surface. New Android/Windows × Light/Dark widget cases assert that TopInfo and BottomInfo resolve to the provided Reader palette background instead of the App theme surface. Chrome tests assert that top and bottom Chrome share the same effective Reader surface.

The historical bottom `BorderSide` on TopChrome was removed entirely. It was not a user Reader divider and caused the line visible below Chrome. The only configurable separators now remain in the hidden-Chrome structure `TopInfo → TopDivider → ReaderBody → BottomDivider → BottomInfo`.

## Verification

- `flutter analyze`: PASS.
- Full Flutter tests: PASS, 557 tests (including the cross-platform supplement).
- Targeted Chrome/Divider widget tests: PASS, including SafeArea surface ownership and full-width divider geometry.
- Android Debug build: PASS.
- Normal APK `install -r`: PASS; emulator data preserved.
- Windows Release smoke build: PASS.
- Windows Light/Dark runtime visual capture: deferred because the remote native window was hidden by the current tray/single-instance state and the Windows Computer Use helper failed to initialize. Cross-platform color ownership is covered by Android pixel evidence plus Android/Windows × Light/Dark widget assertions; this is not represented as a Windows manual visual PASS.
- `git diff --check`: PASS (line-ending warnings only; no whitespace error).

## Final status

- **TOP SURFACE = PASS** — final Android emulator screenshot and row-level pixel analysis.
- **DIVIDER = PASS** — final Android emulator screenshot and exact pixel rows.
- **ANDROID READER COLOR OWNERSHIP = PASS** — runtime screenshot plus Light/Dark contract tests.
- **WINDOWS READER COLOR OWNERSHIP = AUTOMATED PASS / MANUAL VISUAL REQUIRED** — shared implementation and Windows Light/Dark contract tests pass; no local window screenshot was obtainable in the current remote/tray state.
