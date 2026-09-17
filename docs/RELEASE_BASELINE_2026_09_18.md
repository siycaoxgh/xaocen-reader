# XAOCEN Reader 当前发布基线

更新时间：2026-09-18  
唯一项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

本文是当前状态、发布产物和文档优先级的权威入口。旧的 `M0`～`M5.9`
阶段报告继续作为实现与验收证据保留，但其中“当前”“待规划”“最新产物”等
时间敏感表述不再覆盖本文。

## 1. 当前源码基线

- 产品：Windows `XAOCEN Reader`；Android `晓枨阅读`。
- 版本：`4.5.8+5`。
- Android applicationId：`com.xaocen.xaocen_reader`，不得改变。
- Flutter：`3.44.7`；Engine revision：
  `69c8c61792f04cc809dfef0c910414fb9afc06cd`。
- Drift schema：`21`。
- 唯一阅读位置真相：absolute UTF-16 Locator。

当前已完成并受基线保护的主要能力包括：TXT、EPUB、统一
`ReaderContent`、Vertical/Paged Reader、书架/进度/书签/Metadata、
TTS/AutoRead、Windows 真透明、Profile/DataRoot、RSS/Atom 产品闭环、
WebArticle 最小 runtime、WebBook 书源定义/Registry/搜索/加入书架/更新/
章节按需缓存，以及受限的 Legacy 静态规则扫描与转换。

XAOCEN Account 客户端代码已接入设备授权、刷新、退出/撤销、权益查询、
安全凭据存储和离线许可证本地验签；自动分析与合同测试通过。真实账号服务、
Android Keystore/Windows Credential Manager、浏览器授权和有效离线许可证
仍需设备人工验收，在完成前不得写成已冻结的生产账号基线。

主题导入/导出、会员权益门控、唯一开屏广告位、内置加密文件云同步、商店
订阅回执聚合和翻页动画扩展仍属于待规划/待实施，不标记失败或完成。

## 2. 正式产物的唯一地址

| 平台 | 唯一地址 | 正式发布硬 Gate |
|---|---|---|
| Windows | `artifacts\windows\current\Release\xaocen_reader.exe` | `XAOCEN_PATCHED_ENGINE`、revision/artifact guard、干净源码、有效 Authenticode 签名 |
| Android | `build\app\outputs\flutter-apk\app-release.apk` | Release 构建、非 Android Debug 证书、applicationId/version 正确 |

`build\windows\x64\runner\Release` 是中间目录；Debug APK、Standard Engine
Windows 包以及未签名二进制都不是正式发布产物。

2026-09-18 整理前的本地旧产物审计结果：

- Windows `current` 清单为 `STANDARD_ENGINE`，EXE 未签名；
- Android `app-release.apk` 的证书 DN 为 `CN=Android Debug`；
- 因此两者只能作为历史测试产物，不能继续称为“最新正式版”。

发布前运行：

```powershell
.\tool\audit_release_artifacts.ps1
```

该检查只读，不会生成、导入或泄露证书。

## 3. 构建选择

Windows 真透明正式验证只使用：

```powershell
.\tool\build_windows_engine.ps1 -Engine Patched -Configuration Release
```

Standard 构建仅用于 fallback 回归：

```powershell
.\tool\build_windows_engine.ps1 -Engine Standard -Configuration Release
```

构建脚本在 canonical 目录生成 `engine-selection.json`，记录 Engine revision、
DLL hash、源码 commit 和源码是否 dirty。不得手工覆盖 Flutter SDK 或正式
目录中的 `flutter_windows.dll`。

## 4. 签名安全

### Android

Release 已禁止回退到 Debug 签名。真实密钥只能通过本机忽略文件
`android\key.properties` 或以下环境变量提供：

- `XAOCEN_ANDROID_KEYSTORE_PATH`
- `XAOCEN_ANDROID_KEYSTORE_PASSWORD`
- `XAOCEN_ANDROID_KEY_ALIAS`
- `XAOCEN_ANDROID_KEY_PASSWORD`

模板为 `android\key.properties.example`。`.jks`、`.keystore`、密码文件均被
Git 忽略。没有原发布私钥时必须停止发布；不得临时生成另一把密钥冒充升级包，
否则 Android 将无法覆盖安装并继承原应用数据。

### Windows

使用已有代码签名证书执行：

```powershell
.\tool\sign_windows_release.ps1 -CertificateThumbprint <thumbprint>
```

证书私钥、PFX/P12 和密码不得进入仓库。当前机器没有可用的正式 Android
keystore 或 Windows 代码签名证书，所以“签名生产包”仍被真实凭据阻塞；
源码侧的防误签入口已经建立。

## 5. 数据与升级保护

- Windows 标准模式：`%LOCALAPPDATA%\XAOCEN\Reader\profiles\<profileId>`。
- Windows 便携模式：`<程序目录>\user_data\profiles\<profileId>`，仅由
  `--portable`、`XAOCEN_PORTABLE=1` 或 `portable.marker` 显式启用。
- Android：应用私有目录；applicationId 与签名证书必须保持不变。
- 构建、清理和签名不得删除数据库、书库、封面、同步 outbox 或用户原始文件。

便携 DataRoot 可放在局域网共享路径，但同一 profile 同时只允许一个进程持有
租约；它不是多机并发数据库。真正的跨设备同时使用仍应走未来 SyncProvider。

## 6. 文档优先级

1. 本文：当前发布与状态真相；
2. `PRODUCT_BASELINE_FREEZE.md`：不可破坏合同；
3. `ARCHITECTURE_CURRENT.md`：累计架构细节（顶部快照优先）；
4. `M5_9*` 与根目录 `M*`：历史阶段证据；
5. 旧报告中的产物时间、测试数量和“待规划”状态只代表当时，不代表当前。

历史报告不删除、不改写原验收结论；通过明确优先级解决过期信息冲突。

## 7. 本次自动 Gate

- `flutter analyze --no-pub`：PASS；
- Account 定向测试：PASS（3）；
- 全量 Flutter tests：PASS（773 passed，3 live-network tests skipped）；
- Secret scan：PASS（未发现私钥、常见 token 或被跟踪的密钥文件）；
- Windows Patched Release：PASS（revision/artifact guard 与 canonical staging）；
- Android signed Release：BLOCKED，等待原正式 keystore；
- Windows Authenticode：BLOCKED，等待正式代码签名证书。
