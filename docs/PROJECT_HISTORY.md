# PROJECT_HISTORY.md — XAOCEN Reader v4 完整工程时间线

> 记录 2026-08-06 至 2026-08-07 从 Pre-M0 到 M3.4 的真实过程，含失败尝试与修复。
> 只记录当前仓库（v4）历史；已归档的旧 XAOCEN Reader 项目不属于本历史，不引用。
> 原始证据：各阶段 `M*_RESULT.md`、`SPIKE_RESULT.md`、`README_ENGINE_DECISION.md`（均为仓库/父目录实际文件）。

---

## 阶段总览

| 阶段 | 目标 | 分支 | Start → End commit | Commits | 版本 | 验证 |
|---|---|---|---|---|---|---|
| Pre-M0 | 调研/审计/Spike/真机 | （临时目录 research/spike/） | — | — | — | Spike 3+1 全过；真机 8/8 |
| M0 | 工程骨架 | main | `7ce51fe` → `847641b` | 5 | 0.1.0-dev.1+1 | verify 全绿；双平台构建 |
| M1 | TXT 标准化与索引 | feat/m1-local-txt-pipeline | `4b6108c` → `89fe10d` | 6 | 0.1.0-dev.1+1 | 82 测试；真实文件 473/0 章 |
| M2 | 本地书库（Drift 四层） | feat/m2-local-library | `cab2a71` → `e61c8b6` | 6 | 0.1.0-dev.2+2 | 109 测试；真机 9/9 |
| M3 | 纵向 Reader + 精确恢复 | feat/m3-vertical-reader | `45ae988` → `ab866d7` | 8 | 0.1.0-dev.3+3 | 160 测试；真机 9/9（用户+自动化） |
| M3.1 | normalizedHash P1 修复 | fix/m3-normalized-hash-contract | `26d74e5` → `aa73c95` | 6 | 0.1.0-dev.3+3 | 185 测试；真实库修复 |
| M3.2 | 目录完整标题 + 精确跳转 | fix/m3-toc-title-exact-jump | `9bccab6` → `da1a13d` | 6 | 0.1.0-dev.3+3 | 214 测试；真实库 4 本 |
| M3.3 | 目录自动定位 + 深色可读 | fix/m3-toc-current-item-scroll | `68f4be7` → `ce2ff98` | 5 | 0.1.0-dev.3+3 | 250 测试 |
| M3.4 | 平铺目录 + 导航合同 | fix/m3-flat-toc | `38575df` → `f965448` | 6 | 0.1.0-dev.3+3 | 259 测试；真机 13/13 |
| M4 | 横向分页 + 双模式持久化 | feat/m4-horizontal-reader | M3 ff → `2dae263` | — | 0.1.0-dev.4+4 | 327 测试；8 集成；双平台真人验证 |
| M5.1a | ReaderPreferences + Drift | feat/m4-horizontal-reader | `2dae263` → 本阶段提交 | 1 | 0.1.0-dev.4+4 | 338 测试；schema 3→4 |
| M5.1b | Metrics 保位重排 | feat/m4-horizontal-reader | `6c85a49` → 本阶段提交 | 1 | 0.1.0-dev.4+4 | 342 测试；Windows 4 TXT logical error 0 |
| M5.1c | 三态主题 + paint-only | feat/m4-horizontal-reader | `e37e593` → 本阶段提交 | 1 | 0.1.0-dev.4+4 | 346 测试；9 integration；双端构建 |
| M5.1d | V3 日常 Reader 壳层 | feat/m4-horizontal-reader | `651c7e0` → 本阶段提交 | 1 | 0.1.0-dev.4+4 | 352 测试；9 integration 文件 / 12 场景；双端构建 |
| M5.1e | 可用阅读设置面板 | feat/m4-horizontal-reader | `3030ee1` → 本阶段提交 | 1 | 0.1.0-dev.4+4 | 356 测试；9 integration 文件 / 12 场景；4 TXT error 0 |

本阶段提交后合计：67 commits（M0 以来，HEAD 链）；当前分支
`feat/m4-horizontal-reader`。最终 HEAD 以本阶段提交结果为准。

---

## Pre-M0 — 竞品调研、引擎审计、三个 Spike、Android 真机 Spike

### 目标
在写任何代码前回答：技术栈选什么、Reader 核心能否复用现成项目、位置坐标用什么、分页用什么。

### 实现
- **竞品调研**（8 轮检索）：Legado、Readest、ReadYou、Follow/Folo+RSSHub、Miniflux、FreshRSS、Koodo、Thorium、Tachiyomi、Flutter 生态。结论：无项目同时覆盖「本地 + 网络源 + RSS + 统一收件箱」；四层内容模型无直接对标。
- **引擎可行性审计**（binbyu/Reader + legado-with-MD3，仅本地 TXT 链路）：
  - binbyu/Reader：C++/Win32/GDI，全文解码 + **UTF-16 字符偏移**坐标 + 实时位置保存；**无 LICENSE、自定义条款严禁商用** → 不可复制，仅行为参考。
  - legado-with-MD3：Android/Kotlin，**字节偏移**章节边界 + 章节索引+章内字符偏移位置模型；**GPL-3.0** → 不可复制/移植，仅行为参考。
  - 结论：两者主程序代码均不可复制；Fork/FFI/Kotlin 移植全部否决；**行为参考 + Dart 自研**是唯一采用路线；**继续 Flutter**（不切 Tauri）。
- **三个 Spike**（临时目录，未建正式工程）：
  1. GBK/GB18030 解码：pub.dev 无 Dart 3 纯 Dart GBK 包（全部停更在 Dart 2；charset_converter 平台插件行为不可控；charset_codec 需 Rust 工具链）→ **自研纯 Dart 解码器**（WHATWG 23940 双字节表 + 209 锚点四字节表；64MB/s；0x80→U+FFFD 跨端一致；7457→U+E7C7 差异保留 Python 行为）。
  2. 章节扫描：正则 + 相邻去重（行首+缩进、行距≤3、保留行首）；公告「第五十二章被审核了」必须排除（章后须空白/标点/行尾）；**473 章**命中；发现 O(n²) offset 累计 → 正式版必须 O(n)。
  3. TextPainter 分页：首屏 22–29ms；**字符偏移在字体/宽度/滚动/分页变化下稳定**（4/4）；内存 ~7MB 估算 → **锁定 TextPainter**。
- **Android 真机 Spike**（Redmi K60 / Android 15，无线 adb）：8/8 通过——GB18030 表 23940/209、有章节首屏、无章节 7.68MB 首屏、真实内存（PSS 281MB/RSS 431MB，Debug JIT 开销）、字号/横竖屏/重排后偏移稳定、A8 确认 **Android 与 Windows 页边界不同（字体度量差异）但字符偏移语义一致** → 字符偏移坐标系成立。

### 出现问题与修复
- USB ADB 直连失败：Windows 设备被微软通用 WinUSB 驱动抢占（GUID 不匹配），修改官方 INF 被签名校验拒绝 → **无线调试定案**（后续一直沿用）。
- PowerShell 内联命令与中文编码反复踩坑（见 ENGINEERING_LESSONS.md）。

### 最终状态
`README_ENGINE_DECISION.md`（12 项决策确认）+ `SPIKE_RESULT.md` 落盘；未创建任何应用源码。

---

## M0 — 工程骨架（0.1.0-dev.1+1）

### 目标
只做单 Flutter 工程初始化 + git + 最小目录 + 依赖 + 主题/路由入口 + 验证门禁；不实现任何 TXT/Reader/UI 功能。

### 实现
- `flutter create xaocen_reader`；重写 pubspec（版本 0.1.0-dev.1+1；riverpod/drift/sqlite3_flutter_libs/path）。
- lib 骨架：app/（constants/bootstrap/app/router/placeholder）、design/（tokens/theme）。
- `tool/verify.ps1`（7 步门禁）；`test/unit/m0_skeleton_test.dart` 6 项。
- GB18030 asset 位置与格式说明（不放假数据）；版本常量 + dataEpoch `v4-local-1`。

### 出现问题与修复
- Windows Release 构建两次失败：sqlite3_flutter_libs 0.5.42 的 FetchContent 在 configure 期重新 `project()`，把 `CMAKE_INSTALL_PREFIX` 重置为 `C:/Program Files/xaocen_reader`（需管理员）→ 在 `windows/CMakeLists.txt` 的 Installation 段无条件把 install prefix 指向构建目录。
- verify.ps1 初版中文注释被 PowerShell 5.1 按 ANSI 解析出错 → 全英文注释；flutter 不在 PATH → 用 flutter.bat 完整路径。
- git 提交时 PowerShell 把 `chore(project):` 当命令 → 改用 .ps1 脚本提交。

### 验证
6/6 测试；Windows Release（65.8s，exe 91648B）+ APK Debug（179s）；exe 冒烟 6s 无崩溃；verify 全绿；HEAD `847641b`（M0_RESULT.md 记录时 `7532f2f`，`847641b` 为随后补的 docs 提交）。

### 最终状态
clean；M0_RESULT.md 12 项报告；按任务书停止，未进 M1。

---

## M1 — TXT 标准化与索引管线（0.1.0-dev.1+1）

### 目标
正式 TXT 管线：文件校验 → 内容身份 → 编码检测 → GB18030 解码 → 规范化 → 后台 Isolate 卷章扫描 → 目录树 → 原子索引缓存 → 缓存读取与失效判断。

### 实现
- 领域模型：TextEncoding（6 值）、TocEntry、TxtIndex（含 displayTitle 前的旧字段）、PipelineProgress（12 阶段）、LargeFilePolicy（20/50MB 阈值集中）。
- 服务：纯 Dart GB18030 解码器（双/四字节 + replace/strict + 分段输入跨块）、编码检测（BOM→严格 UTF-8→GB18030 候选→unknown，无扩展名判断）、规范化（仅去 BOM + CRLF/CR→LF，O(n)，lineStarts）、O(n) 扫描器（正则 + 相邻去重 + 卷—章）、原子缓存（tmp→序列化→flush→校验→原子替换；校验 size/hash/encoding/parser/normalization/indexFormat，不依赖 mtime）、内容身份（SHA-256，crypto 包）、取消令牌。
- GB18030 Asset 生成器：`tool/generate_gb18030_index.dart` + 内嵌 209 锚点；产出 bin 97,446B，SHA-256 `aebe263d…`（与 Spike 4 真机验证一致）。
- `tool/inspect_txt.dart` 只读诊断。

### 出现问题与修复
- 锚点数据源：`gb18030_ranges_official.json` 是空数组 → 用 spike1 的 209 锚点（Python gb18030 codec 生成）内嵌为 Dart 常量。
- PowerShell 插值 `${pair[0]}` 生成损坏 Dart 数组（`[, ]`）→ 改用 Python 脚本生成。
- 解码器真 bug：`_state==2` 分支第四字节跨块时未置 `_state=3` → 逐字节分段输入四字节序列失败（补状态迁移后 82/82）。
- 编码检测误判：严格 UTF-8 采样 64KB 恰在 65534 处截断多字节序列 → 采样末尾容忍截断（忽略最后 ≤3 字节）。
- O(n²) offset 累计（Spike 遗留）→ 单次 O(n) 顺序扫描（预计算 _lineOffsets）。

### 验证
- 真实文件：有章节 3.7MB → UTF-8 / **473 章** / 9 个指定 offset 全命中 / **首次 251ms**（旧 ~7s，28×）/ 缓存命中 63–127ms；无章节 7.7MB → 0 章 / 368ms / 127ms；外部文件 hash 不变。
- 82 测试全过；verify 全绿；HEAD `89fe10d`。

---

## M2 — 本地书库（0.1.0-dev.2+2）

### 目标
TXT 选择→预检→复制原文件→M1 索引→规范化正文→Drift 四层模型→最小书架→重启持久→删除；不做 Reader。

### 实现
- managed 布局 `<support>/library/local_txt/<hash>/{source.txt, normalized.txt, index.json, manifest.json}`；原子导入 13 步两阶段提交；重复导入 alreadyImported（同名不同内容可分别导入）。
- Drift schema 1（6 表 + FK + 唯一约束 + 6 索引）；正文不落库；确定性 ID（5 种格式）。
- LocalLibraryRepository（6 方法）+ LibraryFileManager（安全删除校验）+ EncodingIndexProvider（FlutterAsset/File/Memory）。
- UI：导入按钮 + 书架 + 进度 10 阶段 + 取消 + 大文件确认。
- M1 管线增加 `onNormalizedText` 回调回传正文（供写 normalized.txt；正文只经内存不入缓存）。

### 出现问题与修复
- Drift 表 id 未标主键导致 FK mismatch（6 表显式 primaryKey）。
- toc_entries.id UNIQUE 冲突（不同书相同章节结构）→ collectionId 前缀。
- Windows `Directory.uri.pathSegments` 尾随空段 → 删除安全校验误拒/漏检 → 过滤非空段。
- AGP 9 + file_picker Kotlin 冲突 → AGP 8.7.3 + 传统 KGP。
- sqlite3 hook 从 github.com 下载被墙 → ghproxy 镜像（pubspec hooks url_pattern）。
- 集成测试 fixture 在 Android 沙箱不可读 → 内嵌字节常量；GB18030 fixture 手写字节序错误（a3ba 写成 ba3a）→ 修正。
- Widget 测试 FakeAsync 不推真实 IO → Provider override + integration_test 承担真实链路。

### 验证
109 测试；Windows 集成 2 文件；**Android 真机 9/9**（含 AssetBundle 23940/209、GB18030 𠀀、alreadyImported、取消不留半成品）；真实文件 473/0 章 + 外部 hash 不变；HEAD `e61c8b6`（ff 合并 main）。

---

## M3 — 纵向 Reader + 精确位置恢复（0.1.0-dev.3+3，schema 2）

### 目标
ReaderLocator（UTF-16 码元偏移唯一真源）、ReaderBlock 派生分块、super_sliver_list 虚拟滚动、真实可见范围、恢复状态机（确认前零写入）、保存分类、目录抽屉。

### 实现
- schema 1→2：新增 reading_progress（collectionId 主键+外键级联、absoluteCharacterOffset、itemIdHint、updatedAt、locatorVersion、normalizationVersion）；onUpgrade 只增不删。
- NormalizedDocumentLoader（manifest 校验：存在/无 BOM/严格 UTF-8/hash/UTF-16 长度；≤50MB 全载内存）。
- ReaderBlock/ReaderBlockIndex（4096–8192 码元，LF 优先，不切 surrogate，确定性重建）。
- RenderReaderTextBlock（同一 TextPainter 显示与测量；local offset↔glyph Rect、characterOffsetAtLocalY、layout 完成回调）。
- 恢复状态机 + 400ms 防抖 + lifecycle flush；目录两阶段跳转（先 jumpToItem 块级）。
- 保存分类：restore 零写入 / tocJump 确认后保存 / 用户滚动防抖 / scroll-end + lifecycle flush。

### 出现问题与修复
- `TransferableTypedData` 位置排查（flutter/services、dart:ui 均错，最终 dart:isolate）。
- 集成测试「进度为 null / 为 0」：恢复状态机 finishRestore 依赖列表 attach → 双 post-frame 重试；GlobalKey 必须作为 Widget key 才能关联 context；fixture 太小只有 1 块 → 生成 27594 字符大 fixture。
- `_visibleRangeForScroll` 早期块级近似 → 后升级（M3.3）。
- Android 构建：androidx.test 动态版本 metadata 404 → dependencyResolutionManagement（google() 优先 + flutter.io 排除 androidx.test）。
- super_sliver_list 准入 Spike 5 通过（双端构建/jumpToItem/不预构建/dispose）。

### 验证
160 测试；4 集成测试；真实文件 9 offset + 无章节比例定位；Windows 全绿；**Android 真机 9/9**（用户开启无线调试后执行；返回动画慢 → 测试加 pop 等待 ab866d7）。**真机白屏教训**：flutter test 会把 app-debug.apk 覆盖为 test-runner 入口版 → 手动安装必须重新 `flutter build apk --debug`。

---

## M3.1 — normalizedHash 合同修复（P1，0.1.0-dev.3+3）

### 目标
修复真实大 TXT 在 Windows 与 Android 打开报 hash_mismatch 的 P1 数据一致性问题。

### 用户发现与错误表现
- 用户电脑 `C:\Users\TOM\Desktop\测试` 与手机 `Documents/测试` 的 4 个大 TXT 打开 Reader 均失败；
- expected `2528925c0ee3946ccedd5911b10d6acaba6e4c592c53feb230d317a5a4aa79db` ≠ actual `d37db97a98372402b0379db75d0624bac4f65d42b7762c28bc94851b59102770`。

### 为什么自动测试没覆盖
- 小 TXT fixture 无 CRLF/BOM，规范化后字节不变 → sourceHash == normalizedHash，拿 sourceHash 校验碰巧通过；自动测试从未用含 CRLF 的大文件走「Drift→Reader」全链（集成测试 fixture 都是小 UTF-8）。

### 诊断如何证明 expected 是 sourceHash
- 新增 `tool/inspect_managed_txt.dart` 只读诊断：collection `local-txt:2528925c…` 的 source.txt 实际 SHA = `2528925c…`（=目录名=Drift 记录值）；normalized.txt 实际 SHA = `d37db97a…`（=manifest.normalizedHash）；文件层与管线完全健康；**唯一损坏点是 Drift content_documents.content_hash 存了 sourceHash**；821 条记录全部如此（m31_dbhash 确认）。

### 最终修复
- 合同：`normalizedHash = 最终落盘 normalized.txt（无 BOM UTF-8 文件字节）的 SHA-256`；
- 共享 `NormalizedArtifact`；12 步写入顺序（tmp→flush→close→落盘算 hash→重解码验证长度→原子 rename→manifest→Drift 事务→最终重读校验）；
- Loader 以 manifest.normalizedHash 为权威，expectedHash 仅回退；ReaderPage 不再把 doc.contentHash 当 expectedHash；
- `ManagedCollectionHealthCheck` + `CollectionRepairService`（保留 source/normalized/collectionId/offset/progress；repair 不改外部 TXT；失败不覆盖旧文件）；
- alreadyImported 三态（健康/repairExisting/corruptedManagedCopy）；Reader 错误页「书籍文件需要修复」+ 修复并重试。

### 回归保护
- hash_contract_test 11 项（8MB 闭环、跨块边界、各损坏场景、repair 全场景、三态）+ repair_service_test 12 项；集成 hash_contract_flow_test（导入→关闭→重开→Loader→Reader 首屏）；大 fixture 用「100 章×80KB」规避 SQLite 999 变量上限。

### 验证
185 测试；真实库 3 大文件 repair 成功 + 821 行更新；外部 TXT hash 不变；Reader 打开青山第 31 章 @192296 成功；Android 用户手动确认（大 TXT 打开/滑动正常/错误消失）；HEAD `aa73c95`。

---

## M3.2 — 目录完整标题 + 精确章节跳转（0.1.0-dev.3+3，parserVersion 2.0.0）

### 目标
目录显示完整标题（非「第X章」片段）；点击目录精确跳到标题行（非块顶）。

### 用户发现
- 目录只有章节序号无完整标题；点目录不能准确定位到标题行。

### 根因
- 标题丢失（情况 B）：M1 扫描器 `title: m.group(0)!` 只取正则匹配片段「第X章/卷」，完整标题从未进入数据链（index.json → Drift → UI 全是短标题）。
- 跳转不准：`jumpToItem(block.index, alignment: 0)` 只对齐块顶，无块内字符二次对齐；且原实现有固定 100ms Timer（违反无固定延迟红线）。

### 实现
- 标题合同：displayTitle（完整行 trim）/ dedupeKey（归一化，不进 UI）/ chapterNumber（单独解析）；parserVersion 1.0.0→2.0.0。
- 两阶段精确跳转：jumpToItem(块) → post-frame rectForCharacterOffset 求标题行 Rect → 二次 jumpToItem(rect, alignment 0) + 12px 微调 → localToGlobal 验证视口相交；bounded retries ≤5；移除固定 Timer。
- 高亮 = 真实可见范围顶部反查（最后一个 start≤topVisible 的 chapter）。
- repair 扩展：按 index.json parserVersion 判定旧数据；repair 显式写 repairDir/index.json（原缺陷：repair 从不写 index.json，旧短标题残留）；Drift 事务同步标题（offset 不漂移才更新）。

### 出现问题与修复
- 真实文件 473→486 回归：正文引用标题的缩进行与行首标题有错别字差异（第468章 这特么 vs 这特码），dedupeKey 比较失败 → 相邻去重附加判据「章节编号相同即视为重复」→ 恢复 473。
- 健康检查曾用「标题太短」猜测（误判「第五十一章」这类合法纯编号标题）→ 改以 parserVersion 为权威。
- 测试断言多次按旧合同写错（楔子 8→7、前言偏移、多字节偏移、第二卷内 order）→ 逐个核对实际 fixture 修正。

### 验证
214 测试；真实库 4 本 repair 后 parserVersion 2.0.0 + 完整标题 + health ok；第 1/19/42/112/195/258/300/400/473 章 offset 全命中；目录点击跳转 + 高亮验证；HEAD `da1a13d`。

---

## M3.3 — 目录打开自动定位当前章节 + 深色可读性（0.1.0-dev.3+3）

### 目标
打开目录即定位到当前章节（视口 35% 处高亮）；修复深色主题下正文不可读（P1）。

### 实现
- `TocIndexLogic` 纯逻辑（currentChapterFor / parentVolumeIdsOf / visibleIndexFor）+ `_TocSheet` StatefulWidget：卷折叠（当前章父卷强制展开）、每次打开最多定位一次、两阶段定位（估算行高 jumpTo → ensureVisible 0.35）、bounded retry（extent 不稳 ≤10 / 实测行高 ≤8）、用户滚动后不拉回 +「定位当前章节」按钮、无固定延迟。
- `_visibleRangeForScroll` 从 block 级近似升级为**块内真实字符级**（视口顶/底坐标 → characterOffsetAtLocalY → 精确 UTF-16 偏移；layout 中/未 attach 安全回退）。
- `ReaderResolvedAppearance`（bg=surface/text=onSurface/secondary=onSurfaceVariant/heading/selection/baseTextStyle）+ WCAG ≥4.5:1；AppTheme.light() + system mode。
- RenderReaderTextBlock style setter：度量变化 markNeedsLayout、仅颜色变化 markNeedsPaint；主题切换不重建 block 索引、不写进度、不改 Locator。

### 出现问题与修复
- Widget 测试 12 项首跑 1 过 11 败：Python patch 破坏中文编码（乱码）→ write 工具整体重写测试文件；测试 4 卷标题在视口外（先 drag 到可见再 tap）；「定位当前章节」按钮不显示（_userScrolled 无 setState）→ 修。
- 正文恢复与目录定位章节偏差：`_visibleRangeForScroll` 用 block 起始近似 → 顶部报 224 章实际 258 章 → preciseTop 字符级计算修复。
- box.dart:2268 断言：layout 期间访问 RenderBox.size → 未 attach 跳过 + layout 期间回退 block 级。
- 真实大 TXT 验证：第 112 章等 autoLocate 早期 maxScrollExtent=0 被 clamp 到 0 → bounded retry；估算行高 48 vs 实际 dense ListTile 不符 → 实测行高重算。

### 验证
250 测试；真实文件 6 章（±1 章，12px 安全区合同行为）；深色 8 项 widget 全过；HEAD `ce2ff98`。

---

## M3.4 — 平铺目录 + 全局内容导航合同（0.1.0-dev.3+3）

### 目标
用户手工测试 M3.3 后产品决定：TXT 层级结构不可靠 → 删除卷折叠，目录始终平铺；并把该原则固化为全局产品合同。

### 实现
- 删除折叠：_collapsed/_toggleVolume/_autoExpandParents/parentVolumeIdsOf/visibleEntries/折叠图标全移除（无死代码）。
- 平铺：volume = Section Header（字重 + 「卷」badge + 间距 + 无箭头，点击跳卷首）；chapter = 完整 displayTitle + 高亮 + 轻缩进；flat = 原始 toc 顺序零过滤。
- 自动定位简化：currentChapterFor → displayIndexFor → jumpTo + ensureVisible 0.35；保留「每次最多一次 / 滚动不拉回 / 定位按钮 / 关闭重开重定位」。
- **全局合同**：`Content hierarchy is semantic, not interactive. Source order is authoritative; navigable entries remain visible.`（层级负责表达关系，顺序负责导航，折叠不参与内容可见性）——覆盖 TXT/EPUB/RSS/Feed/网页；落盘 `docs/CONTENT_NAVIGATION_CONTRACT.md` + 合同测试 8 项。

### 出现问题与修复
- `_locateToCurrent` 在 scroll 未 attach 时直接 return 无重试 → 补 bounded retry。
- 测试适配虚拟列表（混合高度 volume 54px + chapter 40px）；scrollUntilVisible 不稳定 → ScrollUpdate 触发。

### 验证
- 259 测试（251 + 8 合同）；5 集成测试；verify 全绿。
- Windows 真实库 4 collection（473/294 3卷/53 1卷/无章节全文）。
- **Android 真机 13/13**（Redmi K60 / Android 15 / 无线 adb）：覆盖安装数据存留、恢复位置（43/548 章）、平铺无箭头、自动定位高亮（42 章 @39%）、点章节跳转（548→530）、点卷跳转、滚动不拉回、正文滚动保存恢复（八月初七中段）、force-stop、进程退出重进、横竖屏、0 crash（pid 23606 全程不变）。
- 期间教训：image 工具坐标估算 ±200-300px 噪声 → 单次点击现象不能直接判定功能失败（「点 45 章没跳」实为坐标偏差点到当前章节的假象）；keyevent 4 在书架会退出 app。

### 最终状态
HEAD `f965448`（docs Android 结果），工作区 clean，M3 冻结点。

---

## M4.1 — 横向分页核心（0.1.0-dev.4+4）

### 目标（用户收窄指令）
只实现分页计算能力：`document offset → PagedLayoutEngine → PageRange`。
不接入完整 UI；不保存数据库；不修改 reading_progress；不影响 VerticalReader。

### 实现
- **PagedTextRange（PageRange）**：start/end UTF-16 码元偏移，[start,end) 合同；
  纯派生结构，不进 Drift / manifest / ReaderLocator。
- **PagedLayoutEngine**：
  - 行粒度分页（getLineBoundary 行尾对齐）→ 页面视觉连续（无半行跳变）；
  - layoutForwardPage：候选 ≤32768 码元一次布局，逐渲染行累计；
  - layoutPreviousPage：从 end 往回累计行，保证 previous.end == current.start
    （与正向同构 → 100 页往返对称测试通过）；
  - pageContaining：ReaderBlockIndex 锚定 + 有限次 forward（绝不从 0 逐页）。
- **PageWindow**：prev 2 + current + next 3 有限窗口 + 淘汰；Page 对象数
  与全文页数无关（红线 §49-7）。
- **PagedLayoutSignature**：尺寸/字体度量/textScale/padding/policyVersion
  入 key；纯颜色变化不重分页（§32）。
- 引擎层支持：UTF-16 offset、surrogate pair（𠀀）、CRLF 规范化文本、
  长段落（5000 字符无换行）、空文本、无章节 TXT（0 章 → 全文一页链）。

### 出现问题与修复
- 无（引擎层单元测试首轮即过：Ahem 字体确定性分页 + 100 页往返对称）。
- M4.2 阶段（staged 代码）暴露真实缺陷：**PageView 需要窗口预填相邻页
  才能滑动**——初始窗口只有 current 1 页时 fling 无法翻页（PageView
  itemCount=1 无第 2 页可 settle）。已在 staged 控制器加 `_prefillWindow`
  （current 前后各预生成窗口页）。该修复保留在 stash 中，M4.2 接入时生效。

### 验证
- 新增单元测试 27 项（引擎 20 + 窗口 7）全过；
- `flutter test` 全量 313 项通过（M3 基线无回归）；
- `flutter analyze` 零问题；
- M4.1 范围外（M4.2 执行）：真实文件验收、Windows 真人、Android 真机、
  verify.ps1、长期文档全量更新。

### 最终状态
- 分支 `feat/m4-horizontal-reader`，起始 HEAD `539ed8d`；
- M4.2 WIP（控制器/视图/双模式）`git stash` 保留；
- 工作区 clean；按用户指令停止，未自动进入 M4.2。


---

## 附：版本与 schema 历史（git 实测）

| Project version | Milestone | Drift schema | parserVersion | normalizationVersion | indexFormatVersion | Data generation |
|---|---|---|---|---|---|---|
| 0.1.0-dev.1+1 | M0（无库）/ M1 | —（M2 建库）/ 1 隐含 | 1.0.0 | 1.0.0 | 1 | v4-local-1 |
| 0.1.0-dev.2+2 | M2 | **1**（6 表） | 1.0.0 | 1.0.0 | 1 | v4-local-1 |
| 0.1.0-dev.3+3 | M3/M3.1 | **2**（+reading_progress） | 1.0.0 | 1.0.0 | 1 | v4-local-1 |
| 0.1.0-dev.3+3 | M3.2/M3.3/M3.4 | 2 | **2.0.0** | 1.0.0 | 1 | v4-local-1 |
| 0.1.0-dev.4+4 | M4.1 | 2 | 2.0.0 | 1.0.0 | 1 | v4-local-1 |
| 0.1.0-dev.4+4 | M4.2 / M4 P1 | 3 | 2.0.0 | 1.0.0 | 1 | v4-local-1 |

- GB18030 index asset formatVersion = 1（meta.json 实测：source WHATWG 2024-09-18 snapshot，entryCount 23940，anchorCount 209，sha256 aebe263d…）。
- 版本确认方式：`git show <milestone commit>:pubspec.yaml` + `lib/app/constants.dart` 与 `lib/data/database/app_database.dart`（schemaVersion=2）实测。


---

## M4.2 — 横向分页 Reader UI 与双模式精确切换（0.1.0-dev.4+4，2026-08-08）

### 目标（用户任务书 M4 §五 / M4.2 指令）
在 M3 纵向 Reader 基线之上增加横向分页模式，不破坏任何 M3 行为；
唯一位置真源始终是 UTF-16 码元偏移；Page/pageIndex 全部只是派生状态。

### 交付
- `PagedReaderView`（PageView 内置容器，单一 PageController + _followWindow）；
- `PagedReaderController`（open/nextPage/previousPage/jumpToOffset/relayoutSilently/
  onPageSettled/防抖保存/generation/flush）；
- 双模式切换（reader_page.dart）：v→p（switchAnchor 精确）、p→v（confirmed locator
  走 M3 恢复链）、freeze/unfreeze 写冻结、无固定延迟；
- 分页模式目录跳转（精确 target）、resize/横竖屏重分页（offset 不变）、
  Theme 颜色-only 不重分页；
- Windows 键盘翻页 + Android 滑动翻页。

### 关键工程决策与踩坑（详见 ENGINEERING_LESSONS.md）
- 引擎页面边界：getLineBoundary 在 LF 位置返回零宽 → 前进时跳过 LF、
  页尾停在 LF 前（避免 trailing LF 空行超约束）、backward 候选起点回退行首；
  textScaler 统一 noScaling。
- PageView 窗口竞态：itemCount = 窗口页数时 fling 到缺失页会回弹 →
  `_prefillWindow` 预填 prev2/next3；窗口 trim 收缩后显示页索引越界 →
  单一 controller + select 后 _followWindow。
- relayout 竞态：LayoutBuilder 内同步 relayoutSilently（不 notifyListeners），
  首帧即用新尺寸，无闪跳。
- 切换零写入：删除 p→v 时无条件 paged.flush()（未翻页不得写库）。

### 验证
- 313 项单元+widget 全过；8 个集成测试全过（含 4 个真实 TXT 验收：
  473 章 9 锚点、无章节 7.68MB 中段、100 页往返 end 链严格连续）；
- verify.ps1 全绿（含 Windows Release、APK Debug、git diff --check）；
- 已知边界：backward 页首漂移 ≤ 2 屏/100 页（end 链连续，confirmed 零误差）。

### 状态
- 分支 feat/m4-horizontal-reader；M4.2 提交后工作区 clean；
- Android 真机验证待设备上线补做（无线 adb）。


---

## M4 P1 — 模式 + Locator 持久化闭环（2026-08-08）

### 问题
纵向 → 切分页 → 翻到新位置 → 退出重开：模式恢复成纵向、位置恢复成旧纵向位置。

### 根因
1. dispose/lifecycle 无条件 flush 纵向 controller（旧位置覆盖分页新位置）；
2. readingMode 只是 session state，未持久化（schema 2 无 readingMode 列）。

### 修复
- ReaderProgressState（locator + readingMode + updatedAt）；schema 2→3 加 readingMode；
- 只有 active 模式可提交位置（dispose/lifecycle 按 _mode 路由 flush）；
- 重开自动恢复模式（postFrame 自动切 paged，anchor 不变）；
- paged 模式下纵向跳转/对齐/finishRestore 跳过（防误设 failed）；
- removeCollection 显式删进度 + customConstraint 真 FK（CASCADE）。

### 验证
327 单元+widget（新增 14 项 P1 专项）+ 8 集成全过；verify.ps1 全绿。

### 最终真人验证与封存
- Windows：三组模式/位置持久化场景全部通过，完全退出后重开仍保持最后模式与位置；
- Android：三组场景全部通过，force-stop 后重开正常；覆盖安装完成 schema 2→3 迁移，
  原有书架、managed TXT 与阅读数据保留；
- `C:\Users\TOM\Desktop\测试` 中当前实际存在的全部 4 个 TXT 正常；Flat TOC、
  章节跳转、深色模式未发现明显回归；
- **M4 状态正式封存为 COMPLETE。**

---

## M5.1a — ReaderPreferences 设置合同 + Drift 持久化（2026-08-08）

### 范围
只建立强类型 ReaderPreferences、变化分类、AppSettings 持久化与 schema 3→4；
不修改 Reader UI，不做实时重排，不做 V3 Reader 壳层。

### 实现
- ReaderPreferences：fontSize、lineHeight、horizontalPadding、verticalPadding、
  ReaderThemeMode(system/light/dark)，含默认值、合法范围和逐字段 fallback；
- Metrics = 字号/行高/水平边距/垂直边距；Paint = themeMode；
- ReaderPreferencesRepository：load/watch/update/resetToDefaults；storage key/value 不越层；
- schema 4 新增 app_settings，迁移不改 reading_progress、readingMode、Locator 或书库数据；
- 修复 schema 1 直接跨级升级时 current createTable + 后续 addColumn 重复添加 readingMode 的风险。

### 验证
新增 11 项：默认值、范围、强类型 API、变化分类、保存读取/watch、重启持久化、
非法值 fallback、reset 隔离、schema 3→4 数据/managed TXT 保留、schema 1→4、
storage key 不泄漏。全量 338 unit/widget PASS，8/8 integration PASS，analyze 0 问题。

### 状态
M5.1a COMPLETE；按用户要求停止，不自动进入 M5.1b。

---

## M5.1b — Reader metrics 保位重新布局（2026-08-08）

接入 fontSize、lineHeight、horizontalPadding、verticalPadding；纵向复用 M3 精确字符
恢复，分页 invalidate 有限 PageWindow 后重新求包含原 locator 的页面。全流程冻结写入并
使用 generation 拒绝旧代。342 unit/widget、Windows 全部 4 个真实 TXT 共 12 锚点通过，
logical error 全为 0；Android Debug build 通过。因本轮没有 Android 设备连接，Android
真机语料验证待补，不进入 M5.1c。

---

## M5.1c — 主题控制与 paint-only 更新（2026-08-09）

ReaderPreferences 的 system/light/dark 已实时接入 MaterialApp；Reader 继续通过
ReaderResolvedAppearance/ColorScheme 更新 vertical/paged 颜色。纯主题变化不触发 metrics、
重分页、Locator restore 或 progress 写入。346 unit/widget 与 9/9 Windows integration 通过；
Windows Release、最终正常入口 Android Debug 构建通过。Android 真机按新策略统一延后到
M5.1 最终收尾验证。M5.1c COMPLETE，不进入 M5.1d。

### M5.1c 后 P1 回归修复（2026-08-09）

真人验收发现 paged→vertical 会回到顶部。定位确认：M4 首版在 `_mode` 仍为 paged 时调度
纵向恢复，被 paged 防护分支跳过，且 visible-range confirm 前已经解冻。现按非零 Locator X
完成严格状态机：激活 vertical 后恢复，真实可见范围包含 X 且 confirmed=X 才 idle/unfreeze。
补齐双向、快速 generation、继续阅读重开及 A/B 多书隔离测试；schema 4、Preferences、TXT、
TOC、Theme、UI 均未改变。
## M5.1e.1 — per-book typography settings and reopen P1 (2026-08-09)

ReaderPreferences was corrected from global scope to collection scope. Schema 5
adds `reader_preferences(collection_id PK/FK, ...)`; the schema 4 global snapshot
is seeded into every existing book once, without changing books, managed TXT,
reading_progress, readingMode, or ReaderLocator. Reader startup now awaits the
current book's saved preferences before the first effective layout, fixing the P1
where the panel showed saved values but body layout used defaults. Letter spacing,
paragraph spacing, first-line indent, and four independent paddings joined the
metrics contract. All four real TXT files passed at 12 anchors with logical error 0.
M5.1e.1 completed without entering M5.1f.
## M5.1 final seal — COMPLETE (2026-08-09)

M5.1a through M5.1e.1 were closed by M5.1f without adding features. The completed
milestone is “Reader UI + per-book Reading Preferences”: V3 Reader shell, dual
modes, per-book Locator/mode/preferences, full basic typography, four paddings,
three-state theme, exact-position relayout, persistence, and Flat TOC. Final
regression passed 355 contracts/unit/widget, 9 integration suites / 12 scenarios,
and all four real TXT files with logical error 0. Windows user human validation
reported no obvious issue. Android user initial validation reported no obvious issue;
no Android device was connected during the Codex final run. M5.1 is COMPLETE and
M5.2 has not started.

## Reader small-version follow-up — input commands and chapter page policy (2026-08-09)

M5.2 remains paused. Added a platform-neutral physical-input → binding →
`ReaderCommand` boundary with default previous/next page commands. Windows
keyboard and wheel inputs share the Dart binding layer; Android's host only
reports volume inputs while paged Reader is active. Paged pagination policy v2
uses real TOC chapter start offsets so every chapter title begins a fresh page,
without changing normalized text or the UTF-16 ReaderLocator contract. All four
real TXT files pass targeted Windows chapter-boundary and continuity checks;
Android volume-key validation awaits wireless ADB reconnection.

## M5.2a — history, bookmarks, and session persistence (2026-08-09)

M5.2a established the persistence/domain foundation without adding UI. Schema 6
adds nullable collection links for bookmarks and reading history, plus sessions
that remain attached to a history entry. Collection deletion detaches history and
bookmarks instead of silently deleting them; deleting a history entry cascades
only its sessions. Bookmark orphan state is derived at read time from collection
linkage, normalized hash, and UTF-16 offset bounds. ReadingSession is the sole
source for aggregate duration and session count. CurrentChapterResolver derives a
chapter only from the last TOC chapter start at or before the confirmed Locator;
volumes and no-chapter TXT return no chapter. Schema 5→6 migration and actual
SQLite foreign-key actions were validated.

## M5.2b — Reader progress and current-book bookmarks (2026-08-09)

M5.2b connected the persistence foundation to the Reader without changing schema
6. Progress is derived from the active confirmed UTF-16 Locator and normalized
document length; chapter display delegates to CurrentChapterResolver. The Reader
toolbar now opens a responsive current-book bookmark panel with create, dynamic
chapter/context display, delete, orphan-safe handling, and exact vertical/paged
Locator jumps. Duplicate collection+offset creation is idempotent and panel
operations do not write reading_progress. Full 373-test automation, nine
Windows integration files, all four real TXT logical-error-zero checks, Windows
Release, and Android Debug passed.

## M5.2c — current-book search and exact result jumps (2026-08-09)

M5.2c added normalized.txt-only ordinary substring search without a schema
change. Each query runs in a cancellable worker isolate with a 220ms UI debounce,
generation protection, and a 100-result cap. Results retain UTF-16 code-unit
start/end/context offsets and derive chapter names through CurrentChapterResolver.
The responsive Reader search panel highlights context and restores the exact hit
Locator in vertical or paged mode. Synthetic coverage and all-four-TXT Windows
anchor searches passed; full automation reached 381 tests and 10 integration
files / 13 scenarios.

## M5.2d — recent reading, reading history, and Reader sessions (2026-08-09)

M5.2d completed the M5.2 foundation without changing schema 6. Recent Reading is
derived from current-library history rows with valid sessions and `lastReadAt`
ordering. A responsive Reading History page keeps deleted-book snapshots and
session statistics, permits continuation only while the collection exists, and
deletes a history row with its sessions only. Reader lifecycle now starts exactly
one session after the first visible/page confirmation, pauses/resumes with app
lifecycle, ends on route disposal, and updates display-only chapter/progress
snapshots. Aggregate duration and count remain `SUM/COUNT(reading_sessions)`.
The full suite reached 382 passing tests; existing four-TXT logical-error-zero
checks remain green.

## M5.3a+b — typed Reader input bindings and persistence (2026-08-09)

M5.3a+b established the durable input domain contract without changing the
existing Reader route. `ReaderCommand` now includes page/chapter/control/TOC
semantics, while `PhysicalInputId` provides stable Windows and Android string
identifiers. Versioned, platform-isolated `ReaderInputProfile` values are
stored through the strongly typed `ReaderInputBindingsRepository` over
`app_settings`; JSON and storage keys remain private to that repository.
Explicit null disables a binding, malformed data falls back only the affected
platform, unknown rows are ignored, and old profiles merge missing defaults.
Schema remains 6. Capture, routing, and settings UI are intentionally deferred
to M5.3c.

## M5.3c+d — unified input routing and capture (2026-08-10)

The persisted input contract was connected through one ReaderInputRouter for
Windows keyboard/wheel and Android volume events. All six semantic commands are
dispatched from the active platform profile; page commands are paged-only,
while chapter commands resolve real chapter offsets and reuse exact vertical or
paged Locator restore. Profile hot reload and operation generations reject stale
events across mode, metrics, lifecycle, capture, and dispose transitions.
Android MainActivity reports stable volume IDs and gates interception on
paged/capture state. The first-input capture domain was added without settings
UI. Schema remains 6. Full automation reached 396 tests; Windows integration
ran as 10 files / 13 scenarios.

## M5.3e — Reader input settings UI (2026-08-10)

Added the V3 settings route `我的 → 阅读设置 → 按键与操作`. The page renders
only the current platform's physical inputs under all six Reader commands,
supports first-input capture, conflict replacement/cancellation, explicit null
disable, and platform-scoped reset defaults. It reuses the existing typed
router/repository and leaves Locator, reading progress, ReaderPreferences, and
ReadingSession untouched. Schema remains 6; analyze and the 401-test suite
remain green, with Windows Release and Android Debug builds passing.

## M5.3e.1 — keyboard capture correction (2026-08-10)

The Windows settings capture bug was traced to focus remaining on the add
button: the capture overlay did not request a keyboard focus node. A dedicated
focus node is now requested on capture and retry. Stable IDs cover A–Z, 0–9,
arrows, PageUp/PageDown, Home/End, Space, and Enter. Capture uses an explicit
candidate-confirm-persist workflow; cancel and retry never write, conflict
replacement is explicit, and success is visible. Schema remains 6.

## M5.3e.2 — Reading History display and Windows shortcut gestures (2026-08-10)

Corrected Reading History interpolation so aggregate/session and snapshot
values render as text and empty snapshots are omitted. Windows binding profiles
were upgraded to canonical Ctrl/Alt/Shift gestures with lossless migration of
old single-key profiles. Capture now keeps keyboard focus across the complete
overlay and requires candidate confirmation before persistence. Validation:
408 automated tests, 10 integration files / 13 scenarios, both builds PASS.

## M5.3 final contract closure (2026-08-10)

Android volume settings are now physical-input-centric and limited to previous
page, next page, or disabled. Unsupported legacy Android commands restore the
affected key to its platform default without touching Windows profiles. The
shared profile format remains v2 and Drift schema remains 6.

Windows keeps all six ReaderCommands and command-centric single-key, modifier,
and wheel bindings. Chapter navigation now uses an independent operation
generation with active-mode write freeze, visible confirmation, cancellation of
stale operations, and post-confirm flush. No page/chapter index or pixel
position is persisted.

Final validation passed 410 automated tests, 10 integration files / 13
scenarios, all four real TXT logical-error-zero checks, Windows Release, and
Android Debug. Targeted Android ADB was not run because no device was connected.

## M5.3.1 — ChapterBoundaryResolver and vertical chapter progress (2026-08-10)

The Reader now has one shared, defensive chapter-boundary normalizer. It uses
only real chapter entries, normalizes valid UTF-16 offsets, ignores volumes and
malformed rows, and deterministically keeps the first source-order entry when
chapter starts collide. Current chapter and search resolution use this boundary
contract.

Vertical Reader chrome derives chapter percentage from the confirmed Locator
and displays it alongside the existing whole-book percentage. The percentage
is transient display state; ReaderLocator and reading progress remain unchanged.
No-chapter TXT keeps the `全文` presentation. Paged chapter page metrics and
automatic reading remain deferred. Schema remains 6. Validation passed 415
automated tests, 10 integration files / 13 scenarios, all four real TXT files
with logical error 0, Windows Release, and Android Debug.
## M5.3.1.1 — Paged Reader gesture window-tail fix (2026-08-10)

Manual Android investigation identified a reproducible case where PageView
could reach the bounded page-window tail and stop accepting forward swipes,
while Volume Down still advanced through the Controller. The cause was the
PageView `itemCount` boundary, not document EOF. Pagination expansion is now
owned by `PagedReaderController`; touch, volume, and keyboard use the same
ensure/settle path, with bounded prev2/current/next3 prefetch and a pointer-edge
fallback. Layout and window generations reject stale callbacks after relayout,
resize, mode/locator jumps, and dispose. The ReaderLocator and schema 6
contracts are unchanged. Automated gesture-tail coverage, Windows integration,
and all four real TXT logical-error checks passed.

## M5.3.2 — paged chapter page progress (2026-08-10)

The paged Reader now derives `本章 x / y 页` from the confirmed UTF-16
Locator, shared chapter boundaries, and the active layout. Only the current
chapter is paginated; a bounded cache and generation guards prevent full-book
work and stale metrics after relayout or mode changes. PageWindow remains the
bounded interaction window, no page metric is persisted, and no-chapter TXT
continues to show whole-book progress only. All four real TXT files passed the
targeted metrics integration with logical error 0; schema remains 6.

## M5.3.2 label correction (2026-08-10)

Manual review found that only the newly added Paged progress labels contained
mojibake literals. The labels were corrected and centralized; exact Vertical,
Paged, and no-chapter widget assertions pass. No pagination, metrics, Locator,
or persistence code changed.

## M5.4a — AutoRead domain contract (2026-08-10)

Added the transient AutoRead state machine and typed global AutoReadPreferences
repository. States, pause reasons, domain events, and generation invalidation
are defined without driving any Reader controller. Vertical speed is persisted
as one of five presets and paged pacing as one canonical interval; velocity is
runtime-derived. Corrupt/unknown values safely fall back and older preference
versions normalize without touching ReaderPreferences, input profiles, or
reading progress. Schema remains 6; drivers and UI are deferred to M5.4b.

## M5.4b — Vertical AutoRead (2026-08-10)

Added a bounded Ticker adapter for smooth vertical scrolling. Runtime speed
uses the five persisted AutoRead presets; each guarded frame reports through
the existing visible-range confirmation and progress debounce. Manual drag or
wheel pauses, while automatic frames are not mistaken for manual input.
Pause/stop/EOF confirm the final Locator, EOF becomes `stoppedAtEnd`, and
relayout/mode/lifecycle/dispose invalidate stale generations. ReadingSession,
ReaderLocator, schema 6, and no-chapter behavior remain unchanged. Paged
Paged AutoRead and UI were deferred at this point.

## M5.4b.1 — Vertical AutoRead UI

Added the minimal Reader bottom-chrome AutoRead surface on top of the existing
vertical driver. Users can start, pause/resume, stop, and change the five
vertical speed presets with immediate controller effect and typed preference
persistence. Paged automatic paging, keep-awake, shortcuts, and schema changes
remain out of scope.

## M5.4b.2 — Fine vertical speed

Expanded Vertical AutoRead speed selection with a 12–120 px/s, 1 px/s slider
while retaining the five quick presets. Persistence now has one canonical
velocity value with deterministic migration from the former preset JSON;
slider writes are debounced and do not touch position, layout, or session
contracts.
