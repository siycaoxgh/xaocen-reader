# M5.9b-2 — EPUB Import + Library Persistence

## 结论

本阶段已完成，可冻结。没有新增 Drift schema，也没有改变 Reader、Locator、分页或进度的稳定合同。

## 修改文件

- `lib/data/repositories/local_library_repository.dart`
  - 新增 EPUB 内容 hash、source、collection、item、document ID 生成规则。
  - 新增 `importEpub`：解析、去重、原子文件提交、数据库事务提交和完整性校验。
  - EPUB 使用现有 `content_sources / content_collections / content_items / content_documents / toc_entries` 表。
  - 删除书籍时按 source kind 清理 EPUB 受管目录，不影响外部 EPUB。
- `lib/data/repositories/library_file_manager.dart`
  - 增加 `library/epub/<contentHash>/` 受管目录及临时导入目录原子提交/删除能力。
- `lib/domain/library/library_import_models.dart`
  - 增加 `ImportEpubRequest` / `ImportEpubResult`。
- `lib/domain/reader/reader_content.dart`
  - 默认 ReaderContent adapter registry 接入 EPUB adapter；未知 RSS/在线来源仍不会伪装成 TXT。
- `lib/app/providers.dart`
  - 导入状态机增加 EPUB 分支，导入完成后复用现有书架刷新。
- `lib/app/library_page.dart`
  - 文件选择器支持 `.txt` 与 `.epub`；按扩展名路由到既有 TXT 或 EPUB 导入流程。
- `test/unit/epub_import_persistence_test.dart`
  - 覆盖 EPUB 归档、metadata、spine documents、TOC、ReaderContent registry、重新查询和重复导入去重。

## 导入与重开链路

1. 文件选择器选择 `.epub`。
2. `EpubParser` 解析 package metadata、manifest、spine 和 EPUB3/NCX TOC，保持原始 spine 顺序。
3. `EpubReaderContentAdapter` 生成统一 `ReaderContent` 投影。
4. spine 正文按原顺序连接为 UTF-8、无 BOM 的 `normalized.txt`；每个 spine 仍保存自己的 UTF-16 start/end range。
5. 原始包、normalized 正文、manifest 一起提交到：
   `library/epub/<sha256>/source.epub`
   `library/epub/<sha256>/normalized.txt`
6. 书籍 metadata 和 source identity 持久化到现有 Library/Drift 表；TOC 和 document ranges 继续由现有仓库查询。
7. Reader 打开时仍通过 `NormalizedDocumentLoader` 加载同一 normalized 文本，使用现有 absolute UTF-16 Locator、ReaderProgress、Vertical/Paged 和 ReaderContent contract。
8. 相同 EPUB 内容 hash 重复导入不产生第二本书；受管文件缺失时返回 `corruptedManagedCopy`，不会静默覆盖用户数据。

## 身份与数据边界

- `sourceId`: `epub-source:<sha256>`
- `collectionId`: `epub:<sha256>`
- 外部 EPUB 文件只读，不重命名、不移动、不写回。
- 删除书籍只删除 XAOCEN 管理副本和 Library 记录，不删除用户原文件。
- 阅读进度、书签、历史、ReaderPreferences 继续按 collectionId 关联，未新增第二套 truth。

## 本轮范围限制

复杂 CSS、脚注、媒体、DRM、在线书源和云同步仍未实现；这些是后续扩展点，不影响当前 EPUB 纯文本导入/阅读链路。

## 验证

- `flutter analyze --no-pub`：PASS
- EPUB parser + adapter + persistence 定向测试：PASS（10 tests）
- 全量 Flutter tests：PASS（668 tests）
- `git diff --check`：PASS（仅有工作树既有 CRLF 提示，无 whitespace error）

## 阶段状态

**EPUB IMPORT + LIBRARY PERSISTENCE = PASS / FROZEN**
