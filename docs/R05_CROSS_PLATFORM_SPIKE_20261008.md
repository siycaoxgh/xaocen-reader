# R05 跨平台最小试验实测报告

更新：2026-10-08（Asia/Shanghai）
结论：**部分完成，不满足 R05 验收**。HarmonyOS ArkTS/ArkUI 样例已以统一应用标识构建未签名 HAP，但尚无模拟器/设备运行证据。iOS 已在干净 R05 worktree 建立 Flutter Runner、Podfile 和 Codemagic 无签名构建配置；离线依赖解析通过，但 Windows 无 Xcode/CocoaPods，且尚未运行 Codemagic 云构建。

## 隔离基线和范围

- 实现仓库：`D:/xaocen/reader-r05-platform-spike`，分支 `r05-platform-spike`，基于 Reader `b3f96c5acbec0f01101f36c348e110bec2a55f31` 建立独立 worktree。
- 原 Reader 主工作区有大量未提交/未跟踪内容；本次没有修改或复制其内容。代码变更仅在 Reader worktree `D:/xaocen/reader-r05-platform-spike`，分支 `r05-platform-spike`，基于提交 `b3f96c5acbec0f01101f36c348e110bec2a55f31`。
- 用户于 2026-10-08 确认 Android、HarmonyOS、iOS 三端统一应用标识为 `com.xaocen.reader`。Android/Harmony 原来的 `com.xaocen.xaocen_reader` 与新标识属于不同应用身份，旧安装、应用沙箱数据不保证能随新标识升级迁移；该身份变更已由用户接受。AppGallery Connect 与 Apple Developer/App Store Connect 中的标识注册和可用性仍未验证。未改 Android/Windows 阅读业务逻辑、账号政策或共享平台枚举。

## 统一应用标识与 Android 构建验证

Android `namespace`、`applicationId`、Kotlin package、TTS action names 和 Android Emulator helper 已更新为 `com.xaocen.reader`；iOS Runner 与 Harmony bundleName 使用同一 app ID。Dart package 名 `xaocen_reader` 是语言包名，保留不变。

在 R05 worktree 根目录执行：

```powershell
$env:PUB_CACHE = 'D:\xaocen\.tooling\reader-public-cache\pub'
$env:GRADLE_USER_HOME = 'D:\xaocen\.tooling\reader-public-cache\gradle'
$env:ANDROID_USER_HOME = 'D:\xaocen\.tooling\reader-public-cache\android-user'
$env:ANDROID_SDK_ROOT = 'C:\Users\TOM\AppData\Local\Android\Sdk'
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
& 'C:\Users\TOM\flutter\bin\flutter.bat' build apk --debug --no-pub
```

| 证据 | 结果 |
| --- | --- |
| 环境 | Flutter 3.44.7 / Dart 3.12.2；JDK 17.0.19；Android SDK API 36 |
| Android Debug 构建 | PASS，`assembleDebug` 完成；耗时约 234 秒。Flutter 提示当前 AGP 8.7.3 后续需升级到至少 8.11.1 |
| APK | `build/app/outputs/flutter-apk/app-debug.apk`；`aapt dump badging` 确认 `package='com.xaocen.reader'`；SHA-256 `13F408B2462ED8CD3A46B86487DE4AF17B2DAEC7C019F0C6EA8D7CD7CF03D45D` |
| 安装/运行 | 未执行；新包未安装到 Android 设备，不构成 Android 运行验收 |

## R05-A：HarmonyOS NEXT

### 环境盘点

| 项目 | 本机证据 |
| --- | --- |
| DevEco Studio | `D:\HUAWEIDev\DevEco Studio`，`DS-261.23567.138.36.2600851`（26.0.0.851） |
| Harmony SDK | `sdk/default/openharmony`，平台 API 26；构建版本 `26.0.0.105` |
| Hvigor / OHPM | Hvigor 6.26.8；OHPM 6.0.0.630 |
| HDC | 3.2.0f；用户随后报告模拟器已启用；2026-10-08 23:15 复查 `hdc list targets` 仍无输出，当前 HDC 未发现在线模拟器或设备 |
| SDK 环境变量 | `DEVECO_SDK_HOME` 原先未设置；只为当前构建进程临时指向已安装 SDK，没有修改系统或用户全局变量 |
| 模拟器 | 较早盘点时本机尚无已部署模拟器；用户现报告已启用。当前执行环境仅能枚举隔离 shell 进程，无法检查宿主 DevEco/Emulator 进程；HDC 也尚未枚举到目标，因此启动状态待确认 |

Hvigor 首次尝试使用默认 npm 源，未能解析 Harmony 插件；之后在样例目录使用被 Git 忽略的本机 `.npmrc`，为 `@ohos` 包指定 Harmony 官方 npm 源后构建成功。Hvigor 在用户缓存目录生成 pnpm wrapper 并安装两个依赖包，工具输出一项 high severity audit 警告；该机器缓存没有删除或纳入仓库。

用户 2026-10-08 确认手头有 Harmony 设备和 iPhone；它们尚未连接到本机，因此设备验收仍未发生。iPad 是否可用于验收尚未确认。

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
| 初始构建 | `BUILD SUCCESSFUL`；33 tasks，23 executed、10 up-to-date；当时仍使用试验期包名 |
| 初始产物 | `platform_spikes/harmonyos_next_r05/entry/build/default/outputs/default/entry-default-unsigned.hap`；806,987 bytes |
| 初始 SHA-256 | `1CE1BB4FF46C9FD2238A279CED3A6192A7CA36F15F84349C6541AB64FB64346C` |
| 上一标识构建（2026-10-08） | 当时按先前标识 `com.xaocen.xaocen_reader` 构建；该产物已被本次新标识构建替代 |
| 当前统一标识构建（2026-10-08） | `BUILD SUCCESSFUL`；33 tasks，27 executed、6 up-to-date；`pack.info` 确认 `bundleName=com.xaocen.reader` |
| 当前产物 | 同一路径 `entry-default-unsigned.hap`；806,915 bytes |
| 当前 SHA-256 | `C65F7445FE265794FDD61B8FB181EE2365BDE0533B0CFE3003F4686AD071AE5C` |
| 签名 | 未配置 signingConfig，产物为 unsigned HAP；未验证签名或安装资格 |
| 构建警告 | `EntryAbility.ets` 可能抛异常的诊断仍存在；本次没有运行时日志用于判断其实际影响 |
| 安装/启动/交互 | 未执行：没有 HDC 目标和可用模拟器系统镜像 |
| TXT / 图片 / 退出恢复 | ArkTS 编译和资源打包通过；应用内显示、按钮交互、退出后恢复均未实机验证 |

因此，不能将本次结果描述为 Harmony 端功能验收通过。下一步先让已创建的 API 26 兼容模拟器出现在 HDC/DevEco 目标列表中，再通过 IDE“运行”执行未签名调试包，验证安装、TXT/图片显示、前后页交互与退出重开恢复；如果改用实体设备，再生成受控调试签名并单独做真机兼容验收。模拟器成功不等于真机验收。

### 模拟器和调试签名的下一步

用户确认手头有 Harmony 设备。较早盘点时 `C:\Users\TOM\AppData\Local\Huawei\Emulator\deployed` 只有版本信息文件，SDK 目录也没有模拟器系统镜像；用户随后报告模拟器已启用。2026-10-08 23:15 从当前隔离执行环境复查，`hdc list targets` 仍无输出；Windows 进程枚举仅暴露当前命令 shell，不能据此判断宿主 DevEco/模拟器是否存活。请在 DevEco 的设备选择框确认模拟器状态为已启动，或在用户自己的 PowerShell 运行下文 HDC 命令并检查结果。HarmonyOS 支持 DevEco 模拟器，中文界面通常从“工具 > 设备管理器 > 本地模拟器 > 新建模拟器”选择设备模板、下载镜像并启动；具体版本菜单名称可能略有差异。系统镜像与设备实例分别存储，下载镜像需要网络。当前工具目标 API 是 26，模拟器/真机需要满足应用声明的最低 API。华为官方[模拟器创建指南](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-emulator-create)说明了创建与启动流程。

```powershell
& 'D:\HUAWEIDev\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' list targets -v
```

模拟器和实体设备要区分处理：华为入门指南说明，在模拟器/预览器调试无需签名配置；实体设备运行则需要 HAP 调试签名。模拟器可在 DevEco 选择已启动目标并点“运行”，IDE 会编译、推包和启动。实体 Harmony 设备也可替代模拟器做 R05 功能验证：在设备开启开发者模式和 USB 调试，连接电脑后确认授权；开发者模式入口和调试签名要求见[华为调试安装说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/bm-tool-V5)。本机执行 `hdc list targets` 有设备序列号后，才能继续安装与交互验收。若模拟器启动后仍未出现目标，应先查看 DevEco 设备选择框/设备管理器的运行状态，再用同一套本机 HDC 检查确认。

Android APK 的 keystore 不能直接当作 Harmony HAP 的完整签名配置。实体设备调试时，手动签名需要 `.p12` 密钥、`.cer` 数字证书和 `.p7b` Harmony profile，且证书/profile 绑定 Harmony 应用身份和包名；建议生成独立的 Harmony **debug** 密钥，不复用 Android production 密钥。单设备可先尝试 DevEco 自动签名；手动路径是在菜单“构建 > 生成密钥和证书请求（Generate Key and CSR）”创建 `.p12` 与 `.csr`，在 AppGallery Connect 创建普通“应用”（不是元服务），包名填 `com.xaocen.reader`，上传 CSR 申请调试证书并下载 `.cer`；设备连接后用 `hdc shell bm get -u` 获取 UDID，在 AGC 注册调试设备，再创建绑定该应用、调试证书和设备的 Debug Profile 并下载 `.p7b`；最后在“文件 > 项目结构 > 签名配置（Signing Configs）”填入 `.p12`、`.cer`、`.p7b`、别名和密码。私钥和密码仅在本机安全保存，不提交仓库也不发到聊天。官方[HarmonyOS 开发入门](https://developer.huawei.com/consumer/cn/develop-novice-guide/)说明模拟器与真机签名要求，[调试 Profile 指南](https://developer.huawei.com/consumer/cn/doc/doccenter-getting-started/agc-help-debug-profile-0000002248181278)列明调试证书/设备/Profile 关系；[bm get -u 官方说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/bm-tool-V5)列明设备 UDID 获取命令。AppGallery Connect 中注册的应用包名还必须与工程 `bundleName` 一致，见[应用身份配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/iap-config-app-identity-info-V5)。

包名已按用户最终确认的统一值重建。首次安装前仍要确认设备上没有同包名应用；由于 Android 应用身份已改变，旧包不会作为同应用直接覆盖升级。

## R05-B：iOS / iPadOS

### R05 分支 iOS 工程与云构建配置

原 Reader 主工作区的 iOS 目录和大量 Reader 源码更改仍保持原位、未复制、未修改。为避免把未审阅的 dirty 源码混入 R05，本 worktree 基于已提交 Flutter 源码单独生成 iOS 平台骨架；这不是对主工作区全部新功能的验证。

执行 `flutter create --platforms=ios --org com.xaocen --project-name reader --no-pub .` 生成 Runner、Xcode workspace 和 iOS 资源；`ios/Runner.xcodeproj` 的应用 Bundle ID 已设为 `com.xaocen.reader`，RunnerTests 使用 Xcode 标准后缀 `com.xaocen.reader.RunnerTests`。添加 Flutter CocoaPods 标准 Podfile，最低 iOS target 为 13.0；根目录 `codemagic.yaml` 配置 Flutter 3.44.7、macOS/Xcode、依赖解析、`pod install` 和 `flutter build ios --release --no-codesign`。该 workflow 只编译，不签名、不上传、不发布。

| 项目 | 当前观察 |
| --- | --- |
| Flutter / Dart | Flutter stable 3.44.7，Dart 3.12.2 |
| 插件声明 | `pubspec.yaml` 声明 `file_picker ^11.0.3`、`path_provider ^2.1.6`、`flutter_secure_storage 9.2.4`、`cryptography 2.7.0`；`flutter_tts ^4.2.5` 使用本地 `third_party/flutter_tts` 覆盖 |
| iOS 插件证据 | 当前 `GeneratedPluginRegistrant.m` 包含 file_picker、flutter_secure_storage、flutter_tts；本地 TTS 插件有 Swift iOS 实现。它们只证明源码入口存在，不证明 CocoaPods 解析、编译或运行成功 |
| Xcode 项目 | iOS deployment target 13.0，`CODE_SIGN_STYLE = Automatic`，未发现 `DEVELOPMENT_TEAM` |
| Bundle ID | R05 worktree Runner 为 `com.xaocen.reader`；主工作区原工程的 `com.xaocen.xaocenReader` 保持未修改。Apple 账号中的 ID 注册/可用性尚未检查 |
| 构建依赖 | R05 worktree 已有 `ios/Podfile` 和根 `codemagic.yaml`；`flutter pub get --offline` 成功，生成插件登记。`Podfile.lock` 尚未由 macOS/CocoaPods 解析，需首轮云构建后复核并固定 |
| 本机可执行性 | Windows 主机没有 `xcodebuild` 或 `pod`；本机不支持执行 Xcode/iOS 编译，未生成 iOS `.app` / `.ipa` |
| 云构建 / 签名 / TestFlight | YAML 已配置无签名 macOS 构建，但没有 Codemagic 云账号/仓库授权，尚未运行；无 Apple Team、开发/分发证书、Provisioning Profile 或 TestFlight 证据 |

**iOS 当前结论：工程与云构建配置已在干净 R05 worktree 生成，依赖解析通过；尚无 macOS/Xcode 构建、签名、TestFlight 或设备运行证据。** R05 分支仍落后于主工作区的 dirty Reader 功能代码，首次 Codemagic 构建应使用本分支已提交源码完成基线验证；合并主工作区的新代码前需固定并审阅无凭据源码快照。

### Apple / Codemagic 所需条件

- 先把 R05 分支提交推送到 Codemagic 能访问的 Git 仓库/分支，再运行当前无签名 workflow；成功后取回 macOS 生成的 `Podfile.lock` 并审阅提交。无签名编译不需要 Apple 证书，但需要 Codemagic 账号、项目仓库接入和可用 macOS 构建额度。
- 若要安装到 iPhone/iPad 或送 TestFlight，需要 Apple Developer Program 团队、App Store Connect 中可用的 `com.xaocen.reader`、Team ID，以及在 Codemagic 安全配置中的 App Store Connect API key、开发/分发证书和匹配的 Provisioning Profile。密钥不要放在仓库、文档或聊天。[Codemagic iOS 签名说明](https://docs.codemagic.io/yaml-code-signing/signing-ios/)与[无签名到签名的首发流程](https://docs.codemagic.io/yaml-quick-start/first-signed-build/)列出了条件。
- 用户已确认手头有 iPhone，可用于实体 iOS 验收；iPad 或 iPad 模拟器仍需补充以覆盖 iPadOS 布局。两类设备分别验证文件导入/重新打开、恢复、TTS 与布局；云构建产物本身不等于设备验收。
- 用户已确认三端统一为 `com.xaocen.reader`，R05 分支的 Android/Harmony/iOS 工程均使用该应用标识；Apple/AppGallery 注册状态待账号持有人核验。Apple Bundle ID 只允许字母、数字、连字符和点，并且上传 App Store Connect 后不能更改；参见 [Bundle ID 规则](https://developer.apple.com/help/glossary/bundle-id/)和 [CFBundleIdentifier](https://developer.apple.com/documentation/BundleResources/Information-Property-List/CFBundleIdentifier)。R06 平台/账号策略仍待冻结，不应先把新平台值套进现有登录逻辑。

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
| iOS/iPadOS | 干净 R05 worktree 已生成 Runner、Podfile、统一 Bundle ID 和无签名 Codemagic workflow；`flutter pub get --offline` PASS | macOS/Xcode/CocoaPods 云构建、Podfile.lock、Apple Team/签名、TestFlight 和真机行为仍待验 |

R05 **尚未达到验收标准**。R35 需先做 Harmony 渲染/文件沙箱/本地库/定位/安全存储适配，再进入格式和真机性能工作；R36 需在审阅后的源码基线中沿用 `com.xaocen.reader`、完成 Xcode/CocoaPods/Codemagic 云构建、iOS 文件与 Keychain 语义、TTS/音频焦点，以及 iPhone/iPad 布局和恢复。两个完整客户端仍依赖 R06–R10；本次未启动这些工作。

以下是基于目前工程盘点的**相对工作量**，不是排期承诺；不含完整 Reader 功能实现、上架和未确认产品政策：

| 后续部分 | 相对量级 | 依据 |
| --- | --- | --- |
| Harmony TXT/EPUB/图片渲染、书库与导入 | 很高 | ArkTS/ArkUI 与 Flutter/Dart UI、文件及解析插件不能直接复用；当前只有单页合成样本 |
| Harmony 账号安全存储、Picker 授权、定位恢复和 TTS | 高 | 需接系统密钥、文档授权和 Core Speech Kit，并按 R06 冻结平台/设备策略 |
| iOS 可复现构建、Pods 与 Codemagic | 中 | Runner/Podfile/无签名 workflow 已建立，Flutter 依赖解析通过；仍需 Codemagic macOS 解析 CocoaPods、产出并复核 Podfile.lock、实际编译 |
| iOS 文件访问、持久恢复、安全存储和 TTS | 中到高 | 插件入口存在但运行未验证；文档 URL 生命周期、Keychain 策略、语音生命周期仍需适配与真机覆盖 |
| 两端完整设备回归、性能与发行门禁 | 高 | 需要 Harmony 模拟器/真机、iPhone/iPad、签名身份、测试数据及平台政策，不由本次编译替代 |

## 官方平台资料

- HarmonyOS [ArkTS 概览和模拟器差异](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-overview)、[Picker API](https://developer.huawei.com/consumer/en/doc/harmonyos-references/js-apis-file-picker)、[文件持久授权说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/file-persistpermission-V5)、[HUKS 密钥派生](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V13/huks-key-derivation-arkts-V13)、[Core Speech Kit 能力介绍](https://developer.huawei.com/consumer/cn/app/planning)。
- Apple [Bundle ID 字符规则](https://developer.apple.com/help/glossary/bundle-id/)、[Keychain Services](https://developer.apple.com/documentation/security/keychain-services?changes=_1)、[UIDocumentPicker](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller?changes=_4__7)、[AVSpeechSynthesizer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer?changes=_8&language=objc)。
- Codemagic [iOS code signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/)、[iOS simulator build](https://docs.codemagic.io/yaml-code-signing/ios-simulator-builds/)、[first signed build](https://docs.codemagic.io/yaml-quick-start/first-signed-build/)。
