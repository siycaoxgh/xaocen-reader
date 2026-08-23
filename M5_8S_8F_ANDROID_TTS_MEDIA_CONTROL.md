# M5.8s.8f — Android TTS Media Control Validation

验证日期：2026-08-15
项目目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
验证设备：`emulator-5554` / `xaocen_api35_x86_64`
Android：15 / API 35
APK：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`

本轮未修改 XAOCEN 生产代码；仅安装现有 Release APK、执行模拟器操作并保存诊断输出。

## 结果

| 项目 | 结果 | 证据/说明 |
|---|---|---|
| MEDIA SESSION | PASS | 朗读开始后 `dumpsys media_session` 出现 `XAOCEN Reader TTS`，`package=com.xaocen.xaocen_reader`，状态可见 `PLAYING` / `PAUSED`，并带有 Play/Pause、Next、Previous、Stop actions。 |
| LOCKSCREEN CONTROL | MANUAL REQUIRED | 息屏期间 MediaSession 仍保持 PLAYING，且通知为 PUBLIC MediaStyle；当前 AVD 未启用安全锁屏，无法证明真实锁屏控制面的显示/点击行为。 |
| MEDIA KEY PLAY/PAUSE | MANUAL REQUIRED | `adb shell input keyevent KEYCODE_MEDIA_PLAY_PAUSE` 在本 AVD 未路由到 XAOCEN。诊断显示 `Media button session is null`，全局优先会话为 Android Telecom；不能据此判定 XAOCEN MediaSession 失败。通知栏同一 Play/Pause 控件已实测暂停→继续。 |
| MEDIA KEY NEXT/PREV | MANUAL REQUIRED | `KEYCODE_MEDIA_NEXT/PREVIOUS` 同样未在该 AVD 路由到 XAOCEN。通知栏 Next/Previous 控件实测后 MediaSession 更新时间改变且保持 PLAYING，应用命令链可用。 |
| BLUETOOTH MANUAL | MANUAL REQUIRED | 未连接真实蓝牙耳机，无法证明耳机是否发送对应媒体键；AVD 仅有系统 Bluetooth media browser。 |
| RESOURCE CLEANUP | PASS | 通过 TTS 停止入口后，`dumpsys media_session` 不再出现 XAOCEN TTS session；`TtsForegroundService` 不再存在；朗读前台通知被移除（`xaocen_tts` 通知频道本身保留，符合 Android 频道生命周期）。 |

## 实测过程

1. 安装现有普通 Release APK（`adb install -r`），未 uninstall、未 wipe-data、未 pm clear。
2. 进入 Reader → 自动 → 语音设置，使用 AVD 中可用的本地语音 `en-us-x-tpf-local`，避免默认中文网络语音因无网络而立即结束。
3. 开始朗读后确认：
   - `XAOCEN Reader TTS` 会话为 `active=true`、`PLAYING`。
   - 通知标题为“晓枨阅读”，正文为“正在朗读”，通知为 `MediaStyle`，包含上一段、暂停/播放、下一段和停止朗读 action。
4. 通知栏操作结果：
   - 暂停后会话变为 `PAUSED`；再次点击后恢复 `PLAYING`。
   - 下一段、上一段操作后会话更新时间更新并保持 `PLAYING`。
5. 息屏后会话仍保持 `PLAYING`；但 AVD 没有实际安全锁屏界面，因此锁屏媒体控件仍需人工设备验收。
6. 停止朗读后验证 MediaSession、前台服务和通知均清理。

## 根因区分

本轮没有发现 XAOCEN MediaSession 创建或状态发布失败：MediaSession、MediaStyle 通知和通知 action 均真实存在并工作。`KEYCODE_MEDIA_*` 的失败证据来自 AVD 的系统路由状态：`Media button session is null`，且全局优先会话为 `com.android.server.telecom/HeadsetMediaButton/1`。因此模拟器注入的媒体键不能作为耳机/系统媒体键行为的可靠替代；真实耳机发送能力必须在实体设备上确认。

诊断文件保存在：

- `test_output\m58s8f_media_after_start.txt`
- `test_output\m58s8f_notification.xml`
- `test_output\m58s8f_notification2.xml`
- `test_output\m58s8f_after_start.xml`

相关 TTS 单元测试：`test/unit/tts_reading_controller_test.dart`，本轮运行结果 `18 tests passed`。
