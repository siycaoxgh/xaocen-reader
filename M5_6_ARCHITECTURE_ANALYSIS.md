# M5.6 Architecture Analysis

状态：只读架构审计，未修改生产代码、数据库或 schema。

审计基线：

- Git HEAD：`097848074ebac44879fdf296ea486fcfe4f937cf`
- Drift schema：9
- 当前分支：`feat/m4-horizontal-reader`
- ReaderLocator：`normalized.txt` UTF-16 code-unit absolute offset，唯一位置真源

本报告只分析当前实现、已观察行为和后续拆分，不进入 TTS、EPUB、RSS。

## 1. 十项现状与根因

### 1.1 Reader 颜色提示：已有基础，但“当前生效”语义不够明确

当前实现已经具备：

- `ReaderPaletteResolver` 统一解析 preset/custom 与 light/dark variant；
- `ReaderPreferences.paletteId` 区分 preset 与 `custom`；
- Aa 面板显示当前编辑的“浅色方案/深色方案”；
- `ReaderResolvedAppearance` 计算真实正文/背景颜色和 WCAG 对比度；
- 低对比只警告，不替换用户选择。

当前缺口不是数据层，而是提示层：

- 自定义区域的“当前使用”指向当前亮度，不一定表示“自定义颜色正在生效”；当
  选择 preset 时，用户仍可能误以为旧 custom 颜色在绘制；
- 低对比提示主要在 Aa 编辑态出现，Reader 正常阅读中不应出现干扰性提示；
- “当前编辑方案”和“当前生效方案”应分别展示，不能混用。

建议增加 transient 的 `ReaderPaletteResolutionInfo`（来源 preset/custom、有效亮度、
是否有 custom 覆盖、contrast ratio、warning），不增加持久化字段。Aa 只在编辑区展示
轻量提示和小预览；正文中不显示 toast/banner。切换 palette 时以 preset 为唯一 paint source，
只有选择“自定义”后 custom override 才重新生效。

作用域保持不变：Reader 配色是每书设置；App shell 的 system/light/dark 是全局外观，
不能互相覆盖。当前 `XaocenApp.appThemeMode` 固定为 `ThemeMode.system`，全局 App 外观
尚未形成独立持久化设置，这与每书 Reader 配色应继续分离。

### 1.2 AutoRead 状态条：当前确实绕过 Chrome 显隐

`ReaderChrome.build` 当前先构造可隐藏的 `chrome`，随后无条件按：

```dart
if (autoReadState != AutoReadState.idle) ReaderAutoReadStatusBar(...)
```

因此状态条位于 `IgnorePointer/AnimatedOpacity` 之外。Chrome 隐藏时，正文仍会看到
状态条；这正是“状态条一直显示并遮挡阅读”的根因。AutoRead driver 本身不需要改变。

最终合同应为：

- `visible == true && state != idle`：显示状态条及暂停/继续/停止；
- `visible == false`：状态条、按钮一并隐藏，但 driver 继续运行；
- Chrome 再显示：状态条从当前 state 恢复；
- 不因隐藏/显示 Chrome 改变 Locator、ReadingSession 或 AutoRead state。

这是现有 UI 组合错误，属于可直接修复的 P1，不是新状态机。

### 1.3 Windows 窗口边框：目前只有标准有边框窗口

当前 runner 在 `windows/runner/win32_window.cpp` 使用 `WS_OVERLAPPEDWINDOW`，因此有
系统标题栏、边框、最大化/最小化按钮。窗口 normal bounds 和 maximized 已保存在
HKCU 注册表，minimized 不保存；启动先恢复 normal bounds，再应用 maximize；没有
`WM_GETMINMAXINFO`、`SetMinimumSize` 或产品自定义最小尺寸。

“无边框阅读”尚未实现。实现它不能只改 Flutter：需要切换 `WS_OVERLAPPEDWINDOW` /
`WS_POPUP` 或等价 style，并补充：

- `WM_NCHITTEST` 的标题拖动区和四边 resize 命中测试；
- 双击标题区最大化/恢复；
- `WINDOWPLACEMENT` 与多显示器/DPI 的保存和恢复；
- 隐藏窗口后的可恢复入口。

无边框与透明不是同一设置，但都会触及 native runner。透明窗口若采用 layered/DWM
合成，还会放大 GPU、截图和输入命中测试风险；不能把两者绑成一个简单开关。

### 1.4 Windows 任务栏/托盘：当前没有托盘能力

当前没有 tray 依赖、native tray icon、全局恢复菜单或最小化到托盘逻辑。标准窗口天然有
任务栏按钮，`SetQuitOnClose(true)` 使关闭窗口退出进程。

建议的 typed 状态是：

```text
taskbarVisible: bool
trayVisible: bool
```

规范化规则：

1. 两者都为 false 时，拒绝提交并恢复上一次有效组合；首次默认 `taskbar=true`；
2. taskbar=true：标准窗口任务栏入口；
3. tray=true 且窗口关闭/隐藏：进程保留，托盘菜单负责显示、恢复、退出；
4. taskbar=false、tray=true：允许无任务栏按钮但保留托盘恢复；
5. 任何异常导致两个入口同时消失时，启动时强制恢复 taskbar，且提供明确恢复命令。

关闭行为必须区分“关闭窗口”和“退出应用”：启用托盘时关闭只隐藏并保留进程；
未启用托盘时维持当前退出行为。该能力属于 Windows shell 新功能，不属于 ReaderPreferences，
可以放入 app_settings/native shell 配置，不需要立即升级 Drift。

### 1.5 Windows Boss Key：当前不存在 app-local 或 global chord

当前代码只在 Paged Reader 和设置页监听 Flutter pointer/wheel；没有左键+右键同时按下
的 chord 状态机，也没有 `RegisterHotKey`、低级鼠标 hook 或 native MethodChannel。

建议分两级：

- 首版 app-local：仅窗口激活且鼠标事件进入应用时，记录 left/right 按下状态；两者同时
  按下触发隐藏，再次触发恢复。释放、超时和窗口失活清理状态；
- 后续 global：需要 native low-level hook 或系统 hotkey，必须明确 opt-in、权限/安全说明，
  并保留托盘或启动时恢复路径，避免隐藏后无法找回窗口。

绑定入口放在“我的 → 快捷键与操作”，不进入 Reader Aa。持久化应扩展平台输入 profile
（稳定 gesture ID），不直接持久化 Win32 message 或句柄。

### 1.6 Windows 阅读透明：当前只有图片背景透明度/遮罩，没有窗口或文字透明度

现有实现：

- per-book 图片背景 opacity；
- per-book 图片 overlay/scrim opacity；
- Flutter Reader 根 `Scaffold`、`ColoredBox` 和 Material surface 仍是不透明背景；
- native Windows runner 没有 alpha/layered window 支持；
- 正文 `TextStyle.color` 是完整 alpha，未提供独立文字透明度。

因此必须拆成两个独立合同：

**A. 背景透明度**

- `readerSurfaceOpacity`：仅 Reader 内容 surface，建议按书保存，paint-only；
- `windowOpacity`：Windows 原生窗口 alpha，属于全局 Windows shell，保存在 app_settings
  或 native shell 配置，不放入 ReaderPreferences。

目标“背景 0%、文字 100%”只有在 Flutter surface 透明和 native window 合成同时支持时
才成立。需要验证 `WS_EX_LAYERED`/DWM/Flutter host surface、GPU、resize、截图和 DPI，
不能先在 Flutter 里把 Scaffold 改透明就宣称完成。

**B. 文字透明度**

- 只对正文 paint 使用 `textColor.withValues(alpha: x)`；
- RGB 分量保持不变；
- 不参与 font metrics、layout signature、分页或 Locator；
- 图片 overlay 不得偷偷改变文字 alpha，二者独立调节。

这是 native 高风险专项，不应与 Reader 位置模型混合。

### 1.7 Reader 极简信息层：当前是部分实现，且仍有浮窗感与时间门控问题

当前 `ReaderMinimalInfoLayer` 仅在 Chrome 隐藏时显示：

- 顶部：章节标题 + 本章进度；
- 底部：时间 + 全书进度；
- 使用 `MediaQuery.viewPadding`，没有硬编码 status bar 高度；
- 使用 `_MinimalInfoCard`（半透明 Material、圆角、elevation）。

当前没有逐项配置“章节/时间/本章/全书/分隔线”的显示开关，也没有
`top-left/top-center/top-right`、`bottom-left/bottom-center/bottom-right` 槽位模型；
只能粗粒度控制 top/bottom/progress/time mode。

时间的真实根因在显示路径而不是 formatter：`_formatClock` 的 24 小时和 12 小时实现
本身正确，但 `_showReaderClock` 只有在 `statusBarMode == readerInfo`、Chrome 隐藏、
`showBottomInfoBar == true` 且 `timeDisplayMode != hidden` 时才返回 true。默认
`statusBarMode` 是 `system`，所以用户只切换 12/24 小时，往往看不到任何时间，形成
“两种格式都不显示”的实测现象。设置页也没有把“时间格式依赖阅读器信息栏”表达清楚。

建议后续使用 slot-based transient view model：字段、slot、separator、有效亮度和当前值
都在 resolver 派生；不保存自由像素坐标。视觉上改为正文边缘的低干扰文字/分隔线，不再
使用玻璃卡片/elevation。分页仍显示 `本章 x / y 页 · 全书 z%`，纵向仍显示百分比。

交互参考只取行为：

- [binbyu/Reader](https://github.com/binbyu/Reader) 将背景、颜色、字距、段距等集中在
  显示设置，并提供取色器/快捷键思路；
- [legado-with-MD3](https://github.com/HapeLee/legado-with-MD3) 强调可配置阅读界面、
  阅读记录的时间/章节维度，以及 Material 3 分组组织。

两者均不复制源码，也不改变 XAOCEN 的 UTF-16 Locator 合同。

### 1.8 Reader Font：当前系统默认 + fallback，尚无字体注册表/导入

`AppTypography` 收敛 App shell type scale 和 fallback；`ReaderTypography.body` 不设置
具体 `fontFamily`，使用平台默认字体并附加 `Noto Sans CJK SC / Microsoft YaHei /
Noto Sans / sans-serif` fallback。显示与测量共用 `TextStyle`，`PagedLayoutSignature`
已经把 `fontFamily` 和 fallback 纳入 metrics。

建议路线：

1. 系统默认：`fontId = systemDefault`，不复制字体文件；
2. Windows 已安装字体：使用 native/Flutter 字体枚举，仅返回可用 family 名称；
3. Android 系统字体：优先平台可用 family，设备差异必须有 fallback；
4. TTF/OTF 导入：复制到 app-managed `fonts/`，按 SHA-256 去重，记录 family、format、
   size、hash、createdAt、path；
5. TTC：可读取但需确认 Flutter/Skia 对 collection face index 的支持，首版不承诺；
6. 删除/失效：fontId 无法解析时回退 `systemDefault`，提示用户但不阻塞 Reader；
7. 任何 fontId 变化都必须 freeze → relayout/repaginate → 原 Locator 精确恢复 → visible/page
   confirm，旧 layout generation 必须失效。

字体选择是 per-book `ReaderPreferences`；字体文件注册表是全局 app-managed 资源。删除
字体前应找出引用书籍并先回退，不能让 Reader 在 layout 时抛异常。

### 1.9 DataRoot / Portable Mode：当前没有统一根目录抽象

当前启动路径分散在：

- `AppDatabase.open()`：`getApplicationSupportDirectory()` 下的
  `xaocen_v4_local.sqlite`；
- `bootstrap()`：同一 support 目录下的 `library/`；
- 图片背景、managed TXT 由 `LibraryFileManager` 继续在 library 下解析；
- 没有 portable/instance manifest、统一 backup metadata 或 root selector。

推荐先建立 `DataRoot`（纯路径/策略层，不改变 Locator）：

```text
DataRoot
├── database/xaocen.sqlite
├── books/                  # managed source/normalized/index/manifest
├── reader_backgrounds/
├── fonts/
├── settings/               # 可选 native/app settings export
└── backup/metadata.json
```

**Standard**：继续使用平台用户可写 application-support 目录，首次引入时保持现有
`library/` 兼容映射，避免重新导入或移动数据。

**Portable / Instance**：由启动参数或显式实例选择，在程序目录旁使用 `data/`；绝不能
默认写入 `Program Files`。每个实例有 `instance.json`（epoch、schema、root ID、createdAt、
app version），数据库和资源全部相对该 root，多个实例互不引用。

导入/导出/备份应以 manifest + 相对路径 + hash + schema/app version 为单位，采用临时目录、
flush、校验、原子替换；恢复前先做目标 root 和版本检查。云同步未来也应同步这套 manifest
和 domain 数据，而不是同步绝对路径。

DataRoot 应在 Font Import 前实现：字体、图片、managed TXT、数据库和备份需要同一套 root
策略；否则后续字体导入会再次散落路径，portable 迁移成本更高。DataRoot 本身不必升级
Drift，但现有绝对/相对路径解析必须统一到它。

### 1.10 Windows 自定义 PageUp/PageDown/Arrow：静态链路已定位高概率吞键点

当前链路逐层检查结果：

1. **PhysicalInput**：`PhysicalInputId` 稳定字符串包含 arrows/PageUp/PageDown；
2. **Gesture**：设置捕获和 Reader runtime 都调用 `readerInputGestureForKey`；
3. **Profile**：`ReaderInputBindingsRepository` 从 app_settings 读取、watch、normalize，
   单键与 Ctrl/Alt/Shift gesture 可持久化；
4. **Router**：`ReaderInputRouter.handlePhysicalGesture` 查 profile，再以 generation
   microtask dispatch `ReaderCommand`；
5. **Reader action**：`previousPage/nextPage` 进入 `PagedReaderController`，chapter/control
   走 ReaderPage 回调；
6. **模式过滤**：page command 在 vertical 中明确 no-op，paged 才翻页；这是合同，不是
   PageUp/Arrow 失效根因；
7. **AutoRead**：`_routerPreviousPage/_routerNextPage` 先 pause(manualNavigation)，然后
   继续执行同一次页面操作，没有故意吞掉本次输入；
8. **Focus**：Windows paged runtime 依赖 `PagedReaderView` 内部 `FocusNode(autofocus: true)`。
   `PageView` 内部的 `Scrollable` 也拥有默认键盘滚动 actions。Arrow/PageUp/PageDown 很可能
   在子 Scrollable 的默认 action 层被消费，外层 `_onKeyEvent` 因此收不到；Space 不触发
   该默认分页 action，所以能到达 Router。这与“Space 有效、PageUp/PageDown/Arrow 无效”
   的真人现象一致。

因此当前最可信的根因是 **PageView/Scrollable focus 与默认键盘 action 抢占了分页键**，而
不是 repository 未写入或 Router command 错误。静态审计尚未替代真人复现；修复前应加
Windows widget/integration 日志确认 event 是否进入 `_onKeyEvent`。

另外，当前 API 名称是 PhysicalInput，但 runtime 使用 `event.logicalKey` 映射稳定 ID。
设置捕获与 Reader runtime 两端目前一致，所以不是此次回归的直接不一致；但它会随键盘布局
变化，长期应改为明确的 `physicalKey` 映射或同时保存 physical/logical display identity。

建议修复方向：

- 让 Reader route 的专用 Focus/Shortcuts 层在 PageView 之前拥有键盘事件；
- PageView 获得点击后重新 requestFocus，Aa/TOC 返回 Reader 后也恢复 focus；
- 对 Reader 已绑定键的 Scrollable 默认 actions 做明确拦截，仍只调用 Router，不直接调用
  `PagedReaderController`；
- key-up/repeat 规则沿用 capture/runtime 统一合同；
- 增加 PageUp/PageDown/Arrow 单键、组合键、vertical no-op、paged dispatch、focus 丢失后
  恢复、AutoRead pause+continue 的真实 widget/integration 测试。

这是当前唯一需要优先直接修复的功能性 P1。Profile migration、null binding、冲突检测和
Space/toggleAutoRead 现有合同不应因修复而改变。

## 2. Windows / Android 差异结论

| 能力 | Windows | Android |
|---|---|---|
| 输入来源 | keyboard、Ctrl/Alt/Shift gesture、wheel | Volume Up/Down，宿主 MethodChannel |
| Reader profile | command-centric，多命令 | physical-input-centric，仅上一页/下一页/不使用 |
| Chrome/窗口 | border、taskbar、tray、透明可属 shell | edge-to-edge、cutout、system/navigation inset |
| Reader 配色 | per-book，与 Windows shell opacity 分离 | per-book，与 Android App theme/system bars 分离 |
| 字体 | 可枚举已安装字体，导入需托管文件 | 依赖设备字体/fallback，导入需 app-managed 复制 |
| Boss key | 可做 app-local/native global hook | 不纳入本阶段，避免系统手势/电源键风险 |

Android Volume 继续保持：paged 且有 binding 才拦截；vertical、Reader 外、disabled 都
交还系统音量；capture 临时优先。不要因为 Windows shortcut 或 AutoRead 扩大 Android
Volume command capability。

## 3. DataRoot 推荐方案

DataRoot 是字体导入前的架构前置项，而不是 ReaderLocator 或 Drift 的替代品：

1. 启动最早阶段选择 Standard/Portable/Instance root；
2. 所有数据库和 managed assets 只接受 root-relative path；
3. `LibraryFileManager`、`ReaderAppearanceAssetRepository`、未来 FontRepository 和
   backup/restore 共用同一 root；
4. Standard 首次迁移保留当前 support/library 布局，可用兼容 alias；
5. Portable 要求显式选择，不写 Program Files；
6. 每个实例用 root ID 和 lock/manifest 防止误连另一份数据库；
7. 备份恢复采用 manifest/hash/atomic swap，不以绝对路径或 page/scroll 状态为依据。

DataRoot 元数据可以是 root 下的 JSON/manifest，不需要为了路径本身升级 Drift。若未来
需要在 UI 记录最近使用的 root，可使用 app_settings；不要把 DataRoot 绝对路径写进每书
ReaderPreferences。

## 4. Schema 风险

当前 schema 是 9，不是 6。M5.6 分析范围内没有必须升级的现有修复：

- 颜色提示、AutoRead Chrome 显隐、时间门控修复：无 schema 变化；
- Windows border/taskbar/tray/Boss/window opacity：优先 app_settings + native registry，
  无需 Drift；
- info layer 的 slot/字段若按书持久化：建议 schema 10，新增专门的 typed
  `reader_info_preferences` 表或明确版本化 JSON 列；不要把自由像素坐标或位置真源混入
  `reading_progress`；
- Font：若实现 per-book `fontId` 和全局字体注册表，建议正规 schema 10/11（具体版本
  取决于 info layer 是否先落地），包含 font asset、hash、family、format、path/status，
  并对失效字体做 fallback migration；
- DataRoot/backup：root manifest 外置即可，不要求 Drift 升级。

任何 schema 变更都必须保留现有 books、managed TXT、reading_progress、readingMode、
ReaderPreferences、bookmarks/history/sessions，并通过真实 SQLite migration/PRAGMA 验证。

## 5. 推荐实施顺序

### P1 直接修复（先做）

1. 收口 AutoRead status bar 到 Chrome visibility；补 hidden/visible widget regression。
2. 修复 Reader info clock 的显示门控和设置文案，补 12/24 小时 rendered-string test。
3. 修复 Windows PageView focus/default Scrollable 抢键；补 PageUp/PageDown/Arrow、Space、
   custom command、AutoRead manual-navigation 的 integration coverage。

### P2 小范围体验修复

4. 引入 palette resolution info：Aa 显示“编辑方案/当前生效来源/有效亮度/低对比警告”，
   只做 transient derived state，不改 schema。
5. 将极简信息层从浮动卡片收敛为低干扰文字/分隔线，先固定默认槽位，再决定是否开放
   每项 slot 配置。

### 独立 Windows shell 专项

6. Window frame mode（有边框/无边框）与 hit-test/resize/maximize/recovery。
7. Taskbar/tray 互斥保护、关闭行为和 crash/restart recovery。
8. Boss Key app-local chord；global hook 另立风险评审。
9. Window opacity/native transparency 与 text alpha 分离，先做 spike，不通过就停。

### 数据与字体前置/后续

10. 先实现 DataRoot Standard/Portable/Instance 与 backup manifest。
11. 再实现 FontRegistry、fontId、hash/dedupe、失效回退及 metrics relayout。
12. 最后实现可配置 info slots（若产品确认需要持久化，再做 schema 10）。

## 6. Bug 与新功能边界

### 可直接修的现有 Bug

- AutoRead 状态条在 Chrome 隐藏时仍遮挡正文：P1。
- 12/24 小时均不显示的门控/文案问题：P1（formatter 本身不是根因）。
- Windows PageUp/PageDown/Arrow 自定义绑定被 PageView/Scrollable focus 吞掉：P1，需先
  用运行日志和真实键盘测试确认后修复。
- Aa 中 preset/custom 的“当前生效”提示不够准确：P2。

### 需要单独 milestone 的新功能

- 无边框窗口、任务栏/托盘、Boss Key、Windows native transparency；
- Reader surface/window opacity 与文字 alpha 双层能力；
- slot-based 极简信息配置；
- 系统字体枚举、TTF/OTF/TTC 导入、FontRegistry；
- DataRoot portable/instance、完整备份恢复和未来同步基础。

## 7. 核心合同保持不变

无论后续实施顺序如何，以下合同不可改变：

- ReaderLocator 仍是 normalized UTF-16 absolute offset 唯一位置真源；
- pageIndex、PageWindow index、scrollPixels、chapter progress/page metrics 只能是 derived；
- metrics 字体变化继续走 freeze → relayout/repaginate → exact Locator restore → confirm；
- 配色、透明度、信息栏、Chrome、AutoRead UI 变化不得写额外 reading_progress；
- ReadingSession 由 Reader foreground/lifecycle 管理，AutoRead pause 不暂停阅读时长；
- Android Volume 的系统音量 fallback 不被 Windows 能力污染；
- storage key/JSON 只能留在 repository/storage 层，UI/Reader 消费强类型模型。

