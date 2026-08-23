# XAOCEN Reader repository and release layout

This document is the single map for the active repository. The active project
root is:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

The similarly named `aocen_reader` directory is not an XAOCEN project and must
not be used for builds or release links. The empty duplicate that was present
beside the active root was quarantined during this cleanup.

## Canonical outputs

| Platform | Canonical local output | Notes |
|---|---|---|
| Android Release | `build\app\outputs\flutter-apk\app-release.apk` | Universal APK (arm64, armeabi-v7a, x86_64); generated output, not a source file |
| Windows Standard Release | `artifacts\windows\current\Release\xaocen_reader.exe` | Staged by `tool\build_windows_engine.ps1 -Engine Standard -Configuration Release` |
| Windows Patched Release | Same canonical Windows path | Staged only through the same selector after revision/artifact guards pass |

`build\` is an intermediate Flutter directory. The Windows `artifacts\windows\current\Release\`
directory is the only current Windows hand-off directory; old standard/patched
folders are not release sources.

## Build entry points

Run from the active root:

```powershell
& 'C:\Users\TOM\develop\flutter\bin\flutter.bat' pub get
& 'C:\Users\TOM\develop\flutter\bin\flutter.bat' build apk --release
.\tool\build_windows_engine.ps1 -Engine Standard -Configuration Release
# Patched is opt-in and guarded:
# .\tool\build_windows_engine.ps1 -Engine Patched -Configuration Release
```

The selector discovers the same Flutter SDK without modifying the global SDK,
stages one bundle, and writes `engine-selection.json` next to the executable.

## Runtime data is not build output

Standard Windows data is kept outside the installation directory:

`%LOCALAPPDATA%\XAOCEN\Reader\profiles\default\`

Portable mode uses `<program>\user_data\profiles\default\`. Android data is
app-private. Neither location is part of the repository cleanup or release
artifact. Removing an APK/EXE must not be used as a database migration step.

The `data\` folder beside the Windows EXE is Flutter runtime content
(`app.so`, `icudtl.dat`, and `flutter_assets`); it is not the XAOCEN database,
book library, or a portable profile. The release bundle does not create a log
file by default. Diagnostics are captured explicitly through the emulator
`logcat` helper or a debugger when needed.

To inspect the current Windows profile without guessing from the EXE folder:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\XAOCEN\Reader\profiles\default" -Force
```

Portable storage is used only when `--portable`, `XAOCEN_PORTABLE=1`, or a
`portable.marker` file is explicitly supplied. The current canonical Release
bundle contains none of these, so it uses the standard profile above.

## Historical material

The pre-4.0 checkout was moved out of the desktop root to:

`archive\legacy_pre_4_0_20260816\xaocen-reader\`

Its documents, source, and nested Git history remain available for reference.
Generated `.dart_tool`, `build`, `dist`, and Flutter Windows ephemeral output
were removed from that active historical checkout and placed in a recoverable
temporary quarantine outside the repository. They are not build inputs.

Milestone reports in the active repository remain as historical evidence. New
reports should be added under `docs/` or linked from `docs/README.md`, not
duplicated into additional project roots.

## GitHub hygiene

Source, tests, schema migrations, icon source, build scripts, and durable
documentation belong in Git. Generated `build/`, staged release artifacts,
logs, emulator captures, and local user data do not. Release APK/EXE files
should be attached to a GitHub Release rather than committed into the source
tree.
