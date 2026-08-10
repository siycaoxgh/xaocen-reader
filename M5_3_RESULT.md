# M5.3 Result — Reader input contract closure

Date: 2026-08-10  
Drift schema: **6**  
Status: **COMPLETE**

## Android product contract

Android volume settings are physical-input-centric. The page exposes only
Volume Up and Volume Down, each selectable as Previous page, Next page, or
Disabled. Android does not expose chapter navigation, reader controls, or TOC
commands through volume keys in this release. Windows retains all six
ReaderCommands and its command-centric keyboard/wheel UI.

The Android host intercepts volume only while paged Reader is active, or while
input capture is active. Vertical Reader, non-Reader routes, and disabled
bindings leave volume handling to Android. Capture consumes the first input and
never dispatches a ReaderCommand.

## Profile capability migration

ReaderInputProfile remains format v2 and Drift remains schema 6. Repository
decode/normalization filters unsupported Android commands from legacy profiles
and restores that physical input to the Android platform default. Supported
Android null values remain explicit disabled bindings. Windows profiles are
unchanged and isolated. Direct repository writes also reject unsupported
Android commands.

## Chapter navigation generation

Windows previous/next chapter operations now have an independent navigation
generation. Each operation captures the confirmed Locator, invalidates older
operations, freezes active-mode progress writes, restores the real chapter
start offset, waits for visible confirmation, and only then flushes the current
generation. Mode changes, metrics changes, lifecycle interruption, route pop,
and dispose invalidate pending chapter operations. No chapterIndex, pageIndex,
scrollPixels, percentage, or chapter ratio is persisted.

## Validation

- `flutter analyze`: PASS, 0 issues.
- Full unit/contract/widget suite: **410/410 PASS**.
- Windows integration: **10 files / 13 scenarios PASS**.
- Four real TXT corpus checks: PASS, **logical error = 0**.
- Windows Release: PASS — `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`.
- Android Debug: PASS — `build\\app\\outputs\\flutter-apk\\app-debug.apk`.
- `git diff --check`: PASS.
- Android targeted ADB: **NOT-RUN**; no device was present in `adb devices -l`
  during this run. No APK was installed and no Android data was changed.

## Scope boundary

Chapter percentage, paged chapter page metrics, and automatic reading remain
deferred. ReaderLocator, reading_progress, ReaderPreferences, ReadingHistory,
ReadingSession, and Drift schema were not changed.
