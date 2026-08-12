# M5.7c.1 Engine Gate Recovery

Date: 2026-08-13  
Pinned engine: `69c8c61792f04cc809dfef0c910414fb9afc06cd`  
Engine checkout: `C:\xaocen-engine\src`

## Gate results

| Gate | Result |
|---|---|
| Production stabilization automated | PASS |
| Windows/host acceptance (B1) | PASS for automated evidence; native visual items remain MANUAL/DEFERRED(RDP) |
| Android physical acceptance (B2) | DEFERRED — expected USB serial `ce8df63f` unavailable |
| Vanilla Engine Ninja build | **PASS** |
| Vanilla fixture Windows build | **PASS** |
| Vanilla fixture widget test | **PASS** |
| Patch verify | **PASS** |
| Patch apply | **PASS** |
| Patched Engine build | **BLOCKED (environment)** |
| Shared D3D → ANGLE EGL → DComp interop | NOT-RUN |
| Local desktop transparency visual validation | DEFERRED |

## Vanilla build

After the three damaged PDBs had been removed in the prior cleanup, the pinned
`host_debug_unopt` Ninja targets completed successfully:

```text
shell_unittests.exe
gpu_surface_unittests.exe
embedder_a11y_unittests.exe
accessibility_unittests.exe
tonic_unittests.exe
txt_unittests.exe
```

Only a non-fatal MSVC `LNK4217` warning was emitted. No source or patch was
changed for this gate.

## Vanilla fixture

The isolated fixture at
`windows_engine_patches/flutter_engine_spike_test_app` built with the pinned
local engine. Its widget test passed. The fixture test app exercises a
transparent root, opaque Flutter text, a button, Slider/pointer handling,
TextField/focus, and an animation. This is a vanilla local-engine fixture
result; it is not a claim of desktop-through-Flutter transparency.

## Patch infrastructure and stop point

The revision/hash checked scripts initially rejected the patch because they
treated patch-created files as missing upstream files and because the known
bootstrap `_bad_scm/` directory made the checkout appear dirty. The scripts
were minimally corrected to recognize new patch files and ignore only that
known bootstrap diagnostic directory. No Engine source was changed by those
script edits.

Final verify/apply succeeded for the pinned revision. The Engine checkout now
contains only the intended Windows alpha patch plus the pre-existing
`_bad_scm/` diagnostic directory.

Patched regeneration then stopped before compilation: `gn gen out\\host_debug_unopt`
entered `vpython3`/CIPD bootstrap and remained blocked for more than five
minutes. It was terminated safely. No patched target was built, no CPU
readback/compositor result was produced, and no DComp interop claim is made.

Per the queue contract this is the first remaining environment blocker, so the
process stops here. TASK D and M5.7c.2 are not entered.
