# M5.8s.8-REVIEW — TTS / Auto Mode 阶段汇总

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

本轮为只读阶段审阅，没有修改生产代码、没有新增功能，也没有重新构建产物。结论基于 8a、8b、8d 报告、现有代码、定向测试记录和 M5.8s.7 基线报告；仓库中未找到独立命名为 `M5_8S_8C_*.md` 的报告，因此 8c 以代码和 `reader_automation_overlay_test.dart` 为证据。

## 1. 四个任务分别修改了什么

### 8a — Windows TTS Launch Regression

- 修复 Windows `flutter_tts` SAPI voice enumeration 的 native 崩溃风险。
- 对 COM/SAPI 初始化、voice token 可选属性、HRESULT、资源释放和错误结果注册增加保护。
- Dart TTS 边界在 provider 不可用时降级为空 voice 列表，不阻塞 Reader 启动。
- Android TTS/MediaSession 路径未改动。

### 8b — TTS Live Speech Rate

- 播放中改变语速时，记录当前活动段和绝对 UTF-16 speech offset。
- 停止当前 utterance，应用新语速，只朗读剩余 substring，再把平台进度映射回原 Reader offset。
- 不重新朗读已播的大段文本，不改变 Locator、分页或 ReaderProgress。

### 8c — Unified Auto Mode UI

- 底部 Reader Chrome 统一为 `目录 | 自动 | 书签 | 更多`。
- “自动”入口打开 AutoRead / TTS 两个模式选择，并保留 TTS 详细设置入口。
- AutoRead 和 TTS 使用同一个 `ReaderAutomationOverlay` 控制条 Shell，显示模式、速度、暂停/继续、停止。
- 活动超过 2.5 秒后自动隐藏，再次 Reader 交互时重新显示。

### 8d — Unified Auto Mode Volume Keys

- 增加统一的 `AndroidAutoModeVolumeBehavior`：跟随普通阅读、控制自动模式、调节系统音量。
- 设置保存在现有 Reader input profile JSON；旧逐键配置兼容迁移，避免产生第二套 truth。
- Android 活动自动模式时按统一策略路由到 AutoRead 或 TTS；Windows KeyboardBinding 未改动。

## 2. 主要文件

- Windows TTS provider：`pubspec.yaml`、`third_party/flutter_tts/`、Windows plugin 注册/构建文件。
- TTS 状态与连续阅读：`lib/domain/reader/tts_reading_controller.dart`、`lib/domain/reader/tts_readable_text.dart`。
- TTS UI/设置：`lib/reader/tts_controls.dart`、`lib/reader/reader_page.dart`。
- 统一自动入口与控制条：`lib/reader/reader_chrome.dart`、`lib/reader/reader_automation_overlay.dart`。
- AutoRead/TTS 互斥与 Reader 路由：`lib/reader/reader_page.dart`。
- 音量键模型与持久化：`lib/domain/reader/reader_input_bindings.dart`、`lib/data/repositories/reader_input_bindings_repository.dart`。
- 相关测试：`test/unit/tts_reading_controller_test.dart`、`test/unit/reader_input_bindings_repository_test.dart`、`test/widget/reader_automation_overlay_test.dart`、`test/widget/reader_settings_responsive_test.dart`。

## 3. 当前最终用户可见行为

- Reader 底部显示 `目录 | 自动 | 书签 | 更多`。
- 点击“自动”可选择“自动阅读”或“语音朗读”；TTS 设置包含声音、语速和定时停止。
- 朗读从当前 Reader 位置开始，支持连续段落/章节、暂停、继续、上一段、下一段、停止和语速调整。
- 语速播放中调整时，最迟在当前短 segment 内生效，并从当前 speech offset 继续。
- 活动自动模式显示统一悬浮控制条；2.5 秒无操作后隐藏。
- 自动模式运行时，AutoRead 与 TTS 不同时运行。

## 4. Android / Windows 支持情况

| 平台 | 当前支持 | 尚需人工确认 |
|---|---|---|
| Android | TTS、统一 Auto 入口/控制条、三档自动模式音量键策略、后台/Foreground Service 代码路径已存在；Debug/Release 构建和 emulator 安装记录通过 | 真机音量键、息屏、后台持续朗读、Audio Focus、锁屏/通知媒体控制、蓝牙耳机 |
| Windows | TTS provider 启动崩溃已修复；统一 Auto UI 为共享 Flutter UI；语速剩余段重启逻辑已实现 | SAPI 实际发声和实时语速听感、最小化/Tray 后持续朗读；Windows 原生媒体控制仍 DEFERRED |

## 5. AutoRead 与 TTS 互斥规则

- 从 Auto 入口启动 AutoRead：若 TTS 非 idle，先停止 TTS，再启动当前 vertical/paged AutoRead。
- 从 Auto 入口启动 TTS：若 AutoRead 非 idle，先停止 AutoRead，再从当前 Locator 位置开始/继续 TTS。
- 打开 TTS 详细设置会暂停正在运行的 AutoRead。
- 手动导航按现有 Reader contract 暂停自动模式，并继续使用唯一 Locator；不创建 TTS 阅读进度。

## 6. “自动”入口和悬浮控制条

- 正式入口：底部统一 Chrome 的“自动”。
- Auto Hub：自动阅读、语音朗读、语音设置；没有重复的“开始朗读”主按钮。
- 控制条：AutoRead 显示当前速度，TTS 显示当前语速；两者共用位置、尺寸、圆角、动画和暂停/继续/停止操作。
- 2.5 秒隐藏由共享 `ReaderAutomationOverlay` 计时器触发；生产环境只保留这一套隐藏计时器。

## 7. 音量键三个模式

1. **跟随普通阅读（默认）**：音量+ 上一页/上一视口，音量- 下一页/下一视口；有自动模式时先暂停，再执行同一次手动导航。
2. **控制自动模式**：音量+ 暂停/继续当前 AutoRead 或 TTS；音量- 执行下一步（AutoRead 下一页/视口，TTS 下一段）。
3. **调节系统音量**：Dart 不声明 volume key interception，交还 Android 系统媒体音量处理。

没有 AutoRead/TTS 运行时，继续使用普通阅读的原有音量键命令。TTS 语速不是系统音量。

## 8. 语速实时调整规则

播放中修改语速不会从整段开头重读：控制器保存当前活动段和绝对 UTF-16 offset，停止当前 utterance，设置新 rate，只提交剩余文本。暂停/idle 时只保存新 rate，下一次继续/开始时使用。逻辑和位置连续性有自动测试；实际听感仍需人工确认。

## 9. 自动 PASS 项

根据既有报告和定向测试记录：

- Windows 启动崩溃保护、TTS provider failure fallback：PASS。
- TTS controller 的连续阅读、章节边界、定时器、语音/语速偏好、资源释放：自动测试 PASS。
- Live rate 的 offset-preserving restart、Locator 不变：自动测试 PASS。
- 统一 Overlay 的 AutoRead/TTS 共用外观、2.5 秒测试计时、Auto Hub 两模式入口：widget tests PASS。
- 音量键统一设置的默认值、持久化、旧配置迁移、三种策略分派：定向测试 PASS。
- 静态分析、Android Debug 构建及 emulator `install -r`：既有记录 PASS。

注意：本次最终回归的全量 Flutter 测试为 **642 项全部通过**；此前 631/2 的阶段性记录不再代表最终冻结状态。

## 10. MANUAL REQUIRED

- Android 实体音量键：三种模式、AutoRead/TTS 目标、长按 repeat 是否只产生产品允许的命令。
- Android 真机/模拟器真实语音：中文发音、0.5x/1x/2x 连续切换的可听差异。
- Android 息屏、后台持续朗读、Audio Focus 抢占与恢复。
- Android 锁屏/通知栏/蓝牙耳机 Play/Pause、Next、Previous。
- Windows SAPI 实际发声、播放中语速听感、最小化/Tray 后继续朗读。
- Reader 关闭和 App 退出后的真实系统资源释放。

## 11. DEFERRED / 未完成项

- Windows 原生系统媒体控制：DEFERRED，未为此扩展 native 架构。
- Android/Windows 的真实硬件语音、蓝牙和息屏验收：未完成，保持 MANUAL REQUIRED。
- 仓库缺少独立的 `M5_8S_8C` 阶段报告，8c 目前只能由代码和 widget tests 追溯。
- 全量测试仍有 2 个既有目录滚动失败，尚未在本轮处理。
- 未开始 EPUB、RSS、蓝牙媒体键新开发或 UI Alignment。

## 12. 重复 UI、临时逻辑与旧入口审计

- **当前可见 UI**：没有同时显示两个自动控制条；统一底部主入口和统一悬浮条各一套。
- **保留的死代码**：`ReaderChrome` 内仍保留一套 `Offstage(offstage: true)` 的旧底部 action subtree，其中包含独立“自动阅读”和“朗读”按钮；它当前不可见，但尚未删除。
- **旧测试/兼容入口**：`showReaderMorePreview` 中保留 `XAOCEN_LEGACY_TTS_TILE` 编译期开关，默认关闭；打开后会显示“朗读当前未实现”的旧禁用 tile，不属于正常产品入口。
- **设置入口**：TTS 详细设置可从 Auto Hub 和“更多”进入，这是同一设置页的两个低频入口，不是两个“开始朗读”入口。
- **兼容数据**：`autoReadVolumeActions` 仍保留作为旧数据迁移/回退读取，统一设置写入后会清理旧覆盖；不是新的持久化 truth。

## 阶段结论

TTS/Auto 的核心代码和统一 UI 已形成可继续验收的阶段基线；自动化验证覆盖了状态、持久化、Locator 连续性和主要 UI 结构。真实语音、实体音量键、息屏/后台、蓝牙媒体控制和 Windows 原生媒体控制仍不得标记为自动 PASS。

## 简短人工验收清单

### Android

- [ ] 打开 Reader → “自动” → AutoRead；确认暂停/继续/停止和 2.5 秒自动隐藏。
- [ ] 打开 Reader → “自动” → 语音朗读；确认从当前位置开始、连续跨段/章节。
- [ ] 朗读中切换 0.5x → 1x → 2x，确认无需暂停即可听出变化且不跳位置。
- [ ] 分别测试三种“自动模式下的音量键”：普通导航、控制自动模式、系统音量。
- [ ] 测试 AutoRead/TTS 互斥、竖排/分页跟随、息屏/后台、通知栏和蓝牙耳机。

### Windows

- [ ] 启动 Reader，确认 TTS provider 不再阻止启动。
- [ ] 从当前位置开始朗读，测试暂停/继续/停止、上一段/下一段和语速实时变化。
- [ ] 最小化、隐藏到 Tray 后确认朗读行为，再关闭 Reader 确认资源停止。
- [ ] 在 Light/Dark/真透明基线下确认 TTS 控制条颜色和文字可读。
- [ ] 记录 Windows 系统媒体控制为 DEFERRED，不以未实现项判定 PASS。

## M5.8s.8-FINAL 冻结结果（2026-08-15）

本轮只做最终回归和文档冻结，没有新增功能或修改 TTS/AutoRead 生产逻辑。

- `flutter analyze --no-pub`：PASS。
- `flutter test --no-pub`：PASS，642 项全部通过。
- Android Release：PASS。
- Windows Patched Release：PASS，唯一正式输出仍为
  `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe`，并完成短启动烟测。
- Android MediaSession/通知栏控制已通过模拟器验证；真实锁屏界面、实体蓝牙耳机和 AVD `KEYCODE_MEDIA_*` 路由保持 `MANUAL REQUIRED`。
- Windows 原生系统媒体控制保持 `DEFERRED`；Windows TTS provider 启动保护和失败降级保持 PASS。
- Windows True Transparency、UTF-16 Locator、ReaderProgress 和分页行为保持冻结基线，不因本轮回归改变。
