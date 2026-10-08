# R05 跨平台最小试验实测报告

更新：2026-10-08（Asia/Shanghai）
结论：**部分完成，不满足 R05 验收**。HarmonyOS 已构建 ArkTS 最小样例并生成未签名 HAP；尚未有模拟器/设备运行证据。iOS 仅完成现有工程静态盘点，没有可执行的 macOS/Xcode 或 Codemagic 构建。

## 隔离基线和范围

- 实现仓库：`D:/xaocen/reader-r05-platform-spike`，分支 `r05-platform-spike`，基于 Reader `b3f96c5acbec0f01101f36c348e110bec2a55f31` 建立独立 worktree。
- 原 Reader 主工作区有大量未提交/未跟踪内容。为避免误纳或覆盖，本任务只基于 HEAD 建立样例；iOS 配置盘点是只读查看原主工作区中的当前文件，不复制、不修改其内容。
- 本次未改 Android/Windows 生产逻辑、账号政策或共享平台枚举。Harmony bundle name 是样例值，不是已登记的正式 Bundle ID。

## R05-A：HarmonyOS NEXT

### 环境盘点

| 项目 | 本机证据 |
| --- | --- |
| DevEco Studio | `D:\HUAWEIDev\DevEco Studio`，`DS-261.23567.138.36.2600851`（26.0.0.851） |
| Harmony SDK | `sdk/default/openharmony`，平台 API 26；构建版本 `26.0.0.105` |
| Hvigor / OHPM | Hvigor 6.26.8；OHPM 6.0.0.630 |
| HDC | 3.2.0f；`hdc list targets` 无输出，没有已连接模拟器或设备 |
| SDK 环境变量 | `DEVECO_SDK_HOME` 原先未设置；只为当前构建进程临时指向已安装 SDK，没有修改系统或用户全局变量 |
| 模拟器 | DevEco 的 Emulator 程序存在；SDK 内未发现可用系统镜像，HDC 也没有在线目标；没有完成模拟器启动 |

Hvigor 首次尝试使用默认 npm 源，未能解析 Harmony 插件；之后在样例目录使用被 Git 忽略的本机 `.npmrc`，为 `@ohos` 包指定 Harmony 官方 npm 源后构建成功。Hvigor 在用户缓存目录生成 pnpm wrapper 并安装两个依赖包，工具输出一项 high severity audit 警告；该机器缓存没有删除或纳入仓库。

### 样例实现和构建证据

独立原生样例位于 [`platform_spikes/harmonyos_next_r05`](../platform_spikes/harmonyos_next_r05/README.md)。ArkUI 页面从 rawfile 加载合成 TXT，显示仓库内图片资源，提供前后页交互；`PersistentStorage` 保存样例页索引。该页索引是试验状态，**不是 Reader 生产 Locator**。源码只覆盖最小链路，没有账号、真实书库或云功能。

在 `platform_spikes/harmonyos_next_r05` 目录执行：

```powershell
$env:DEVECO_SDK_HOME = 'D:\HUAWEIDev\DevEco Studio\sdk'
$env:NPM_CONFIG_USERCONFIG = (Join-Path (Get-Location) '.npmrc')
& 'D:\HUAWEIDev\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

| 证据 | 结果 |
| --- | --- |
| 构建 | `BUILD SUCCESSFUL`；33 tasks，23 executed、10 up-to-date |
| 产物 | `platform_spikes/harmonyos_next_r05/entry/build/default/outputs/default/entry-default-unsigned.hap`；806,987 bytes |
| SHA-256 | `1CE1BB4FF46C9FD2238A279CED3A6192A7CA36F15F84349C6541AB64FB64346C` |
| 签名 | 未配置 signingConfig，产物为 unsigned HAP；未验证签名或安装资格 |
| 构建警告 | `EntryAbility.ets` 可能抛异常的诊断仍存在；本次没有运行时日志用于判断其实际影响 |
| 安装/启动/交互 | 未执行：没有 HDC 目标和可用模拟器系统镜像 |
| TXT / 图片 / 退出恢复 | ArkTS 编译和资源打包通过；应用内显示、按钮交互、退出后恢复均未实机验证 |

因此，不能将本次结果描述为 Harmony 端功能验收通过。下一步需配置 API 26 兼容的模拟器镜像或提供真机，生成受控签名后验证安装、TXT/图片显示、前后页交互与退出重开恢复；之后仍需单独做真机兼容验收。

## R05-B：iOS / iPadOS

### 现有 Flutter 工程静态盘点

以下内容只读自原 Reader 主工作区的当前文件；该工作区 dirty，且 iOS 配置不在本次干净 worktree 的 HEAD 中，因此这些观察不等同于本任务分支内可复现的工程基线。

| 项目 | 当前观察 |
| --- | --- |
| Flutter / Dart | Flutter stable 3.44.7，Dart 3.12.2 |
| 插件声明 | `pubspec.yaml` 声明 `file_picker ^11.0.3`、`path_provider ^2.1.6`、`flutter_secure_storage 9.2.4`、`cryptography 2.7.0`；`flutter_tts ^4.2.5` 使用本地 `third_party/flutter_tts` 覆盖 |
| iOS 插件证据 | 当前 `GeneratedPluginRegistrant.m` 包含 file_picker、flutter_secure_storage、flutter_tts；本地 TTS 插件有 Swift iOS 实现。它们只证明源码入口存在，不证明 CocoaPods 解析、编译或运行成功 |
| Xcode 项目 | iOS deployment target 13.0，`CODE_SIGN_STYLE = Automatic`，未发现 `DEVELOPMENT_TEAM` |
| Bundle ID | 当前工程为 `com.xaocen.xaocenReader`；Master Plan 记载的计划值是 `com.xaocen.xaocen_reader`。二者不一致，未擅自改动，需由产品/Apple 开发者账号持有人确认并登记 |
| 构建依赖 | 当前检查未找到 `ios/Podfile` 或仓库根 `codemagic.yaml` |
| 本机可执行性 | Windows 主机没有 `xcodebuild` 或 `pod`；Flutter CLI 信息采集未能完成并中断，未执行 iOS 编译 |
| 云构建 / 签名 / TestFlight | 本次没有 Codemagic 工程访问和 Apple 账号/签名材料，未构建、签名、上传或发布 |

**iOS 当前结论：仅静态配置检查；没有 iOS `.app` / `.ipa` 构建证据，也没有模拟器、iPhone 或 iPad 运行验收。** 由于现有 iOS 文件位于原 dirty 工作区而不在本次 HEAD，本报告不以不完整拷贝拼装工程，也不将已有文件声称为本任务分支中的可复现 build baseline。

### Apple / Codemagic 所需条件

- Codemagic 需连接包含可构建 iOS 工程的固定 Reader 源码基线，并使用 macOS/Xcode 构建机。仓库需提供有效 CocoaPods 项目配置；云配置提交后再进行一次不签名或模拟器目标的构建以检查编译。
- 要签名设备包或送 TestFlight，需要 Apple Developer Program 团队、已确认且可注册的 Bundle ID、Team ID，以及通过 Codemagic 安全配置维护的 App Store Connect API key/签名资产。密钥不要放在仓库、文档或聊天。
- 还需一台 iPhone 和一台 iPad（或明确可用的受控设备池）验证文件导入/重新打开、恢复、TTS 与布局；云构建产物本身不等于设备验收。
- 不应在尚未裁决 Bundle ID 和 R06 平台/账号策略前，把新的 `ios` 值直接套进现有 Android/Windows 分支或共享身份逻辑。

## 共享数据与平台适配

现有 Reader 代码将 `ReaderProgressState` 定义为 `collectionId`、`absoluteCharacterOffset`、`readingMode`、`itemIdHint`、`updatedAt`；`ReaderLocator` 以 normalized text 的 UTF-16 code-unit offset 为唯一阅读位置真源，禁止用页码、滚动像素或页面索引替代。数据库也保存 `locatorVersion` 与 `normalizationVersion`。R05 Harmony 样例当前持久化的整数页码与此合同不同；R35/R36 应复用或经版本化适配该合同，不能把样例数据直接迁移成正式阅读进度。

| 能力 | Flutter 现状 / iOS | HarmonyOS NEXT 后续 |
| --- | --- | --- |
| 文本、图片 | Flutter 渲染链路可共享的前提仍需 Xcode 实际构建确认；真实格式和长文本需设备验证 | ArkUI 渲染与 Reader/Dart 代码不同；重做解析、排版、导航和资源加载适配。当前仅为合成 TXT/单图样例 |
| 用户文件 | `file_picker` 与 `path_provider` 已声明；iOS 外部文档使用安全作用域 URL/文档协调时需正确管理文件访问和长期书签；未做行为验证 | 通过系统 Picker 读取用户文件，若要跨重启再次访问，需要按系统要求保存并重新激活持久授权；样例目前只读应用 rawfile |
| 账号秘密 | Flutter 依赖 `flutter_secure_storage`；iOS 侧以 Keychain 能力实现安全存储，实际 plugin behavior 尚未设备验证 | 需采用 Harmony 安全密钥/存储服务并核查 API、权限与恢复语义；不能假定 Flutter secure-storage 插件兼容 |
| TTS | 当前本地插件的 iOS 源码调用 `AVSpeechSynthesizer`；语音、生命周期、后台和声音可用性需真机验收 | 需接入 Harmony Core Speech Kit 并重新适配 voice、暂停/恢复、进度回调及生命周期 |
| 本地数据目录 | `DataRoot` 对 Windows 路径有明确隔离和迁移约束；iOS 要映射到应用容器与文件保护/备份策略，不能复用 Windows 目录约定 | 采用应用沙箱和 ArkData/文件 API；导入书源 URI 与内部副本/授权应清楚区分 |
| 平台身份 | 现有 Reader AccountPlatform 只支持 Android/Windows；iOS 值及认证/MFA/设备登记策略尚未冻结 | Harmony 值同样等待 R06；不得以 Windows fallback 代替平台注册 |

官方 API 边界可参考报告末的 Apple 与 Harmony 开发者资料。上述差异是适配清单，不构成新产品策略或契约批准。

## 退出标准与后续工作量

| 端 | 已达到 | R05 仍需完成 |
| --- | --- | --- |
| HarmonyOS NEXT | DevEco/SDK/Hvigor 盘点；独立 ArkTS/ArkUI 工程；API 26 编译和 HAP 产物哈希 | 可启动模拟器/实体目标、受控签名安装、TXT/图片/交互/退出恢复运行证据；真实设备验收分开记录 |
| iOS/iPadOS | 现有 Flutter/Xcode 配置静态盘点；识别 Bundle ID、Team、Podfile、Codemagic 缺口 | 固定干净 Flutter/iOS 基线，补齐/核实 Pods 与 Codemagic macOS build，至少一次云构建产物；确认 Apple 签名条件；TestFlight 和真机行为按授权/账号另验 |

R05 **尚未达到验收标准**。R35 需先做 Harmony 渲染/文件沙箱/本地库/定位/安全存储适配，再进入格式和真机性能工作；R36 需确认正式 Bundle ID、Xcode/CocoaPods/Codemagic 可复现流水线、iOS 文件与 Keychain 语义、TTS/音频焦点，以及 iPhone/iPad 布局和恢复。两个完整客户端仍依赖 R06–R10；本次未启动这些工作。

以下是基于目前工程盘点的**相对工作量**，不是排期承诺；不含完整 Reader 功能实现、上架和未确认产品政策：

| 后续部分 | 相对量级 | 依据 |
| --- | --- | --- |
| Harmony TXT/EPUB/图片渲染、书库与导入 | 很高 | ArkTS/ArkUI 与 Flutter/Dart UI、文件及解析插件不能直接复用；当前只有单页合成样本 |
| Harmony 账号安全存储、Picker 授权、定位恢复和 TTS | 高 | 需接系统密钥、文档授权和 Core Speech Kit，并按 R06 冻结平台/设备策略 |
| iOS 可复现构建、Pods 与 Codemagic | 中 | Flutter 和插件代码有复用基础，但当前缺 Podfile、云配置和可审阅源码基线；需先验证实际解析与编译 |
| iOS 文件访问、持久恢复、安全存储和 TTS | 中到高 | 插件入口存在但运行未验证；文档 URL 生命周期、Keychain 策略、语音生命周期仍需适配与真机覆盖 |
| 两端完整设备回归、性能与发行门禁 | 高 | 需要 Harmony 模拟器/真机、iPhone/iPad、签名身份、测试数据及平台政策，不由本次编译替代 |

## 官方平台资料

- HarmonyOS [ArkTS 概览和模拟器差异](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-overview)、[Picker API](https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-file-picker)、[文件持久授权说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/file-persistpermission-V5)、[HUKS 密钥派生](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V13/huks-key-derivation-arkts-V13)、[Core Speech Kit 能力介绍](https://developer.huawei.com/consumer/cn/app/planning)。
- Apple [Keychain Services](https://developer.apple.com/documentation/security/keychain-services?changes=_1)、[UIDocumentPicker](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller?changes=_4__7)、[AVSpeechSynthesizer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer?changes=_8&language=objc)。
- Codemagic [iOS code signing](https://docs.codemagic.io/flutter-code-signing/ios-code-signing/)、[iOS simulator build](https://docs.codemagic.io/yaml-code-signing/ios-simulator-builds/)、[first signed build](https://docs.codemagic.io/yaml-quick-start/first-signed-build/)。
