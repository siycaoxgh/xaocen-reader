# M5.7s Windows Audit + Acceptance

Date: 2026-08-12  
HEAD before this audit: `113b236a75ddae394d5678dfef1b325b0ac64a8d`  
Schema: 12

## Build artifact

Windows Release EXE exists:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

The Release build completed during this audit. The generated executable is
149,504 bytes. The build is a fresh artifact after the storage cleanup; its
presence does not imply a manual visual acceptance.

## Itemized acceptance

| M5.7s item | Result | Evidence / limitation |
|---|---|---|
| Platform capability diagnostics entry | **AUTOMATED PASS** | `platform_capabilities_test.dart` and `platform_diagnostics_page_test.dart` pass; unknown values are not rendered as supported. |
| Default shortcuts effective on cold start | **MANUAL REQUIRED** | Profile/default routing unit tests pass, but a native cold-start key press was not performed in this remote audit. |
| LMB + RMB Boss Key | **DEFERRED(RDP)** | Domain tracker tests pass; native mouse chord/hide/restore needs a local desktop session. |
| Keyboard Boss Key | **DEFERRED(RDP)** | Gesture/domain tests pass; native focused-window behavior needs a local desktop session. |
| Boss hide → restore | **DEFERRED(RDP)** | Recovery guards are covered in shell/domain tests; actual hide and restore were not visually exercised. |
| Tray left click Show/Restore/Activate | **DEFERRED(RDP)** | Native implementation is present; Explorer tray interaction requires a local desktop session. |
| Tray right-click Show/Exit | **DEFERRED(RDP)** | Native menu path is present; actual menu selection was not performed remotely. |
| Same DataRoot second launch activates existing instance | **MANUAL REQUIRED** | Startup mutex/activation path is present; two-process native launch was not run in this audit. |
| Borderless top drag | **DEFERRED(RDP)** | Native `WM_NCHITTEST` drag band is present; pointer feel requires local interaction. |
| Edge/corner resize | **DEFERRED(RDP)** | Native resize hit-testing is present; continuous resize was not manually exercised. |
| Chrome hidden top drag band | **DEFERRED(RDP)** | Native band is independent of Reader Chrome visibility; local interaction still required. |
| Dark/light settings live update | **MANUAL REQUIRED** | Reader paint-only theme tests pass; settings-page live update was not manually observed in this audit. |
| Reader Top/Bottom Info Region | **AUTOMATED PASS** | Widget tests pass for hidden paged info and no-chapter behavior; body region reservation is in production code. |
| Separator hairline | **AUTOMATED PASS** | Info-region widget tree includes the boundary divider and all tests pass. |
| Font preview card | **AUTOMATED PASS** | Preview is now a keyed rounded card with an outline and the explicit title `中文阅读效果预览`; analyze/tests pass. Visual typography remains manual. |
| Windows localized font display name | **DEFERRED(RDP)** | Registry localized-name → English-name → file-name fallback is implemented; locale-specific native output was not observed remotely. |

The one concrete issue found was a labeling/affordance gap in the font preview:
the existing rounded container lacked an explicit card border and still used the
short title “中文阅读效果”. It was corrected to a bordered card titled
“中文阅读效果预览”. No Reader engine, Locator, pagination, AutoRead, or schema
change was made.

## Verification rerun

- `flutter analyze`: PASS
- Flutter unit/contract/widget tests: PASS — 510 tests
- Windows integration: PASS — 11 files, including all 4 real TXT corpora and
  7.68MB no-chapter corpus; logical error = 0
- Windows Release: PASS
- `git diff --check`: PASS (only LF/CRLF normalization warnings)
- Android physical device: **DEFERRED — device unavailable** (`ce8df63f` was
  absent from USB `adb devices -l`; no wireless service was discovered)

## Overall status

**WINDOWS M5.7s = PARTIAL**

Automated Reader/platform checks pass. Native shell interactions and visual
desktop behavior remain explicitly deferred/manual in the current RDP
environment; they are not promoted to PASS without local Windows validation.

Android APK remains:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

## Gate adjustment

Android physical validation is an environment condition, not a production
failure. B1 host acceptance is therefore allowed to proceed independently;
B2 remains **DEFERRED — physical device unavailable** (expected serial
`ce8df63f`). No further adb restart or wireless discovery is required for this
queue.
