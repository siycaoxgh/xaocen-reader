# M5.7s.5 Appearance + Windows Recovery Fix

## Scope

This pass keeps the Windows Engine/DComp spike paused and changes only the
Reader appearance presentation and Windows shell recovery boundary. Reader
location, pagination, AutoRead, sessions, and database schema are unchanged.

## Divider visibility

`ReaderInfoScaffold` still owns the fixed `TopInfo → TopDivider → ReaderBody →
BottomDivider → BottomInfo` geometry. Top and bottom divider booleans remain
independent and a disabled divider keeps its one-device-pixel slot. Enabled
dividers now blend the current Reader text/on-surface color over the actual
Reader background and strengthen the blend when luminance is too close to the
background. The final paint is therefore non-transparent and never identical
to the background, including custom palettes.

## Reader palette UI

Appearance now presents a unified `阅读配色方案` selector. Each bundled
`ReaderPalette` is represented by a paired light/dark swatch and one name;
the old independent text/background chip groups are inert. Custom text and
background values continue to use the existing HEX/RGB field and color picker
controls, are paint-only, and remain per-book.

The requested OS-level desktop eyedropper is not silently simulated. The
current Flutter runner has no screen-sampling/crosshair channel; implementing
it requires a Windows capture overlay and native pixel sampling. It remains a
follow-up platform capability item rather than a fake in-app picker.

## Windows tray and Boss Key recovery

The native tray menu now has separate **Show window**, **Hide window**, and
**Exit application** commands. Tray activation restores, raises, foregrounds,
and focuses the existing window; Explorer's `TaskbarCreated` path continues to
re-add the icon. A process-owned `RegisterHotKey` path is added for keyboard
Boss Keys, so the configured keyboard gesture toggles hide/show even after the
window is hidden. The app-local left+right mouse chord remains a 250 ms hide
gesture and does not install a global mouse hook. Recovery is always available
through the registered keyboard gesture or tray when enabled; shell visibility
settings still reject a configuration with no taskbar and no tray entry.

## Verification

- `flutter analyze`: PASS
- full Flutter test suite: PASS (540 tests)
- divider widget regression: PASS
- Windows Release: PASS
  `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android Debug build: regenerated after this change (device validation is
  deferred when USB device is unavailable)
- `git diff --check`: PASS (existing CRLF notices only)

Manual local validation remains required for the physical tray, Boss Key,
cross-window screen eyedropper, and desktop visual contrast. No Engine/DComp
work was resumed.
