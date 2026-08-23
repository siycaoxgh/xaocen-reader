# M5.8 — App Identity / Icon / Version Consolidation

日期：2026-08-15
唯一项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 合同

- Windows 用户可见产品名：`XAOCEN Reader`
- Android 用户可见产品名：`晓枨阅读`
- 用户可见版本：`4.5.8`
- Android applicationId：`com.xaocen.xaocen_reader`（保持不变）
- 单一图标源：`C:\Users\TOM\Desktop\logo-ico\新建文件夹\xaocen-reader_cropped_rounded.ico`

Android 的 Manifest label、MaterialApp title、Launcher/Adaptive Icon、TTS
媒体会话和通知说明统一使用中文名；Windows 窗口、EXE 元数据、任务栏和
托盘继续使用英文产品名。

## 产物

- Android Release：`build\app\outputs\flutter-apk\app-release.apk`
- Windows Patched Release：`artifacts\windows\current\Release\xaocen_reader.exe`

历史 changelog 中的旧版本号是历史记录，不代表当前构建版本；当前源版本只
由 `pubspec.yaml` 的 `4.5.8+5` 提供。

## 最终验证

| Gate | Result |
|---|---|
| WINDOWS ICON | PASS — Runner resource SHA-256 equals the supplied ICO |
| TASKBAR ICON | PASS — window class and `WM_SETICON` use `IDI_APP_ICON` |
| TRAY ICON | PASS — `AddTrayIcon` loads `IDI_APP_ICON` |
| ANDROID ICON | PASS — mdpi through xxxhdpi generated from the ICO |
| ADAPTIVE ICON | PASS — adaptive XML uses generated foreground/background |
| DISPLAY NAME | PASS — Windows `XAOCEN Reader`; Android `晓枨阅读` |
| VERSION 4.5.8 | PASS — Android `versionName=4.5.8`, Windows visible version `4.5.8` (build `5`) |
| PACKAGE ID PRESERVED | PASS — `com.xaocen.xaocen_reader` |
| OLD ICON CLEANUP | PASS — no Flutter logo marker remains in active platform resources |
| `flutter analyze --no-pub` | PASS |
| Full Flutter tests | PASS — 643 tests |
| Android Release | PASS — installed with `adb install -r` on `emulator-5554` |
| Windows Patched Release | PASS — staged through the official engine-selection script |
| `git diff --check` | PASS — only existing line-ending warnings |
