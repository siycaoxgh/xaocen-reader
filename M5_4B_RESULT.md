# M5.4b — Vertical AutoRead

## Scope

Vertical AutoRead is implemented as a Ticker-driven adapter only. No Paged
timer, AutoRead controls UI, keep-awake integration, shortcut, TTS, EPUB, RSS,
or schema change is included.

## Architecture

`VerticalAutoReadDriver` owns the frame clock and calls `ScrollPosition.jumpTo`
with a delta derived from the active `VerticalSpeedPreset` (18/28/40/56/76
pixels per second). It never stores scroll pixels or creates a progress writer.
Each frame reports the current visible range through the existing
`ReaderController.reportUserScroll` path, so `ReaderLocator` remains the only
position truth and chapter/full-book progress continues to derive from it.

The driver distinguishes its guarded frame (`isApplyingAutoScroll`) from
notifications caused by a user drag or wheel. Manual vertical navigation
pauses AutoRead and does not resume automatically. Pause, stop, interruption,
and EOF perform a final visible-range confirmation/flush. Relayout, mode
switch, lifecycle interruption, and dispose stop the ticker and invalidate its
generation. A stale tick cannot append a new position or restart itself.

At the real scroll extent the driver confirms the final Locator and transitions
the domain controller to `stoppedAtEnd`; it does not loop. No-chapter documents
use the same scroll/Locator path and require no chapter metadata. ReadingSession
continues to use its existing foreground lifecycle and is not controlled by
AutoRead pause state.

Global AutoReadPreferences are loaded through the typed repository in
`ReaderLaunchContext`; repository watch updates the active speed without
restarting the Reader. The preference repository remains app-settings based and
Drift schema remains 6.

## Validation

- Vertical driver widget tests: smooth tick movement, guarded auto frames,
  pause/stop final confirmation, interruption generation invalidation, real EOF
  stop, and no looping: PASS.
- Full Flutter tests: 440/440 PASS.
- Windows integration: PASS, 11 files / 14 scenarios.
- Windows Release and Android Debug builds: PASS.
- The Paged AutoRead remains deferred.

## M5.4b.1 — Vertical AutoRead UI

The existing bottom Reader chrome now exposes an AutoRead action. Its compact
sheet offers start, pause/resume, stop, and the five persisted vertical speed
presets. Running and paused states are explicit, and changing a preset updates
the existing controller immediately while persisting through the typed
AutoReadPreferencesRepository when available.

The UI is vertical-only; Paged mode explains that automatic paging is not yet
available. No second scroll driver, progress writer, keep-awake behavior,
shortcut, or schema change was added. ReaderLocator and ReadingSession
contracts remain unchanged.

Widget coverage was added for the bottom action, state transitions, and live
speed selection.

## M5.4b.2 — Fine vertical speed

Vertical AutoRead keeps the five quick presets (18/28/40/56/76 px/s) and adds
a 12–120 px/s slider with 1 px/s steps. The persisted canonical value is now
`verticalVelocityPixelsPerSecond`; the UI derives a preset label only for exact
preset values and otherwise shows a custom value such as `自定义 · 47 px/s`.

Version 1 JSON containing `verticalSpeedPreset` is read and migrated to the
canonical velocity. New writes do not contain both fields. Slider changes are
applied immediately to the existing driver/controller, while repository writes
are debounced and flushed on disposal. No Locator, layout, progress, session,
or Drift schema behavior changed.

Validation for this slice: full Flutter tests **443/443 PASS**, Windows
integration **11 files / 14 scenarios PASS**, Windows Release and Android Debug
builds PASS, and `git diff --check` PASS.
