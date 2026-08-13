# M5.7s.7c-1.4 Visual Root Cause Audit

## 参考原则

本轮只借鉴了参考阅读器的交互原则：阅读页的状态栏/顶部信息应与当前页面表面属于同一视觉层；排版设置应使用正文可用宽度和实际字体度量，而不是通过改变原文或加入空格“修正”视觉效果。`binbyu/Reader` 的显示设置也把字号、首行缩进、段距等排版参数集中在显示设置中；`legado-with-MD3` 强调阅读页与设置页使用清晰的主题层级和紧凑信息组织。本项目继续使用自身 ReaderLocator、UTF-16 文本和现有 relayout 合同。

## ROOT CAUSE — TOP SURFACE

Reader 的 `_effectiveReaderTheme()` 已经为正文解析了 per-book 阅读主题，但 Reader Chrome 仍在外层 `Theme.of(context)` 下绘制，状态栏则同时由 `_syncAndroidSystemUi()` 的 imperative `SystemChrome.setSystemUIOverlayStyle` 和 Reader build 中的 `AnnotatedRegion` 写入。于是首帧可能使用正确的阅读表面，Reader fully mounted 或主题刷新后却被全局 App Theme 再覆盖；深色方案的差异尤其明显。App Shell 此前也没有自己的 system-bar owner。

本次窄修复：

- App Shell 增加唯一的 `AnnotatedRegion<SystemUiOverlayStyle>`，其状态栏 underlay/图标亮度来自当前 Shell surface。
- Reader route 用 `_effectiveReaderTheme()` 包住实际 Reader subtree，使 Chrome、正文和设置入口读取同一 Reader Theme。
- Reader 的 imperative 代码只保留可见性、导航栏、cutout、方向等平台状态；移除第二次颜色/图标样式写入。最终 bar color/icon style 由 Reader subtree 的 `AnnotatedRegion` 负责。
- Chrome visible 仍使用 Chrome surface；Chrome hidden 使用 Reader palette/background surface，符合产品合同。

这不改变 Locator、Info geometry、Insets 或 Reader metrics。

## ROOT CAUSE — JUSTIFY

原实现对负首行缩进计算 `x < 0` 时使用 `width - x` 作为该行 `TextPainter.maxWidth`。这会把段落第一行的可布局宽度扩大到 ReaderBody 之外；不同字体/回退字体的 glyph advance 和标点 side-bearing 会进一步放大右边界不齐的视觉差异。正常 paragraph-last-line 不应 justify；少量中文标点右侧留白属于 glyph optical boundary，不是 paragraph 几何错误。

窄修复保持段落可用宽度不变：

- 负缩进仍只改变第一行 paint origin（悬挂缩进）。
- 负 `x` 的 `TextPainter` 最大宽度固定为正文 `width`，不再把整行扩宽。
- 正缩进继续使用 `width - x`，只为首行保留实际缩进空间。
- paint-style 更新采用相同规则。

源文本、UTF-16 offsets、paragraph boundaries 和最后一行不 justify 合同均不变。

## 结论分类

- 真实 BUG：多个 system-bar/theme owner 导致 App Shell/Reader surface 在 fully mounted 后被覆盖；负缩进扩大首行 layout width。
- 正常行为：justify 的段落最后一行保持自然起始对齐；某些字体的标点 glyph side-bearing 造成极少量 optical 白边，不通过改变 paragraph geometry 修复。

## 验证

- `flutter analyze`：PASS
- 定向 typography/App Shell/Reader Info tests：17 PASS；新增负缩进宽度测试 PASS
- 全量 Flutter tests：551 PASS（修复前全量回归）
- `flutter build apk --debug`：PASS
- `flutter build windows --release`：PASS
- `git diff --check`：PASS（仅换行风格 warning，无 whitespace error）
- Android physical screenshot：本轮未重新连接实体设备；emulator 基础启动已验证，真人深/浅色视觉仍需设备/人工验收。

## 构建产物

- Android APK：`build/app/outputs/flutter-apk/app-debug.apk`
- Windows EXE：`build/windows/x64/runner/Release/xaocen_reader.exe`
