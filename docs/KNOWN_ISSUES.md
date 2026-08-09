# KNOWN_ISSUES.md — XAOCEN Reader v4 已知问题清单

> 状态截至 M5.1d COMPLETE（`feat/m4-horizontal-reader`）。Android 真机统一延后到 M5.1 收尾。
> 已解决的问题不在此列为 open；「Resolved but regression-sensitive」列出需要持续盯防的已修复项。

---

## Current open issues

（截至 M4 最终封存，无已知的 open bug。M4 P1 已解决并从已知问题中移除；以下均为验证覆盖的边界行为或工具性限制，见 Known limitations / Deferred。）

- M5.1d 未发现新的 Reader engine P1/P2。Aa 当前仅为明确标注的预览容器；
  字号、行距与边距实际控件属于 M5.1e。
- M5.1c/d Android 真机验收为 NOT-RUN，按既定策略延后到 M5.1 最终统一验收；
  各子阶段仍要求 Android Debug 构建通过。

---

## Known limitations（当前版本的能力边界）

| 限制 | 说明 |
|---|---|
| 仅支持 TXT | EPUB/PDF/Markdown/HTML 未实现（见 Deferred） |
| >20MB 需确认 | 导入前提示，用户确认后后台扫描 |
| >50MB 0.1.x 暂不支持 | 明确提示，不尝试打开（阈值集中定义于 large_file_policy.dart，可调） |
| Reader 双模式 | 纵向滚动 + 横向分页（M4 已交付，v0.1.0-dev.4+4）；位置真源始终为 UTF-16 偏移，页码为派生 |
| 文件选择依赖系统对话框 | file_picker 调起系统选择器（Android 上需手动配合） |
| Android 调试依赖无线调试 | USB 直连被 Windows 驱动签名阻塞，需设备开启无线调试 |
| 调试 APK 内存占用高 | Debug 构建 PSS ~281MB（JIT/引擎常驻）；Release 会显著下降 |
| 12px 顶部安全区 | 恢复/跳转后顶部可能显示上一章尾部（合同行为：标题行对齐 topInset+8~24px；目录高亮允许 ±1 章） |
| 目录 UI 长距离滚动受限 | DraggableScrollableSheet 手势会吞掉长距离 drag；远跳能力由 controller 层 + 集成测试保证，UI 层点到即达 |
| normalized.txt 全文载入内存 | ≤50MB 文件全量加载为 Dart String（设计内）；>50MB 惰性读取未承诺 |
| 分页 backward 页首漂移 | Flutter getLineBoundary 在 LF/wrap 边界行首定位偏差：≤2 屏/100 页（end 链严格连续，字符链不重不漏；confirmed locator 零误差，仅翻回时起始行略偏移） |

---

## Deferred（已排期/延后，未开始）

| 项 | 说明 |
|---|---|
| 搜索 | FTS5 未建 |
| 书签 | 未实现 |
| Reader V3 壳层/设置 UI | Metrics 与 theme paint 已完成；完整 V3 Reader UI 尚未做 |
| M5.1 Android 最终真机验证 | M5.1c/d/e 开发阶段仅要求 Debug build；真人/真实语料统一在 M5.1 收尾执行 |
| TTS | 未引入 flutter_tts |
| RSS / 网络书源 | webfeed/JSON Feed 调研过但未引入；RSS 属 v2.0 范围 |
| EPUB / PDF | 未实现 |
| 完整 V3 UI | 当前为最小功能 UI；统一 UI 未做 |
| 云同步 / 账号 | 未做 |
| 多设备同步 | 未做 |

---

## Resolved but regression-sensitive（已修复，需持续盯防）

| 项 | 为何敏感 | 防护 |
|---|---|---|
| normalizedHash 合同 | M3.1 P1：Drift 曾存 sourceHash 导致大文件 hash_mismatch；任何写入路径改动都可能复发 | hash_contract_test + repair_service_test + 集成 hash_contract_flow_test；Loader 以 manifest 为权威 |
| parser 完整标题 | M3.2：group(0) 曾丢标题；任何扫描器改动可能复发 | scanner 完整标题 8 项 + toc_title_persistence 6 项；真实库 4 本 parserVersion 2.0.0 |
| 目录自动定位/当前章高亮 | M3.3：block 级近似曾差 34 章 | toc_scroll_test 12 项；真实文件 6 章 ±1 |
| 深色可读性 | M3.3 P1：硬编码深字曾致黑底不可读 | reader_dark_mode_test 8 项（≥4.5:1） |
| progress 恢复冻结 | M3：恢复未确认前写入会污染位置 | reader_controller_test 冻结/防抖用例 |
| 外部 TXT 不可修改 | 全阶段红线：repair/删除不得触碰外部文件 | 验收测试断言外部 hash 不变；删除级联测试 |
| 473 章去重 | M3.2：正文引用行（错别字）曾致 486 章 | 章节编号相同即相邻重复；真实文件 473 断言 |
| Android APK 正常入口 | flutter test 会覆盖为 test-runner 版 | 测试后必须重新 build apk --debug |

---

## 记录但未修复的观察（文档审计发现）

以下为本任务（M3 封存审计）中观察到、按任务书仅记录不修改的事项：

1. **M2 遗留 storagePath 语义**：`content_documents.storage_path` 存 `library/local_txt/<hash>/normalized.txt`（相对 `<support>`），而 `LibraryFileManager.libraryRoot` 即 `<support>/library` —— M3 已用 `resolveStoragePath` 去前缀修复（loader 与 manifest 读取），但数据中保留 `library/` 前缀的语义仍属冗余，未来 schema 变更时可考虑清理。
2. **`test/fixtures/txt/` 大文件 fixture**（20MB/50MB 共 4 个，~146MB）已由 git 压缩存储（pack 很小），但克隆体积仍会因 worktree 展开而变大；如未来仓库分发受限可改为运行时生成。
3. **`integration_test/vertical_reader_flow_test.dart` 内嵌大 fixture 数组**（74,593 行，~676KB）—— 为保证格式门禁，行尾已统一 LF；该文件体量较大，未来可改为运行时生成 fixture。
4. **`tool/inspect_managed_txt.dart`** 依赖 `sqlite3` 直接依赖（pubspec 显式加入，原为传递依赖）—— 属工具链用途，勿移除。
5. **父目录 `m1_cache/`、`m1_cache_notoc/`** 是 M1 阶段 inspect 工具的缓存产物（管理目录，不在仓库内），非外部 TXT 旁缓存。
6. **`docs/README.md` 的权威文档索引**未列 M1–M3.4 报告（本任务新增 6 份长期文档后应同步更新索引——见最终交付说明）。
