# Windows DirectComposition alpha spike

This is an isolated Win32 prototype for M5.7b. It is not part of the Flutter
runner and intentionally has no dependency on Reader, Locator, pagination, or
app data.

Build from a **x64 Native Tools Command Prompt for VS 2022**:

```text
cl /nologo /std:c++17 /EHsc /W4 /WX dcomp_alpha_spike.cpp /Fe:dcomp_alpha_spike.exe
```

Run the non-visual resource self-test:

```text
dcomp_alpha_spike.exe --self-test --fp16
```

Run the visible borderless prototype:

```text
dcomp_alpha_spike.exe --fp16
```

The RGBA8 path renders a premultiplied background at 0/25/50/75/100% and an
opaque foreground test block. `--fp16` separately probes an FP16/scRGB
composition swapchain and present path.
