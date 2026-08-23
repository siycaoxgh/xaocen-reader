# M5.7s.9a-3 — Local Book Metadata Edit

## 实现

- 书籍卡片新增“书籍操作 → 编辑书籍信息”入口。
- Windows / Android 共用 `MetadataEditPage`：可编辑书名、作者、简介；原文件名和来源只读展示。
- 保存使用 `LocalLibraryRepository.updateManualMetadata`，仅更新 metadata 字段和 source 标记，不触碰 TXT、`collectionId`、`sourcePath`、normalized 内容、Locator、进度、书签、历史或 ReaderPreferences。
- 来源优先级正式写入：`manual` > 自动识别（`localInference` / `autoDetected`）> `fileName` fallback。手动修改后重复导入/扫描不会覆盖现值。
- “恢复自动识别”读取已管理的 `normalized.txt` 与当前安全文件名重新运行保守推断，仅清除 manual override；不会重新导入书籍。
- 书名不能为空；作者和简介允许为空；取消不写入。

## 验证

| Gate | Result |
|---|---|
| MANUAL METADATA EDIT | PASS |
| MANUAL OVERRIDE PRIORITY | PASS |
| RESTORE AUTO METADATA | PASS |
| PERSISTENCE | PASS |
| COLLECTION/PROGRESS REGRESSION | PASS |

- `flutter analyze` — PASS
- 全量 Flutter tests — PASS（596 tests）
- metadata/re-scan/progress 单元测试 — PASS
- metadata editor/card widget tests — PASS
- Windows Release — PASS
- Android Debug — PASS
- `git diff --check` — PASS

Schema 保持 19，本轮不需要 migration。

构建产物：

- Windows: `build/windows/x64/runner/Release/xaocen_reader.exe`
- Android: `build/app/outputs/flutter-apk/app-debug.apk`

未执行在线 metadata、在线封面或在线书源。
