# M5.6a Result — P1 regression fixes

Status: COMPLETE
HEAD: fcc52d4e5a9cc98f41262e29176ab4140c876429
Drift schema: 9

## Fixes

1. AutoRead status chrome now follows the Reader chrome visibility. Hiding
   chrome removes the status bar from the hit-test/render tree without touching
   the AutoRead controller, ReaderLocator, or ReadingSession. Showing chrome
   restores the current running/paused/stopped state and actions.
2. The Reader settings behavior panel now explains that the 12/24-hour clock
   requires the Reader information-bar mode and the bottom information layer.
   The existing formatter was retained. Rendered widget coverage verifies both
   `HH:mm` and `hh:mm AM/PM` output.
3. Paged Reader owns a route-level focus node. Pointer entry explicitly restores
   that focus, and Aa/TOC completion requests it again. PageUp/PageDown/Arrow
   events therefore reach `ReaderInputRouter` after a text control or modal has
   taken focus; no keyboard path calls `PagedReaderController` directly.

## Regression evidence

- Targeted pre-fix focus test reproduced the bug: after another control held
  focus, the bound PageDown command was not delivered (`0` callbacks).
- The same test passes after the Reader-owned focus restoration and covers
  PageUp, PageDown, ArrowLeft, and ArrowRight bindings.
- Full Flutter unit/contract/widget: **480 passed**.
- Windows integration: **14 scenarios passed** across 11 files, including the
  four real TXT corpus flows; logical error remained **0**.
- Windows Release: PASS.
- Android Debug application build: PASS (no device/ADB actions in this pass).
- `git diff --check`: PASS.

Artifacts:

- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

No schema, ReaderLocator, PageWindow, AutoRead state, or ReadingSession
contract changed.
