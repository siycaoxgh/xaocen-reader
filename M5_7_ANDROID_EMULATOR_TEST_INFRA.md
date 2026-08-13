# M5.7 Android Emulator Test Infrastructure

## Environment

- SDK root: `C:\Users\TOM\AppData\Local\Android\Sdk`
- ADB: Platform-Tools 37.0.0 (`adb` 1.0.41)
- Emulator: 37.1.11
- AVD: `xaocen_api35_x86_64`
- Device profile: Pixel 7
- Image: Android 15 / API 35 / Google APIs / x86_64
- Resolution/density: 1080×2400 / 420 dpi
- Running serial observed: `emulator-5554`

The AVD was created without replacing any existing AVD. Daily start does not use `-wipe-data`; no `adb uninstall`, `pm clear`, or DataRoot deletion is performed by the fixed scripts.

## APK and launch gate

The current normal application APK was installed with:

```text
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
```

Install result: PASS. Package: `com.xaocen.xaocen_reader`; launcher activity: `.MainActivity`. Launcher start and foreground activity were confirmed. A pulled emulator screenshot showed the 首页 shell with “继续阅读”, “本地书库”, and bottom 首页/书架/我的 navigation. No app `FATAL EXCEPTION`, FlutterError, PlatformException, Drift/SQLite, or migration error appeared in the captured app log window.

The AVD initially has no books, so an end-to-end Reader/Locator restore requires importing a corpus through the app. The existing M2 Android integration test was used as the safe integration target gate and passed; it creates isolated test fixtures rather than validating the production UI's full manual import journey.

## Integration target

```powershell
flutter test integration_test/m2_android_verify_test.dart -d emulator-5554
```

Result: PASS (2 tests). The command built and ran against the emulator. Integration tests may install a test runner; reinstall the normal APK with the script before a manual smoke session.

## Capability results

| Area | Result | Evidence/limit |
|---|---|---|
| SDK/emulator/AVD | PASS | API 35 x86_64 image and Pixel 7 AVD created |
| adb online emulator | PASS | `emulator-5554 device` |
| normal debug APK install | PASS | `install -r` succeeded |
| Launcher / 首页 shell | PASS | foreground activity + screenshot |
| 书架 / 我的 navigation | PASS | shell navigation screenshots/taps completed |
| Reader open | DEFERRED | no imported book in fresh AVD; needs corpus import/manual flow |
| vertical / paged | DEFERRED | requires an opened book |
| theme / settings | DEFERRED | requires Reader settings route and opened book |
| Locator restore | DEFERRED | requires a persisted reading session/book |
| logcat capture / screenshot | PASS | fixed scripts and ADB commands verified |

The deferred items are not production failures; they are data-entry/manual coverage not safely fabricated from an empty emulator. The emulator now provides a repeatable target for those checks without the physical phone.

## Fixed scripts

`tool/android_emulator/xaocen_emulator.ps1` supports:

- `start`: starts the fixed AVD with GPU auto and waits for boot; no wipe
- `wait`: waits for an online, boot-complete `emulator-*`
- `install`: installs the latest normal `app-debug.apk` with `-r`
- `launch`: launches the normal package
- `logcat`: writes a device-scoped logcat capture under `artifacts/android-emulator/`
- `screenshot`: writes a binary PNG via `exec-out screencap -p`
- `status` / `smoke`

Usage and the no-wipe contract are documented in `tool/android_emulator/README.md`. All commands select the emulator serial explicitly and never uninstall, clear package data, or wipe the AVD as a daily operation.

## Source/worktree

No production source was changed for emulator setup. The current project HEAD before this infrastructure addition is `7d7b12dce5082808722dc2ac1b9be3e47109a2c`; generated emulator screenshots/logs are not part of the repository.
