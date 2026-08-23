# M5.9a-1 — Product UI / Data Architecture Audit

审计范围：

- 项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
- 本轮仅做只读审计与方案整理；没有修改生产 UI、Reader、数据库 schema 或平台 Runner。
- 重点覆盖首页、书架、我的、Reader、设置、Windows/Android 响应式、DataRoot、profile、同步边界和未来 EPUB/RSS 接入点。

## 结论摘要

```text
CURRENT UI HIERARCHY = AppShell 三个一级目的地：首页 / 书架 / 我的；Android 使用底部 NavigationBar，Windows 宽窗口使用侧栏；Reader、历史、设置、Metadata Editor 为二级 route/sheet。
DATA ROOT MODEL = stable standard/explicit portable 双模式已经存在；当前 Windows 实例使用 standard profile `default`，安装目录中的 `data` 不是用户数据。
MULTI USER MODEL = 已有 profile-scope 基础，但尚无正式 UserProfile、账号身份、profile UI 或在线会话模型；属于待补充，不是失败。
SYNC BOUNDARY = metadata-first 的本地 SyncOutbox 已存在，但当前没有 repository 写入接线、网络传输和冲突策略；属于待规划，不是失败。
EPUB/RSS INTEGRATION POINT = 复用 ContentSource → ContentCollection → ContentItem → ContentDocument 与同一 Reader；已有 `ReadableTextSource` 为 TTS 的 source-neutral 接口，但正式 `ReaderContent`/source adapter contract 仍待补充。
```

## 1. 当前 UI 层级

### 1.1 根层级

启动链路为：

```text
bootstrap
  → DataRoot.resolve
  → AppDatabase.open
  → XaocenApp / MaterialApp
  → AppShellPage
```

`AppShellPage` 使用一个 `IndexedStack` 持有三个一级目的地：

| 一级目的地 | Android | Windows 宽窗口 | 当前内容 |
|---|---|---|---|
| 首页 | 底部导航“首页” | 侧栏“首页” | 最近阅读、继续阅读、本地书库入口 |
| 书架 | 底部导航“书架” | 侧栏“书架” | TXT 导入、书籍卡片、删除、Metadata 编辑 |
| 我的 | 底部导航“我的” | 侧栏“我的” | 阅读历史、应用设置入口 |

一级导航身份由导航控件表达，当前代码没有再为这三个 root destination 维护第二套 route title。`IndexedStack` 会保留三个页面的局部状态，这是当前实现的稳定行为。

### 1.2 二级页面与 Reader

- `Reader` 由 `openReader` 打开，拥有自己的 `ReaderChrome`、正文、目录、自动、界面、书签和更多面板。
- `Reader` 内的 Aa/阅读设置是当前书作用域，写入 `ReaderPreferencesRows`；它不应与“我的 → 应用设置”混合。
- `/settings` 是应用级设置页，当前包含应用主题、按键与操作、Windows 窗口/托盘等。
- 阅读历史、书籍 Metadata 编辑属于二级页面；返回与保存动作仍由二级页面自己拥有。
- 自动阅读与 TTS 共用 Reader Automation Overlay；详细 TTS 设置仍有低频入口，后续需要继续维护“主入口唯一、详细入口可复用”的约束。

### 1.3 当前结构判断

现有一级/二级边界总体合理，且没有发现必须立即重做的 UI 层级问题。需要在后续产品规划中明确的事项：

1. “我的”目前仍是本地阅读信息与应用设置容器，不是用户账户中心；不能在文案上伪装成已完成的多用户系统。
2. `/settings` 与 Reader 内 Aa 的职责已经分离，但“阅读设置”名称容易让用户误以为包含每书排版；后续应统一命名/说明，不要复制一套设置。
3. `LegacyWindowsShellSettingsPage` 仍存在于代码中但不是当前路由入口。本轮只记录为遗留审计项，不删除。

## 2. Windows / Android 响应式实现

### 2.1 共用部分

Windows 与 Android 主要复用同一套 Flutter 页面、Reader controller、ReaderChrome、ReaderPreferences 和仓库。平台差异集中在：

- Android system bar、cutout、orientation、volume-key bridge、后台 TTS；
- Windows window/tray/input、true transparency、桌面字体和 Eyedropper。

Reader 的 vertical/paged 是同一 Reader 页面内的 body 分支，不是两套 Reader 产品。

### 2.2 当前分叉点

当前代码在多个页面重复使用 `MediaQuery.sizeOf(context).width >= 720`，并同时混用 `Platform.isWindows`、`Platform.isAndroid` 和 `defaultTargetPlatform`：

- App Shell：Android NavigationBar / Windows sidebar；
- Library：embedded root 模式、移动列表、桌面 Grid；
- Settings/History：同一页面不同 maxWidth/padding；
- Reader sheet：宽度、最大高度、部分 Windows 专属能力条件；
- native capability：透明、TTS background、Windows input。

这不是当前功能失败，但存在响应式规则逐步漂移的风险。下一阶段应把“布局类别”和“平台能力”分开：布局只看可用尺寸，平台能力只看 capability provider；不要在业务页面继续堆叠新的平台判断。

## 3. DataRoot 与实际数据位置

### 3.1 代码合同

| 模式 | 根目录 | 启用方式 | 说明 |
|---|---|---|---|
| Standard | Windows：`%LOCALAPPDATA%\XAOCEN\Reader\profiles\<profileId>`；Android：`getApplicationSupportDirectory()/XAOCEN/Reader/profiles/<profileId>` | 默认 | 与 EXE/APK 安装目录分离 |
| Portable | `<exe>\user_data\profiles\<profileId>` | `--portable`、`XAOCEN_PORTABLE=1` 或 `portable.marker` | 必须显式启用；不会因 EXE 所在位置自动推断 |

每个 profile 内的目录合同：

```text
database\xaocen_v4_local.sqlite     Drift 数据库（含 WAL/SHM）
books\local_txt\<contentHash>\      source.txt / normalized.txt / index.json / manifest.json
books\covers\                        本地书籍封面
books\reader_backgrounds\            Reader 背景图片
fonts\                               导入字体文件
settings\                            预留设置资产
backups\                             profile 导出/备份
sync\outbox\                        未来同步的本地变更队列
tmp\                                 导入/临时 staging
```

安装包旁的 Flutter `data\` 目录只包含运行时资源（如 `app.so`、`icudtl.dat`、Flutter assets），不是数据库、书库或用户 profile。

### 3.2 当前 Windows 实例实测

当前机器的标准 profile 为：

```text
C:\Users\TOM\AppData\Local\XAOCEN\Reader\profiles\default\
```

`.xaocen_data_root.json` 显示：

- `mode = standard`
- `profileId = default`
- `migratedFromLegacy = true`
- 当前数据库：`database\xaocen_v4_local.sqlite`
- 当前书库、封面、Reader 背景和 sync 目录均位于同一 profile 根下

这证明当前安装版默认不是“随 EXE 目录移动”的便携数据模式。删除 EXE/Release 目录不会删除 standard profile；反之，删除 profile 才会删除本机书库和阅读状态。

## 4. 当前数据库与身份关系

现有 Drift 数据模型已经形成四层内容关系：

```text
ContentSource → ContentCollection → ContentItem → ContentDocument
```

- `ContentSource` 当前以 `type = localTxt` 表示 TXT 来源，拥有 content hash 和 managed source path。
- `ContentCollection` 是一本书，保存 title/author/description、metadata source、cover source/path 等元数据。
- `ContentItem` 是 chapter 或 whole；章节顺序和 UTF-16 起止偏移保留在数据层。
- `ContentDocument` 指向 managed `normalized.txt` 的范围；正文不写入 SQLite。
- `ReadingProgress` 一书一条，`absoluteCharacterOffset` 是 normalized text 的 UTF-16 唯一位置真源。
- `ReaderPreferencesRows` 按 collection 保存每书阅读外观/布局；Bookmarks、History、Sessions 也按当前 profile 的数据库保存。

书籍 identity 使用内容 hash 派生的稳定 ID，修改标题、作者、简介或封面不会改变 TXT 文件 identity、collectionId、进度或 Locator。

## 5. 多用户模型审计

### 当前已具备

- `DataRoot.profileId` 已是文件系统和数据库作用域边界。
- profile 选择支持 `--profile=<id>`、`XAOCEN_PROFILE` 和 `active_profile.json`。
- 每个 profile 有独立数据库、书库、ReaderPreferences、进度、书签、历史、字体和 outbox。
- profile 导出/导入已有带 manifest/hash 校验的备份服务。

### 当前尚未正式建立（待补充）

- 没有 `UserProfile` 领域实体或 Drift 表；`profileId` 只是本地作用域标识，不等于登录账号。
- 没有 profile 列表/切换/删除 UI；切换是重启作用域，不是运行时热切换。
- 没有 accountId、认证会话、远端设备列表或云端身份映射。
- 由于当前每 profile 一库，“书库归属”是隐含的；未来若要共享内容，需要显式的 profile-library membership，不能把 collectionId 改成用户相关 ID。

### 建议的目标关系（本轮不实现）

```text
UserProfile(localProfileId, accountId?, displayName, timestamps)
  ├─ ProfileLibrary(profileId, collectionId, local metadata/order flags)
  ├─ ReaderProgress(profileId, collectionId, locator)
  ├─ ReaderPreferences(profileId, collectionId, appearance/layout)
  ├─ Bookmarks(profileId, collectionId, locator)
  └─ History/Sessions(profileId, collectionId, snapshots)
```

现阶段可继续保留“一 profile 一数据库”，先补充 profile registry 和类型化边界，再决定是否需要共享内容库；不要为未来登录提前复制第二套 Reader 数据模型。

## 6. 同步边界

### 适合进入同步协议的对象

| 对象 | 建议同步形态 | 约束 |
|---|---|---|
| Profile 元数据 | profile/account 映射、显示名、更新时间 | 不含本地设备路径 |
| ContentCollection 元数据 | title、author、description、metadata/cover source | 以 collection/content identity 合并 |
| ReaderProgress | collectionId + absolute UTF-16 offset + normalizedHash/version | 先校验正文 identity，再处理冲突 |
| ReaderPreferences | 每书字体、主题、排版与阅读显示偏好 | 不同步平台能力字段 |
| Bookmarks | collectionId + UTF-16 offset + note | normalizedHash 不匹配时标为待复核 |
| History | 可选的阅读快照与时间 | 不作为进度真源 |
| 封面/背景 | 可选的 content-addressed binary | 不同步临时 file path；需大小/隐私策略 |

### 默认保留本地的对象

- `source.txt`、`normalized.txt`、index/cache/manifest 等正文与派生文件：当前产品明确不由 SyncOutbox 复制；未来是否云端存正文需单独的内容授权/存储方案。
- 临时导入 job、`tmp`、运行时缓存、解析缓存、TTS 播放队列、AutoRead/TTS 当前 session。
- Windows 窗口位置、Tray、Boss、Raw Input、DComp/true-transparency capability、设备 DPI 等设备能力。
- 本地字体二进制与平台字体枚举结果：默认只同步稳定 font identity/引用，缺失时由本机 fallback。
- 数据库 WAL/SHM 和 lock 文件。

### 当前实现状态

`SyncOutbox` 已能写入带 `profileId/rootId/entityType/entityId/operation/payload` 的本地 JSON 队列，但代码搜索未发现业务 repository 自动 enqueue。也就是说，它是未来同步的结构入口，不是当前已启用的同步功能；网络、认证、重试服务和冲突解决仍为待规划。

## 7. EPUB / RSS 共用 Reader 接入点

### 可以直接复用的基础

1. `ContentSource → ContentCollection → ContentItem → ContentDocument` 已有来源、书籍、条目、文档范围分层；`ContentSource.type` 不应继续只假设 `localTxt`。
2. `TocEntries` 已保存 `kind/parentId/level/orderIndex/start/end`，适合承载 EPUB spine/TOC 与 RSS source/category/date 分组；遵守现有“源顺序权威、内容默认可导航”的合同。
3. `ReaderLaunchContext`、ReaderController、vertical/paged、Locator、ReaderProgress、Bookmarks 和 TTS 均应继续接收统一的 Reader 内容接口，而不是按 TXT/EPUB/RSS 复制 Reader。
4. `ReadableTextSource` 已经是 source-neutral 的 TTS 段落接口，保留原始 UTF-16 范围；它是 TTS 复用点，但还不是完整 Reader 内容抽象。

### 目前缺少的正式抽象（待补充）

建议新增一个平台中立的 `ReaderContent`/`ReaderContentAdapter` contract，至少提供：

```text
contentIdentity
sourceKind / sourceRevision
metadata
ordered navigation entries
normalized readable text or range loader
UTF-16 offset map
mediaType / asset references
```

- **EPUB**：导入器负责 package/manifest/spine/TOC 和资源映射，转换为同一套 collection/item/document；Reader 只看统一文本与 offset map。
- **RSS**：Feed/source 是 ContentSource，文章可作为 ContentItem；文章正文经安全 HTML/富文本转为 Reader 可读文本，保留 source/category/date 作为分组元数据，不另建 RSS Reader。
- **TXT**：现有 `LocalLibraryRepository` 作为第一个 adapter，继续保持 source.txt/normalized.txt/hash/UTF-16 合同。

最重要的保护点是：EPUB/RSS 不能直接制造第二个 pagination、第二个 progress 或第二套 locator。若某来源有多文档/资源，需要在 adapter 内提供统一的逻辑文本坐标与资源引用。

## 8. 风险与待补充项

| 项目 | 当前判断 | 后续处理 |
|---|---|---|
| UI breakpoint 重复 | 代码中多个页面各自判断 720px | 待补充统一 LayoutClass/spacing tokens |
| `embedded` Library 变体 | 同一 LibraryPage 同时服务 root shell 和独立 route | 待规划单一 shell contract，避免新增第三种入口 |
| Legacy Windows settings subtree | 代码仍保留但当前不在路由入口 | 本轮只记录；删除需单独确认和测试 |
| Profile UI | API/目录已有，用户操作入口缺失 | 待补充 profile registry 与安全切换流程 |
| Sync event wiring | Outbox 可用但无业务写入接线 | 待规划事件类型、幂等键、冲突策略 |
| ReaderContent | 现有内容表可扩展，但 Reader adapter 尚未正式抽象 | EPUB/RSS 前必须先补 contract 与 TXT adapter 测试 |

上述“待补充/待规划”不代表失败，也不应在产品状态中标记为已完成。

## 9. 下一阶段最多 3 个小任务

### M5.9a-2 — ReaderContent / Source Adapter Contract

只建立 `ReaderContent`、`ContentSourceAdapter`、`MetadataSource` 的领域接口，并让现有 TXT 路径实现它。增加 identity、TOC、UTF-16 offset map 和 media/asset 引用的合同测试；不接 EPUB/RSS UI。

### M5.9a-3 — UserProfile Registry + Local Scope Events

在不改变“一 profile 一数据库”现状的前提下，补充类型化 `UserProfile` registry、profile 列表/切换边界和安全生命周期；把 metadata/progress/preferences/bookmark 变更接入本地 outbox，但不联网、不做账号登录。

### M5.9a-4 — Responsive Shell Consolidation

集中定义布局类别、断点、面板宽度和 Android/Windows 容器策略；保留平台能力分支，删除新增页面中重复的 720px 判断；以首页/书架/我的/设置/Reader 五组 widget contract 验证，不改变 ReaderLocator 或数据模型。

## 10. 审计结论

- 当前产品已经有可继续扩展的内容四层模型和稳定 DataRoot；不需要为 EPUB/RSS 另建 Reader。
- 当前最重要的结构缺口不是 UI 重构，而是“profile 只是路径作用域”和“ReaderContent 尚未正式抽象”。
- 同步必须先做 metadata/progress/bookmark 的边界和冲突合同，再决定正文/资源上传；不能把数据库复制或安装目录复制当作同步。
- 本轮没有生产代码、UI、数据库或构建产物修改。
