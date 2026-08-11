# M5.5e.2 Reader 交互、主题、字体与 Aa 设置审计

状态：只读分析，不修改代码、不升级 schema。

基线：`ec6ddb8873f9e08da864168ba5a334260fca3ed2`

参考行为：

- [binbyu/Reader](https://github.com/binbyu/Reader)
- [legado-with-MD3](https://github.com/HapeLee/legado-with-MD3)

两者只作为交互、信息架构和配色思路参考，不复制源码。

## 1. AutoRead 新入口与运行状态 UI

当前 Reader 已有 `目录 / 阅读模式 / 书签 / Aa / 更多` 底栏，AutoRead 仍在
`更多 → 自动阅读`。建议将底栏收敛为：

`目录 / 自动阅读 / 书签 / Aa / 更多`

顶部模式图标只显示当前阅读方式的只读状态，不可点击，也不承担设置入口；阅读方式
统一在 Aa → 阅读行为中修改。Search、TOC 以外的低频动作继续放在“更多”。这样
AutoRead 是高频阅读操作，Search 不必占用底栏，也不会出现同一功能在底栏和更多中重复。

AutoRead running 或 paused 时，在正文和底栏之间显示轻量非模态状态条：

- Vertical running：`自动阅读中 · 28 px/s`；Paged running：`自动翻页中 · 5 秒/页`。
- running 直接提供 `[暂停] [停止]`；paused 直接提供 `[继续] [停止]`。
- `stoppedAtEnd` 显示 `已读到本书末尾`，不继续显示可触发的下一次 tick。
- 状态条关闭/Chrome 隐藏只影响显示，不改变 AutoRead 状态；点击暂停、继续、停止
  才改变状态。

Android 状态条应全宽、触控高度至少 44 logical px；Windows 使用限宽条，与桌面
Reader 内容对齐。状态条不写入 Locator、progress 或 ReadingSession。

## 2. AutoRead 下手动翻页/按键合同

手动操作与 AutoRead 自己产生的 navigation 必须有明确来源标记：

| 输入 | running 时行为 |
|---|---|
| Vertical touch / wheel scroll | 先 `pause(manualNavigation)`，再执行滚动 |
| Paged swipe | 先暂停，再由 `PagedReaderController` 执行翻页 |
| Windows keyboard | 先暂停，再经 `ReaderInputRouter` 执行 command |
| Android Volume | Paged 且绑定有效时先暂停，再执行上一页/下一页；Vertical 按既定合同交给系统音量 |
| 上一章/下一章 | 先暂停，再以 confirmed Locator → 真实 chapter start → restore 执行 |
| TOC / Search / Bookmark jump | 先暂停，再执行精确 Locator restore |
| AutoRead 自己的 scroll / nextPage | 不触发 pause |

暂停后不自动 resume。用户需要明确点击继续。打开 Aa、TOC、Bookmark、Search 或
AutoRead 面板时暂停；仅显示/隐藏 Reader Chrome 不暂停。`stop` 是显式结束并回到
`idle`，与手动 navigation 的 `paused` 不混淆。

## 3. 阅读模式最终入口层级

当前存在三处模式相关位置：

1. 顶部 `readerModeActionKey` 图标状态提示；
2. 底部模式按钮；
3. Aa → 翻页中的 `ReaderMode` segmented control。

建议冻结层级：

- 顶部模式图标改为只读状态提示，禁止点击，不打开 PopupMenu；
- 底部模式按钮由 AutoRead 取代，不再重复模式切换；
- Aa → 阅读行为是当前唯一可写入口，包含“阅读方式”：滚动 / 分页；
- `readingMode` 仍只写入该书 `ReaderProgressState`，不进入 ReaderPreferences。

不要把未来的组合塞进单一 `readingMode` enum。长期应拆成三个正交字段：

- `readingFlow`：滚动 / 分页；
- `pageLayout`（分页）：单页 / 双页 / 自动；
- `pageTurnEffect`（分页）：无 / 平滑 / 滑动 / 仿真（未来）。

当前阶段只实现并持久化现有滚动 / 分页合同；双页和翻页效果留后续阶段。

## 4. 主题 × Reader 配色最终模型

### 当前实现事实

- App 根 `MaterialApp` 当前使用全局 `ThemeData.light/dark`，`ThemeMode` 仍为系统跟随；
  这控制首页、书架、设置和 Reader Chrome。
- 每本书的 `ReaderPreferences.themeMode` 决定正文的 system/light/dark 解析；自定义
  `textColorArgb` / `backgroundColorArgb` 是同一组单值覆盖。
- Reader 正文使用 `_effectiveReaderTheme()` 和 `_resolveAppearance()`，Chrome 仍使用
  外层 App `Theme.of(context)`，因此 App UI 与正文配色本来就是两个层次。

### 对候选模型的判断

- A（自定义颜色永远覆盖主题）：实现最简单，但浅色自定义值会被带入深色环境，风险高。
- B（浅色/深色分别保存一套）：最安全但需要扩展当前单值字段，模型较完整。
- C（切换主题自动切换对应预设）：对普通用户最自然，但必须保留自定义覆盖能力。
- D（冲突时提示）：只能作为辅助反馈，不能替代可靠的解析规则。

### 推荐：B + C 的混合模型

Reader 每本书保存一个 `readerPaletteId`（预设或 custom）和亮/暗两套可选自定义
覆盖。解析顺序：

1. `themeMode` 先解析有效亮度：system 使用系统/App 当前亮度，light/dark 强制该亮度；
2. 预设提供 light 与 dark 成对颜色；
3. 当前亮度有用户自定义值时使用该值；没有时使用预设的对应亮度值；
4. 仍缺失或非法时回退安全预设，并明确提示“已使用深色/浅色回退”。

这样从浅色切到深色时不会继续使用浅色正文色，同时不会丢掉用户在两种环境下的
自定义偏好。自定义颜色应继续是 paint-only；字体、字体粗细和字体族则是 metrics-changing。

App Appearance 与 Reader 配色分工：

- App Appearance：全局 shell 的 system/light/dark、导航、表面和品牌色；不绑定某一本书。
- Reader 配色：当前书正文的背景、正文色、图片背景、遮罩和阅读预设；不反向修改
  首页/书架/设置。

## 5. 字体颜色未生效的真实原因

当前不是 Repository 或数据库丢值，也不是正文 `TextStyle` 完全没有接入。真正原因是：

`lib/reader/reader_page.dart` 与 `lib/reader/reader_appearance.dart` 都调用
`ensureReadableTextColor()`。当用户选择的前景色与当前背景色对比度低于 4.5:1 时，
该函数静默返回黑色或白色，而不是用户选择的颜色。数据库仍保存原始 ARGB，因此会出现
“设置值正确、背景已变化、正文部分字体色不变化”的现象。

Reader body 的 vertical / paged 路径都使用解析后的 `_appearance.baseTextStyle`，所以
这不是某一种分页路径漏传；Reader Chrome 使用 App Theme 的颜色也属于设计上的层级差异。

建议改为：用户明确选择的颜色必须用于正文绘制；实时计算对比度并给出警告、示例和
“仍然使用”操作。不要偷偷替换。默认预设仍应满足可读性，图片背景继续通过遮罩提高
可读性，但不能改变用户已确认的正文色。

## 6. 推荐阅读配色预设

预设应是成套的 `fontColor + backgroundColor`，而不是两组互相独立、容易搭出低对比
组合的色块。建议首版表如下（均需在实现时再次用 WCAG 工具验证）：

| ID | 名称 | 正文色 | 背景色 | 用途 |
|---|---|---|---|---|
| paper | 纸白 | `#2B2A27` | `#FFFDF7` | 默认浅色、长时间阅读 |
| warm | 暖黄 | `#3A2F20` | `#FFF4D6` | 暖色护眼 |
| green | 青绿 | `#20352D` | `#EAF4EE` | 低刺激冷暖中间色 |
| blue | 青蓝 | `#1F3344` | `#E8F2FA` | 清晰冷色 |
| night | 夜间 | `#D9D5CB` | `#242424` | 深色环境 |
| ink | 墨黑 | `#D6D6D6` | `#101010` | 极暗背景 |

配色预设可参考 binbyu/Reader 的显示设置、取色器、段距与阅读布局集中管理思路，
以及 legado-with-MD3 的阅读配置分组、Typography tabs、主题/排版即时调整思路；
XAOCEN 只采用行为和信息架构，不复制实现。

## 7. 字体不一致原因

当前首页、书架、设置主要依赖 Material 3 `TextTheme`，但部分页面还直接使用
`TextStyle`、`FontWeight.w600/w700/bold`；Reader 正文自己创建 TextStyle，却没有统一的
`fontFamily` / `fontFamilyFallback` / `fontWeight`。此外：

- AppTheme 没有声明统一字体族；
- Android 与 Windows 的 Flutter 系统字体和 CJK fallback 不同；
- Reader Chrome、正文、章节标题、调试信息分别有局部样式；
- `fontFamily`、`fontWeight` 已参与 paged layout signature，所以将来改动会改变 metrics。

因此观感差异是字体栈和局部 hard-coded weight 共同造成的，不是单一字号问题。

## 8. 系统字体与导入字体未来方案

建议建立独立的强类型 `ReaderFontProfile`，每本书保存稳定 `fontId`，而不是保存
Flutter runtime object：

1. `systemDefault`：跟随当前平台默认字体；
2. `installed:<stable-name>`：仅列出平台确认存在的字体；
3. `managed:<assetId>`：应用管理目录中的 TTF/OTF/TTC，保存 hash、family、来源和版本。

Windows 可通过 runner/native 枚举系统字体；Android 只展示平台实际可用的字体，不能假设
Windows 字体名存在。导入字体应复制到 app-managed assets、校验格式/hash、失败时回退
systemDefault，并允许删除未被书籍引用的资产。字体族、weight、fallback 链均为 metrics
设置，修改时必须复用现有 freeze → relayout/repaginate → Locator restore 合同。

## 9. Aa 最终信息架构

建议保留“排版”和“外观”两个稳定一级分类；将“翻页”更名为“阅读行为”，作为
当前唯一可写的阅读方式入口，并为后续页面布局/翻页效果预留位置；“高级”仅放恢复
默认、兼容性/诊断说明，避免空页。

### 排版

- 文本：字号、字距、行距、段距、首行缩进；
- 边距：Windows 用 2×2（上/下、左/右）紧凑网格，Android 用两行两列或可展开卡片；
- 每行显示当前值和 +/- 精调，滑块只负责连续调整。

### 外观

- 跟随系统 / 浅色 / 深色；
- 成套阅读配色预设；
- 自定义字体色、背景色、取色器；
- 图片背景、透明度、遮罩；
- 实时示例预览和恢复当前书外观。

### 阅读行为

- 阅读方式：滚动 / 分页；
- 分页时的页面布局：单页 / 双页 / 自动（后续实现）；
- 分页时的翻页效果：无 / 平滑 / 滑动 / 仿真（后续实现）；
- 顶部模式图标只读显示当前 `readingFlow`，不重复提供写入口。

### 高级

- 恢复当前书全部 ReaderPreferences；
- 字体资产/兼容性说明；
- 不放普通用户每天会调整的参数。

统一 token 建议：间距 8/12/16/24，面板圆角 12，控件圆角 8 或统一胶囊体系，
Android 控件高度至少 44，Windows 至少 36；不要在同一层混用无语义的圆角、胶囊和矩形。

## 10. Windows / Android wireframe 描述

### Windows

```text
┌─ Reader 顶部：返回 书名/章节进度                 [滚动] ┐
│                                                        │
│                         正文                           │
│                                                        │
├─ 自动阅读中 · 28 px/s                 [暂停] [停止] ────┤
└─ [目录] [自动阅读] [书签] [Aa] [更多] ─────────────────┘

Aa：左侧分类 rail（排版/外观/阅读行为/高级）│右侧紧凑卡片区
    阅读行为：阅读方式（滚动/分页）及未来布局/效果
```

### Android

```text
┌─ 轻量顶部：返回 / 书名 / 当前模式                     ┐
│                       正文                           │
├─ 自动阅读中 · 每 5 秒翻页       [暂停] [停止]          │
└─ [目录] [自动阅读] [书签] [Aa] [更多]                 ┘

Aa：横向分类 chips → 当前分类的单列子面板，控件触控高度 ≥44
```

两端都保持正文为视觉主体；状态条和面板是可关闭的 transient chrome，不参与位置真源。

## 11. 数据模型 / schema 风险

本轮不修改代码、不升级 schema。当前 schema 7 足以保存单值颜色和图片引用，但不能
无损表达“浅色一套自定义色 + 深色一套自定义色”、`paletteId` 或字体资产 profile。

若正式实现推荐模型，应进行一次正规 schema 8 migration（保留旧单值颜色迁移为当前
亮度的 custom override，并为另一亮度回退预设），可能增加：

- `palette_id`；
- light/dark text/background ARGB overrides；
- `font_id` / managed font metadata（或独立字体资产表）。

不要把 per-book 配色写进全局 app_settings，也不要把字体文件或图片 BLOB 写入 Drift。
AutoRead running/paused、状态条、当前预览值仍然是 transient；ReaderLocator、pageIndex、
scrollPixels 和章节进度继续禁止持久化为位置真源。

## 12. 建议实施拆分顺序

1. 先加解析合同和回归测试：主题亮度解析、预设成对颜色、contrast warning、用户色不被静默替换。
2. 调整 ReaderChrome：底栏换入 AutoRead、顶部模式改为只读状态、Aa → 阅读行为成为唯一
   可写入口，并加入运行状态条；保持现有 InputRouter/AutoRead/Locator 合同。
3. 收敛 Aa layout tokens 和四边距 2×2 布局，Android/Windows 分别做响应式 widget 测试。
4. 实现 `ReaderPalette`/`ReaderPaletteResolver`，同时为 `readingFlow/pageLayout/pageTurnEffect`
   的正交模型和旧 `readingMode` 兼容迁移设计 schema 8；
   再做旧 schema 7 → 新 schema 8 的正式迁移
   设计与 migration test；未确认前不改 schema。
5. 统一 AppTypography 与 ReaderTypography，先统一现有字体栈和 weight，再引入系统字体枚举。
6. 最后实现字体资产导入/管理，并为 font family/weight/fallback 的 metrics relayout 做独立
   测试和 Windows/Android 真人体验验收。

本报告结束于分析阶段，不进入 M5.5f，不实现透明窗口或字体导入。
