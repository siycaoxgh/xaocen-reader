# XAOCEN Android Emulator

固定 AVD：`xaocen_api35_x86_64`（Android 15 / API 35 / Google APIs / x86_64，Pixel 7，1080×2400，420 dpi）。

```powershell
pwsh -File tool/android_emulator/xaocen_emulator.ps1 -Action start
pwsh -File tool/android_emulator/xaocen_emulator.ps1 -Action install
pwsh -File tool/android_emulator/xaocen_emulator.ps1 -Action launch
pwsh -File tool/android_emulator/xaocen_emulator.ps1 -Action logcat
pwsh -File tool/android_emulator/xaocen_emulator.ps1 -Action screenshot
```

脚本显式选择 `emulator-*` serial，日常启动不使用 `-wipe-data`，也不执行 `uninstall` 或 `pm clear`。
