# M5.3a+b Result — Reader input binding contract and persistence

Date: 2026-08-09  
Branch: `feat/m4-horizontal-reader`  
Drift schema: **6**  
Status: **COMPLETE**

## Delivered

- Extended the typed `ReaderCommand` contract with `previousChapter`,
  `nextChapter`, `toggleReaderControls`, and `openToc`.
- Added stable `PhysicalInputId` values for the Windows keyboard/wheel and
  Android volume inputs. Persisted data contains only these strings.
- Added `ReaderInputProfile` with platform, version, typed bindings, and
  timestamp. Windows and Android profiles are isolated under private
  `app_settings` repository keys.
- Added `ReaderInputBindingsRepository` (`load`, `watch`, `bind`, `unbind`,
  `update`, `resetToDefaults`). UI/Reader code does not access storage keys or
  JSON.
- Kept the existing default input route unchanged. Capture UI, host capture
  bridge, and Reader action routing remain M5.3c scope.

## Persistence contract

```json
{
  "version": 1,
  "platform": "windows",
  "updatedAt": "2026-08-09T00:00:00.000Z",
  "bindings": {
    "keyboard.arrowLeft": "previousPage",
    "keyboard.arrowRight": "nextPage",
    "keyboard.pageUp": "previousPage",
    "keyboard.pageDown": "nextPage",
    "mouse.wheelUp": "previousPage",
    "mouse.wheelDown": "nextPage"
  }
}
```

`null` is a deliberate disabled binding. Invalid whole JSON falls back only
the affected platform; unknown input/command rows are ignored; valid rows and
explicit nulls survive. Missing known inputs are filled from the current
version defaults, and older profile versions are upgraded to the current
version. Schema remains 6.

## Validation

- `flutter analyze`: PASS, 0 issues.
- Targeted input/domain/repository tests: **9/9 PASS**.
- Covered defaults, bind/unbind/null, reset, restart persistence, platform
  isolation, malformed JSON, partial unknown rows, version migration, watch,
  ReaderPreferences isolation, and schema 6.
- `git diff --check`: PASS.

