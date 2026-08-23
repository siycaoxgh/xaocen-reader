# M5.7s.9a-1 — Local Book Metadata Foundation

## 结果

本轮只建立本地书籍 metadata 基础，不改首页/书架 UI、不联网、不实现在线书源或封面。

```
BOOK METADATA MODEL = PASS
TXT TITLE INFERENCE = PASS
TXT AUTHOR INFERENCE = PASS
METADATA PERSISTENCE = PASS
EXISTING LIBRARY MIGRATION = PASS
LOCATOR/PROGRESS REGRESSION = PASS
```

## 模型与身份边界

- `content_collections.id` 继续使用稳定的 `local-txt:<contentHash>`，不受显示名称变化影响。
- `content_sources` 保留文件身份：`displayName`（原始文件名）、root-relative `managedSourcePath`、内容 hash、大小和编码。
- `content_collections` 新增 `author`、`description`、`metadataSource`、`titleSource`、`authorSource`。
- 领域 `LibraryCollection` 同时暴露 metadata 与 `fileName`/`sourcePath`，但 Reader progress、absolute UTF-16 Locator、bookmarks、history、ReaderPreferences 仍以原 collection ID 关联。
- metadata 来源预留为本地推断/用户编辑/在线等可扩展状态，本轮只写 `localInference` 或兼容旧数据的 `legacy`。

## 保守 TXT 推断

- 明确 `《书名》` 或 `书名：...` 行才作为正文标题。
- 明确 `作者：...` / `作者: ...` 才填 author；否则保持 `null` / `unknown`，不猜第二行或任意短行。
- 无明确标题时，从文件名去除 `.txt`；仅去除明确的末尾章节范围 `(1-500章)` 这类后缀，不删除普通数字或可能属于书名的内容。
- 推断只读取导入管理副本的 UTF-8 normalized prefix，不修改原始 TXT 或 normalized content。

四本真实 corpus（`C:\Users\TOM\Desktop\测试`）验证结果：

| FILE | TITLE | AUTHOR | TITLE SOURCE | AUTHOR SOURCE |
|---|---|---|---|---|
| 苟在初圣魔门当人材(1-500章).txt | 苟在初圣魔门当人材 | 鹤守月满池 | explicitText | explicitText |
| 青山(501-809章).txt | 青山 | 会说话的肘子 | explicitText | explicitText |
| 因果快递-20260625.txt | 因果快递-20260625 | unknown | fileName | unknown |
| 无章节数字测试.txt | 苟在武道世界成圣 | 在水中的纸老虎 | explicitText | explicitText |

## Schema / migration

schema `18 → 19` 正规 migration：只向 `content_collections` 增加 metadata 列，并为旧库保留 `legacy` / `unknown` 默认值。迁移测试验证旧 collection 与 progress offset `194` 保持不变；对极简旧库在表不存在时跳过 collection-only migration，保留原 progress migration 合同。

## 验证

- `flutter analyze`：PASS
- 全量 Flutter tests：PASS（593 tests）
- local library + metadata + 4 TXT tests：PASS
- migration / progress / font / preferences regression tests：PASS
- Windows Release：PASS
- Android Debug smoke build：PASS
- `git diff --check`：PASS

产物：

- Windows：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

HEAD 未提交变更：`af454b5b81d546cd33d720b7e3ec90395e8755b8`；保留原有 worktree dirty/untracked 文件，未修改旧项目目录。
