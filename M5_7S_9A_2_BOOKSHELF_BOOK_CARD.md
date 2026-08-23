# M5.7s.9a-2 — Bookshelf Book Card Foundation

## Scope

仅改造书架 / 本地书库卡片 UI；未改 Reader、TXT parser、metadata inference、Windows/Android Reader 能力或首页结构。

## 实现

- 书籍卡片改为封面占位 + metadata 标题 + 作者 + 阅读进度信息。
- `BookCoverPlaceholder` 不加载或生成图片，使用标题的稳定 FNV-1a 哈希派生配色与首字，重建/重启后保持一致，比例约 2:3。
- 标题和作者直接使用 `LibraryCollection.title` / `author`；缺失作者显示“作者未知”，不会显示 null、Unknown 或路径。
- 进度通过 `collectionProgressProvider` 读取现有 `ReadingProgressRepository` / `ReaderProgressState`，没有新增进度真源。百分比基于已持久化 absolute UTF-16 offset 与 normalized length 展示。
- 保留整张卡片打开 Reader、删除按钮和现有 repair/ReaderLaunch 链路。
- 窄布局使用横向卡片列表；嵌入的宽 Windows 布局保留网格并增高卡片以容纳 2:3 封面。

## 验证结果

| Gate | Result |
|---|---|
| BOOK CARD | PASS |
| COVER PLACEHOLDER | PASS |
| METADATA DISPLAY | PASS |
| RESPONSIVE | PASS |
| PROGRESS REGRESSION | PASS |

验证命令：

- `flutter analyze` — PASS
- `flutter test` — PASS（594 tests）
- `flutter test test/widget/library_page_test.dart` — PASS
- `flutter test test/unit/local_library_test.dart`（包含 4 个真实 TXT metadata 回归）— PASS
- `flutter build windows --release` — PASS
- `flutter build apk --debug` — PASS
- `git diff --check` — PASS

构建产物：

- Windows: `build/windows/x64/runner/Release/xaocen_reader.exe`
- Android: `build/app/outputs/flutter-apk/app-debug.apk`

## 备注

本轮没有进行真人 Windows/Android 视觉操作；真实设备/桌面视觉仍需按验收清单人工确认。
