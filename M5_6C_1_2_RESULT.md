# M5.6c.1.2 Result — unified AutoRead toggle and Android volume contract

Status: complete.

## Product contract

- `ReaderCommand.toggleAutoRead` is the shared semantic action for Windows and
  Android. It toggles `idle/stoppedAtEnd → running`, `paused → running`, and
  `running → paused`; no platform-specific AutoRead state machine was added.
- Starting or resuming shows Reader Chrome and schedules a 2.5-second hide.
  Pausing for manual navigation, explicit stop, and EOF show Chrome and cancel
  the hide timer. AutoRead continues while Chrome is hidden.
- The per-book `showAutoReadMinimalInfo` preference controls whether the fixed
  minimal information layer remains visible during the hidden running state.
  Existing chapter/time/progress slot settings remain authoritative.

## Android volume contract

- Android profiles now accept `previousPage`, `nextPage`, `toggleAutoRead`, or
  explicit `null` independently for Volume Up and Volume Down. Existing valid
  bindings are preserved; Windows profiles are isolated.
- The Flutter router remains the only place that maps a physical volume input
  to a ReaderCommand. The native bridge only reports volume input and receives
  a `volumeBindingActive` gate.
- Volume is intercepted only while the Reader route is active and a binding is
  actionable (paged page command, or toggleAutoRead). Vertical page bindings
  and disabled bindings are left to Android system volume behavior. Capture
  remains the temporary exception.

## Persistence

- Drift schema 10→11 adds `reader_preferences.show_auto_read_minimal_info`,
  defaulting to enabled for existing books. Locator, reading progress,
  readingMode, ReadingSession, PageWindow, and AutoRead preferences are not
  changed.

## Validation

- `flutter analyze`: PASS
- Full Flutter unit/contract/widget suite: 495 PASS
- Targeted Android binding, preference migration, and AutoRead Chrome widget
  tests: PASS
- `git diff --check`: PASS
- Windows Release: PASS — `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android Debug: PASS — `build\\app\\outputs\\flutter-apk\\app-debug.apk`
- Windows integration: 11 files / 14 scenarios PASS
- Real TXT integration corpus: PASS; existing four-file logical-error checks remain 0
- Android physical-device execution: not run in this coding pass.
