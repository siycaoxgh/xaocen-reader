# TEST_VALIDATION_MATRIX.md — XAOCEN Reader v4 验证矩阵

> 状态：M4 COMPLETE（`feat/m4-horizontal-reader`）；P1 修复后的 Windows + Android 真人验证已完成。
> 自动测试与真人测试分开记录。**Android Debug 构建 PASS ≠ Android 真机 PASS**，两者分别列出。
> 真人环境：Windows（本机，用户 + 自动化集成测试）；Android 真机 Redmi K60（23013RK75C / mondrian，Android 15 / API 35，无线 adb）。

图例：✅ 通过 · ✅* 通过（用户手动确认） · ➖ 不适用/未执行 · 🔒 回归敏感

---

## A. 自动测试（当前全绿）

**单元 + Widget：327 项**（`flutter test`，Windows VM）：
- M1 系：gb18030_decoder（含全表 23940/锚点 209/四字节/非法/跨块）、txt_encoding_detector、txt_normalizer、txt_toc_scanner（24）、txt_index_cache、large_file_policy
- M2 系：local_library_test（20）、library_page_test（8）、m0_skeleton_test（6→更新）
- M3 系：reader_block（9）、reader_locator（10）、reading_progress_repository（8）、reader_controller（12）、normalized_document_loader（9）、reader_page_test（6）、reader_jump（11）、toc_title_persistence（6）、toc_display（4）
- M3.1 系：hash_contract（11）、repair_service（12）
- M3.3 系：toc_index（10）、reader_appearance（7）、toc_scroll（12）、reader_dark_mode（8）
- 合同：txt_pipeline_contract（10）、content_navigation_contract（8）
- M4 系：paged_layout_engine（20）、page_window（7）、paged_reader_controller（18）、paged_reader_view（11）
- M4 P1 系：reader_progress_state（3+1 迁移）、mode_persistence_contract（4）、mode_persistence_widget（3）

**集成测试：8 个文件**（`flutter test integration_test`，Windows 逐文件 + Android 真机）：
`accept_real_files_test` · `accept_real_paged_test` · `hash_contract_flow_test` · `m2_android_verify_test` · `m2_library_flow_test` · `paged_reader_flow_test` · `reader_mode_switch_test` · `vertical_reader_flow_test`

**构建门禁**：`tool/verify.ps1` 全绿（pub get / format / analyze / test / integration / Windows Release / APK Debug / git diff --check）。

---

## B. 能力验证矩阵

| Capability | Unit | Widget | Integration | Windows manual | Android real device |
|---|---|---|---|---|---|
| UTF-8 编码检测 | ✅ | — | ✅ | ✅ | ✅ |
| GBK/GB18030 解码（23940 表+209 锚点+四字节𠀀） | ✅ | — | ✅ | ✅ | ✅*（A1 + M2 真机 9/9） |
| 章节 473（真实文件） | ✅ | — | ✅ accept_real | ✅ | ✅*（用户打开大 TXT） |
| 无章节（0 章不伪造目录） | ✅ | — | ✅ accept_real | ✅ | ✅*（用户滚动） |
| 相邻重复标题去重（错别字正文引用行） | ✅ | — | ✅ | ✅（473 保持） | — |
| 卷层级（卷章/卷一/卷后重编号/卷不计章数） | ✅ | — | ✅ | ✅ | ✅（因果快递 1 卷） |
| 大文件阈值（20MB/20+1/50/50+1） | ✅ | ✅ 确认 UI | — | ✅ | — |
| 导入（原子两阶段/取消无残留/alreadyImported） | ✅ | ✅ | ✅ m2_flow | ✅ | ✅ 9/9 |
| managed 文件（source/normalized/index/manifest） | ✅ | — | ✅ | ✅ | ✅（数据存留） |
| hash 合同（manifest 权威/落盘字节） | ✅ 11 | — | ✅ hash_contract_flow | ✅ | ✅*（错误消失） |
| repair（损坏→自 source 重建/不改外部 TXT） | ✅ 12 | — | ✅ | ✅（真实库 3 本+821 行） | — |
| Reader 打开 | ✅ | ✅ | ✅ | ✅ | ✅（4 本书） |
| 滚动（滚轮/滚动条/触摸） | — | ✅ | ✅ vertical_flow | ✅ | ✅ |
| restore（位置恢复/防抖/零写入/生命周期） | ✅ | ✅ | ✅ | ✅（八月初七中段） | ✅（43/548 章恢复） |
| force-stop 重启 | — | — | ✅ | — | ✅*（最后模式+位置、书架数据保留） |
| TOC 完整标题（displayTitle） | ✅ | ✅ | ✅ | ✅（第1章 百世书…） | ✅（目录平铺） |
| TOC 精确跳转（两阶段字符对齐） | ✅ 11 | ✅ | ✅ | ✅（9 章 offset） | ✅（548→530） |
| 当前章目录定位（35% 视口/不拉回/定位按钮） | ✅ | ✅ 12 | ✅ | ✅（±1 章） | ✅（42 章 @39%） |
| 平铺目录（无折叠/异常层级可见/卷跳转） | ✅ | ✅ | ✅ | ✅（4 collection） | ✅（13/13） |
| 深色/浅色可读（≥4.5:1） | ✅ | ✅ 8 | — | ✅ | ✅*（用户确认深色可读） |
| 横竖屏旋转 | — | — | ✅ | — | ✅（渲染正常位置连续） |
| 外部文件保留（删除/repair/导入均不改外部 TXT） | ✅ | ✅ | ✅ | ✅（hash 不变） | ✅ |
| 分页引擎（行粒度/LF 边界/end 链连续/surrogate 不拆） | ✅ 20 | ✅ 11 | ✅ accept_real_paged | ✅* | ✅* |
| 分页惰性窗口（prev2+next3，Page 数与总页数无关） | ✅ 7 | ✅ | ✅ paged_flow | ✅* | ✅* |
| 双模式切换（v↔p 精确 anchor/零写入/generation） | ✅ 18 | ✅ 11 | ✅ mode_switch | ✅* | ✅* |
| 分页目录跳转（精确 target/标题可见） | ✅ | ✅ | ✅ paged_flow | ✅* | ✅* |
| 键盘翻页 / 滑动翻页（Win / Android） | — | ✅ | ✅ paged_flow | ✅* | ✅* |
| 100 页往返（end 链严格连续，页首 ≤2 屏漂移） | ✅ 20 | — | ✅ accept_real_paged | ✅ | ✅*（实际翻页无明显问题） |
| 模式+位置持久化（重开 = 上次模式 + 最后 Locator） | ✅ 11 | ✅ 3 | ✅ mode_switch | ✅*（A/B/C 三场景） | ✅*（A/B/C 三场景） |
| 退出只 flush active 模式（覆盖竞态修复） | ✅ 4 | ✅ 3 | ✅ mode_switch | ✅*（完全退出） | ✅*（force-stop） |
| schema 2→3 迁移（旧数据默认 vertical） | ✅ 1 | — | — | ✅ | ✅（覆盖安装） |

---

## C. Android 真机专项（Redmi K60 / Android 15）

### Spike 4 受控 Spike（2026-08-06）— 8/8
GB18030 解码输出 · 有章节首屏 · 无章节 7.68MB 首屏 · 真实内存（PSS 281MB/RSS 431MB Debug）· 字号变化偏移稳定 · 横竖屏偏移稳定 · 后台恢复偏移保持 · 字体度量差异（Android 3993 页 vs Windows 373/390px，偏移语义一致）

### M2（2026-08-06）— 9/9
安装启动 · AssetBundle（23940/209 并发去重）· 双编码小文件导入 · 书架显示 · 重启持久 · 删除级联+外部保留 · alreadyImported · 取消无残留 · GB18030 𠀀

### M3（2026-08-07 用户 + 自动化）— 9/9
覆盖安装数据存留 · schema 迁移 · 打开已导入书 · 触摸滚动 · 返回重开 · force-stop 重开 · 第 400 章跳转 · 无章节大文件滚动 · 横竖屏仍可见 · 0 crash（含返回动画等待修复 ab866d7）

### M3.4（2026-08-07 自动化）— 13/13
覆盖安装数据存留 · 恢复位置（43/548 章）· 平铺目录无箭头 · 自动定位高亮（42 章 @39%）· 点章节跳转（548→530）· 点卷跳转 · 目录滚动不拉回 · 正文滚动保存恢复 · force-stop · 进程退出重进 · 横竖屏 · 0 crash（pid 23606 全程不变）· 无章节「全文」（Windows 真库验证）

### M4 P1 最终真人验证（2026-08-08）— PASS
vertical A → paged → 不翻页 → 重开 = paged + A · vertical A → paged → 翻页到 B → 重开 = paged + B · paged B → vertical → 滚动到 C → 重开 = vertical + C · force-stop 重开 · 覆盖安装 schema 2→3 数据保留 · 原有书架/managed TXT 保留 · 4 个真实 TXT 正常 · Flat TOC/章节跳转/深色模式无明显回归

---

## D. Windows 真人/验收

- 真实库 4 collection 全链（M3.4）：苟在初圣魔门 473 章 / 青山 294 章 3 卷 / 因果快递 53 章 1 卷 / 无章节数字测试 → 平铺、高亮、跳转、不拉回、全文。
- M3.2：真实库 4 本 repair → parserVersion 2.0.0、完整标题、9 章 offset 命中、第 31 章 @192296 跳转。
- M3.1：真实库 3 大文件 repair + 821 行更新、外部 hash 不变、Reader 打开成功。
- M1/M2：真实文件 473/0 章、9 个指定 offset、二次 cacheHit、外部 hash 不变。
- 构建：Windows Release exe 可启动（冒烟 6s）；App 日常使用由用户确认。
- M4 P1：三组模式/位置持久化场景通过；完全退出后重开正常；4 个真实 TXT、
  原有书架/managed TXT、Flat TOC、章节跳转、深色模式无明显回归。

---

## E. 测试缺口（诚实记录）

| 项 | 状态 |
|---|---|
| >50MB 文件真机打开路径 | 未验证（策略为拒绝，仅阈值单测） |
| EPUB/RSS 等非 TXT 源 | 未实现，无测试 |
| 搜索/书签/TTS | 未实现，无测试 |
| Release 版 Android 内存实测 | 未测（PSS 281MB 为 Debug 值） |
| 多用户/多设备 | 未做 |
| Android 12 以下版本 | 未测（真机为 Android 15；minSdk 21） |
| Windows 低 DPI/高 DPI 缩放 | 未专项验证 |
