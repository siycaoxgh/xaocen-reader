# M5.7c.1b Windows Flutter Engine Vanilla Build Retry

Date: 2026-08-12

## Result

`VANILLA_ENGINE_BUILD = FAIL (linker/environment)`.

The retry was performed against the isolated checkout `C:\xaocen-engine\src`
at the exact pinned engine commit. The SDK gate is satisfied, GN successfully
generated `out\host_debug_unopt\build.ninja`, and the regenerated toolchain now
contains the ATL include directory. The incremental Vanilla link then stopped
at the first linker error: MSVC reported a corrupted PDB (`LNK1285`) for several
unit-test targets. No XAOCEN alpha patch was inspected, applied or modified, and
no Reader code was changed.

## Correct XAOCEN repository check

The requested path was checked exactly:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

It exists, but it currently contains no `.git` directory.  Its visible contents
are the prior environment report and `windows_engine_patches` directory only.
Consequently a truthful XAOCEN HEAD/worktree value cannot be recovered from this
path in this environment; no commit was made.

## SDK and native toolchain evidence

The requested pinned SDK payload is now present (the newer SDK remains
installed):

- include: `C:\Program Files (x86)\Windows Kits\10\Include\10.0.22621.0`
- lib: `C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0`
- retained additional SDK: `10.0.26100.0`
- debugger runtime: `C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\dbghelp.dll`

The pinned engine toolchain script explicitly selects `SDK_VERSION =
'10.0.22621.0'`. The generated Ninja command line confirmed GN selected the
22621 include family under `C:\Program Files (x86)\Windows Kits\10`.

Other tools and dependencies remain available:

- Visual Studio Build Tools 2022 17.14.37
- ANGLE at `engine/src/flutter/third_party/angle` (pinned DEPS checkout)
- GN at `engine/src/flutter/third_party/gn/gn.exe`
- Ninja at `third_party/ninja/ninja.exe`
- Clang at `engine/src/flutter/buildtools/windows-x64/clang/bin/clang.exe`

The isolated engine commit is still:

`69c8c61792f04cc809dfef0c910414fb9afc06cd`

GN regeneration succeeded and produced:

`C:\xaocen-engine\src\engine\src\out\host_debug_unopt\build.ninja`.

## Gate results

- SDK 10.0.22621 include/lib: **PASS**
- Debugging Tools / SDK `dbghelp.dll`: **PASS**
- GN regeneration: **PASS**
- Vanilla Engine Ninja build: **FAIL (linker/environment)**
- First linker error: `LNK1285: PDB file ...\\shell_unittests.exe.pdb is corrupted; delete and regenerate` (the same error was reported for `embedder_a11y_unittests.exe.pdb` and `gpu_surface_unittests.exe.pdb`).
- Vanilla fixture: **NOT-RUN**
- Patch verify/apply: **NOT-RUN** (vanilla gate failed)
- Patched Engine build: **NOT-RUN**
- Shared D3D texture → ANGLE EGL client buffer → DirectComposition: **NOT-RUN**

## Stop condition and next action

Per the task contract, the remaining blocker is the corrupted/stale PDB state
from the interrupted incremental link. The ATL/MFC and 22621 SDK/debugger gates
are now satisfied. A subsequent retry may remove only the affected generated
PDB/target outputs and rerun the same Vanilla Ninja gate; do not modify engine
source or apply XAOCEN patches before that gate passes.

Do not modify the alpha patch, Flutter common renderer, Reader, Locator, or
schema until `VANILLA_ENGINE_BUILD = PASS`.

Disk remaining at the end of this retry was approximately 27.9 GiB. No engine
artifact was copied into the XAOCEN application.
