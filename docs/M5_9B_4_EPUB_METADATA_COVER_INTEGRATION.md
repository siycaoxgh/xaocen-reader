# M5.9b-4 — EPUB Metadata / Cover Integration

## 结论

本阶段已完成。EPUB 的 package metadata 与内嵌封面现在通过现有 Library、Cover、ReaderContent 链路落库和展示；没有新增数据库 schema，也没有修改 Reader、Locator、Pagination 或 Progress。

## 修改文件

- `lib/sources/epub/epub_models.dart` — 为 EPUB metadata 增加 title/author 来源和 cover href/media type。
- `lib/sources/epub/epub_parser.dart` — 识别 EPUB 3 `properties="cover-image"` 与 EPUB 2 `<meta name="cover">`，并把非 spine 封面纳入 asset 集合。
- `lib/sources/epub/epub_reader_content_adapter.dart` — 将 EPUB metadata provenance 投影到统一 `ReaderContent`。
- `lib/domain/library/metadata_source_priority.dart` — 统一 metadata/cover 来源优先级合同，不新增存储真相。
- `lib/data/repositories/local_library_repository.dart` — 导入时持久化 EPUB 封面、metadata 来源和 manifest 信息；复用现有 `coverPath`/`coverSource` 字段。
- `lib/data/repositories/local_book_cover_repository.dart` — 支持解析 EPUB managed cover；删除手动封面后自动回退到 EPUB 内嵌封面或 placeholder。
- `test/unit/epub_parser_test.dart` — EPUB 3/EPUB 2 封面识别测试。
- `test/unit/epub_import_persistence_test.dart` — 封面文件、来源、手动覆盖和删除回退测试。
- `test/unit/metadata_source_priority_test.dart` — metadata/cover 优先级测试。

## Metadata 链路

```text
EPUB OPF dc:title / dc:creator / dc:description
  → EpubBookMetadata（autoDetected；缺失 title 时为 fileName）
  → EpubReaderContentAdapter / LibraryCollection
  → 现有 content_collections 字段与书架展示
```

来源优先级为：

```text
manual > onlineConfirmed（预留） > autoDetected > fileName
```

当前 EPUB 本轮只实现 `autoDetected` 与 `fileName`；online metadata 没有实现。现有手动编辑仍写入 `manual`，重复导入直接返回已有 collection，不会覆盖手动值。

## Cover 链路

```text
EPUB 3 cover-image / EPUB 2 meta cover
  → EpubParser.coverHref
  → EPUB asset
  → library/epub/<contentHash>/cover.<ext>
  → content_collections.coverPath + coverSource=autoDetected
  → 现有 LocalBookCoverRepository / 书架 BookCover
```

本地手动封面仍保存到 `library/covers/`，优先级为 `manual > online（预留） > autoDetected > placeholder`。删除手动封面时，如果 EPUB 内嵌封面仍存在，会恢复为自动封面；否则回退 placeholder。封面文件损坏或不存在时，现有 resolver 返回空并由 UI 使用 placeholder，不会导致崩溃。

## 数据与兼容性

- 未增加 Drift schema 或 migration。
- 继续复用现有 `coverPath`、`coverSource`、`metadataSource`、`titleSource`、`authorSource` 字段。
- 原始 EPUB 复制到 `library/epub/<contentHash>/source.epub`，normalized text、rendering images 和 manifest 同目录管理。
- collection identity、UTF-16 locator、阅读进度、书签、历史和 ReaderPreferences 均未改变。
- EPUB CSS、脚本、DRM、远程资源、在线 metadata/cover 仍是本阶段范围外。

## 验证

- `flutter analyze --no-pub` — PASS（No issues found）
- EPUB/ReaderContent/Library 定向测试 — PASS（24 tests）
- 全量 Flutter tests — PASS（676 tests）
- `git diff --check` — PASS（仅现有 LF/CRLF 提示，无 whitespace error）

## 冻结结论

**M5.9b-4 可冻结。** 后续若实现 online metadata/cover，应通过本报告定义的 priority contract 接入，不得覆盖 manual 值，也不应为 EPUB/RSS 另建一套 Reader 或数据库 truth。
