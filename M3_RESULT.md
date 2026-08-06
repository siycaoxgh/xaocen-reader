# M3_RESULT.md — 纵向滚动 Reader + 精确位置恢复

日期：2026-08-07
分支：`feat/m3-vertical-reader`
基线：`feat/m2-local-library @ e61c8b6`（main 已 ff 合并）
HEAD：`b5f80fa`（工作区 clean）

## 1. 版本与数据代际

- 应用版本：`0.1.0-dev.3+3`
- 数据代际：`v4-local-1`（不变）
- Drift schema：1 → 2（仅新增 `reading_progress` 表，只增不删）

## 2. 位置合同（唯一真源）

- **唯一持久化位置真源**：normalized.txt 对应 Dart String 的 UTF-16 码元偏移
  （`ReaderLocator.collectionId + absoluteCharacterOffset + 可选 itemIdHint`）
- 禁止作为真源：页码 / scroll pixels / blockIndex / 章节比例 / 全文百分比
- `clampLocatorOffset`：超界 clamp 到 `[0, len]`，且不切 surrogate pair（落在
  low surrogate 中间时向前回退一个码元）

## 3. reading_progress 表与仓库

- 每 collection 一条；主键 collectionId + 外键级联删除
- 字段：collectionId / absoluteCharacterOffset / itemIdHint(可空) /
  updatedAt / locatorVersion / normalizationVersion
- `ReadingProgressRepository`：getProgress / saveProgress（upsert）/ clearProgress
- UI 不经 Drift，一律经 Repository

## 4. NormalizedDocumentLoader

- 按 M2 Document.storagePath（相对路径）经 `LibraryFileManager.resolveStoragePath`
  解析（处理 `library/` 前缀去重）
- 校验：文件存在 / 无 BOM / 严格 UTF-8 / normalizedHash（manifest）/ UTF-16 长度
- ≤50MB 全文加载为 Dart String（内存）
- 修复 M2 遗留 bug：storagePath 带 `library/` 前缀导致重复路径段

## 5. ReaderBlock 与 ReaderBlockIndex

- 块大小 4096–8192 码元（默认 6144），优先 LF 后切分，不切 surrogate
- 连续 / 不重叠 / 不遗漏；首 0 尾全文长；确定性可重建（policyVersion=1）
- `blockForOffset` 二分定位；越界 clamp 首/末块
- 不存 substring、不落库、不因字体/窗口变化改变

## 6. 列表方案（super_sliver_list 准入）

- **Spike 5 准入验证通过**（research/spike/spike5_sliver）：
  - 双平台构建（Windows Release 52s / Android APK 57s）
  - 可变高度块 ✅
  - `ListController.jumpToItem` 按块跳转（第 400 章位置）✅
  - 不预构建前置块（跳转后已构建 <500/10000）✅
  - ScrollController + Scrollbar + 滚轮 ✅
  - dispose 无异常 ✅
- 正式引入 `super_sliver_list 0.4.1`（MIT，2024-03-26）
- 未引入两套列表；未用全文单 Widget / 预排全文 / 比例估算

## 7. 渲染（ReaderTextBlock）

- 显示与测量同一 `TextPainter`（RenderReaderTextBlock 单一 RenderObject）
- 暴露：local offset→glyph Rect / 本地 y→TextPosition / 实际高度 / 布局完成状态
- 正文零插入零删除（不缩进、不删空行、不改标题）
- 修复：itemBuilder 内 GlobalKey 关联 RenderObject（原先误用列表项 context）

## 8. ReaderVisibleRange（真实可见范围）

- 来自**当前树中活跃块**（GlobalKey.currentContext 非 null 的块集合）
- 以活跃块最小/最大 index 与 offset 作为可见范围
- 禁止比例估算；滚动后旧块回收不影响

## 9. 恢复状态机

- loadingDocument → buildingBlockIndex → locatingTargetBlock → jumpingToBlock
  → resolvingTargetCharacter → confirmingVisibleRange → completed / failed
- **恢复完成前零写入**（`_restoreWriteUnlocked` gate）
- 结束条件：requested offset 在真实可见范围内（确认 + 解冻）
- 修复：列表 attach 前跳转失败 → 双 post-frame 重试

## 10. 目录跳转

- 目录抽屉（卷 / 章；当前章高亮；无章节文件显示"全文"入口）
- `jumpToOffset` → pendingTargetBlock → jumpToItem → finishTocJump 确认后立即保存
- itemIdHint 保存为 chapter 稳定 ID

## 11. 保存策略

| 来源 | 行为 |
|---|---|
| programmaticRestore | 零写入（恢复完成前） |
| programmaticTocJump | 可见范围确认后保存 |
| userDrag / userWheel / userScrollbar | 真实顶部可见字符 + 400ms 防抖 |
| scroll end / lifecycleFlush | 立即 flush 已确认位置 |

- lifecycle：route pop / inactive / paused / detached 均 flush

## 12. UI（最小功能）

- 顶部：返回 / 书名 / 目录按钮
- 正文：Scrollbar + NotificationListener + SuperListView.builder
- 目录：DraggableScrollableSheet 抽屉
- 诊断条（`--dart-define=XAOCEN_READER_DEBUG=true` 默认关闭）
- 书架点击书籍 → 打开真实 Reader（替换 M2 占位提示）
- 未复制旧 XAOCEN UI

## 13. 测试（全绿）

- 单元 + widget：**160 项全过**（M2 109 + M3 新增 51）
  - reader_block_test 9（连续/无遗漏/surrogate/空文本/只有换行/超长单段/定位/clamp/确定性）
  - reader_locator_test 10（clamp 边界/surrogate 回退/copyWith/相等性）
  - reading_progress_repository_test 8（CRUD/upsert/级联/互不影响/迁移）
  - reader_controller_test 12（恢复冻结/防抖/flush/事件边界/jumpTo/dispose）
  - normalized_document_loader_test 7（hash/长度/路径穿越/BOM/非法 UTF-8/UTF-16 长度）
  - reader_page_test 6（打开/零写入/返回/目录/跳转/dispose）
- 集成测试 4 个全过：
  - vertical_reader_flow_test：导入→打开→滚动→返回→重开→恢复→目录远跳
  - accept_real_files_test：真实文件验收
  - m2_library_flow_test / m2_android_verify_test（M3 适配后仍通过）

## 14. 真实文件验收（accept_real_files_test）

- `苟在初圣魔门当人材(1-500章).txt`：
  - UTF-8 / 473 章 / 9 个指定章节 offset 全部命中且落在对应 chapter 范围：
    #1=54、#19=49208、#42=108790、#112=298039、#195=516559、
    #258=685040、#300=795861、#400=1062206、#473=1257817
  - 每 offset 均定位到包含它的 block（block 内偏移 ≥ 0）
  - 外部文件字节数不变（只读）
- `无章节数字测试.txt`：
  - 0 章不伪造目录 / 1 whole item / 25%·50%·75% 定位均不命中末块

## 15. 构建

- Windows Release：✅（xaocen_reader.exe）
- Android Debug APK：✅（app-debug.apk）
- 修复：android/settings.gradle.kts 增加 dependencyResolutionManagement，
  google() 优先 + download.flutter.io 排除 androidx.test（否则动态版本
  `1.2+` 解析访问 storage.googleapis.com 404 导致构建失败）

## 16. verify.ps1 全绿

pub get / format check / analyze / 单元测试(160) / 集成测试×4 /
Windows Release / APK Debug / git diff --check —— 全部 PASS（exit 0）

## 17. 提交记录（6 个）

```
45ae988 feat(reader): add reading progress schema and repository
846a67b feat(reader): add vertical reader core with block index and restore state machine
bb11c95 feat(ui): add minimal vertical reader page and bookshelf entry
7a9eacb test(reader): add reader unit widget and integration tests
02b8252 build(android): resolve androidx from google() to avoid flutter.io 404
b5f80fa chore: add super_sliver_list for virtualized vertical scrolling
```

## 18. 尚未完成（需用户配合）

- **Android 真机 9 项验证未执行**（设备未连接无线 ADB）：
  覆盖安装（不卸载）/ 书架数据存留 / schema 迁移成功 / 打开已导入书 /
  触摸滚动 / 返回重开 / force-stop 重开 / 第 400 章跳转 / 无章节大文件滚动 /
  横竖屏仍可见 / 0 crash
  → 连接设备后执行（apk 已构建，`integration_test/m2_android_verify_test.dart`
  模式可复用）
- Windows 真实启动手测（滚轮/滚动条/目录跳转/关闭重启/调窗口尺寸）待做
- M3 完成后停止，未自动进入 M4
