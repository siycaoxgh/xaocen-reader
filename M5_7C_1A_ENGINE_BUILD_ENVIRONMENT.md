# M5.7c.1a Engine Build Environment Bootstrap

Date: 2026-08-12

## Result

`VANILLA_ENGINE_BUILD = BLOCKED (environment)`.

The official pinned dependency sync completed the source/dependency phase far
enough to verify the Flutter engine checkout, ANGLE, GN, Clang, Ninja, Dart and
the Windows build tooling.  The first vanilla GN generation then stopped before
writing `build.ninja`, because the pinned Windows toolchain requires the
Debugging Tools for Windows (`dbghelp.dll`) and this installation does not have
that SDK feature.  No XAOCEN patch was applied and no Reader code was changed.

This is an environment gate, not a Flutter/Reader source result.  Per the stop
conditions, fixture, patched build and shared-texture interop were not run.

## Pinned checkout

- Isolated checkout: `C:\xaocen-engine\src`
- Framework/Flutter checkout commit: `69c8c61792f04cc809dfef0c910414fb9afc06cd`
- Flutter 3.44.7 framework revision used by the daily SDK: `84fc5cbb223bc12f83d65b647ff8a56caf779ffd`
- Engine revision: `69c8c61792f04cc809dfef0c910414fb9afc06cd`
- Root `DEPS` blob: `e0e46d3e86d2a60b3ae7515fce97b195a33663b2`
- Pinned ANGLE checkout: `84027aca9b71c9ba335bd000dad1107b8810a511`

The daily SDK at `C:\Users\TOM\develop\flutter` was not modified.

## Tools and dependency state

- Official `depot_tools`: `C:\depot_tools`
- `gclient` and `vpython3`: runnable from the isolated PATH
- `git`: the installed official Git executable used by depot_tools
- Visual Studio Build Tools 2022 17.14.37: detected
- Windows SDK installed: `10.0.26100.0`
- Pinned engine toolchain script expects: `10.0.22621.0`
- ANGLE: present at `C:\xaocen-engine\src\engine\src\flutter\third_party\angle`
- Clang: present under `C:\xaocen-engine\src\engine\src\flutter\buildtools\windows-x64\clang`
- GN: present at `C:\xaocen-engine\src\engine\src\flutter\third_party\gn\gn.exe`
- Ninja: present at `C:\xaocen-engine\src\third_party\ninja\ninja.exe`
- Pinned Dart, Skia, libcxx/libcxxabi and other DEPS repositories are present.

`gclient sync --no-history` was used from the official Flutter monorepo layout.
The first sync encountered transient Schannel TLS failures for the official LLVM
repositories; the same pinned revisions were fetched from their official
remotes and a low-concurrency gclient sync completed the remaining hooks.  No
ANGLE headers were copied by hand.

## Vanilla build gate

The official Windows flow was invoked from `C:\xaocen-engine\src\engine\src`
with the local Visual Studio path (`DEPOT_TOOLS_WIN_TOOLCHAIN=0`).  GN reached
the Windows toolchain setup and failed at the required diagnostic runtime copy:

```text
dbghelp.dll not found in
C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\dbghelp.dll
You must install the "Debugging Tools for Windows" feature from the Windows 10 SDK.
```

The pinned source also hard-codes SDK `10.0.22621.0` in
`build/toolchain/win/setup_toolchain.py`; that SDK is not installed.  The source
was restored after diagnostic inspection; no compatibility edit was retained.

Therefore:

- `VANILLA_ENGINE_BUILD`: **FAIL / BLOCKED (environment)**
- `build.ninja`: not generated
- Ninja compile/link: not started
- Vanilla fixture: **NOT-RUN** (vanilla gate did not pass)

## Patch and interop gates

- XAOCEN patch apply: **NOT-RUN** (required vanilla gate failed)
- Patched engine build: **NOT-RUN**
- Shared D3D texture → ANGLE EGL client-buffer → DComp swapchain: **NOT-RUN**
- FP16/scRGB: **NOT-RUN**
- XAOCEN Reader integration: **NOT-RUN**

No CPU readback, `UpdateLayeredWindow`, whole-window alpha, native text overlay,
or second Reader renderer was introduced.

## Disk and safety

- C: free space before bootstrap: approximately 61.5 GB
- C: free space after official dependency sync: approximately 36.2 GB
- Isolated checkout files: approximately 17.8 GiB
- depot_tools files: approximately 0.6 GiB
- No `out/` or dependency artifact was copied into the XAOCEN application.

## Next gate / recommendation

`M5.7c.1b` is **not recommended yet**.  First install, using the official
Visual Studio/Windows SDK installer, the Debugging Tools for Windows feature and
the pinned Windows SDK 10.0.22621.0 (or obtain an official engine revision whose
documented toolchain matches the installed SDK).  Then rerun vanilla GN and
Ninja from this isolated checkout.  Only after `VANILLA_ENGINE_BUILD = PASS`
should the revision-checked XAOCEN patch infrastructure be applied.

## XAOCEN repository state

The user-specified application baseline is `4e2b91d`.  During this remote
bootstrap the visible `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
directory no longer contains a `.git` directory (only the pre-existing
`windows_engine_patches/flutter_engine_spike_test_app` directories are visible),
so a fresh `git rev-parse`/worktree check cannot be performed from that path.
No application file was intentionally modified.  The isolated engine checkout
contains only generated dependency/build state outside the application repo.
