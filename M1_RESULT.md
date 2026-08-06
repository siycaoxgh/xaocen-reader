# M1_RESULT.md

> **XAOCEN Reader v4 · M1 本地 TXT 标准化与索引管线结果**
> 日期：2026-08-06 · 阶段：M1（TXT 标准化与索引，不含 Reader/UI）
> 分支：feat/m1-local-txt-pipeline

---

## 1. 最终 HEAD

`28c71ca`（见 §2 提交列表）

## 2. 完整提交列表

| Commit | 说明 |
|---|---|
| `4b6108c` | feat(encoding): add deterministic gb18030 decoder |
| `fefeb23` | feat(txt): add normalized toc scanner |
| `0eba0bc` | feat(txt): add atomic txt index cache |
| `532d0e8` | test(txt): add local txt contract fixtures |
| `28c71ca` | tool(txt): add readonly txt inspection |

（基线：`847641b` M0 完成点；分支从 main 创建，未强制 reset）

## 3. GB18030 Asset 格式

- 二进制：`assets/encoding/gb18030_index.bin`（97,446 字节）
- 元数据：`assets/encoding/gb18030_index.meta.json`
- 格式 v1（小端）：`magic "GBIX" (4B) + formatVersion u8=1 + flags u8=0 + entryCount u32 + entries[pointer u16, cp u16]×23940 + anchorCount u32 + anchors[pointer u32, cp u32]×209`
- 生成器：`tool/generate_gb18030_index.dart`（重复运行字节一致）
- 数据来源：WHATWG index-gb18030.txt（2024-09-18）+ Python gb18030 codec 验证的 209 锚点（内嵌 `tool/gb18030_anchors_data.dart`）
- SHA-256：`aebe263d5a6b037d2155fd9f78598686e7f369732f9fc3e5f5ccc0778cc82697`（与 Spike 4 真机验证的 bin 一致）
- 运行时加载：`gb18030_index_loader.dart` 验证 magic/版本/长度/一致性，失败抛明确异常

## 4. 全量映射测试结果

| 测试 | 结果 |
|---|---|
| 双字节全表 23940 项 | ✅ 全部有效（valid > 23000） |
| 锚点全表 209 项 | ✅ |
| 四字节区间边界（U+10000/pointer 189000、U+20000/pointer 254536） | ✅ |
| ASCII / 常用中文 / 全角标点 / 生僻字 | ✅ |
| 非法 lead / 非法 trail / 截断序列 | ✅ |
| 跨块序列（双字节/四字节逐字节分块） | ✅ |
| replace 模式（U+FFFD） | ✅ |
| strict 模式（FormatException） | ✅ |
| 0x80 → U+FFFD（跨端一致） | ✅ |

## 5. 有章节真实文件结果

文件：`C:\Users\TOM\Desktop\测试\苟在初圣魔门当人材(1-500章).txt`（3,707,874B，只读）

| 项 | 值 |
|---|---|
| 编码 | UTF-8（BOM 检测 → 严格 UTF-8 校验通过） |
| 规范化字符数 | 1,261,383 |
| 卷数 / 章数 | 0 / **473** |
| 内容 hash | 9ace0b9b79f746f64c63749e808b10d49b07ebbe9a6e9ce34025d6b40d08a5d6 |
| 公告误匹配 | 「第五十二章被审核了」排除 ✅ |
| 远距同名 | 保留（无全局去重）✅ |

## 6. 无章节真实文件结果

文件：`C:\Users\TOM\Desktop\测试\无章节数字测试.txt`（8,054,340B，只读）

| 项 | 值 |
|---|---|
| 编码 | UTF-8 |
| 规范化字符数 | 2,739,888 |
| 卷数 / 章数 | 0 / **0**（不伪造目录，不视为错误） |
| 内容 hash | 12b6e8af42dd57b906e7d891d28e34a975ef164f049148e451deb9fe1d1a78b3 |

## 7. 章节扫描耗时（有章节文件，首次全量）

| 阶段 | 耗时 |
|---|---|
| 文件读取 | 4ms |
| 解码 | 20ms |
| 规范化 | 16ms |
| 扫描 | 24ms |
| 去重 | 20ms |
| 缓存写入 | 98ms |
| **总耗时** | **251ms**（旧 Spike O(n²) 实现约 7s，提速 ~28×） |

## 8. 第二次缓存命中耗时

- 缓存命中（不重扫）：**63ms / 90ms / 127ms**（含文件读取 + hash + 缓存读取）
- cacheHit=true，decode/normalize/scan/dedupe 均为 0

## 9. 473 章指定 offset（UTF-16 码元坐标，规范化全文）

| 章 | 偏移 | 章 | 偏移 |
|---|---|---|---|
| 第1章 | 54 | 第258章 | 685,040 |
| 第19章 | 49,208 | 第300章 | 795,861 |
| 第42章 | 108,790 | 第400章 | 1,062,206 |
| 第112章 | 298,039 | 第473章 | 1,257,817 |
| 第195章 | 516,559 | | |

与 SPIKE_RESULT.md §2 记录完全一致 ✅

## 10. 卷层级测试结果

| 场景 | 结果 |
|---|---|
| 第X卷 + 卷内章节 | ✅ 卷数/章数分开统计，卷内 order 重新编号 |
| 卷一（中文数字） | ✅ |
| 卷前章节 parentId 为空 | ✅（不创建默认卷） |
| 无卷时章节平铺 | ✅ |
| 卷不计入章节总数 | ✅ |

## 11. 大文件阈值测试

| 大小 | 预期 | 结果 |
|---|---|---|
| 20MB | normal | ✅ |
| 20MB+1 | requiresConfirmation | ✅（未确认时抛 TxtImportRequiresConfirmation） |
| 50MB | requiresConfirmation | ✅ |
| 50MB+1 | unsupported | ✅（抛 TxtImportException） |

阈值集中定义于 `lib/domain/local_txt/large_file_policy.dart`。

## 12. 取消与缓存失败结果

- 取消：提前取消抛 `TxtImportCancelledException`，独立缓存目录**不留下正式缓存** ✅
- 缓存损坏：readIfValid 返回未命中（reason=corrupt），管线重扫恢复 ✅
- 原子写入：成功无 .tmp 残留；失败清理临时文件不覆盖原缓存 ✅
- 缓存命中校验：size/hash/encoding/parserVersion/normalizationVersion/indexFormatVersion；**不依赖 mtime**（mtime 变化但 hash 不变仍命中）✅

## 13. Windows 验证

- `flutter analyze`：✅ No issues
- `flutter test`：✅ 82/82 通过（单元 + 合同）
- `flutter build windows --release`：✅
- `flutter build apk --debug`：✅
- `tool/verify.ps1`：✅ 全绿
- 真实文件 inspect：✅（§5/§6）

## 14. Android 验证

- **解码器/扫描器/缓存为纯 Dart**，与平台无关——82 项测试即 Windows 与 Android 相同向量验证（合同 2 显式验证确定性：同输入同输出）
- Android Debug 构建通过（§13）
- M1 无 Android 专项真机验证（与 M0 Android 真机 Spike 结果一致：GB18030 解码、UTF-16 偏移、缓存逻辑已验证）
- 后续 M2+ 可补充 Android 真机 inspect 运行

## 15. verify.ps1 结果

```
flutter pub get      ✅ (2.2s)
dart format check    ✅ (1.1s, 0 changed)
flutter analyze      ✅ (10.7s)
flutter test         ✅ 82 passed (7.7s)
flutter build windows --release ✅ (12.6s)
flutter build apk --debug       ✅ (13.2s)
git diff --check     ✅
```

## 16. 工作区状态

`git status` 干净（clean）。外部 TXT 文件 hash 校验未修改（§5/§6 hash 与验收前一致）；缓存写入 `C:\Users\TOM\Desktop\xaocen-reader-v4\m1_cache*`（管理目录，不在 TXT 旁）；正文未写入缓存；日志不记录正文。

## 17. M2 建议

1. **Reader 分页管线**：基于 TxtIndex + 规范化文本，实现惰性分页（首屏/恢复页/邻近页），TextPainter 分页（Spike 3 已验证合同）
2. **读取器坐标服务**：UTF-16 偏移 ↔ 页码双向映射、章节跳转
3. **书架与数据库**：Drift schema（ContentSource/ContentCollection/ContentItem/ContentDocument 四层模型）、导入记录
4. **进度/取消 UI 消费**：PipelineProgress 接入加载页（首扫显示阶段+进度）
5. **GB18030 Asset 运行时加载**：Flutter AssetBundle 加载器（当前 tool 用文件路径，运行时需 rootBundle）
6. **Android 真机验收**：补一轮 inspect 工具真机运行
7. 大文件确认流程 UI（>20MB 提示确认）

**M2 完成标准建议**：真实 TXT 打开 → 首屏渲染 → 翻页 → 位置保存恢复，全链路走通。
