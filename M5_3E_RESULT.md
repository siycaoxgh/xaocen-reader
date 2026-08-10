# M5.3e Result — Reader input settings UI

Date: 2026-08-10
Branch: `feat/m4-horizontal-reader`
Drift schema: **6**
Status: **COMPLETE**

## M5.3e.2 correction

- Fixed the Reading History presentation bug that rendered Dart objects as
  `Instance of ...`. Detail rows now interpolate complete expressions, display
  the real session count, and omit null/blank chapter and progress snapshots.
- Upgraded Windows bindings from a plain physical-input ID to the strong
  `ReaderInputGesture(primaryInput, modifiers)` contract. Supported modifiers
  are Ctrl, Alt, and Shift; supported primary keys are A-Z, 0-9, four arrows,
  Page Up/Down, Home/End, Space, and Enter. Escape remains capture cancel;
  modifier-only and repeated/key-up events do not create a candidate.
- Profile format version is now 2. Gestures persist as canonical structured
  JSON (`primary`, ordered `modifiers`, nullable `command`). Existing version-1
  single-key maps migrate losslessly to modifier-free gestures. Drift schema
  remains 6 and Windows/Android profiles remain isolated.
- Capture now has an explicit focus-bordered input region and the state flow
  `idle -> capturing -> candidateCaptured -> confirm -> persisted`. A candidate
  never writes storage. Retry/cancel/page close preserve the old profile;
  conflicts show both commands and replace only after confirmation; success
  displays `✓ 已保存` and the command list immediately reflects the gesture.
- The capture `Focus` now owns the complete page stack, including the overlay,
  and is explicitly requested on capture start/retry. This prevents overlay
  controls from removing keyboard events from the capture path. Wheel and
  Android volume inputs continue through the same router without modifiers.

### M5.3e.2 validation

- `flutter analyze`: PASS, 0 issues.
- Full unit/contract/widget suite: **408/408 PASS**.
- Windows integration: **10 files / 13 scenarios PASS**, run individually to
  avoid the documented Windows debug-connection race.
- All four real TXT metrics corpus checks: PASS, `logical error = 0`.
- Windows Release: PASS — `build\windows\x64\runner\Release\xaocen_reader.exe`.
- Android Debug: PASS — `build\app\outputs\flutter-apk\app-debug.apk`.
- `git diff --check`: PASS.
- Android ADB: **NOT-RUN**, as required for this correction.

## M5.3e.1 correction

- Root cause of Windows keyboard capture failure: the settings page's `Focus`
  was autofocus-only. Tapping the add button left focus on the button, while
  the capture overlay did not request the keyboard focus node. `KeyDownEvent`
  therefore never reached the capture router. The page now owns a named
  `FocusNode` and requests it on capture start and retry.
- Added a stable Windows single-key registry: A–Z, 0–9, Arrow Up/Down/Left/Right,
  PageUp/PageDown, Home, End, Space, and Enter. Persistence uses only stable
  IDs such as `keyboard.keyA`, `keyboard.digit1`, `keyboard.space`; Flutter
  runtime key objects are never stored. Escape remains reserved for cancel.
- Capture now follows `idle → capturing → candidate → confirm → persist`.
  Candidates show the detected input; retry and cancel discard them, and only
  confirmation writes the repository. Conflicts show current and target
  commands and require explicit confirmation. Success emits visible feedback.
- The registry is used by vertical and paged Reader keyboard routing; wheel
  behavior and Android bridge contracts remain unchanged.

## Delivered

- Added `Library → 我的 → 阅读设置 → 按键与操作` as the V3 settings entry.
- The page is platform-aware: Windows shows keyboard and mouse-wheel inputs;
  Android shows volume inputs. The six semantic commands are grouped with
  current bindings, disabled-input visibility, clear actions, and a
  platform-limited reset-to-default action.
- Added a clear capture overlay. The first supported key/wheel/volume input is
  consumed by `ReaderInputCapture` and never dispatches a `ReaderCommand`.
- Added conflict confirmation with cancel/replace behavior. Replacement writes
  one profile map atomically through `ReaderInputBindingsRepository`; one
  physical ID cannot remain assigned to two commands. Clearing persists an
  explicit `null` and survives profile reload.
- Android bridge state is enabled only while this page is capturing; Windows
  capture stays in the Dart keyboard/wheel path. Settings operations do not
  touch ReaderLocator, reading progress, ReaderPreferences, or sessions.
- Profile watch remains hot-reloadable; all UI consumes typed profiles and does
  not access storage keys or JSON.

## Validation

- `flutter analyze`: PASS, 0 issues.
- Full unit/contract/widget suite: **401/401 PASS**.
- Targeted registry/capture/workflow tests: **12/12 PASS**.
- Existing M5.3a-d repository/router/capture coverage remains green; schema is
  unchanged at 6.
- `git diff --check`: PASS.
- Windows Release: PASS — `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`.
- Android Debug: PASS — `build\\app\\outputs\\flutter-apk\\app-debug.apk`.
- Android real-device validation: **NOT-RUN / deferred**.

## Scope boundary

No automatic reading, TTS, EPUB, RSS, or binding-customization persistence
outside the existing platform-scoped `app_settings` profile was added.
