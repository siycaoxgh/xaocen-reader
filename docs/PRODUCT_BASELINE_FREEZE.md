# XAOCEN Production Baseline Freeze

> 2026-10-08 R05 addendum: the user approved a cross-platform application ID
> of `com.xaocen.reader`. The R05 isolated branch updates Android,
> HarmonyOS NEXT, and iOS/iPadOS project identities accordingly. This is a
> new Android application identity; it does not provide in-place update or
> automatic app-sandbox data migration from the historical
> `com.xaocen.xaocen_reader` release. R05 Debug/HAP builds are validation
> artifacts only and have not been released. The 2026-08-15 M5.8 identity row
> below remains a historical production snapshot.

> 2026-09-18 current addendum: the active product is `4.5.8+5`, Drift schema
> `21`. TXT/EPUB/ReaderContent/Profile/Responsive Shell, RSS/Atom, WebArticle
> minimal runtime, WebBook product loop/on-demand chapter cache, TTS/AutoRead,
> and Windows true transparency are present in the current source. XAOCEN
> Account is integrated but still requires real-service and OS credential-store
> acceptance before production freeze. For current release/artifact truth and
> documentation precedence, read `RELEASE_BASELINE_2026_09_18.md`. Counts,
> paths and “planned” labels in older amendments are historical snapshots.

## 基线范围

本文件用于保护已经完成或已自动化验证的 Reader 功能，避免后续新增功能改变既有产品合同。它不是 Git freeze，也不禁止修复真实 bug；所有改动必须可追踪、可回归。

## M5.8 — App identity baseline (2026-08-15)

- Official desktop product name: `XAOCEN Reader`.
- Android user-visible name: `晓枨阅读` for launcher, recents, system app
  information, and the TTS media/notification surfaces.
- User-visible version: `4.5.8`; Android internal build number: `5`.
- Android applicationId remains `com.xaocen.xaocen_reader`.
- The supplied `xaocen-reader_cropped_rounded.ico` is the single icon source;
  Windows and Android resources are generated from it without changing aspect
  ratio or redesigning the mark.

## 不可隐式改变的合同

1. Reader 位置以 absolute UTF-16 locator 为唯一真相；Chrome、Reader Info、主题、Insets、方向变化必须 exact restore。
2. TXT 原文、normalized 文本、chapter order 不因显示 metadata 或 UI 调整而改变。
3. `collectionId`、sourcePath、progress、bookmark、history、ReaderPreferences 不能因 metadata/cover/UI 改动丢失。
4. Reader Body、TopInfo、BottomInfo、Chrome 的主题来源必须是同一 effective Reader Theme；不得新增 hardcoded surface。
5. KeyboardBinding、MouseChord、Tray、Eyedropper 是独立平台输入/窗口能力，不得互相序列化或污染。
6. Android system bars/cutout/orientation 与 Windows window/tray/input 属于平台层；不能把平台实现泄漏到 Domain。
7. True transparency/DComp/Engine patch 已完成生产接入并冻结；后续改动必须走独立 revision guard、interop、视觉和回归验证，不得绕过基线直接重构。

## 以后每次改动的最小要求

- 先列出受影响合同与不受影响合同。
- 为行为变化增加 unit/contract/widget 或平台测试。
- 运行 `flutter analyze --no-pub`、`flutter test --no-pub`、目标平台 Release build 和 `git diff --check`。
- Android/Windows 构建产物必须来自唯一根目录：
  `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
- 不使用历史相似目录，不执行 `git init`，不丢弃用户 worktree 修改。
- 只有真实证据支持时才标记 PASS；无法验证的视觉/物理项目写 MANUAL REQUIRED 或 DEFERRED。
- 计划中的能力写“待补充/待规划/计划中”，不写 FAIL，也不写完成。

## 构建发布规则

- 日常 Android 安装优先使用 Release universal APK；Debug 包只在明确需要调试时临时生成，测试后删除。
- Windows 对外验证使用 `artifacts\windows\current\Release\xaocen_reader.exe`；`build\windows\x64\runner\Release` 仅为中间构建目录。
- 每次发布只保留最新 APK/EXE；旧包、重复包、PDB/OBJ/ZIP 属于可重新生成产物，可在确认路径后清理。
- 不清理 Engine source/dependencies、`windows_engine_patches`、DataRoot、SQLite、书库或测试 TXT corpus。

## M5.7s.8d-4-FINAL — Windows True Transparency Baseline Freeze (2026-08-15)

This amendment supersedes the earlier transparency spike/deferred notes in
this document. Windows true transparency is **COMPLETED — MANUAL ACCEPTANCE
PASSED**.

Frozen production path:

```text
Patched Engine
  -> ANGLE app-owned D3D11 BGRA8 texture
  -> GPU CopyResource
  -> premultiplied DirectComposition swapchain
  -> real desktop transparency
```

Background opacity (0–100%) is independent from Reader foreground/text RGB;
foreground alpha remains 100% in this baseline. Light, dark, and custom Reader
text colors remain authoritative at every background opacity, including BG 0%.
Borderless mode uses the native DWM border removal path while retaining native
drag and resize hit testing.

The only externally supported Windows artifact directory is:

```text
C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\
```

The adjacent `engine-selection.json` is the build-selection truth. Standard
Engine remains the opaque fallback and must continue to launch without the
alpha path.

Final gates: `TRUE TRANSPARENCY BASELINE = PASS`,
`MANUAL ACCEPTANCE = PASS`, `STANDARD FALLBACK = PASS`.

## M5.8s.8-FINAL — TTS / AutoRead Baseline Freeze (2026-08-15)

The TTS and AutoRead contracts are frozen with no new feature work in this
amendment. Both modes consume the existing Reader locator stream and remain
mutually exclusive; neither creates a second reading-progress truth.

Frozen product behavior:

- Windows and Android system-voice TTS, with current-location start,
  pause/resume/stop, previous/next, continuous segment/chapter follow,
  vertical/paged follow, rate changes that preserve the current UTF-16 speech
  offset, and end-of-book stop;
- one Reader `自动` entry and one shared automation overlay for AutoRead/TTS;
  the overlay uses a 2.5-second inactivity hide timeout and can be recalled by
  Reader interaction;
- 15/30/60-minute and current-chapter-end TTS sleep timers, with cleanup on
  Reader/App disposal;
- one Android automatic-volume-key policy with the three frozen profiles:
  follow normal reading, control the active automatic mode, or return keys to
  Android system volume handling;
- Android MediaSession/foreground notification controls and unified command
  routing. Physical lock-screen/earbud verification remains MANUAL REQUIRED;
  the AVD's injected `KEYCODE_MEDIA_*` path was not routed to XAOCEN and is
  recorded as manual-required rather than a false PASS;
- Windows TTS provider failures fall back to TTS unavailable without blocking
  Reader startup. Windows native system-media-control integration remains
  DEFERRED.

Final automated gates for this freeze: `flutter analyze --no-pub` PASS,
`flutter test --no-pub` PASS (642 tests), Android Release build PASS, Windows
Patched Release build and launch smoke PASS, and `git diff --check` PASS
(existing line-ending warnings only).

Canonical release outputs remain under the single XAOCEN project root:

```text
C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk
C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe
```

The frozen Windows true-transparency baseline remains PASS and is not changed
by TTS/AutoRead work. EPUB and RSS remain planned, not PASS or FAIL.

## M5.8s.7 — TTS Final Validation & Baseline Freeze (2026-08-15)

TTS is frozen as a first-generation system-voice capability. It consumes the
shared readable-text/Reader locator stream; it does not create a second reading
progress store and does not modify TXT normalization, chapter parsing,
pagination, UTF-16 locator semantics, or ReaderProgress.

Frozen capabilities:

- current-location start, pause/resume/stop, previous/next, continuous
  segment/chapter advance, vertical/paged follow, end-of-book stop;
- system voice selection, persisted speech rate/voice preferences and safe
  fallback when a saved voice is unavailable;
- session sleep timer (15/30/60 minutes or current-chapter end), with timer
  cleanup on Reader/App disposal;
- Android MediaSession/foreground-service path and notification controls.

Validation policy:

- automated TTS, locator, progress, cleanup, theme, and build gates passed;
- Android screen-off/background, physical Bluetooth headset/lock-screen media
  keys, and live Windows minimize/Tray speech require real-device/manual
  acceptance and are not marked PASS here;
- Windows native system-media-control integration remains DEFERRED, as recorded
  in the M5.8s.5 report; existing keyboard/tray/input contracts are protected.

This freeze adds no EPUB/RSS functionality and does not change the existing
Windows true-transparency baseline.
