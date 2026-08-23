# M5.8s.8e-1 — Windows Reader Open Crash

## 诊断结论

ROOT CAUSE = `ReaderPage` 为新文档设置 TTS source 时，`TtsReadingController.setSource()` 无条件异步调用 `stop()`。Reader 尚未开始朗读，Windows `flutter_tts_plugin.dll` 却收到一次空闲 stop；该原生 provider 在没有活动 utterance 时发生 `0xc0000005` 访问冲突。Reader dispose 路径还会再次无条件调用同一 native stop，因此返回书架也可触发同类崩溃。

Windows Application Error 事件的第一条真实 blocker：

- Faulting application: `xaocen_reader.exe`
- Faulting module: `artifacts\\windows\\current\\Release\\flutter_tts_plugin.dll`
- Exception: `0xc0000005` (access violation)
- Reproduced at Reader open and again during Reader close before the lifecycle guard was added

这不是 TXT、UTF-16 Locator、分页、ReaderProgress 或透明渲染错误。

## 最小修复

- 只有 TTS state 为 `playing` / `paused` 时，替换 source 才调用 native stop。
- `FlutterTtsEngine` 记录是否真的启动过 utterance；空闲时的 `stop()` 与 `dispose()` 不再触碰 Windows native provider。
- `speak()` / `resume()` 的 platform exception 被收敛到 TTS controller，provider 不可用时 Reader 保持可用并回到安全状态。
- 未修改 Android native 实现、TXT parser、Locator、pagination、ReaderProgress 或透明 Engine。

## 正式产物

构建入口：`tool\\build_windows_engine.ps1 -Engine Standard -Configuration Release`

正式 Windows 产物目录：

`C:\\Users\\TOM\\Desktop\\xaocen-reader-v4\\xaocen_reader\\artifacts\\windows\\current\\Release`

EXE：

`C:\\Users\\TOM\\Desktop\\xaocen-reader-v4\\xaocen_reader\\artifacts\\windows\\current\\Release\\xaocen_reader.exe`

## 验证

- Windows 启动：PASS
- 正式 Release 打开本地 TXT Reader：PASS
- 返回书架：PASS
- 第二次进入同一本书：PASS
- Windows TTS 控制条打开并开始朗读：PASS
- TTS stop 后 Reader 仍正常：PASS
- TTS 不可用 fallback（`_UnavailableVoicesEngine` 定向测试）：PASS
- `flutter analyze --no-pub`：PASS
- `flutter test test/unit/tts_reading_controller_test.dart`：PASS
- `flutter build apk --debug`：PASS（`build\\app\\outputs\\flutter-apk\\app-debug.apk`）
- `git diff --check`：PASS（仅已有 CRLF 提示，无 whitespace error）

## 最终状态

WINDOWS READER OPEN = PASS
SECOND OPEN = PASS
WINDOWS TTS = PASS
TTS FAILURE FALLBACK = PASS
TRUE TRANSPARENCY = PASS（Reader 进入路径未改；透明实现未重构）
ANDROID REGRESSION = PASS（Android Debug 构建与共享 TTS 定向测试通过；实体设备人工项沿用既有基线）

本轮未处理 Auto UI、TTS Overlay、2.5 秒隐藏、设置页背景或 UI Alignment。
