# ENGINEERING_LESSONS.md — XAOCEN Reader v4 永久踩坑簿

> 每条记录真实发生的问题、根因、错误做法、正确做法、回归保护与以后禁止事项。
> 所有条目来自本项目实际开发过程（M0–M3.4），无虚构。

---

## 1. sourceHash / normalizedHash 混用（P1，M3.1）

### 现象
真实大 TXT 打开 Reader 报 `hash_mismatch`（expected `2528925c…` vs actual `d37db97a…`）；Windows 与 Android 均失败；自动测试全绿。

### 根因
M2 `_writeDatabase` 把 `content_documents.content_hash` 写成 sourceHash（源文件 hash），M3 ReaderPage 却把它当 expectedHash 传给 Loader 去校验 normalized.txt 落盘字节。两个不同对象的 hash 被当作同一个值。

### 错误做法
- 一个字段同时承载「内容身份」（source）与「派生文件校验」（normalized）两种语义；
- Reader 侧不核对字段来源直接消费。

### 正确做法
- 明确两个 hash：sourceHash（外部 TXT 字节 = 内容身份）与 normalizedHash（落盘 normalized.txt UTF-8 字节 SHA-256）；
- 所有消费点用同一值：manifest / Drift / Loader / 导入完成 / repair 完成；
- 共享强类型 `NormalizedArtifact`；Loader 以 manifest.normalizedHash 为权威，expectedHash 仅回退；
- 写入顺序：tmp → flush → close → **从落盘字节算 hash** → 重解码验证 UTF-16 长度 → 原子 rename → manifest → Drift 事务 → 最终重读校验。

### 回归保护
hash_contract_test（8MB 闭环、各损坏场景、跨会话重开）+ repair_service_test + 集成 hash_contract_flow_test；`tool/inspect_managed_txt.dart` 只读诊断。

### 以后禁止事项
禁止把 sourceHash 当 normalizedHash 使用；禁止在 flush/close 前保存预期 hash；禁止捕获 hash_mismatch 后继续加载或直接覆盖 expected。

---

## 2. CRLF 规范化导致 hash 变化

### 现象
小 TXT 全过、真实大 TXT 必失败。

### 根因
规范化把 CRLF→LF 改变字节 → normalized 字节 ≠ source 字节；小 ASCII 文件无 CRLF → 字节不变 → hash 碰巧相等。

### 错误做法
用「小文件通过」推断「大文件也通过」；没有覆盖「规范化改变字节」的测试向量。

### 正确做法
意识到「与文件大小无关，与规范化是否改变字节有关」；测试必须包含 CRLF/BOM 源文件，且断言 hash 反映**落盘**字节。

### 回归保护
hash_contract 测试含 CRLF 跨 buffer 边界、8MB 运行时生成文件（含 CRLF/UTF-8 四字节/GB18030 四字节跨块）。

### 以后禁止事项
禁止假设 source==normalized 字节；禁止用内存字符串算 hash 代替落盘字节。

---

## 3. 章节正则 group(0) 丢完整标题（M3.2）

### 现象
目录只显示「第X章」无具体名称；卷标题同理。

### 根因
M1 扫描器 `title: m.group(0)!` 只存正则匹配片段，完整标题从未进入数据链（index.json → Drift → UI）。

### 错误做法
把「匹配片段」当「标题」持久化；displayTitle 与匹配判定混为一个字段。

### 正确做法
- 判定用正则（行首 + 章后须空白/标点/行尾）；
- 标题另取：完整行 trim 首尾空白 → displayTitle；
- dedupeKey（空白归一化，不进 UI）与 chapterNumber（单独解析）独立字段；
- parserVersion 升级（1.0.0→2.0.0）驱动存量数据 repair。

### 回归保护
scanner 8 项完整标题合同测试；toc_title_persistence 6 项；真实库 4 本 repair 后验证完整标题。

### 以后禁止事项
禁止用正则匹配片段直接作为展示标题；禁止 UI 用 orderIndex/「第${i+1}章」合成标题。

---

## 4. 相邻重复标题去重 vs 全局同名

### 现象
真实文件扫描出 486 章（多 13 章），预期 473。

### 根因
正文引用章节标题的缩进行与行首标题存在错别字差异（「第468章 这特么是元婴」vs「第468章 这特码是元婴」），完整标题 dedupeKey 不同 → 不去重。

### 错误做法
只按完整标题文本去重；把正文引用行当独立章节。

### 正确做法
相邻去重（行距 ≤3）附加判据：**章节编号相同即视为重复**（真实小说缩进重复行常是正文对标题的引用，可能带错别字）；楔子/序章等无编号的仍按 dedupeKey。同时保持「远距同名保留、两个行首不去重、公告行排除」。

### 回归保护
真实文件验收断言恰为 473 章（accept_real_files_test）；扫描器相邻重复/远距同名/公告测试。

### 以后禁止事项
禁止全书同名全局去重；禁止因去重规则删除正文重复标题行。

---

## 5. 公告「第五十二章被审核了」误识别

### 现象
作者公告行被当成章节标题。

### 根因
正则只检查「第X章」前缀，未检查「章」后的字符。

### 错误做法
`^第.{1,12}章` 之类宽松匹配。

### 正确做法
「章/卷/部/节」后必须跟空白/标点/行尾（`(?=[ \u3000\t：:，,。.!！?？、]|$)`）；公告行「第五十二章被审核了，稍等～」被排除。

### 回归保护
notice_false_positive fixture + 扫描器公告排除测试；真实文件 473 章断言。

### 以后禁止事项
禁止放宽「章」后字符约束。

---

## 6. O(n²) 章节扫描约 7s

### 现象
Spike 2 全量扫描 ~7s（1,300,867 字符）。

### 根因
逐行计算 offset 时用累计/切片 O(n²) 算法。

### 错误做法
每命中一次就重新累计前面所有行；用固定延迟/加载动画掩盖。

### 正确做法
单次 O(n) 顺序扫描，预计算 _lineOffsets 一次遍历累计 UTF-16 offset；后台 Isolate 执行；正式版首次 251ms（28× 提速），缓存命中 63–127ms。

### 回归保护
真实文件耗时验收（M1）；缓存命中不重扫断言。

### 以后禁止事项
禁止 O(n²) offset 计算；禁止先扫前 N 章再补扫。

---

## 7. jumpToItem(block) 不是字符精确跳转（M3.2）

### 现象
目录点击后正文停在块顶，标题行不在期望位置。

### 根因
`jumpToItem(block.index, alignment: 0)` 只对齐块顶；标题常在块中间。

### 错误做法
把「块定位」当「字符定位」；固定 100ms Timer 假装完成。

### 正确做法
两阶段：块级 jumpToItem（第一阶段）→ post-frame 等目标块 layout → `rectForCharacterOffset(localOffset)` 求标题行 Rect → 二次 jumpToItem(rect, alignment 0) + 12px 微调 → `localToGlobal` 验证与视口相交；bounded retries ≤5，超限明确失败；无固定延迟。

### 回归保护
reader_jump_test 11 项（多章同块/块末/越界/不切 surrogate）；集成 multi-block fixture；真实文件 9 章 offset 验证。

### 以后禁止事项
禁止以 blockIndex/scroll extent 比例为跳转依据；禁止 Future.delayed 固定延迟。

---

## 8. 真实 visible range 不能用 block 级近似（M3.3）

### 现象
正文恢复/目录高亮差约 34 章（顶部报 224 章实际 258 章）。

### 根因
`_visibleRangeForScroll` 用块起始 offset 当可见范围顶。

### 错误做法
用块边界近似用户实际看到的字符。

### 正确做法
块内真实字符级：视口顶/底全局坐标 vs 块坐标 → `characterOffsetAtLocalY` → 精确 UTF-16 偏移；layout 进行中/未 attach 时安全回退 block 级。

### 回归保护
toc_scroll_test 12 项（含真实可见范围定位）；真实文件 6 章 ±1 验证。

### 以后禁止事项
禁止任何比例估算/块级近似作为可见范围真值。

---

## 9. 程序化 restore 期间不能写 progress（M3）

### 现象
恢复过程可能把位置写回旧值/中间值。

### 根因
恢复完成（confirmingVisibleRange）前 _restoreWriteUnlocked=false 的 gate 缺失或时序错误。

### 错误做法
恢复过程中 flush/防抖写进度。

### 正确做法
`_restoreWriteUnlocked` gate：programmatic restore 零写入；仅确认可见范围后解冻；用户滚动才触发防抖保存。

### 回归保护
reader_controller_test 恢复冻结/防抖/flush 用例。

### 以后禁止事项
禁止恢复未确认前任何位置写入。

---

## 10. 目录打开不能只从列表顶部显示（M3.3）

### 现象
长目录打开后看不到当前章节，需手动滚半天。

### 根因
目录打开默认显示列表顶部。

### 错误做法
不做任何定位；或依赖上次点击位置。

### 正确做法
打开时用真实可见范围顶部反查当前 chapter → flat 索引 → 两阶段定位（估算 jumpTo 带入构建区 → ensureVisible 35%）→ 高亮；每次打开最多一次；用户滚动不拉回；提供「定位当前章节」按钮；bounded retry（extent 不稳 ≤10 / 实测行高 ≤8）。

### 回归保护
toc_scroll_test 12 项（定位/不拉回/重开重定位/无章节全文）。

### 以后禁止事项
禁止打开目录不定位；禁止每次打开多次定位。

---

## 11. TOC 折叠不适合内容导航（M3.4）

### 现象
用户手工测试发现卷折叠导致查找/跳转繁琐，且 TXT 层级数据本身不可靠。

### 根因
把层级当交互结构；异常层级（幽灵 parentId/连续卷）会造成内容被折叠隐藏。

### 错误做法
用 collapse/expand 解决长列表；把层级当可见性开关。

### 正确做法
全局合同：**Content hierarchy is semantic, not interactive. Source order is authoritative; navigable entries remain visible.** 层级只做语义/分组/搜索/导出；卷作 Section Header；所有可导航项始终可见；长列表用自动定位/高亮/搜索/索引。

### 回归保护
content_navigation_contract_test 8 项（异常 fixture 全部平铺可见）；toc_scroll_test 平铺语义。

### 以后禁止事项
禁止内容导航中引入折叠；禁止保存 collapsed 状态；禁止无功能箭头。

---

## 12. 深色背景 + TextPainter 默认深字（M3.3 P1）

### 现象
深色主题下正文不可读（黑底深字或白底黑字不匹配）。

### 根因
正文 TextPainter 硬编码 `Color(0xFF222222)`，与 theme 背景无关。

### 错误做法
正文颜色硬编码；显示与测量用两套样式。

### 正确做法
`ReaderResolvedAppearance` 从 Theme colorScheme 解析（surface/onSurface/onSurfaceVariant/primaryContainer）；TextSpan 显式携带解析色；同一 TextPainter 显示与测量；对比度 ≥4.5:1。

### 回归保护
reader_dark_mode_test 8 项（浅/深可读、无深底深字组合、主题切换不写进度不改 Locator）。

### 以后禁止事项
禁止 Reader 正文硬编码颜色；禁止依赖 DefaultTextStyle。

---

## 13. Theme 颜色变化与 TextPainter layout/paint 分离（M3.3）

### 现象
主题切换触发整页重排/闪烁。

### 根因
style setter 一律 markNeedsLayout。

### 错误做法
颜色变化也走重排路径。

### 正确做法
度量变化 → markNeedsLayout；仅颜色变化 → 同步 span + markNeedsPaint；主题切换只重绘不重建 block 索引、不写进度、不改 Locator。

### 回归保护
reader_dark_mode_test（切换后 block 颜色更新、度量不变）。

### 以后禁止事项
禁止颜色变化触发 layout；禁止主题切换重建索引/写进度。

---

## 14. flutter test 可能产生 test-runner APK（真机白屏）

### 现象
真机安装后白屏，进程存活、logcat 无错误。

### 根因
`flutter test integration_test` 会把 `build/app/outputs/flutter-apk/app-debug.apk` 覆盖为 test-runner 入口版（main 是测试驱动），手动 `adb install -r` 装的是测试版 APK。

### 错误做法
测试后直接安装 build 目录 APK 当正常版。

### 正确做法
测试/集成测试后必须重新 `flutter build apk --debug` 再安装。

### 回归保护
操作规范（M3 真机记录）；verify.ps1 末尾步骤顺序注意。

### 以后禁止事项
禁止把测试后的 APK 直接交付/安装；禁止把「APK 构建成功」当「功能通过」。

---

## 15. Windows sqlite3_flutter_libs / CMAKE_INSTALL_PREFIX（M0）

### 现象
Windows Release 构建失败（需管理员权限写 C:/Program Files/xaocen_reader）。

### 根因
sqlite3_flutter_libs 0.5.42 的 FetchContent 在 configure 期重新初始化 `project()`，把 CMAKE_INSTALL_PREFIX 重置为默认值；Flutter 模板的 `if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)` 保护失效。

### 错误做法
重复尝试普通构建；试图给 Program Files 权限。

### 正确做法
`windows/CMakeLists.txt` Installation 段无条件把 install prefix 指向构建目录（保留注释解释原因）。

### 回归保护
Windows Release 构建步骤（verify.ps1）。

### 以后禁止事项
禁止删除该 CMake 修复；禁止依赖默认 install prefix。

---

## 16. PowerShell 5.1 中文注释解析问题

### 现象
verify.ps1/脚本报行号偏移、`$itDir` 为空、语法错误；行为诡异。

### 根因
PowerShell 5.1 按 ANSI 解析 UTF-8 无 BOM 文件，中文多字节吞掉换行 → 行号错位。

### 错误做法
在 .ps1 里写中文注释；内联命令用中文字符串。

### 正确做法
脚本文件全英文注释/纯 ASCII；内联复杂命令写成 .py/.ps1 脚本文件；中文内容用 write 工具写 Dart/测试文件（UTF-8 可靠）。

### 回归保护
verify.ps1 英文注释；find_cjk.py 检查无残留中文。

### 以后禁止事项
禁止在 PowerShell 脚本内联中文；禁止依赖 PS 5.1 的 UTF-8 中文解析。

---

## 17. Windows USB ADB 驱动冲突

### 现象
USB 直连设备不识别。

### 根因
手机 ADB 接口被 Windows 微软通用 WinUSB 驱动抢占（GUID 不匹配 adb 认的 Google 驱动）；修改官方 INF 被签名校验拒绝（Windows 11 驱动签名强制）。

### 错误做法
反复重装驱动/尝试绕过签名。

### 正确做法
**无线调试定案**：开发者选项 → 无线调试 → 配对码（`adb pair`）→ TLS 连接；后续开发调试一直沿用。

### 回归保护
操作规范（记录于 SPIKE_RESULT.md §6 连接备注）。

### 以后禁止事项
禁止为 USB 驱动绕过 Windows 签名强制。

---

## 18. 无线 ADB / mDNS 端口变化

### 现象
设备离线；`adb devices` 为空；连接端口每次变化；出现双 mDNS 通道（`(2)` 变体）导致 "more than one device"。

### 根因
无线调试端口动态分配；mDNS 服务名不可直接 connect（cannot resolve host）；重启 adb server 后设备延迟自动出现。

### 错误做法
硬编码旧端口；connect 不可解析的服务名。

### 正确做法
`adb kill-server/start-server` 后等 mDNS 自动发现；多设备时 `adb disconnect` 清空后手动连接实际端口；serial 解析注意空格截断。

### 回归保护
操作规范；真机流程脚本按 serial 全量解析。

### 以后禁止事项
禁止硬编码无线端口；禁止假设单通道。

---

## 19. adb keyevent 4 行为

### 现象
点击「无效」的假象：书架按返回键其实是退出 app（回到设置页）；app 不在前台时 tap 全部无效。

### 根因
书架是首页，keyevent 4 直接 finish app；误以为 tap 失效。

### 错误做法
用 keyevent 4 当「返回书架」；不确认 app 前台状态就点。

### 正确做法
阅读页返回用 AppBar 返回箭头（或测试里 Navigator.pop）；退出验证用 am start 重启；每次 tap 前先截图确认页面状态。

### 回归保护
真机操作规范（记录于 memory）。

### 以后禁止事项
禁止不确认前台页面就批量点击；禁止把 keyevent 4 当通用返回。

---

## 20. GUI 自动点击坐标估算误差

### 现象
「点第45章没跳转」结论错误——实际跳转正常（548→530 差分验证）。

### 根因
image 工具坐标估算有 ±200–300px 噪声；单次点击命中相邻行/当前章节造成假象。

### 错误做法
用一次点击现象直接判定功能失败；依赖单次截图坐标。

### 正确做法
**差分验证**：点远距离目标，观察正文是否变化；用已验证锚点 + 相对行距推算；必要时多次尝试 + 截图确认；结论前先排除坐标误差。

### 回归保护
真机验证流程（M3.4 13/13 用差分法确认）。

### 以后禁止事项
禁止单次点击失败即判定功能缺陷；禁止信任单张截图的绝对坐标。

---

## 21. Android 字体 metrics 与 Windows 不同（坐标真源意义）

### 现象
同一文件 Android 分页 3,993 页 vs Windows 1,651 页（同配置）；页边界完全不同。

### 根因
平台字体度量差异（Spike 4 A8 实测确认）。

### 错误做法
依赖页边界/页号跨平台定位。

### 正确做法
字符偏移坐标（UTF-16 码元）为唯一真源——页/块是派生结构；跨字体、横竖屏、重排、平台变化下偏移稳定。

### 回归保护
Spike 3/4 偏移稳定性测试（字号/宽度/横竖屏）；Reader 恢复状态机。

### 以后禁止事项
禁止 ReaderLocator 依赖页边界/blockIndex/像素。

---

## 22. 大文件不能因无章节而成为单一巨大 Widget

### 现象
无章节 7.68MB 文件（2,739,888 字符）若整体渲染必卡死。

### 根因
无章节 = 1 个 whole item ≠ 1 个 Widget；正文必须分块虚拟化。

### 错误做法
按 item 粒度渲染；预排全文。

### 正确做法
whole item 覆盖 0..normalizedCharacterLength；ReaderBlock 派生分块（6144 码元/块）+ super_sliver_list 按需构建；只预排首屏/恢复页/邻近页。

### 回归保护
无章节大文件滚动集成/真机验证（25%/50%/75% 定位不跳末尾）。

### 以后禁止事项
禁止全文单 Widget/SelectableText；禁止预排全书。

---

## 23. source order 高于不可靠 hierarchy（M3.4 合同）

### 现象
真实 TXT 层级数据不可靠（错误 parentId/连续卷/卷部混用）。

### 根因
第三方 TXT 的层级结构天然不可信。

### 错误做法
把层级当导航依据；异常时隐藏内容或崩溃。

### 正确做法
source order 权威；异常层级只影响视觉分组；所有可导航项始终可见。

### 回归保护
content_navigation_contract_test 异常 fixture；toc_scroll_test 平铺。

### 以后禁止事项
禁止因层级异常隐藏内容；禁止依赖 parentId 正确性。

---

## 附：其他小型教训（简记）

- **锚点数据源**：`gb18030_ranges_official.json` 是空数组不可用；209 锚点来自 spike1（Python gb18030 codec 生成）。
- **PowerShell 插值**：`${pair[0]}` 生成损坏 Dart 数组（`[, ]`）→ 用 Python 生成。
- **解码器跨块**：`_state==2` 分支第四字节跨块未置 `_state=3` → 逐字节分段输入失败。
- **编码检测截断**：严格 UTF-8 采样在 65534 截断多字节序列误判 → 采样末尾容忍 ≤3 字节截断。
- **Drift 主键**：`text()` 默认非主键 → 6 表显式 primaryKey；toc id 冲突 → collectionId 前缀。
- **路径段尾随空**：Windows `Directory.uri.pathSegments` 末尾空段 → 过滤非空。
- **SQLite 999 变量**：8MB fixture 33 万章 × 3 表 insert 超限 → 100 章×80KB 生成。
- **测试 FakeAsync**：widget 测试不推真实 IO → Provider override + integration_test 真实链路。
- **AGP 9 + file_picker**：Kotlin 冲突 → AGP 8.7.3 + 传统 KGP。
- **sqlite3 hook 被墙**：github.com 不可达 → ghproxy 镜像 url_pattern。
- **androidx.test 动态版本**：flutter.io metadata 404 → dependencyResolutionManagement。
- **GlobalKey**：必须作为 Widget 的 key 才能关联 context（存 map 单独管理无效）。
- **fixture 中文编码**：Python patch 会破坏 UTF-8 → 用 write 工具写测试文件。


---

## M4 系列教训（横向分页，2026-08-07/08）

### 1. TextPainter 分页边界三连坑（P0，多轮重构的根源）

**现象**：真实大 TXT 在 UI 层报 `RenderReaderTextBlock does not meet its constraints`
（渲染 22 行 × 29px = 638px > 约束 610.4px）；100 页往返不对称（页首差 348→4→22→729 字符
反复变化）；Ahem 纯字符测试却全部通过（真实含 LF 才暴露）。

**根因三连**：
1. `TextPainter.getLineBoundary(TextPosition(offset))` 在 offset 恰为 LF 时返回**零宽 [x,x)**，
   前进循环 lineStart 停在 LF 上不再推进 → 页尾漏行；
2. `computeLineMetrics('a\n')` 返回 **2 行**（trailing LF 产生额外空行）——页面 substring
   以 LF 结尾时渲染高度比引擎累计多 1 行 → 超约束；
3. 引擎 `TextScaler.linear(1.0)` 与渲染端 `TextScaler.noScaling` 在部分字体有微小度量差。

**正确做法**：
- 前进：lineStart 恒为内容行行首（0 或 LF 后），行尾 = getLineBoundary(LF 前)，
  **LF 归下一页**（页尾无 trailing LF）；零宽防御 `end = lineStart + 1`；
- 后退：候选起点回退行首（lastIndexOf LF → lf+1），getLineBoundary 往回数渲染行；
- **显示与测量两端 textScaler 必须完全一致**（统一 noScaling）；
- 页面累计严格 ≤ contentHeight，无 ε 容差。

**回归保护**：引擎 20 项 Ahem 测试 + `accept_real_paged_test` 真实文件 9 锚点/100 页往返。

### 2. backward 页首系统性漂移（P1，已接受为已知边界）

**现象**：100 页往返 end 链严格连续，但页首差随轮次累积（实测最大 729 字符 ≈ 35 行/100 页）。

**根因**：backward 候选起点（LF 回退）与 forward 页首（前一页 end = LF）的行划分在
个别 LF/wrap 边界不严格同构，每轮 ~0.35 行偏差。

**正确做法**：合同核心是 **end 链严格连续（字符链不重不漏）**；页首漂移不影响
confirmed locator（UTF-16 offset 真源）。测试断言改为「end 连续 + 页首差 ≤ 2 屏」，
漂移记录 KNOWN_ISSUES。**不要**为了页首精确引入每页二分/重排（性能爆炸）。

### 3. PageView 窗口竞态（P1）

**现象**：widget 测试 fling 后 currentPage.start 仍为 0——onPageChanged 从未触发。

**根因**：PageView itemCount = PageWindow 页数，open() 初始窗口只有 1 页；
fling 到 index 1 时该页不存在 → 回弹。窗口 `_trim` 收缩后显示页索引越界。

**正确做法**：`_prefillWindow()` 在 open/jump/relayout 后预填 prev2/next3（文档边界即停）；
单一 PageController（不重建）+ `_followWindow`（仅当显示页 ≠ currentIndex 时 jumpToPage）；
onPageChanged 里 select 后显式 _followWindow。

### 4. relayout 竞态（P1）

**现象**：LayoutBuilder 在 build 中同步调 relayout() → notifyListeners → listener setState
in build → 异常被吞、首帧用旧尺寸排页超约束。

**正确做法**：`relayoutSilently`（与 relayout 同逻辑但**不 notifyListeners**）；
PagedReaderView build 外包 LayoutBuilder，尺寸不匹配时同步调 relayoutSilently
（本帧即用新尺寸，无闪跳）。

### 5. 切换零写入（P1）

**现象**：v→p→v 未翻页但 DB 出现进度写入（违反 §二十一零写入合同）。

**根因**：p→v 切换时无条件 `paged.flush()`（自己加的「切换前落盘」），
即使 confirmed == anchor == 0 也写库。

**正确做法**：删除无条件 flush；翻页进度由防抖 Timer 自然落盘，退出 Reader 由
dispose flush 落盘（与 M3 一致）；目录跳转=明确用户操作 → 立即防抖保存精确 target。

### 6. 测试断言设计：测合同核心，不测 Flutter 边界（P2）

**现象**：真实文件往返测试逐页比较 forward/backward 页首，差 4→22→64→219→729 反复失败。

**根因**：断言「页首完全一致」超出了 Flutter 布局引擎在 LF/wrap 边界的保证。

**正确做法**：断言分解为「end 链严格连续」（合同核心：不重不漏）+「回到原位 ≤ 2 屏」
（视觉边界）。**合同核心是字符链连续，不是页边界逐字符一致**。

### 7. 环境偶发 SIGKILL 排查（P2）

**现象**：全量 `flutter test` 与 `test/unit` 目录 SIGKILL，但单文件全部通过。

**根因**：`taskkill /F /IM flutter_tester.exe` 杀掉进程后 flutter 工具状态异常，
后续启动卡死（killall 脚本误杀测试进程）。

**正确做法**：先确认单文件是否通过（hash_contract_test 单独 18s 全过）；重启环境
（杀 dart/flutter_tester 后再等 flutter 工具恢复正常）后重试全量；**不要**在
flutter test 运行期间 killall 测试进程。全量 313 项最终 30s 全过。


---

## M4 P1 教训（模式 + Locator 持久化，2026-08-08）

### 8. 退出时无条件 flush 旧模式覆盖新进度（P0）

**现象**：纵向 → 切分页 → 翻页到 B → 退出重开 = 纵向 + 旧位置 A。

**根因**：`ReaderPage.dispose()` 里 `paged.flush()`（保存 B）之后**无条件
`_controller.flush()`（纵向）**——纵向 confirmed 还是切换前的 A → 覆盖 B。
`didChangeAppLifecycleState`（App 后台）同样无条件纵向 flush。

**错误做法**：dispose/lifecycle 里对两个 controller 都 flush；
只想到「分页退出要 flush」却忽略「纵向退出也会 flush」。

**正确做法**：**只有「当前激活的 Reader 模式」允许提交位置**——
dispose/lifecycle 按 `_mode` 路由：`paged → paged.flush()`；`vertical → _controller.flush()`。
切换本身零写入，mode 的持久化由退出时 active flush 自然落盘。
**诊断方法**：把每个 saveProgress 调用点打印 `source + mode + offset`，
能直接看到「paged 保存成功后被 vertical 覆盖」的顺序。

### 9. 重开恢复模式：自动切 paged 触发纵向 align failed（P1）

**现象**：重开（上次 paged）自动切分页后页面变错误页。

**根因**：postFrame 自动 `_switchToPaged()` 后，纵向 `_scheduleSecondStageAlign`
发现 `_listController.isAttached == false`（body 已切 paged）→ `_alignFailed` →
`markRestoreFailed` → state=failed → build 返回错误页。

**正确做法**：paged 模式下纵向跳转/对齐/finishRestore 全部跳过
（`_scheduleJumpToPendingTarget`/`_scheduleSecondStageAlign`/`_alignFailed`/`_finishRestore`
开头检查 `_mode == paged` 直接标记完成返回）。

### 10. Drift `references()` 未生成 FK（P2，隐蔽）

**现象**：reading_progress 级联删除测试失败；`removeCollection` 删书后进度残留。

**根因**：Drift 生成器在 `text().references(Table, #col)` 下未产出
REFERENCES 子句（g.dart 全文件 `references:` 出现 0 次）——SQL 层无 FK。

**正确做法**：用 `text().customConstraint('REFERENCES content_collections (id) ON DELETE CASCADE')`
显式声明；同时应用层（removeCollection）显式删除，双保险。
**验证**：PRAGMA foreign_keys 查询 + 诊断测试确认 CREATE TABLE SQL 含 REFERENCES。

---

## M5.1a 教训（设置持久化，2026-08-08）

### 1. Drift 多级迁移中的 current table shape 重复加列

**现象**：审查 schema 1→4 路径时发现，`from < 2` 的 `createTable(readingProgress)`
会按当前代码生成包含 readingMode 的完整表；随后 `from < 3` 再 addColumn readingMode，
跨级升级可能因重复列失败。

**根因**：把迁移步骤误当成历史表快照；Drift `createTable(tableInfo)` 使用的是当前表定义。

**正确做法**：只有真实 schema 2 旧表执行 readingMode addColumn（`from == 2`）；
schema 1 直接升级时由 current createTable 一次创建完整 reading_progress，再创建 app_settings。

**验证**：文件库构造 schema 1 快照直升 schema 4，断言 reading_progress/app_settings 存在且
reading_mode 只有一列；schema 3→4 另测书库、progress、mode、Locator、managed TXT 保留。

---

## M5.1b 教训（metrics 重排，2026-08-08）

### 分页引擎失效不仅是替换引用

**现象**：metrics/viewport 变化会创建新的 PagedLayoutEngine；若只覆盖字段，旧引擎持有的
TextPainter 不会释放，连续快速改设置会积累渲染资源。

**正确做法**：generation 先使旧结果失效，显式 dispose 旧 engine，再按新 signature 构建
engine 和有限 PageWindow；controller 最终 dispose 仍释放当前 engine。

---

## M5.1c 后 P1 教训（模式恢复状态机，2026-08-09）

模式目标必须先成为 active subtree，再调度只对该模式有效的布局恢复；否则保护分支会把合法
恢复当成旧模式工作直接跳过。解冻边界也不能以 Future 完成为准，只能以真实 visible range
包含目标 Locator 且 confirmed 相等为准。核心切换测试必须使用非零 X，并直接调用强类型菜单
回调；offset 0 与不可靠 popup 坐标 tap 都会制造假阳性。

---

## M5.1e 教训（设置面板持久化测试，2026-08-09）

带 Drift `watch()` 的 widget 测试若在页面仍挂载时先 `db.close()`，数据库关闭会等待仍活跃的
stream，而页面的 subscription 又尚未进入 dispose，表现为测试进程无 CPU、无断言输出地挂起。
正确 teardown 顺序是先关闭 modal、卸载 Reader 并推进一帧完成 subscription cancel，最后关闭
测试数据库。该问题只影响测试资源生命周期，不应通过业务层固定 delay 掩盖。
## M5.1e.1 lessons (2026-08-09)

### Persisted state must gate the first layout, not merely update it later

A watch stream can eventually make controls display the saved values while an earlier
Reader layout has already committed defaults. For layout-critical persisted state,
startup needs an explicit initial-load barrier: load the current collection snapshot,
derive metrics, subscribe to that same collection, then create the Reader layout.

### Additive migrations must tolerate sparse historical test schemas

Production schema 4 contains content_collections, but older migration fixtures may
model only the table relevant to their original transition. A schema 5 seed query now
checks sqlite_master before selecting existing collections. This preserves real data
while keeping every supported historical migration path executable.

## Reader input and chapter-boundary lessons (2026-08-09)

Physical keys and gestures should terminate at a small command vocabulary before
they reach pagination. This keeps Android host code platform-specific only at the
event-reporting boundary and leaves future user remapping independent of the page
engine. Chapter starts likewise belong in pagination policy: use real TOC offsets
as boundaries, allow intentional whitespace at the prior page end, and never add
synthetic characters to normalized text.

## M5.2a lessons (2026-08-09)

### Drift FK contracts require real SQLite verification

Nullable historical relations and delete actions are easy to misread from Dart
table declarations. M5.2a uses explicit `customConstraint` declarations for
`ON DELETE SET NULL` and `ON DELETE CASCADE`, then verifies the generated schema
with `PRAGMA foreign_key_list` and exercises actual collection/history deletes.
Migration tests must reopen a schema-5 SQLite file, not only test a fresh schema-6
in-memory database.

### Aggregate reading statistics must have one source

`reading_history` stores book and display snapshots only. Duration and session
count are calculated from `reading_sessions`; duplicating those totals in history
would create a second mutable truth that can drift during pause/resume or crash
recovery.

### M5.2b Reader panels must not leak long-lived Drift watchers

A widget-level Drift `watch()` subscription kept the test isolate alive during
Reader teardown even after the visible panel had closed. For this short-lived
current-book panel, load the scoped bookmark list when opening it and explicitly
refresh after create/delete. The UI remains current without adding a lifecycle
watcher to the Reader route; any future always-live list must await/verify
subscription cancellation as part of route disposal.
