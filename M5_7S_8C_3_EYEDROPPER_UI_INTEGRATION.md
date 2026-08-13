# M5.7s.8c-3 — Windows Eyedropper UI Integration

## Scope

Windows Reader appearance settings now use the existing eyedropper mode for
custom text/background colors. Transparency, Tray, shortcuts, Boss Key,
Android, Palette structure, Reader layout, and the sampler/controller contracts
were not changed.

## UI contract

On Windows, each custom color row exposes:

`current swatch · HEX input · desktop eyedropper · color picker`

The Android row keeps its existing color input/picker behavior and does not
show the Windows desktop eyedropper button.

## Data flow

1. The text or background row records its target (`text` or `background`).
2. `WindowsEyedropperController` enters the existing temporary picking mode.
3. A confirmed `ColorSample` is converted to opaque ARGB and written through
   the existing `ReaderPreferences` draft and `onPreferencesCommitted` path.
4. The active light/dark custom override is updated, `paletteId` becomes
   `custom`, and the existing controllers/preview are synchronized.
5. Escape/right-click leaves the draft unchanged.

No second color truth or database field was introduced. HEX manual editing
continues through the existing parser and same preference commit path.

## Results

| Check | Result | Evidence |
|---|---|---|
| TEXT EYEDROPPER | AUTOMATED PASS / MANUAL REQUIRED | Text row targets only text custom override; local cross-app pick remains required. |
| BACKGROUND EYEDROPPER | AUTOMATED PASS / MANUAL REQUIRED | Background row targets only background custom override; local visual pick remains required. |
| HEX SYNC | AUTOMATED PASS | Existing text controllers and preview are synchronized after sample/manual parse. |
| LIVE PREVIEW | AUTOMATED PASS / MANUAL REQUIRED | Commit uses the live ReaderPreferences callback; local visual Reader confirmation remains required. |
| PERSISTENCE | AUTOMATED PASS / MANUAL REQUIRED | Existing ReaderPreferences persistence path is reused; restart confirmation remains local. |
| ANDROID REGRESSION | PASS | Android keeps the existing color picker row and no Windows sampler is shown. |

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: PASS (585 tests)
- Windows Release: PASS
- `git diff --check`: PASS

Windows Release executable:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

Manual checks remain required for sampling another application, left-click
confirmation, Escape/right-click cancellation, target isolation, and restart
persistence.

