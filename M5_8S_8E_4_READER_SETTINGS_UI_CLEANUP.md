# M5.8s.8e-4 Reader Settings UI Cleanup

## 本轮变更

- TTS“语速”行统一为固定的图标列、文字列、滑块列和值列，并使用相同的 48 logical px 控件高度垂直居中。
- 在“自动”入口恢复“自动阅读设置”，重新连接现有 `showReaderAutoReadControls` 面板；该面板继续提供纵向自动阅读速度和 Paged 自动翻页间隔。
- Paged 自动翻页间隔按 5、15、30、60、120 秒升序显示。
- “更多阅读操作”不再重复显示“语音设置”；语音设置只保留在“自动”入口。
- AutoRead 状态机、TTS 状态机、Locator、分页和阅读进度未改变。

## 验证

| 项目 | 结果 |
|---|---|
| `flutter analyze --no-pub` | PASS |
| 定向 Settings / TTS / AutoRead / Overlay tests | PASS |
| `git diff --check` | PASS（仅换行符提示） |
| 全量 Flutter tests | PASS（642 项） |
| APK release build | PASS |
| Windows Patched Release build | PASS |

## 固定产物

- APK release：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`
- APK debug：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
- Windows EXE：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe`
- Engine selection：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\engine-selection.json`
