# M5.8a-1 — XAOCEN Reader App Identity

日期：2026-08-15
唯一项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 品牌合同

- 正式产品名：`XAOCEN Reader`
- Android 中文显示名：`晓枨阅读`
- Android package/applicationId：`com.xaocen.xaocen_reader`（保持不变）
- Logo 源：`C:\Users\TOM\Desktop\logo-ico\xaocen-reader.png`
- 项目内源副本：`assets/branding/xaocen-reader-source.png`
- 项目内统一生成图：`assets/branding/xaocen-reader-icon.png`

统一资源从同一 PNG 等比例生成。图标保留白底与 XAOCEN 橙黄色标志，并将画布外角做透明圆角矩形处理；没有拉伸或裁掉主体。Windows ICO 同时包含 16、20、24、32、40、48、64、96、128、256 像素档位。

## 平台接入

### Windows

- `windows/runner/resources/app_icon.ico`：EXE 图标资源。
- `Runner.rc`：ProductName/FileDescription 更新为 `XAOCEN Reader`。
- 原生窗口标题更新为 `XAOCEN Reader`。
- 窗口类图标、Taskbar 图标、Tray `NIM_ADD` 图标均继续复用同一个 `IDI_APP_ICON`，没有建立第二套图标真相。
- 内部文件名、Runner binary name、DataRoot 和 package identity 不变。

### Android

- `mipmap-mdpi` 至 `mipmap-xxxhdpi` 更新为统一生成的 PNG。
- `mipmap-anydpi-v26/ic_launcher.xml` 启用 Adaptive Icon。
- `drawable-nodpi/ic_launcher_foreground.png` 与白色背景资源来自同一 Logo。
- Manifest 使用 `@string/app_name`，实际名称为 `晓枨阅读`，并保留 `android:roundIcon`。

## 验证

| 项目 | 结果 | 证据 |
|---|---|---|
| Windows EXE icon | PASS | Release EXE 资源可提取，透明角与新 Logo 正确 |
| Windows Taskbar icon | PASS | Window class 使用 `IDI_APP_ICON` |
| Windows Tray icon | PASS | `AddTrayIcon` 使用同一 `IDI_APP_ICON` |
| Android icon | PASS | 各密度资源、Adaptive Icon 与 Release APK 构建通过 |
| Android display name | PASS | APK resource 解析为 `晓枨阅读` |
| package identity | PASS | `com.xaocen.xaocen_reader` 未改变 |
| `flutter analyze --no-pub` | PASS | No issues found |
| Full Flutter tests | PASS | 609 tests passed |
| Windows Release | PASS | Patched bundle staged at `artifacts/windows/current/Release/` |
| Android Release | PASS | `build/app/outputs/flutter-apk/app-release.apk` |
| `git diff --check` | PASS | exit code 0 |

本轮没有修改 Reader、Engine、真透明、数据库或其他运行时功能。

## 产物与 Shell 图标收口（2026-08-15）

- 唯一对外 Windows 产物地址固定为：
  `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe`
- `build\windows\x64\runner\Release` 仅是 Flutter 中间输出，不是启动地址。
- 项目内旧的 `artifacts\windows\patched` / `standard` 目录已移出生成边界并保留在本机临时隔离目录，避免被误启动；项目内 `artifacts\windows` 现在只保留 `current`。
- EXE 在创建时显式设置 `WS_EX_APPWINDOW`，并同时设置大/小窗口图标为 `IDI_APP_ICON`，避免任务栏在首帧启动或 Shell 刷新时退回默认 Flutter 图标。
- 当前 canonical EXE 启动检查：窗口标题 `XAOCEN Reader`、`WS_EX_APPWINDOW=true`、`WS_EX_TOOLWINDOW=false`，大小图标句柄均有效；用户已启用的任务栏/托盘设置仍由现有偏好控制。
