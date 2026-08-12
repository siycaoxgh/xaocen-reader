# M5.7 Storage Cleanup

Date: 2026-08-12  
Status: completed; build and Engine tasks remain paused.

## Scope and safety

The cleanup targeted only regenerable build outputs, temporary Flutter artifacts,
and three PDB files already identified as damaged by the paused Engine build.
Source, user data, databases, books, test corpora, SDKs, Engine dependencies, and
patch infrastructure were not removed.

## Before scan

| Location | Size before |
| --- | ---: |
| `C:\Users\TOM\Desktop\xaocen-reader-v4` | 77,092,294,684 bytes (~71.81 GiB) |
| `C:\xaocen-engine` | 52,222,294,902 bytes (~48.63 GiB) |
| C: free space | 7,067,025,408 bytes (~6.58 GiB) |

Largest regenerable areas found:

- `xaocen_reader\.dart_tool\flutter_build`: 72,072,629,685 bytes (~67.13 GiB)
- `xaocen_reader\build`: 4,474,699,012 bytes (~4.17 GiB)
- `xaocen_reader\windows\flutter\ephemeral`: 323,342,313 bytes (~308 MiB)
- `C:\xaocen-engine\src\engine\src\out\host_debug_unopt`: the active Engine output variant; only confirmed damaged PDBs were removed.
- Large generated files included APKs, Windows PDBs, and object/library/debug outputs.

No actual project/archive `*.zip`, `*.7z`, or `*.rar` backup was found. The only
archive-like match was a Gradle wrapper filename. No repository/Desktop PowerShell
backup script or tool invocation using `Compress-Archive`/`7z` was found.

## Removed

1. Entire `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\`.
2. Entire `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\.dart_tool\flutter_build\`.
3. Entire generated `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\windows\flutter\ephemeral\`.
4. Only these confirmed damaged Engine PDBs:
   - `C:\xaocen-engine\src\engine\src\out\host_debug_unopt\shell_unittests.exe.pdb`
   - `C:\xaocen-engine\src\engine\src\out\host_debug_unopt\embedder_a11y_unittests.exe.pdb`
   - `C:\xaocen-engine\src\engine\src\out\host_debug_unopt\gpu_surface_unittests.exe.pdb`

The Engine checkout, `third_party\ANGLE`, dependencies, source, and remaining
`out` variant were intentionally retained. No full `gn clean` or checkout-wide
deletion was performed.

## After scan

| Location | Size after | Reclaimed |
| --- | ---: | ---: |
| `C:\Users\TOM\Desktop\xaocen-reader-v4` | 367,857,901 bytes (~350.87 MiB) | 76,724,436,783 bytes (~71.47 GiB) |
| `C:\xaocen-engine` | 50,056,491,894 bytes (~46.62 GiB) | 2,165,803,008 bytes (~2.02 GiB) |
| Total deleted | — | 78,890,243,889 bytes (~73.49 GiB) |
| C: free space | 85,983,309,824 bytes (~80.06 GiB) | +78,916,284,416 bytes observed |

The small difference between filesystem free-space delta and item-size totals is
normal filesystem allocation/metadata variance.

## Preserved

- XAOCEN source (`lib`, `test`, `integration_test`, `android`, `windows/runner`), Git data, and all project reports/specifications.
- DataRoot, SQLite/database files, imported books, four real TXT corpora, fonts, and reader background assets.
- `C:\xaocen-engine\src`, dependencies, `third_party\ANGLE`, pinned revision, and `windows_engine_patches`.
- Flutter/Dart SDKs, Windows SDK, Visual Studio/ATL/MFC toolchains.
- `.dart_tool` package/pub metadata (only its generated `flutter_build` subtree was removed).

## Backup retention audit

No automatic archive generator was found in the project, Desktop PowerShell
scripts, or the scanned build tooling. `DataRootBackupService` is a directory-based
backup/restore service and does not create mandatory archive snapshots. Therefore
there was no existing archive rotation point to change and no archive was deleted.

The requested maximum-three policy is recorded as a follow-up contract: if an
archive-producing scheduler is introduced, it must retain only the newest three
complete source snapshots and delete the oldest when creating the fourth. It was
not fabricated or applied to a non-existent generator in this cleanup.

## Final state

No Flutter, Dart, Ninja, GN, C++, linker, or Engine build process is running.
The Engine spike remains paused. No APK/EXE was rebuilt, no database or book was
changed, and no source code was reverted.
