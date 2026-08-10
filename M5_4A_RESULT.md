# M5.4a — AutoRead domain contract and preferences

## Scope

This slice establishes the automatic-reading domain contract only. It does
not drive a `ScrollController`, `PageController`, `PagedReaderController`,
Reader UI, keep-awake behavior, shortcuts, or any platform automation.

## Contract

- `AutoReadState` is `idle`, `running`, `paused`, or `stoppedAtEnd`.
- `start`, `pause`, `resume`, `stop`, and `stopAtEnd` are idempotent and keep
  no persisted run state.
- `AutoReadPauseReason` records why a running operation was paused, including
  manual navigation, settings, TOC, bookmark, search, lifecycle, mode switch,
  and relayout.
- Every effective state or preference change increments the controller
  generation. `invalidate(reason)` also invalidates a pending operation
  without changing state, which covers mode/lifecycle/route interruptions.
  Future drivers can capture a token and reject stale ticks.
- `AutoReadController` has no Reader/controller dependency and never controls
  `ReadingSession`.

## Preferences and persistence

`AutoReadPreferences` is an app-global typed model. The canonical values are a
vertical speed preset (`slow`, `slower`, `standard`, `faster`, `fast`) and a
paged interval of 3, 5, 8, 10, or 15 seconds. Defaults are `standard` and 5
seconds. Vertical velocity is derived at runtime as 18/28/40/56/76 px/s and
is not persisted separately.

`AutoReadPreferencesRepository` is the only layer that knows the private
`app_settings` key and JSON representation. Missing/corrupt data returns
defaults, unknown presets fall back to `standard`, invalid intervals fall back
to 5 seconds, and older versions are normalized to the current version.
Windows/Android input profiles, per-book ReaderPreferences, and reading
progress are isolated. Drift schema remains 6.

## Validation

- AutoRead state, idempotence, pause reasons, events, generation invalidation,
  and disposal: PASS (435 full Flutter tests overall).
- Defaults, valid updates, watch, reset, restart persistence, malformed JSON,
  invalid values, version migration, schema 6, and settings isolation: PASS.
- `flutter analyze`, full Flutter test suite, and `git diff --check`: PASS.

M5.4b (drivers/UI) is intentionally not started.
