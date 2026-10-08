# XAOCEN Reader / 晓枨阅读

正式产品身份：Windows 使用 **XAOCEN Reader**；Android 用户可见名称统一为
**晓枨阅读**。正式版本：**4.5.8**。

当前唯一项目根目录：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 构建与发布

- Windows 唯一交付目录：`artifacts\windows\current\Release\`；其中
  `engine-selection.json` 必须明确为 `XAOCEN_PATCHED_ENGINE`，真透明正式版不得用
  Standard 产物冒充。
- Android Release universal APK：`build\app\outputs\flutter-apk\app-release.apk`。
- `build\windows\x64\runner\Release` 仅为 Flutter 中间构建目录，不作为对外启动地址。
- 当前已交付 Android applicationId：`com.xaocen.xaocen_reader`（4.5.8 release baseline）
- R05 分支 Android / HarmonyOS / iOS 目标 app ID：`com.xaocen.reader`（尚未发布；Android 是新应用身份）
- 当前版本：`4.5.8`（Android build number `5`）
- Android 图标源与生成说明：[tool/branding/README.md](tool/branding/README.md)

文件位于上述地址只表示“已生成”，不自动等于正式发布包。正式交付还必须
通过 [发布基线与签名说明](docs/RELEASE_BASELINE_2026_09_18.md)：Android
不得使用 Debug 证书，Windows 必须通过 Patched Engine、干净源码和
Authenticode 检查。可运行 `tool\audit_release_artifacts.ps1` 查看事实状态。

Windows 标准模式的用户数据与程序安装目录分离，固定使用：
`%LOCALAPPDATA%\\XAOCEN\\Reader\\profiles\\default\\`。显式便携模式使用
程序目录下的 `user_data\\profiles\\default\\`；安装目录中的 `data\\` 仅是
Flutter 运行时资源，不是书库目录。

启动时可用 `--profile=<id>` 或 `XAOCEN_PROFILE=<id>` 选择另一个本地
profile；不传参数时继续使用 `default`。profile 切换在下一次启动生效，
不会在运行中替换数据库。每个 profile 的 `sync/outbox` 仅保存未来同步
所需的本地元数据变更信封，当前不联网。

Android Release APK 同时包含 arm64-v8a、armeabi-v7a 和 x86_64，适用于实体 Android 设备及当前 Emulator。日常 Emulator 安装：

```powershell
.\tool\android_emulator\xaocen_emulator.ps1 -Action install
```

## 文档入口

- [当前发布基线、签名状态与文档优先级](docs/RELEASE_BASELINE_2026_09_18.md)
- [M5.7 历史产品状态与验收记录](M5_7_PRODUCT_CONSOLIDATED_STATUS.md)
- [Production Baseline Freeze](docs/PRODUCT_BASELINE_FREEZE.md)
- [历史变更记录](docs/CHANGELOG.md)
- [当前架构](docs/ARCHITECTURE_CURRENT.md)
- [验证矩阵](docs/TEST_VALIDATION_MATRIX.md)
- [仓库与构建产物布局](docs/REPOSITORY_LAYOUT.md)
- [M5.9 数据根与迁移基础](M5_9_DATA_ROOT_STORAGE_FOUNDATION.md)

## 验证

标准验证入口：

```powershell
.\tool\verify.ps1 -SkipIntegration
```

该入口构建 Windows Release 和 Android Release，不会把约 200 MiB 的 Debug APK 当作发布产物。
