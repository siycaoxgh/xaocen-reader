# M5.8s.8d — Unified Auto Mode Volume Keys

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 结果摘要

Android 的 AutoRead 与 TTS 共用 `ReaderInputProfile.autoModeVolumeBehavior` 一项设置，默认值为“跟随普通阅读”。没有新增数据库 schema，也没有修改 Windows KeyboardBinding。

设置项“自动模式下的音量键”包含：

- 跟随普通阅读（默认）：音量+ / 音量- 分别执行上一页（或上一视口）/下一页（或下一视口）。若 AutoRead 或 TTS 正在运行，先暂停自动模式，再执行同一次手动导航。
- 控制自动模式：音量+ 暂停/继续当前自动模式；音量- 执行下一步（AutoRead 下一页/视口，TTS 下一段）。
- 调节系统音量：Dart 不声明音量键拦截，交由 Android 系统调节媒体音量。

运行时只根据当前实际活动的 AutoRead/TTS 选择命令目标；没有自动模式时继续使用普通阅读音量键行为。TTS 与系统媒体音量保持不同概念。

## 兼容与持久化

设置存入现有 Reader input profile JSON。旧版本没有该字段时默认跟随普通阅读；旧的逐键配置会迁移为统一行为（全系统音量映射为“调节系统音量”，其他非普通映射为“控制自动模式”）。写入统一设置时清理旧逐键覆盖，避免两套 truth 竞争。

## 验证

| 项目 | 结果 | 说明 |
|---|---|---|
| NORMAL READING PROFILE | PASS | 默认值、普通上一页/下一页路径与现有导航保持一致 |
| AUTO CONTROL PROFILE | PASS | AutoRead/TTS 共用暂停/继续与下一步分派 |
| SYSTEM VOLUME PROFILE | PASS | Android 拦截标志关闭，按键交还系统 |
| AUTOREAD | MANUAL REQUIRED | 已完成状态分派与自动化测试；真实设备音量键长按/单次仍需人工确认 |
| TTS | MANUAL REQUIRED | 已完成当前段/下一段分派；真实设备音量键操作需人工确认 |
| MODE SWITCH | PASS | 同一设置在 Reader 设置页即时写入并刷新输入路由 |
| ANDROID REGRESSION | PASS | `flutter analyze`、定向测试、APK Debug 构建与 emulator-5554 `install -r` 完成；实体按键行为保留人工门槛 |

已执行的定向测试：

- `test/unit/reader_input_bindings_repository_test.dart`
- `test/unit/reader_input_router_test.dart`
- `test/unit/reader_input_test.dart`
- `test/widget/reader_settings_responsive_test.dart`
- `test/widget/reader_automation_overlay_test.dart`

以上定向测试全部通过。全量 Flutter 测试完成 631 项通过、2 项失败；失败来自既有目录滚动用例基线，不涉及本轮音量键代码，未将其伪报为全量 PASS。

Android Debug APK：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

已对 `emulator-5554` 执行非破坏性 `adb install -r`；未 uninstall、未清除数据、未运行 integration runner 覆盖普通 APK。
