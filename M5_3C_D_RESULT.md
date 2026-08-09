# M5.3c+d Result — ReaderInputRouter and Android input capture

Date: 2026-08-10  
Branch: `feat/m4-horizontal-reader`  
Drift schema: **6**  
Status: **COMPLETE**

## Delivered

- Added unified `ReaderInputRouter`: `PhysicalInputId → ReaderInputProfile → ReaderCommand → Reader action`.
- ReaderPage owns one router for vertical and paged modes; Windows keyboard/wheel and Android volume use the same dispatch path.
- Connected all six commands. Page commands are paged-only; chapter commands resolve real TOC `chapter` entries and restore exact UTF-16 chapter-start Locators in either mode. Controls and Flat TOC reuse existing callbacks without progress/session side effects.
- PagedReaderView reports physical keyboard/wheel IDs to the router. Profile watch hot-reloads bindings; timestamp and operation generations reject stale profile/input events.
- Added `ReaderInputCapture`: first valid physical input is captured and ends capture without executing a command; cancel/dispose clears it.
- Android host now exposes `setInputCaptureActive(bool)`, reports `android.volumeUp/down`, ignores key-up/repeat dispatch, and intercepts volume only when paged or capture is active.

## Validation

- `flutter analyze`: PASS, 0 issues.
- Full unit/contract/widget suite: **396/396 PASS**.
- Windows integration: **10 files / 13 scenarios PASS**, run individually.
- Windows Release: PASS — `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`.
- Android Debug: PASS — `build\\app\\outputs\\flutter-apk\\app-debug.apk`.
- Four real TXT corpus regression checks: logical-error **0**.
- `git diff --check`: PASS.
- Android real-device validation: **NOT-RUN / deferred**.
