# R05 HarmonyOS NEXT 最小样例

本目录是独立的 ArkTS/ArkUI 技术样例，不是完整 Reader，也不连接账号、云同步或真实书库。它从应用资源读取合成 TXT 文本，显示本地图片，并用 `PersistentStorage` 保存当前样例页码。

## 环境与构建

本次机器核验环境：DevEco Studio 26.0.0.851、HarmonyOS SDK 6.0.0 / API 26、Hvigor 6.26.8、OHPM 6.0.0.630、HDC 3.2.0f。使用你本机已安装的 DevEco，不把其机器路径写进工程配置。

在 DevEco 中打开本目录，再选择 entry/default 构建 HAP。命令行等价入口（PowerShell 当前目录设为本目录）：

```powershell
$env:DEVECO_SDK_HOME = 'D:\HUAWEIDev\DevEco Studio\sdk'
$env:NPM_CONFIG_USERCONFIG = (Join-Path (Get-Location) '.npmrc')
& 'D:\HUAWEIDev\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

默认输出在 `entry/build/default/outputs/default/`。安装到已启动且已连接的模拟器时，先用 `hdc list targets` 确认目标，再执行：

```powershell
& 'D:\HUAWEIDev\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' shell bm install -p '<entry-default-signed.hap 的完整路径>'
```

运行验证顺序：启动样例，观察 TXT 与图片，点“下一页”后退出应用并重新打开，确认页面号恢复；再点“上一页”，确认状态变化。这里的页码是样例状态，不是 Reader 生产 Locator。

## 边界

- TXT 与图片均为合成、仓库内资源；不访问公共文件夹或用户授权文件。
- Bundle name 使用用户于 2026-10-08 确认的跨端 ID `com.xaocen.reader`。它与此前 Android 身份不同；安装样例前确认测试设备上没有同 ID 的其他 Reader 包，避免覆盖或签名冲突；包名一致不代表已经在 AppGallery Connect 注册。
- 不含签名私钥或开发者配置。模拟器安装、签名和真机兼容须分别记录；HAP 构建不代表真机验收。
- Harmony 原生工程不复用 Flutter 插件或 Dart 状态；共享数据合同仍需 R06/R07 明确。

## 本次实测记录

2026-10-08：DevEco/Harmony SDK 的 HAP 编译通过，产物与本次证据见 [R05 实测报告](../../docs/R05_CROSS_PLATFORM_SPIKE_20261008.md)。没有在线 HDC 目标，因此未安装或启动；该结果只证明本机编译与打包成功。
