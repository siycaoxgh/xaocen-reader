# XAOCEN M5.7 产品状态、构建产物与基线汇总

> **历史验收记录：**本文冻结 M5.7 当时的结果，不再代表当前测试总数、
> 最新产物或后续 M5.8/M5.9 能力。当前发布和签名状态统一见
> `docs/RELEASE_BASELINE_2026_09_18.md`。

更新时间：2026-08-16
唯一项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 1. 当前构建产物

| 平台 | 类型 | 状态 | 地址 |
|---|---|---|---|
| Windows | Release EXE | 最新保留 | `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe` |
| Android | Release universal APK | 最新保留 | `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk` |

Android 包信息：

- applicationId：`com.xaocen.xaocen_reader`
- version：`4.5.8`（Android versionCode/build number：`5`）
- APK：约 61.5 MiB（64,489,642 bytes）；当前图标留白版本 SHA-256：
  `DEBC4EEB8873A1F610BFC9270B7A10963C475EF8DBDDA6BE1FF3247C15B4FF9D`
- ABI：`arm64-v8a`、`armeabi-v7a`、`x86_64`，同一 universal APK 可用于实体 arm64 设备和当前 x86_64 Emulator。
- 标准化构建入口：`tool\verify.ps1` 的 Android gate 与 `tool\android_emulator\xaocen_emulator.ps1 -Action install` 均使用此 Release APK。

本次体积优化来自 Release 构建与 Dart/icon tree-shaking：旧 Debug APK 约 191.31 MiB，已移出当前项目产物；没有修改 Android Reader 功能或用户数据。

## 2. 构建产物清理

已删除：

- 旧 Debug APK 及其重复输出目录
- 重复的 Android Release APK
- 旧 Windows Debug 输出、PDB/中间产物
- 旧 Windows `Release.zip`
- 不再需要的 Android release native-debug-symbols 压缩包

保留：

- 最新 Windows Release EXE
- 最新 Android Release universal APK
- 源码、测试、报告、用户数据、Engine checkout、`windows_engine_patches`

未执行 `git reset`、`git clean`、源码删除、DataRoot/数据库/书库清理。

## 3. 已完成能力

以下以现有报告和自动化证据标记为“已完成/自动化通过”，不等同于所有物理视觉项目均已人工通过：

- Reader vertical/paged、UTF-16 absolute Locator、进度恢复与 TXT 内容链路
- Reader Chrome、Reader Info、Android status/navigation/cutout/orientation 语义
- AutoRead、音量键映射、屏幕保持/智能常亮状态机
- App Shell Light/Dark live theme 与 Root navigation
- 本地 TXT metadata、手动 metadata 编辑、手动本地封面及 placeholder fallback
- Windows keyboard capture、OEM/numpad/navigation keys、Keyboard Boss、MouseChord
- Windows Tray 左键恢复、右键菜单、退出、Explorer 重注册
- Windows DesktopColorSampler、Eyedropper mode/UI 基础能力
- Windows localized font display/preview、设置页响应式基础能力
- 本次取色中文文案、Popup/Dialog 圆角、metadata 编辑表单对比度

当前自动化基线：`flutter analyze --no-pub` 通过；全量 Flutter tests 为 650 passed；Windows Standard Release 构建与 8 秒启动 smoke 通过。

## 8. M5.8 icon and repository cleanup (2026-08-16)

- Android adaptive foreground now uses only the transparent orange mark in the
  Android safe zone; the white rounded background is declared separately. The
  Release APK was installed on `emulator-5554` and the launcher showed the
  complete mark with the label `晓枨阅读`.
- The pre-4.0 desktop checkout was moved to
  `archive\legacy_pre_4_0_20260816\xaocen-reader`. Its source and durable
  documents remain available, while generated caches and old APK/EXE builds
  were moved out of the active repository. User databases and application data
  were not touched.
- The active project map is documented in `docs\REPOSITORY_LAYOUT.md`; the
  cleanup/code audit is recorded in
  `M5_8_ICON_BUILD_REPOSITORY_CLEANUP.md`.

## 4. 必须保持的产品真相

- TXT 原文、normalized 内容和 UTF-16 locator 不因 UI/metadata 改动而重写。
- `collectionId`/source identity 与显示 title/author/cover 分离。
- Reader progress、bookmark、history、ReaderPreferences 是现有持久化合同。
- KeyboardBinding、MouseChord、Tray command 保持不同来源模型。
- Android 与 Windows 平台能力只影响 Shell/平台层；平台中立 Reader Theme/UI 不建立第二套颜色真相。
- Background/foreground true transparency 已进入生产 Reader 集成，并由 8d-4-FINAL 人工验收通过。

## 5. 待补充 / 待规划（不是失败，也不是完成）

- `M5.7 PRODUCTION STABILIZATION`：自动化通过，但因 Windows 人工视觉/本地桌面验收仍标记 **REOPENED**。
- Android 实体设备完整人工清单：**待人工复核**；Emulator 可用于常规 smoke/integration。
- Windows true transparency / patched Engine / DComp Reader integration：**已完成 + 人工验收通过**（详见第 7 节）；不再列为待补充/计划项。
- Qingshan 原始 TXT 的章节缺失/重复：诊断已完成，遵循原文件顺序；是否增加用户可见提示属于**待规划**，不自动重排。
- Android split-per-ABI 发布包、商店签名和发布流水线：**待规划**。当前先保留 universal Release APK，避免模拟器/真机安装分叉。

## 6. 后续变更闸门

任何后续功能必须先阅读 `docs/PRODUCT_BASELINE_FREEZE.md`，并为受影响合同增加测试；未通过 analyze、全量 tests、目标平台 Release build 和 `git diff --check`，不得把结果标记为完成。计划项只能使用“待补充/待规划/计划中”，不得写成 FAIL 或 PASS。

## 7. M5.7s.8d-4-FINAL — Windows True Transparency Baseline Freeze (2026-08-15)

Windows True Transparency is now **COMPLETED + MANUAL ACCEPTANCE PASSED**.
This section supersedes the earlier deferred/planned transparency entry.

Production render path:

```text
Patched Engine -> ANGLE app-owned D3D11 texture -> GPU CopyResource
-> premultiplied DirectComposition -> true desktop transparency
```

Background opacity and Reader foreground/text color are separate contracts.
BG 0% exposes the real desktop while Reader text keeps the effective Reader
Theme/custom RGB and foreground alpha remains 100%.

The sole current Windows Release output is:

```text
C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe
```

`engine-selection.json` beside the executable records whether that staged
bundle is `Standard` or `Patched`. Standard Engine remains the supported
opaque fallback. No transparency implementation changes are planned under
this freeze.

Final gates: `TRUE TRANSPARENCY BASELINE = PASS`,
`MANUAL ACCEPTANCE = PASS`, `STANDARD FALLBACK = PASS`.

## M5.8s.7 — TTS final baseline (2026-08-15)

The M5.8 TTS foundation through UX/preferences closure is complete for the
automated contract. TTS uses the existing readable-text source and absolute
UTF-16 Reader locator, with no independent TTS progress truth. Continuous
segment/chapter follow, vertical/paged follow, manual-navigation restart,
sleep-timer modes, cleanup, system voice selection, speech-rate persistence,
and missing-voice fallback are covered by tests and build validation.

Android MediaSession/foreground-service and notification command routing are
implemented and compile. Physical screen-off/background, Bluetooth headset and
lock-screen controls remain `MANUAL REQUIRED`. Windows minimize/Tray speech also
remains `MANUAL REQUIRED`; Windows native system media control is `DEFERRED`.

Current final build evidence:

- Android Release: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`
- Windows Release build: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe`
- Android Emulator `emulator-5554`: latest Release APK installed with `adb install -r` and launcher smoke passed.

No EPUB or RSS work is included in this baseline.
