# M5.8 Icon, build and repository cleanup audit

Date: 2026-08-16

## Scope

This audit used only the active project root:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

The screenshot supplied for this task was treated as visual evidence only; it
contained no additional build instructions.

## Icon result

The Android adaptive foreground previously contained the complete white rounded
icon. Android applied its adaptive mask a second time, which made the orange
mark look cropped on the launcher. The foreground is now generated from the
provided ICO source as a transparent, safe-zone-only orange mark. Legacy
density icons and the round adaptive icon reference the same generated source.

The installed Release APK was checked on `emulator-5554`. The launcher shows
the complete orange mark and the Chinese label `晓枨阅读`. The adaptive
foreground now includes an intentional, enlarged inset so the launcher-provided
white background remains visible as a safe ring around the mark, comparable to
the surrounding system icons.

## Build/code findings

| Finding | Action | Result |
|---|---|---|
| Windows scripts searched only the stale `%USERPROFILE%\flutter` path | Added the actual `develop\flutter` SDK candidate and PATH fallback | Fixed; Standard Release stages successfully |
| Verification could bypass the canonical Windows staging selector | Routed verification through `build_windows_engine.ps1` | Fixed; one output truth |
| Flutter Windows codec rejected Win32 `LONG` coordinates from the desktop sampler | Explicitly encoded `POINT::x/y` as `int32_t` in `windows/runner/flutter_window.cpp` | Fixed; Windows Release compiles |
| Drift reports multiple test database instances | Existing test-fixture warning only; no failing assertion | Recorded for a separate test-harness cleanup, not changed in this release |
| Flutter reported newer dependency versions and a future AGP compatibility warning | No dependency upgrade performed in this cleanup | Deferred; not a current build failure |

## Cleanup boundary

The abandoned pre-4.0 checkout `C:\Users\TOM\Desktop\xaocen-reader` was
moved to the active repository archive:

`archive\legacy_pre_4_0_20260816\xaocen-reader\`

Historical source and documentation remain. Generated build caches and old
APK/EXE material were moved to a recoverable temporary quarantine rather than
touching user library databases. No Windows or Android application data was
deleted. An empty duplicate `aocen_reader` directory beside the active
`xaocen_reader` root was also quarantined after verifying it contained no
files.

## Current hand-off

- Android Release: `build\app\outputs\flutter-apk\app-release.apk`
- Windows Standard Release: `artifacts\windows\current\Release\xaocen_reader.exe`
- Android package: `com.xaocen.xaocen_reader`
- User-visible version: `4.5.8`

Latest Android Release verification: 64,489,642 bytes, SHA-256
`DEBC4EEB8873A1F610BFC9270B7A10963C475EF8DBDDA6BE1FF3247C15B4FF9D`.
Launcher evidence is stored at
`artifacts\android\current\launcher.png`.

The Windows release directory contains runtime resources, not user data or
application logs. Standard profile data remains at
`%LOCALAPPDATA%\XAOCEN\Reader\profiles\default\`; the absence of a log file
inside the release directory is expected.

Release artifacts are generated locally and should be attached to a GitHub
Release, not committed as source history.
