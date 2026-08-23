# M5.9d-9 — WebBook Update / New Chapter Check

## 范围与结论

本阶段为已加入书架的 WebBook 增加手动“检查新章节”能力，并将首页 RSS 入口的用户文案统一为“内容订阅”。没有新增数据库表，也没有修改 Reader、Locator、Progress 或既有书源规则。

结论：`M5.9d-9 = PASS / 可冻结`

## 更新链路

```text
原书源 Registry
  → 重新获取详情/目录
  → planWebBookUpdate（校验稳定 key 与原始顺序）
  → 只获取新增章节正文
  → 追加 normalized.txt 尾部
  → 增量写入 ContentItem / ContentDocument / TocEntry
  → 更新 collection/source manifest
```

更新策略是 append-only：

- 通过已保存的 `sourceId / bookKey / detailUri` 恢复原书源。
- 现有章节必须以完全相同的顺序保留；重排、删除或在中间插入会返回 `failed`，不会改写本地快照。
- 只对目录尾部的新稳定章节 key 发起正文请求，已有章节不会重复抓取或重复入库。
- 原有 normalized 文本和 UTF-16 偏移保持不变，新章节从文件尾部追加。
- 不触碰 `reading_progress`、书签、历史和 ReaderPreferences，因此已有 Locator / Progress 保持不变。

状态模型：

- `updated`：发现并成功追加一个或多个新章节。
- `noChanges`：原书源目录与本地快照一致，提示“当前已是最新章节”。
- `failed`：书源缺失/禁用、目录顺序不安全、网络/解析/写入失败等，给出可理解的错误提示。

## UI 验收

书架中 WebBook 卡片的菜单新增“检查新章节”。检查时先显示“正在检查新章节…”，完成后显示结果；本次真实源目录无新增，最终提示为“当前已是最新章节”。

首页原“订阅”卡片已改为：

- 标题：`内容订阅`
- 说明：`管理内容订阅并手动刷新文章`

Android 实机（`emulator-5554`，AVD `xaocen_api35_x86_64`）证据：

- [首页与内容订阅入口](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_update/01_launch.png)
- [书架 WebBook 卡片](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_update/02_bookshelf.png)
- [检查新章节菜单](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_update/03_update_menu.png)
- [检查中状态](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_update/05_update_feedback.png)

真实交互确认：

1. 首页可见“内容订阅”。
2. 书架《青山》菜单可见“检查新章节”。
3. 点击后进入检查状态。
4. 使用本地环境变量配置的实时目录复查后正确显示“当前已是最新章节”。

## Sudugu / Shudugu 真实验收

使用现有通用规则和跨域重定向安全策略，没有加入域名特判。实时 POC 命令：

```text
flutter test --dart-define=XAOCEN_SUDUGU_POC=1 --dart-define=XAOCEN_LIVE_SOURCE_URL=$env:XAOCEN_LIVE_SOURCE_URL test/manual/sudugu_web_book_poc_test.dart
```

结果：PASS。详情、目录、首章/最新章正文和 `ReaderContent` 链路均成功；实测目录为 825 章，本次复查无新增。增量追加与顺序保护由离线定向测试覆盖。

## 修改文件

- `lib/domain/library/library_import_models.dart`：新增更新状态、计划、结果和快照元数据模型。
- `lib/data/repositories/local_library_repository.dart`：新增 WebBook 目录计划、append-only 增量写入、manifest 快照读取/更新。
- `lib/app/library_page.dart`：WebBook 卡片菜单接入“检查新章节”，显示检查/成功/失败状态。
- `lib/app/app_shell_page.dart`：首页“订阅”改为“内容订阅”。
- `test/unit/web_book_update_test.dart`：新增新增章节、顺序变化、Locator/Progress 保持测试。
- `test/widget/app_shell_page_test.dart`：新增“内容订阅”文案断言。
- `docs/M5_9D_9_WEBBOOK_UPDATE.md`：本阶段报告。

没有 Drift schema migration，没有新建第二套内容或进度真相。

## Gate

| Gate | 结果 |
|---|---|
| `flutter analyze --no-pub` | PASS — No issues found |
| WebBook 更新及相关定向 tests | PASS — 27 tests |
| 全量 `flutter test` | PASS — 741 passed, 2 skipped |
| `git diff --check` | PASS |
| Sudugu/Shudugu 实时 POC | PASS |
| Android 实机更新入口 | PASS |
| Windows Release build | PASS |
| Windows Release launch smoke | PASS |

全量测试中的 2 个 skipped 是原有手动网络 POC 未设置 live 开关，并非本阶段失败；本阶段已单独运行并通过 Sudugu/Shudugu live POC。

## 冻结边界

本阶段只支持用户手动检查，不包含后台自动更新、通知、账号同步或通用书源导入。未来如需处理“目录中间插入/删除后的安全合并”，应另立阶段，不应在本 append-only 合同上隐式改写已有 Locator。
