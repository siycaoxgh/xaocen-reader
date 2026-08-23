# M5.7s.8d-2 — Patched Engine Build Chain Unblock

日期：2026-08-14
范围：仅 `C:\xaocen-engine\src` 的 patched Flutter Engine 配置 Gate。
XAOCEN Reader、生产 Runner、Reader Theme、schema 均未修改；未执行完整 Ninja 编译。

## Gate 结果

```text
ENGINE REVISION MATCH = PASS
DEPOT_TOOLS = PASS
VPYTHON = PASS
CIPD = PASS
GN GEN = PASS
CURRENT BLOCKER = 本轮 gn gen 已通过；完整 patched Engine 编译和 Flutter-frame/DComp interop 尚未执行，仍需后续 Gate
```

## 1. 前置 Gate

已读取 `M5_7S_8D_1_WINDOWS_TRANSPARENCY_REENTRY_AUDIT.md`：

- `ENGINE REVISION MATCH = PASS`；
- alpha patch 状态为 `PRESENT (applied / build-unverified / not production-integrated)`。

Engine checkout HEAD 仍为：

`69c8c61792f04cc809dfef0c910414fb9afc06cd`

本轮没有重新 apply patch，也没有修改现有 dirty worktree。

## 2. 工具链检查

### depot_tools

`C:\depot_tools` 存在，包含 `gclient.bat`、`cipd.bat`、`.cipd_bin`、Python
runtime 与 bootstrap 脚本。当前 shell 的初始 PATH 没有包含 depot_tools，因此
`where.exe gn/ninja/vpython3/cipd` 对裸命令不返回路径；这属于环境 PATH 问题，
不是工具不存在。

本轮使用的显式工具位置：

```text
C:\depot_tools
C:\depot_tools\.cipd_bin\vpython3.exe
C:\depot_tools\.cipd_client.exe
C:\xaocen-engine\src\engine\src\flutter\third_party\gn\gn.exe
C:\xaocen-engine\src\third_party\ninja\ninja.exe
```

`gclient.bat --version` 可启动并输出 depot_tools usage；没有执行全量 `gclient
sync`。

### vpython / CIPD / GN / Ninja

实际 smoke 结果：

| 工具 | 结果 | 证据 |
|---|---|---|
| vpython | **PASS** | `C:\depot_tools\.cipd_bin\vpython3.exe --version` → Python 3.8.10 |
| CIPD | **PASS** | `C:\depot_tools\.cipd_client.exe version` → cipd 2.8.1 |
| GN | **PASS** | pinned tree 的 `gn.exe --version` → 2285 (81b24e01531e) |
| Ninja | **PASS** | pinned tree 的 `ninja.exe --version` → 1.11.1 |
| Python | **PASS** | 系统 Python 3.12.10；Engine GN 实际使用 vpython runtime |

## 3. Engine dependencies

没有盲目重新同步 Engine。只读确认以下依赖/输入存在：

```text
C:\xaocen-engine\src\engine\src\.gn                         present
C:\xaocen-engine\src\DEPS                             present
C:\xaocen-engine\src\engine\src\flutter\third_party\ANGLE  present
C:\xaocen-engine\src\engine\src\flutter\buildtools         present
C:\xaocen-engine\src\third_party\ninja\ninja.exe            present
C:\xaocen-engine\src\engine\src\flutter\third_party\gn\gn.exe present
```

`C:\xaocen-engine\src\engine\src\out\host_debug_unopt` 原有配置和输出也存在，
其中已经有 `args.gn` 与历史 `build.ninja`。本轮不删除、不清理 out。

## 4. gn gen 首次阻断与精确原因

首先用现有输出目录执行：

```powershell
gn gen out\host_debug_unopt
```

初次失败不是 CIPD 下载卡死。GN 进入：

```text
build/vs_toolchain.py
  → get_toolchain_if_necessary.py --no-download
```

并返回：

```text
Toolchain is out of date. Run "gclient runhooks" to update the toolchain,
or set DEPOT_TOOLS_WIN_TOOLCHAIN=0 to use the locally installed toolchain.
```

这说明 depot_tools/vpython 已能运行，真正阻断点是默认 Windows toolchain 选择
与当前本地安装状态不匹配，而非 GN 本身或 CIPD 网络活动。

## 5. 受控修复与 GN Gate

未修改仓库文件；只在当前 PowerShell 进程设置本地工具链变量：

```text
DEPOT_TOOLS_WIN_TOOLCHAIN=0
GYP_MSVS_VERSION=2022
GYP_MSVS_OVERRIDE_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools
WINDOWSSDKDIR=C:\Program Files (x86)\Windows Kits\10\
```

本机 VS locator 确认：

```text
Visual Studio 2022 Build Tools 17.14.37516.0
installationPath = C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools
isComplete = true
```

Windows SDK include 目录同时存在 `10.0.22621.0` 与 `10.0.26100.0`；本轮未卸载或
修改 SDK。使用本地 VS path 后再次执行同一输出目录：

```powershell
gn gen out\host_debug_unopt
```

结果：

```text
//out/host_debug_unopt/environment.x64
HOMEDRIVE=C:Done. Made 1466 targets from 413 files in 6934ms
GN_EXIT=0
```

已确认有效文件：

```text
C:\xaocen-engine\src\engine\src\out\host_debug_unopt\build.ninja
size = 347208 bytes
```

因此 `GN GEN = PASS`。

## 6. 当前状态与边界

- 未运行 `ninja flutter_windows.dll` 或完整 Engine 编译。
- 未执行 Flutter fixture。
- 未验证 Flutter frame → ANGLE shared texture → DComp。
- 未接入 XAOCEN Reader。
- 没有删除 `_bad_scm`、patch、Engine source/dependencies，也没有 `git reset`、
  `git clean` 或全量 `gclient sync`。
- Engine worktree 原有 alpha patch 状态保持不变。

本轮 `CURRENT BLOCKER` 不再是 `gn gen`；下一 Gate 的真实风险是 patched Engine
编译阶段的 compile/link/PDB/toolchain 问题，以及尚未执行的运行时 interop。

## 7. 下一步建议

下一阶段应单独执行 patched Engine 的受控 Ninja build；若出现首个真实 compile/link
错误立即停止并记录，不扩大 patch。只有 patched build 成功后，才进入隔离 fixture
和 Shared D3D Texture → ANGLE EGL → DComp interop Gate。
