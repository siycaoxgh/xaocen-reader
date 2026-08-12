# M5.7s.2 Visual Contract Recovery

Date: 2026-08-13  
Baseline commit: `4781fdfc6f4b30ec5624c90cfb280e6e2ec40820`  
Drift schema: **12**  
Engine alpha patch: **unchanged in `C:\xaocen-engine\src`; no compositor work was resumed**

## Why M5.7 was reopened

The previous result promoted automated tests and the presence of native code to
product acceptance. Manual Windows testing showed that those are different
claims. This pass records automated evidence separately from local interaction
and visual validation and keeps the overall stage **REOPENED**.

The audit used the existing V3 constraints and the interaction principles of the
public [binbyu/Reader](https://github.com/binbyu/Reader) and
[legado-with-MD3](https://github.com/HapeLee/legado-with-MD3) references. No
source was copied.

## Concrete fixes

### Reader Info layout

Production Reader content now uses `ReaderInfoScaffold`:

```text
TopInfoRegion
Divider slot (one physical pixel)
ReaderBody (Expanded)
Divider slot (one physical pixel)
BottomInfoRegion
```

The old production padding-plus-overlay path was replaced. Information widgets
are siblings of the body, so vertical scrolling and paged layout receive the
remaining viewport and cannot be covered by a Stack/Positioned info layer.
Android top/bottom insets are reserved through MediaQuery/SafeArea; Windows
uses the same semantic regions without mobile status-bar assumptions. Hiding a
region releases its reserved extent. Hiding the divider changes only its paint,
not the region geometry.

### Responsive Reader settings

The Aa settings surface responds to available width at runtime:

| Width | Navigation |
|---:|---|
| `< 600` | horizontally scrollable category chips, full-width content |
| `600–839` | compact icon rail with tooltips |
| `>= 840` | labeled icon + text rail and content panel |

The four categories remain reachable at every tier. Stable category keys were
added to widget/integration tests so tests do not assume long labels are visible
in the compact rail.

### Paged Chrome tap behavior

`PagedReaderView` no longer reports manual navigation on raw pointer-down. A
plain center tap while AutoRead is idle/paused therefore toggles Chrome and
keeps it visible. A real drag still reports `manualNavigation` from the scroll
start path, so AutoRead pauses before user navigation. The existing 2.5 s hide
timer remains limited to AutoRead `running` and is cancelled by panels, pause,
stop, and manual navigation.

### Diagnostics visibility

Platform diagnostics is exposed from Reader settings on Windows and Android,
not only in debug mode. The runtime page reports platform, renderer, backend,
resolution, pixel ratio, refresh rate, HDR/WCG, alpha surface, borderless,
desktop transparency, tray/taskbar, input capabilities, and an explicit
fallback reason. Unknown is rendered as `unknown`; unsupported desktop
transparency on the current opaque Flutter Windows surface remains
`rendererUnsupported`.

## Itemized audit

`AUTOMATED PASS` means source + focused tests + integration/build evidence; it
does not claim a human saw the effect on a local desktop.

| Item | Status | Evidence / limitation |
|---|---|---|
| Windows platform capability diagnostics | AUTOMATED PASS | Production route is visible on Windows; capability widget and adapter tests pass. Unknown values are explicit. |
| Reader Info no longer covers body | AUTOMATED PASS | Geometry tests assert top/body/bottom non-intersection with insets, hidden-info expansion, and divider geometry. |
| Separator semantics | AUTOMATED PASS | Hairline has a reserved one-physical-pixel slot; visibility changes paint only. |
| Paged Chrome idle/paused center tap | AUTOMATED PASS | Raw pointer-down no longer calls the manual-navigation callback; full Reader widget tests pass. Local visual confirmation remains recommended. |
| Dark/light settings live refresh | MANUAL REQUIRED | Paint-only theme tests pass; external theme change while a modal is already open still needs local observation across Aa, sheet, dialog, and child page. |
| Font preview card | AUTOMATED PASS | Existing card is a rounded bordered preview with an explicit preview title and candidate-font path; Reader tests/build pass. Human typography comparison remains manual. |
| Windows localized font display name | MANUAL REQUIRED | Native registry fallback is localized name → English family/full name → file name; locale-specific output was not observed in RDP. |
| Android vertical volume one-viewport navigation | AUTOMATED PASS / DEVICE DEFERRED | Dart derives the current scroll viewport and preserves the shared input contract; physical Volume validation is deferred because `ce8df63f` is unavailable. |
| Android AutoRead volume mapping | AUTOMATED PASS / DEVICE DEFERRED | Mapping stays in Dart Router; Kotlin only reports physical volume input. Physical confirmation is deferred. |
| Windows LMB+RMB Boss Key | DEFERRED — RDP/local physical validation required | App-local/native state and recovery guards exist; no reliable local mouse-chord observation in RDP. |
| Windows keyboard Boss Key | MANUAL REQUIRED | Binding/domain/native focused-window path exists; cold-start/focused key press needs a local Windows session. |
| Boss hide → restore | DEFERRED — RDP/local physical validation required | Recovery code and entry invariant exist; visual hide/restore was not performed here. |
| Tray left-click Show/Restore/Activate | DEFERRED — RDP/local physical validation required | Native path calls show/restore/foreground/focus; Explorer tray interaction needs local shell. |
| Tray right-click Show/Exit | DEFERRED — RDP/local physical validation required | Native menu has both commands; menu selection was not manually performed. |
| Default shortcut cold start | MANUAL REQUIRED | Default profile is supplied at Router startup and profile tests pass; native cold-start key press was not performed. |
| Same-DataRoot single instance | MANUAL REQUIRED | Standard instance mutex and activation path are present; two-process launch needs local host validation. |
| Borderless top drag / edge resize | DEFERRED — RDP/local physical validation required | Native `WM_NCHITTEST` implements drag band and edge/corner hit tests; pointer feel and resize need local desktop. |
| Chrome-hidden top drag band | DEFERRED — RDP/local physical validation required | Native hit test is independent of Flutter Chrome visibility; local pointer validation remains required. |

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | PASS — no issues found |
| Full Flutter unit/contract/widget tests | PASS — 522 tests |
| Windows integration | PASS — all selected integration files; real four-TXT corpus, 8 MB no-chapter corpus, search, mode restore, chapter metrics, logical error = 0 |
| Windows Release | PASS |
| Android Debug | PASS |
| `git diff --check` | PASS; only LF/CRLF normalization warnings |
| Android ADB | DEFERRED — physical device unavailable; expected serial `ce8df63f` |

Build artifacts:

- Windows EXE: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android APK: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

## Final gate

**M5.7 PRODUCTION STABILIZATION = REOPENED**

This pass is **AUTOMATED PASS** for corrected layout, responsive settings,
diagnostics visibility, and regression coverage. Overall acceptance remains
**MANUAL REQUIRED** until local Windows shell/visual checks and Android
physical-device checks are completed. The patched Engine remains paused; do not
enter DComp/Reader integration or M5.7c.2 from this report.
