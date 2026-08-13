# M5.7s.7c-1.5 Emulator Visual Surface Closure

## Scope

本轮只处理 Android App Shell 顶部 surface、Paged Reader 顶部 surface 与 Reader Info divider。未修改 Locator、Reader Info slots、system-bar/cutout/orientation 语义，也未处理 justify、battery、Windows 或 Engine/DComp。

## Root cause

- **App Shell 顶部白条**：透明状态栏下方的 Scaffold/安全区 underlay 与 `_ShellHeader` 使用了不同 surface，导致状态栏、顶部安全区和标题区出现色块边界。Shell Scaffold 现在使用 header surface，正文内容单独使用 body background。
- **Paged 顶部色差**：Paged/Vertical 共用 Reader 外壳，但 `ReaderInfoScaffold` 的顶部安全区/信息区没有显式继承操作 Chrome surface。现改为 Chrome 可见时统一使用 `_readerTopSurface`，并移除 Reader 内重复的 Android status-bar surface 层；ReaderBody 的分页布局没有被改动。
- **Divider 不可见**：divider 的几何高度与开关语义没有形成稳定的绘制合同，且 info content 状态可能抑制 divider。现改为固定至少 1 logical px 的 TopDivider/BottomDivider；两个开关只切换颜色为透明/可见，不改变 geometry，颜色由正文前景派生并与背景保持对比。

## Implementation

- `lib/app/app_shell_page.dart`
  - Scaffold `backgroundColor` 使用 shell/header surface。
  - Shell body 使用 `Material(color: scheme.background)`，避免中间层破坏 ListTile ink/material 语义。
- `lib/reader/reader_chrome.dart`
  - `ReaderInfoScaffold.regionBackgroundColor` 用于 Chrome 可见时的顶部/底部预留区。
  - Divider 保持 Top/Bottom 独立、geometry 稳定、最小 1 logical px。
- `lib/reader/reader_page.dart`
  - Chrome 可见时 Reader Scaffold/Info region 使用同一 `_readerTopSurface`。
  - 删除重复的 Android status-bar `Positioned` surface，避免第二个 inset 色块。

## Emulator evidence

设备：`emulator-5554`，Android 15 / API 35，1080×2400，420 dpi，60 Hz SwiftShader。

截图证据（临时目录）：

- `C:\Users\TOM\AppData\Local\Temp\m57s15_final_home_dark.png`
- `C:\Users\TOM\AppData\Local\Temp\m57s15_home2.png`
- `C:\Users\TOM\AppData\Local\Temp\m57s15_reader2.png`
- `C:\Users\TOM\AppData\Local\Temp\m57s15_hidden2.png`

观察结果：最终 Dark App Shell 的状态栏与标题 surface 连续；Paged 截图中状态栏至顶部 Chrome 使用同一 Chrome surface。已有隐藏 Chrome 截图显示信息区与正文的独立布局；但本轮没有在模拟器中通过 UI 明确设置并保存“TopInfo/BottomInfo + 两条 divider 开启、Chrome 隐藏”这一精确组合，因此 divider 的最终肉眼像素结果仍标记为人工确认项，而不是用 widget test 冒充视觉通过。

## Verification

- `flutter analyze`: PASS（无错误；仅现有 AGP 提示/ColorScheme.background 弃用信息）。
- `flutter test`: PASS，552 tests。
- `flutter build apk --debug`: PASS。
- `adb -s emulator-5554 install -r build\\app\\outputs\\flutter-apk\\app-debug.apk`: PASS；未 wipe、未 pm clear、未 uninstall。
- `flutter build windows --release`: PASS。
- `git diff --check`: PASS（仅 CRLF 转换提示）。
- Drift schema：未修改。

## Visual gate status

- **APP SHELL TOP SURFACE = PASS**（模拟器 Light/Dark 截图与像素检查）。
- **VERTICAL/PAGED TOP CONSISTENCY = PASS**（共同 Reader 外壳 surface；Paged 截图复核，Vertical ReaderBody 路径未改）。
- **DIVIDER PIXEL VISIBILITY = MANUAL REQUIRED**（绘制合同与 widget 几何/颜色测试已通过；精确用户偏好组合的模拟器截图尚未完成）。

## Artifacts

- Windows EXE: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android APK: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

本轮完成后停止，不进入 justify/negative first-line indent。
