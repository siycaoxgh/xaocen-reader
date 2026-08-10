# M5.3e Result — Reader input settings UI

Date: 2026-08-10
Branch: `feat/m4-horizontal-reader`
Drift schema: **6**
Status: **COMPLETE**

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
- Full unit/contract/widget suite: **396/396 PASS**.
- Existing M5.3a-d repository/router/capture coverage remains green; schema is
  unchanged at 6.
- `git diff --check`: PASS.
- Windows Release: PASS — `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`.
- Android Debug: PASS — `build\\app\\outputs\\flutter-apk\\app-debug.apk`.
- Android real-device validation: **NOT-RUN / deferred**.

## Scope boundary

No automatic reading, TTS, EPUB, RSS, or binding-customization persistence
outside the existing platform-scoped `app_settings` profile was added.
