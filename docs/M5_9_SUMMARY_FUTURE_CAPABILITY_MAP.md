# M5.9 Summary + Future Capability Map

> **Historical planning snapshot:** this file captured the boundary before the
> later M5.9c/M5.9d implementation stages. Its statements that RSS/Atom,
> WebArticleSource, WebBookSource and Content Transform were merely planned are
> superseded by the corresponding stage reports and
> `RELEASE_BASELINE_2026_09_18.md`. Keep this document for design rationale;
> do not use it to decide current product support or release artifacts.

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

本文件只汇总 M5.9 已完成的架构合同，并登记后续能力边界。本轮没有修改生产代码、数据库 schema、Reader、平台 Runner 或构建产物。

## 1. M5.9 当前基线

### 1.1 TXT

TXT 仍通过现有本地导入管线处理：外部文件只读，受管副本、normalized text、索引和 manifest 进入当前 profile 的 DataRoot。`ContentSource → ContentCollection → ContentItem → ContentDocument` 负责来源、书籍、章节/全文条目和规范化文档范围。

标题、作者、简介具有来源信息；书名修改不会改变 source identity、collectionId、sourcePath、进度、书签、历史或 ReaderPreferences。

### 1.2 EPUB

当前 EPUB 已支持：

- package metadata、manifest、spine 和 EPUB3/NCX TOC；保持原始 spine 顺序；
- 通过 EPUB adapter 生成统一 `ReaderContent`；
- 导入到现有 Library/Drift 层并按 content hash 去重；
- normalized text + UTF-16 文档范围；
- 基础标题、段落、粗体、斜体、有限 CSS 和本地内嵌图片；
- EPUB3 `cover-image` 与 EPUB2 `<meta name="cover">` 封面识别；
- 自动封面与手动封面共用现有 `coverPath` / `coverSource` 优先级。

复杂 CSS、脚本、DRM、远程资源、音视频、复杂脚注、在线 metadata/cover 仍是待规划能力。

### 1.3 ReaderContent

`ReaderContent` 是 Reader 运行时只读聚合，不负责数据库写入、文件字节、分页、进度或 Locator 状态。它提供：

- `ReaderContentIdentity`：contentId、sourceId、sourceKind、可选 revision；
- metadata 及 title/author/metadata 来源；
- 保持来源顺序的 documents 和 navigation；
- normalized UTF-16 长度和 primary document；
- 可选 presentation metadata / asset references。

TXT 与 EPUB 都通过 `ReaderContentAdapter` 进入同一 Reader。未知来源不能伪装为 TXT，也不能创建第二套 Reader、分页或进度系统。

### 1.4 UserProfile / DataRoot

当前本地 profile 基础已完成，但不包含账号登录或云同步：

```text
UserProfile       = 本地/未来账号映射的身份与显示信息
DataRoot          = 物理存储与数据库作用域
ContentSource     = 一本内容的来源身份与受管内容入口
SyncProvider      = 未来远端同步传输与冲突协调能力
```

四者不可互相替代：

```text
UserProfile ≠ DataRoot ≠ ContentSource ≠ SyncProvider
```

默认 profile 仍为 `default`；每个 profile 拥有独立数据库、书库、ReaderPreferences、进度、书签、历史、字体和本地 outbox。profile 切换是下一次启动生效的本地 scope event，不是运行时热切换。

### 1.5 Responsive Shell

一级导航固定为：首页 / 书架 / 我的。Windows 宽窗口使用侧栏，Android 和窄窗口使用底部导航或移动布局；三者共享目的地、选中状态和页面语义。`AppShellLayout` 集中维护 720 logical px desktop breakpoint。

Reader、历史、设置、Metadata Editor 是二级页面；Reader 的 Vertical/Paged 只是同一 Reader 的 body 模式。响应式只改变容器和导航外观，不改变 ReaderContent、Locator、Pagination 或 Progress。

## 2. 已冻结模块与不可破坏规则

下列合同属于 M5.9 及之前的冻结基线：

1. `absolute UTF-16 Locator` 是 Reader 唯一位置真相；任何来源 adapter、transform、TTS 或动画都不能另建阅读位置。
2. TXT normalized content、章节源顺序和 EPUB spine 顺序不可因 UI、metadata 或封面处理而改变。
3. `collectionId`、`sourcePath`、ReaderProgress、Bookmarks、History、ReaderPreferences 不得因 metadata/cover/UI 变化丢失。
4. Reader、Vertical/Paged、TOC、TTS、AutoRead 共用同一内容/Locator/Progress 合同。
5. `ReaderContent` 只负责统一 Reader 输入；分页、滚动、进度持久化仍由现有 Reader 层负责。
6. App Shell 的一级导航和 Android/Windows 响应式断点保持稳定；二级页面不得被 root header 清理误删。
7. UserProfile 只表达身份/本地 scope，不包含数据库句柄、路径或网络会话。
8. DataRoot 是本地存储边界；安装目录中的 Flutter runtime `data` 不是用户书库。
9. Reader Theme、Windows True Transparency、Tray、Shortcut、MouseChord、Eyedropper、Android system bar/cutout/orientation 属于已冻结平台/视觉能力，后续修改必须独立审计和回归。
10. 计划中的能力只能标记为“待补充 / 待规划 / 计划中”，不能把未实现能力写成 FAIL，也不能伪造 PASS。

## 3. Future Capability Map

以下项目均为后续能力登记，不代表本轮已实现。

### 3.1 RSS / Atom

状态：**待规划**。

RSS/Atom 应建为独立的 `FeedSourceAdapter`：

```text
Feed / Atom endpoint
  → ContentSource(type = rss/atom)
  → article ContentItem(s)
  → sanitized ReaderContent
```

Feed metadata（标题、作者、发布时间、分类、原始 URL）属于 source/item metadata；文章正文进入统一 ReaderContent。Feed refresh、缓存、网络错误和授权不应进入 Reader 核心。

RSS/Atom 与在线书源不是同一层：RSS 是 feed/文章时间流，在线书源是可持续更新的书籍/章节集合。

### 3.2 WebArticleSource

状态：**待规划**。

`WebArticleSource` 面向单篇网页文章或一次性快照，重点是 URL、抓取时间、canonical URL、标题/作者和净化后的正文。每篇文章可成为一个 ContentCollection 或一个明确的 ContentItem，但不得借用 WebBookSource 的章节续更语义。

### 3.3 WebBookSource

状态：**待规划**。

`WebBookSource` 面向有书籍身份、章节目录、更新顺序和章节增量的在线内容。它应输出稳定的 book identity、chapter items、source revision 和增量事件；不能把网页文章列表简单拼成一本书，也不能把一个网站 parser 写进 Reader。

两者都应通过 source adapter 产出 `ReaderContent`，但 adapter、缓存、刷新和冲突策略保持分层：

```text
WebArticleSource ≠ WebBookSource ≠ RSS/Atom FeedSource
```

### 3.4 净化替换（Content Transform）

状态：**待规划**。

净化、HTML 安全过滤、广告移除、格式替换属于 `ContentTransform`，不属于 Reader、Locator 或 source parser 的隐式副作用：

```text
ContentSource
  → source adapter
  → ContentTransform pipeline
  → ReaderContent
```

正式设计必须保留 canonical source text 和稳定 UTF-16 映射。若净化删除/合并文本，transform 需要提供 transformed range → source range 的 anchor map；ReaderProgress 仍保存 source/canonical locator，不能把临时净化文本偏移当成新的 truth。无法建立可靠映射的变换应只提供展示副本，不能写入 progress/bookmark。

### 3.5 翻译（Content Transform）

状态：**待规划**。

翻译同样属于 Content Transform，不应复制 Reader 或创建第二套 progress。翻译结果可以作为临时或缓存 presentation projection；原文 identity、source revision 和 canonical Locator 必须保留。若用户在译文上做书签/跳转，必须能映射回原文范围，不能静默覆盖原文位置。

### 3.6 更多翻页动画

状态：**待规划**。

翻页动画属于 Reader presentation/transition layer，必须与 Pagination、PageWindow、ReaderLocator 分离：

```text
Pagination  → 决定页面内容与边界
Locator     → 决定当前阅读位置
Animation   → 只决定页面切换过程
```

动画不得重新分页、改变页边界、写入第二个 offset 或让 Vertical/Paged 产生不同的 progress 语义。动画不可用时应回退为当前稳定切换。

### 3.7 Account / Multi-user

状态：**待补充**。

未来账号只应把远端 `accountId` 映射到本地 `UserProfile`，不应把账号身份塞进 DataRoot 路径或 ContentSource。多用户关系建议保持：

```text
UserProfile
  ├─ profile-scoped Library membership
  ├─ ReaderProgress
  ├─ ReaderPreferences
  ├─ Bookmarks / History
  └─ SyncOutbox
```

共享内容库、profile membership、删除/合并和权限需要单独合同；当前“一 profile 一数据库”先保持不变。

### 3.8 Cloud Sync

状态：**待规划**。

`SyncProvider` 只负责远端传输、重试、冲突和能力协商，不负责 Reader 内容解析。优先同步 metadata、progress、preferences、bookmarks 和必要 cover references；正文、临时缓存、设备窗口状态、TTS 队列、DComp、Tray、字体二进制默认保留本地。

同步必须使用 profileId、content identity、normalized/source revision 和幂等 operation id；正文版本不匹配时应进入冲突/待复核，而不是强行覆盖 Locator。

### 3.9 Cross-platform

状态：**待规划**。

跨平台共享范围：domain contracts、ReaderContent、source adapters、metadata/cover priority、Reader/Locator/Progress 和纯 Flutter UI。平台差异只通过 capability/provider 表达：

```text
Android: system bars, cutout, volume/media, background TTS
Windows: window/tray/input, DirectComposition transparency, desktop sampling
```

平台实现不得泄漏到 Domain；响应式布局看 available width/height，平台能力看 capability provider，不能继续复制 Windows/Android 两套 Reader。

## 4. 后续阶段建议（最多 3 个）

### M5.9c-0 — Remote Source Architecture

只定义远程来源、缓存、刷新、错误和安全边界的 contract；明确 `FeedSourceAdapter`、`WebArticleSourceAdapter`、`WebBookSourceAdapter` 的分层，不接真实网站、不做登录、不做同步 UI。

### M5.9c-1 — Content Transform Contract

定义净化/替换/翻译的 transform pipeline、source revision 和 UTF-16 anchor map；先用离线 fixture 验证 Locator/Bookmark/Progress，不接在线翻译服务。

### M5.9c-2 — Sync Boundary + Profile Membership

在不改变当前 DataRoot 的前提下，补充 profile-scoped membership、outbox event schema、幂等键和冲突分类；暂不接云服务和账号登录 UI。

## 5. 阶段结论

- M5.9a 的 ReaderContent、UserProfile registry、Local scope events 和 Responsive Shell 基线可继续冻结。
- M5.9b 的 EPUB 导入、持久化、基础渲染、真实 EPUB 验收和 metadata/cover integration 可继续冻结，兼容边界按各阶段报告执行。
- RSS、Atom、WebArticleSource、WebBookSource、Content Transform、动画扩展、账号和 Cloud Sync 均应保持“待规划/待补充”，不标记 FAIL，也不提前标记完成。
- **可以进入 `M5.9c-0 Remote Source Architecture`**，前提是继续遵守本文件的分层和冻结合同；c-0 仍应只做架构 contract，不直接开始在线书源实现。
