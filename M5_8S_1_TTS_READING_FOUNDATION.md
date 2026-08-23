# M5.8s.1 — TTS Reading Foundation

## Scope

第一版 TTS 使用系统语音能力，不连接在线语音服务，也不改变 TXT、章节解析、分页或阅读进度模型。TTS 读取统一的 `ReadableTextSource` 段落抽象，后续可复用到其他可读文本来源。

## Implementation

- `TtsReadingController` 负责单一 Reader 会话的朗读状态：`idle`、`playing`、`paused`、`stoppedAtEnd`。
- `FlutterTtsEngine` 是 Android / Windows 的系统 TTS 平台边界；语速和系统可用 voice 列表均通过该边界处理。
- 段落仅保存本次朗读的 UTF-16 起止区间和文本，不写入第二套阅读进度 truth。
- 默认从当前 vertical 可见 offset 或 paged 已确认 Locator 对应的 offset 开始。
- 完成回调自动推进到下一段，到文档末尾转为 `stoppedAtEnd`。
- 手动滚动、翻页和目录跳转会把 TTS 会话跟随到新的 Reader offset；不会改写 normalized TXT 或 absolute Locator。
- 当前段落用 paint-only 半透明高亮绘制，未参与 layout、metrics 或 pagination。
- Reader dispose / 书籍关闭会停止并释放 TTS engine。
- Android manifest 增加 TTS service package visibility 查询，未申请危险权限。

## Verification

| Contract | Result | Evidence |
|---|---|---|
| TTS WINDOWS | PASS | `flutter_tts` Windows system plugin is included and Windows Release build succeeded |
| TTS ANDROID | PASS | Android Release build succeeded with Android TTS service query |
| START FROM CURRENT LOCATION | PASS | offset-to-segment selection tests; no progress write |
| PAUSE / RESUME | PASS | controller fake-engine tests |
| PREVIOUS / NEXT | PASS | controller navigation tests and Reader controls |
| SPEED | PASS | clamped 0.1–2.0 speech-rate path and Slider UI |
| VOICE SELECTION | PASS | system voice enumeration, locale/name/identifier selection |
| TTS HIGHLIGHT | PASS | paint-only `ReaderTextBlock` / typography highlight tests |
| LOCATOR REGRESSION | PASS | Reader page regression tests; highlight does not relayout or repaginate |
| RESOURCE CLEANUP | PASS | controller dispose stops engine and removes Reader listener |

## Test and build record

- `flutter analyze --no-pub` — no issues.
- `flutter test --no-pub` — **614 tests passed**.
- Windows Release — passed through the single selector script, staged at `artifacts\windows\current\Release`.
- Windows staged executable launch smoke — PASS; it stayed alive for the smoke window and was then closed cleanly.
- Android Release — passed; APK size 60.1 MB.
- `git diff --check` — passed (only existing line-ending normalization warnings were reported by Git).

语音输出依赖目标主机/设备已安装并启用的系统 voice；本轮没有接入网络语音服务。自动化测试覆盖控制器状态、段落定位、voice/rate 调用和资源释放，实际听觉验收仍应在目标 Windows 与 Android 设备上进行。

## Final artifacts

- Windows EXE: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe`
- Android APK: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`

No EPUB, RSS, online voice, or online service work was started in this milestone.
