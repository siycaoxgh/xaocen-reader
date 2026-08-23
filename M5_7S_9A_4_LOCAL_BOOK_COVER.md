# M5.7s.9a-4 — Local Book Cover Management

## Scope

本轮为本地书籍增加了手动封面管理，不联网、不修改 TXT 原文件，也没有改动 Reader 定位、进度或分页事实源。

## Implementation

- `content_collections.cover_path` 保存相对于应用 DataRoot 的托管路径。
- `content_collections.cover_source` 保存 `manual` 或 `placeholder`，为未来 `online` 来源保留模型位置。
- schema 19 → 20 正规 Drift migration：旧书封面路径为空、来源为 `placeholder`，collection/progress/bookmark/history 不迁移。
- 选择封面时只接受 `.jpg`、`.jpeg`、`.png`、`.webp`，复制到 `DataRoot/books/covers/<safeCollectionId>/cover.<ext>`，不保存 picker 临时路径。
- 更换封面会清理该书旧的托管封面；移除封面只删除托管文件并回退 placeholder，不触碰用户原文件。
- 书架卡片和 metadata 编辑页都读取同一个托管封面 repository；文件缺失或图片解码失败时回退确定性的 `BookCoverPlaceholder`。
- 图片使用 2:3 容器与 `BoxFit.cover`，不会拉伸变形。

## Verification

| Check | Result |
|---|---|
| BOOK METADATA MODEL | PASS — cover fields are separate from file identity and display metadata |
| LOCAL COVER | PASS — JPG/JPEG/PNG/WebP validation, managed copy, card/editor integration |
| COVER PERSISTENCE | PASS — schema migration, database path/source persistence and restart-safe relative path |
| COVER FALLBACK | PASS — missing/corrupt/unresolvable managed file returns deterministic placeholder |
| BOOK IDENTITY REGRESSION | PASS — collection id, TXT/source path, progress and locator data are not changed |
| Flutter analyze | PASS |
| Flutter tests | PASS — 597 tests |
| Windows Release | PASS — `build/windows/x64/runner/Release/xaocen_reader.exe` |
| Android Debug | PASS — `build/app/outputs/flutter-apk/app-debug.apk` |
| git diff --check | PASS (exit code 0) |

Manual picker/visual checks were not simulated by automation; they remain suitable for the next Windows/Android hands-on acceptance. The implementation has no online-cover behavior and therefore falls back to placeholder when no manual cover exists.
