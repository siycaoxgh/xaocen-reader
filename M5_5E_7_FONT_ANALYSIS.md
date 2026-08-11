# M5.5e.7 Reader 字体系统设计分析

日期：2026-08-11  
基线：`a2cb41957eaf25b70e3cc5b57b5d70038a4320c5`  
Drift schema：8

本阶段只做设计分析，不实现字体导入、字体枚举、字体注册或 schema
迁移。ReaderLocator、分页引擎、ReaderPreferences 的现有行为保持不变。

## 1. 当前实现审计

- App 已有 `AppTypography`，统一 shell 的 type scale、权重和
  `fontFamilyFallback`。
- Reader 已有 `ReaderTypography`。正文没有强制具体的
  `fontFamily`，仍使用当前平台默认字体，并附加共享 fallback。
- `ReaderTextBlock` 在布局比较中已经比较 `fontFamilyFallback`；分页的
  `PagedLayoutSignature`/`textStyleMetricsKey` 也已经包含
  `fontFamily` 和 fallback。后续真正选择字体时，不能绕过这条 metrics
  失效链路。
- `ReaderPreferences` 是每本书独立的排版/外观设置，目前没有 `fontId`。
  颜色、图片背景和阅读位置分别遵守现有 per-book / app-managed / Locator
  合同。
- 现有图片背景由 `ReaderAppearanceAssetRepository` 复制到应用管理目录，
  数据库只保存受控的相对引用。这是字体文件应采用的存储方向；字体不应
  作为 SQLite BLOB 保存。
- `ReaderLocator` 仍是 normalized.txt 的 UTF-16 code-unit absolute offset，
  字体、字体文件路径和排版页码都不能成为位置真源。

## 2. 字体来源与稳定身份

### 2.1 系统默认字体

用一个强类型的 `systemDefault`（或 `fontId == null`）表示，不把 Flutter
运行时 `TextStyle`、`Typeface` 或平台对象写入持久化层。解析失败时始终回退
到该值。

### 2.2 Windows 已安装字体

Windows 可通过 runner/native 层枚举当前用户和系统可见的字体族，Dart
层只接收稳定的元数据快照（族名、样式、来源标识、可用状态）。枚举属于
能力发现，不应阻塞 Reader 首帧，也不应假设注册表路径永久有效。字体列表
应以内存缓存为主，平台字体变化后允许重新扫描。

推荐的系统字体 ID 形式为平台限定的稳定字符串，例如
`windows.system.family.<normalized-name>`。它只是选择引用，实际测量仍由
解析后的字体族完成；找不到该族时回退到系统默认并给出可见提示。

### 2.3 Android 可用系统字体

Android 没有跨版本、跨厂商完全一致的 Flutter 字体枚举接口。可用时通过
最小 platform channel 查询 Android `Typeface` 能力，否则只提供系统默认和
应用已导入字体。Android 返回的系统字体 ID 必须带平台/族名作用域，不能把
某台设备的临时 key 当作跨设备保证。

首版建议：Android UI 至少稳定提供“系统默认”；只有枚举能力确认可用时再
显示系统字体列表。列表不可用不应影响阅读或已导入字体。

### 2.4 导入 TTF / OTF

导入流程应是：选择文件 → 读取并校验字体容器 → 计算 SHA-256 → 复制到
app-managed fonts 目录 → 写入元数据 → 注册运行时字体 → 才允许把选择提交
给本书。原文件被移动或删除不影响已复制的字体。

TTF 和 OTF 是首版最可靠的导入格式。扩展名不能作为唯一校验依据；解析失败、
损坏、超大或不支持的字体必须返回可理解的错误，不能让 Reader crash。

### 2.5 TTC 可行性

TTC 是一个文件中包含多个 face 的 collection，理论上需要额外的
`faceIndex` 才能准确选择字体。各平台/Flutter 渲染路径对 TTC 的加载和
face 选择能力并不完全一致。

推荐合同：

1. 数据模型允许 nullable `faceIndex`；
2. 只有校验器和目标平台都能确认指定 face 可注册时才接受 TTC；
3. 无法选择 face 时明确提示“不支持此字体集合”，不静默取第一个 face；
4. TTC 支持可以作为第二阶段能力，不能阻塞 TTF/OTF。

## 3. 建议的强类型模型

UI、Reader 和 Controller 不直接处理路径或字符串 key，建议建立：

```text
ReaderFontRef
  kind: systemDefault | installedSystem | imported
  fontId: String?              // imported 时为 content-hash identity
  platformScope: String?
  familyNameSnapshot: String?
  faceIndex: int?

ReaderFontAsset
  fontId
  contentHash                 // SHA-256，精确文件字节
  relativePath                // app-managed 相对路径
  format: ttf | otf | ttc
  familyNameSnapshot
  styleNameSnapshot
  faceIndex
  fileSize
  createdAt
  lastUsedAt
  availability: available | missing | invalid
```

`ReaderFontRef` 是 per-book ReaderPreferences 的一部分；`ReaderFontAsset`
是共享资产。多个 collection 可以引用同一个 `fontId`，但每本书的选择仍然
独立。`fontId == null` 明确表示系统默认，而不是“数据库异常”。

文件名、目录名、平台运行时对象都不能作为身份。SHA-256 相同的文件得到同一
`fontId`，即使文件名不同也不重复导入；字节不同则视为不同资产，即使族名
相同也不能错误合并。

## 4. app-managed 字体文件与失效处理

建议目录类似：

```text
support/library/reader_fonts/<fontId>.<format>
```

路径由 repository 生成并校验，禁止使用用户输入拼接任意路径。导入应采用
临时文件写入后原子 rename，避免半写文件被加载。可以设置单文件大小上限和
总资产清理策略，但清理不能删除仍被任何书引用的字体。

字体被用户删除、文件丢失或 hash 校验失败时：

- resolver 返回 system default；
- UI 显示“字体不可用，已使用系统默认”并提供移除/重新选择；
- 不修改 normalized.txt、ReaderLocator、reading_progress 或历史快照；
- 不把失效文件当作另一个字体自动替换；
- 已保存的 `fontId` 可以保留为 unavailable 状态，待用户处理，或在明确
  的“移除字体”操作中置空。

删除共享资产前必须检查引用数；有引用时只删除选择关系，不能静默删除文件。
无引用文件可由显式垃圾回收清理。

## 5. 运行时加载与 fallback

注册层应使用 Dart/Flutter 的字体加载能力（例如以字节注册
`FontLoader`），并以 `fontId` 缓存已注册结果。数据库只保存稳定引用；运行
时的 `FontLoader`、`Typeface` 和 `TextStyle` 不进入 repository。

为避免族名冲突，导入字体的运行时 family 可使用应用命名空间，例如
`xaocen_<fontId>`，元数据中的原始 family 只用于展示。多 face 字体需明确
face/style 映射；不能仅保存一个容易碰撞的家族名。

推荐解析顺序：

1. 已选且已成功注册的导入字体；
2. 选定的可用平台系统字体；
3. `AppTypography/ReaderTypography` 共享 fallback；
4. 平台默认字体。

缺字时允许 fallback 继续工作；用户明确选择的可用字体不能被“可读性”逻辑
偷偷替换。字体失效是可见警告和系统默认 fallback，不是异常退出。

## 6. 对 Reader metrics、分页和 Locator 的影响

字体族、face、style、variation 和 fallback 都属于 metrics-changing；颜色、
遮罩等 paint-only 变化不属于这一类。更换字体必须复用现有状态机：

```text
freeze progress writes
→ capture confirmed ReaderLocator
→ metrics/layout generation + 1
→ 加载并注册目标字体
→ 应用 ReaderPreferences
→ 纵向 relayout / 分页 PageWindow 失效并重建
→ 用原 Locator 精确恢复
→ visible-range/page confirm
→ confirm
→ unfreeze writes
```

加载失败时不应提交一个未注册的字体选择；保持旧字体或系统默认，并维持原
Locator。字体更换不能创建新 ReadingSession，也不能把章节百分比、页码、
scrollPixels 或 pageIndex 写入任何位置表。

Paged cache 的签名必须至少包含：

- collection/normalized hash；
- 字体资产 `fontId` 或系统字体稳定身份；
- 解析后的 family、fallback、face/style/variation；
- 现有字号、字距、行距、段距、首行缩进、四边距；
- viewport 尺寸、text scale、pagination policy version。

已有 `textStyleMetricsKey` 已包含 `fontFamily` 和 fallback；实现字体选择时
只需把稳定解析结果送入同一签名，不应另造第二套 cache key。旧 generation
不得向新 PageWindow 追加页面，bounded PageWindow 合同保持不变。

字体切换后页数变化是正常的（例如 7/12 变成 9/16），但恢复目标必须是同一
UTF-16 Locator，不能恢复到旧页码。四个真实 TXT（含大文件、章节文件）应以
logical error = 0 验证。

## 7. schema 9 判断

本轮是分析阶段，不修改 schema。当前 schema 8 足以继续使用现有字体默认行为，
但一旦实现“per-book fontId + app-managed 导入字体元数据”，推荐正规升级到
schema 9，而不是把字体信息塞进 app_settings 或路径旁路存储。

建议的 8 → 9 migration：

1. 新建 `reader_fonts`（或等价 `font_assets`）表；
2. `reader_preferences` 增加 nullable `font_id`；
3. `font_id` 对资产表使用 `ON DELETE SET NULL`，资产删除后书籍自然回退
   系统默认；
4. 对 `content_hash` 建唯一约束/索引，防止重复导入；
5. 保留所有旧书、ReaderPreferences 颜色/图片/排版、reading_progress、
   readingMode、书签、历史、session 和 managed TXT；旧行的 font_id 为 null；
6. 通过真实 SQLite migration 与 `PRAGMA foreign_key_list` 验证约束，不能只
   依赖 Drift Dart 定义。

如果最终只做“系统默认”而不保存导入资产，schema 9 可以推迟；但这不满足
per-book 自定义字体与 app-managed 文件的完整目标。因此完整实现阶段应把
schema 9 视为合理且必要的正规数据模型变更。

## 8. UI 与能力分层建议

入口仍放在 `Reader → Aa → 排版布局` 的字体卡片，系统默认、已安装系统字体、
已导入字体分组展示；`阅读外观` 继续只负责颜色/背景。每个字体显示预览、
来源、缺失状态和“恢复系统默认”。Windows 可以展示更完整的已安装字体列表，
Android 在枚举不可用时只显示系统默认和已导入字体；两端消费同一强类型模型。

导入操作应有校验进度、成功预览和失败反馈。删除或失效字体需要显示影响书籍
范围；不允许让用户猜测为什么正文回到默认字体。

## 9. 后续实现拆分（本轮不执行）

1. **M5.5e.7a：domain/schema**：`ReaderFontRef/Asset`、per-book
   `fontId`、schema 9 migration 和真实 FK/旧库保留测试。
2. **M5.5e.7b：asset store**：安全复制、SHA-256 去重、TTF/OTF 校验、
   生命周期与 orphan/GC 测试。
3. **M5.5e.7c：platform capability**：Windows 字体枚举、Android 可用
   能力探测、字体注册和缺失 fallback。
4. **M5.5e.7d：Reader integration**：font resolver、metrics signature、
   relayout/repaginate + Locator restore、bounded cache 和 generation。
5. **M5.5e.7e：UI/真人验证**：Aa 字体入口、导入/删除/失效反馈、双端布局、
   四个真实 TXT、Windows Release、Android Debug 与最终真机验证。

## 10. 结论

当前代码已经具备统一 typography 和字体变化必须进入 metrics 的基础，但尚未
具备字体资产身份、per-book 选择或平台枚举能力。建议保留系统默认作为稳定基线，
TTF/OTF 先行、TTC 显式能力检测；完整导入方案采用 schema 9 正规迁移，并始终
以 ReaderLocator 为唯一位置真源。
