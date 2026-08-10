# M5.5 UI Audit（只读审计）

日期：2026-08-11  
范围：当前实现对照 `AAA/产品定义.txt`、`AAA/V3 XAOCEN Reader-统一原型.html`
和 `AAA/xaocen-v3-design-constraints.html`。本文件只记录差异和拆分建议，
不代表本轮开始大规模 UI 重构。

## 总体结论

当前 Reader 核心壳层已经具备 V3 的主要行为：正文为主体、顶部/底部控制区、
Android 与 Windows 响应式宽度、Flat TOC、Aa/Bookmark/Search/AutoRead 面板。
主要差异集中在 App shell 信息架构：当前 `LibraryPage` 同时承担首页和书架，
没有 V3 原型中的移动端底部导航与桌面端侧栏；桌面端若干面板仍采用受限宽度的
bottom sheet，而不是更适合宽屏的侧栏/居中面板。

本轮没有发现必须阻断日常阅读的 P0 UI 问题。ReaderLocator、readingMode、
ReaderPreferences、Bookmark、Search、ReadingHistory 和 AutoRead 的数据/位置
合同不应因 UI 审计而改变。

## 逐页对照

| 页面/区域 | 当前实际实现 | 与 V3 的差异 | 优先级 | 类型 | 平台 |
|---|---|---|---|---|---|
| 首页 | `LibraryPage` 的 AppBar、最近阅读区域、导入入口、书籍列表 | V3 首页应突出最近阅读/继续阅读，并通过统一导航进入其他一级区域；当前首页与书架混合 | P1 | 结构/信息架构 | Android + Windows |
| 书架 | `ListView.separated` 书籍列表，TXT 导入与删除 | V3 原型倾向卡片/网格、分类/筛选和更清晰的书籍层级；当前功能正确但视觉密度偏工程化 | P1 | 结构 + spacing | Android + Windows |
| Reader | Stack 正文 + 顶部进度 + 底部限宽控制区；vertical/paged 共用语言 | 核心已接近 V3；底部动作较多，Android 小屏单行拥挤，Windows 仍是手机式底栏语义 | P1 | 结构/响应式 | Android + Windows |
| TOC | Flat `DraggableScrollableSheet`，当前章节定位、章节跳转 | Flat 合同正确；桌面端仍是 bottom sheet，宽屏可读性和层级不如侧栏/居中面板 | P2 | 结构/spacing | Android 优先、Windows |
| Aa / 阅读界面 | Bottom sheet；字号、字距、行距、段距、首行缩进、四边距、主题、每书模式 | 设置能力完整；桌面端面板可进一步改为居中限宽/侧栏，当前滑块纵向较长 | P2 | 结构/spacing | Android + Windows |
| Bookmark | 当前书书签 bottom sheet，摘要/备注/orphan/删除/跳转 | 行为合同完整；桌面端侧栏更符合 V3，书签创建后的反馈与排序可再强化 | P2 | 结构/interaction | Android + Windows |
| Search | 当前书搜索 bottom sheet，debounce/isolate、上下文、高亮、精确跳转 | 行为合同完整；桌面端应优先侧栏或可停靠面板，结果状态可增加空结果/取消说明 | P2 | 结构/feedback | Android + Windows |
| 自动阅读 | Reader 底栏入口 + 统一面板；Vertical 预设/滑杆，Paged 间隔 | 已满足当前 M5.4 合同；V3 原型没有强制该功能的既定视觉，后续只需保持与 Reader tools 一致 | P2 | spacing/interaction | Android + Windows |
| 阅读历史 | 独立 `ReadingHistoryPage`，Card/ListTile、继续阅读、删除、统计快照 | V3 “我的/个人中心”信息架构尚未完整；Windows 尚未使用宽屏双栏或表格化布局 | P1 | 结构 | Android + Windows |
| 我的 | 当前 AppBar 入口，主要只有“阅读设置” | V3 预期同步、规则、插件、数据管理等分组；当前是最小功能页，不应伪装成完整个人中心 | P1 | 结构/信息架构 | Android + Windows |
| 阅读设置 | `ReaderSettingsPage` 目前只提供“按键与操作”入口 | V3 需要把阅读相关全局设置、按键设置和数据管理分组；每书排版设置继续留在 Reader Aa | P1 | 结构 | Android + Windows |
| 按键与操作 | Windows command-centric capture；Android physical-input-centric Volume 选择 | 与平台差异合同一致；Windows 页面卡片偏密集，Android 可进一步简化为两颗音量键 | P2 | spacing | Android + Windows |

## 平台差异

### Android

- 需要优先建立 V3 移动端底部一级导航；当前使用 AppBar actions，不是原型中的
  轻量 tab bar。
- Reader 底部动作在窄屏容易拥挤，建议后续保留高频入口（TOC、Aa、更多/AutoRead）
  并把低频动作放入更多面板；不得改变现有功能合同。
- Bottom sheet 是合适的首选交互，但应统一拖拽句柄、最大高度、空状态和关闭行为。

### Windows

- 需要 V3 桌面侧栏/主内容区；当前首页、历史、设置使用标准 AppBar + 单列内容。
- TOC、Aa、Bookmark、Search、AutoRead 当前虽有限宽，但仍是 bottom sheet；后续可
  按面板类型改为居中对话框或右侧栏，避免机械放大手机布局。
- 当前 runner 默认启动尺寸来自 `windows/runner/main.cpp` 的 `1280×720`。
  本次新增的窗口状态保存在 Windows shell 注册表，不进入 Drift：保存 normal
  bounds 与 maximized，忽略 minimized，启动时做 monitor 可见性校验。
- 当前没有 `WM_GETMINMAXINFO`、`SetMinimumSize`、`window_manager` 或其它显式
  minimum-size 设置。`WS_OVERLAPPEDWINDOW` 只提供 Windows 系统窗口框架的默认
  tracking minimum；`MediaQuery.width >= 720` 只是布局断点，不是窗口最小尺寸。
  产品尚未决定最小可用尺寸，因此本轮不强行写死 800×600。

## 优先级定义

- **P0**：阻断核心阅读/导航、造成数据合同风险。本审计未发现新的 P0。
- **P1**：一级信息架构或响应式结构明显偏离 V3，应优先进入 M5.5a/b。
- **P2**：不阻断功能的 spacing、color、type、icon、面板形态和反馈优化。

## 结构问题 vs 视觉问题

结构问题：

- 首页/书架/我的缺少统一一级导航；首页与书架职责混合。
- Windows 没有 V3 桌面侧栏和宽屏主内容布局。
- Reader action hierarchy 尚未按移动端高频/低频分层。
- 历史、设置、阅读工具面板的 Android/Windows 容器策略尚未完全分化。

视觉问题：

- AppBar、ListTile、Card 的默认 Material 感偏强；可通过 token 统一圆角、边框、
  阴影和表面层级。
- 部分页面的留白、标题层级、图标语义、选中态和空状态仍可向原型靠拢。
- 深浅主题需要继续做对比度和 disabled 状态检查，但当前没有已知 crash/P1。

## 推荐 M5.5 拆分

1. **M5.5a：App shell 与导航**
   - Android 底部导航：首页/书架/我的；Windows 侧栏 + 主内容区。
   - 拆分首页与书架职责，最近阅读继续从 ReadingHistory 派生。
2. **M5.5b：Reader action hierarchy**
   - 保持 ReaderLocator/进度合同不变，整理 Reader toolbar 的高频/低频入口和
     面板容器；分别优化 Android bottom sheet 与 Windows 侧栏/居中面板。
3. **M5.5c：历史、设置与状态反馈**
   - 阅读历史宽屏布局、删除/不可跳转状态、设置分组、统一空状态/错误/成功反馈。
4. **M5.5d：视觉 token audit**
   - 统一 spacing、type scale、color/surface、icon size、focus/selected/disabled
     状态；补充 light/dark/system 与 resize 截图回归。

任何后续实现都应先锁定 V3 信息架构，不应在 P2 视觉调整前重新设计 Reader 核心引擎。

## Reader 外观能力规划（本轮只审计，不实现）

### 作用域建议

| 能力 | 建议作用域 | 原因 |
|---|---|---|
| 正文字体颜色 | per-book `ReaderPreferences` | 不同书籍可使用不同阅读主题，且属于正文排版/绘制外观 |
| 阅读背景颜色 | per-book `ReaderPreferences` | 与当前书的阅读舒适度直接相关 |
| 本地图片阅读背景引用 | per-book `ReaderPreferences` | 背景是当前书的阅读呈现选择，不应污染其它书 |
| 图片背景遮罩/透明度 | per-book `ReaderPreferences` | 与图片背景及当前正文对比度绑定 |
| 自定义阅读主题（文字/背景/遮罩组合） | per-book 选择的主题快照或主题 ID | 书籍可独立保留主题；主题定义本身可由共享目录复用 |
| App shell system/light/dark、品牌色、导航表面 | 全局 App appearance | 影响首页、书架、我的、设置等非 Reader 页面 |
| Windows Reader/窗口背景透明度 | 全局 Windows shell appearance；Reader 内容透明另有独立开关 | 原生窗口属性属于桌面壳层，不能让每本书改变整个 App 窗口行为 |

`themeMode` 当前已经属于每书 ReaderPreferences；后续扩展文字色、阅读背景、
图片引用和遮罩时，应继续保持 Reader 外观与 App shell 外观分离。不要把
Windows 原生窗口透明度写入每书偏好，也不要让全局 App appearance 覆盖每书
正文主题的明确选择。

### 图片引用与存储

图片背景不应写入 Drift BLOB。推荐保存强类型引用元数据，例如：

- `assetId`（稳定 ID）
- `sourceUri` 或 app-managed 相对路径
- `contentHash`
- `mimeType`
- `updatedAt`

实际图片文件放在 app-managed assets 目录；如果来源是 Windows 文件或 Android
`content://` URI，应在导入/授权阶段复制或持久化授权后再使用稳定引用。加载时
校验 hash/文件存在性，失效时显示安全 fallback 背景，不让 Reader crash。数据库
只保存引用和必要元数据，不保存图片二进制。

### Windows 真透明的两层能力

Windows 透明必须拆成两层，不能只在 Flutter widget 上设置颜色：

1. **Flutter 内容透明**：Reader 根背景、surface 和绘制层使用可配置 alpha，
   不能由 Material 默认不透明背景重新填满。
2. **Windows 原生窗口透明**：runner 需要原生窗口样式/合成支持（例如 layered
   window、DWM/alpha surface、透明背景的 Flutter host surface），并提供受控
   的 opacity 通道。需要验证 resize、DPI、截图、GPU 合成和性能。

最低目标可以是 opacity = 0，完全看到桌面；但窗口仍保持正常命中测试和键盘焦点。
本项目不默认做鼠标穿透：不要添加 click-through hit-test、`HTTRANSPARENT` 或
其它会让用户失去控制的行为。透明状态必须有可恢复入口/快捷方式，避免正文和
控制区同时不可见。

### V3 入口建议

- **Reader Aa → 阅读外观**：文字颜色、阅读背景、图片背景、遮罩/透明度和自定义
  阅读主题。它们按当前书保存，并复用现有 metrics/paint 分类：文字/背景颜色
  与遮罩通常 paint-only；影响布局的字体或间距仍走 metrics relayout。
- **我的 → 应用外观**：App shell 的 system/light/dark、品牌色和全局 surface。
- **我的 → Windows 桌面窗口（仅 Windows）**：窗口 opacity、透明模式说明、恢复
  默认；不把 native window opacity 放入 ReaderPreferences。
- Windows Reader 内可提供一个轻量“窗口透明度”快捷入口，但最终设置页仍应归属
  应用/桌面壳层，避免与每书正文背景混淆。

### 后续 M5.5 拆分建议补充

1. **M5.5e：Reader 外观数据合同**：先确定 per-book 字体色/背景色/图片引用/遮罩
   与全局 App appearance、Windows shell opacity 的强类型边界；评估 schema/asset
   存储，不实现透明 runner。
2. **M5.5f：Reader 外观 UI**：在 Aa 中加入外观分组、预览、恢复默认和失效图片
   fallback；保持 paint-only 不触发 Locator restore。
3. **M5.5g：Windows 原生透明能力评估**：单独验证 Flutter 内容 alpha、native
   window alpha、DPI/resize/GPU/无穿透交互，再决定是否实现 runner channel。

这些规划项不改变当前 ReaderLocator、reading_progress、ReaderPreferences 现有
字段合同，也不在本轮引入 schema 或第三方依赖。
## M5.5a App Shell 实施记录（2026-08-11）

- 根路由现在进入统一 `AppShellPage`，一级信息架构固定为“首页 / 书架 / 我的”。
- Android 使用响应式 `NavigationBar`；Windows 在宽窗口使用限宽桌面侧栏和主内容区。
- 书架继续复用现有 `LibraryPage`，通过 embedded surface 放入 Shell；Reader、历史、阅读设置等既有入口保持可达。
- Shell 只负责导航状态和 surface 编排，不读取或写入 ReaderLocator、reading_progress 或其他阅读数据真源。
- `LibraryPage()` 默认构造仍保留，兼容既有测试及直接调用方；窗口状态恢复仍由 Windows runner 原生层负责。
## M5.5b：首页 / 书架实施记录（2026-08-11）

- 首页现在只显示 reading history 派生的最多两条最近阅读，并提供继续阅读与空状态入口。
- 书架独立承担完整 collection 的导入、浏览、打开和删除；Shell embedded 模式关闭重复的最近阅读区。
- Windows 宽窗口书架采用有界卡片网格，Android 保持移动列表；Reader、历史、数据和位置合同未改。
## M5.5c Reader 操作层级实施记录（2026-08-11）

- 移动端底栏收敛为目录、模式、书签、界面和更多；搜索/自动阅读在更多面板中保持稳定入口。
- Windows 保留桌面高频入口并使用有界控制区；进度信息和 Reader chrome 显示逻辑保持原合同。
## M5.5d 我的 / 历史 / 设置实施记录（2026-08-11）

- 我的按阅读信息与应用设置分组；阅读历史独立显示会话/时间/脱离书架状态。
- 阅读设置明确区分应用级按键配置与 Reader Aa 的每书排版；Windows/Android 容器分别响应式适配。
