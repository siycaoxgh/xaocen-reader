# M5.9d-8.1 — WebBook UI Acceptance

## 范围

本轮只做 WebBook 产品闭环验收，不扩展功能。Android 使用 `emulator-5554`（AVD `xaocen_api35_x86_64`，1080×2400，density 420）通过 ADB 实际操作；Windows 使用当前 Release 构建做启动冒烟。

验收用的 XAOCEN WebBook JSON fixture：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\test\fixtures\web_sources\sudugu_source.json`

fixture 使用 `fixture.invalid`，真实验收地址只通过本地环境变量注入，不在生产代码中加入站点特判。

## Android 实际验收

| 场景 | 结果 | 证据 |
|---|---|---|
| 首页“在线书源”入口 | PASS | [01_home.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/01_home.png) |
| 空书源状态 | PASS | [02_webbook_entry.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/02_webbook_entry.png) |
| 导入 JSON / 注册书源 | PASS | [17_source_search_ready.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/17_source_search_ready.png) |
| 启用 / 禁用书源 | PASS | [30_source_disabled.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/30_source_disabled.png) |
| 删除书源与确认对话框 | PASS | [48_source_menu.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/48_source_menu.png)、[49_delete_confirm.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/49_delete_confirm.png)、[50_source_deleted_empty.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/50_source_deleted_empty.png) |
| 重新导入并恢复使用 | PASS | [52_source_reimported.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/52_source_reimported.png) |
| Sudugu/Shudugu 搜索 | PASS：返回 6 条结果 | [18_search_results_success.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/18_search_results_success.png) |
| 搜索结果 → 详情 / 目录 | PASS：结果页滚动后显示详情、简介、目录预览 | [34_results_scrolled.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/34_results_scrolled.png) |
| 加入书架 | PASS：显示获取章节进度，完成后进入书架 | [35_add_to_shelf_progress.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/35_add_to_shelf_progress.png)、[38_add_to_shelf_progress_120s.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/38_add_to_shelf_progress_120s.png) |
| 书架显示 WebBook | PASS | [40_shelf_after_add.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/40_shelf_after_add.png) |
| 书架 → 章节 → Reader | PASS | [41_reader_from_webbook.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/41_reader_from_webbook.png) |
| 返回后再次进入 | PASS | [43_reader_reopen.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/43_reader_reopen.png) |
| 加载 / 章节抓取进度 | PASS | [36_add_to_shelf_progress_20s.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/36_add_to_shelf_progress_20s.png)、[37_add_to_shelf_progress_65s.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/37_add_to_shelf_progress_65s.png) |
| 错误状态 | PASS：无可用搜索结果时给出可理解提示 | [15_search_results.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/15_search_results.png) |
| 窄屏 / 溢出 | PASS：模拟器操作和 WebBook widget 定向测试未见横向或 RenderFlex overflow | [18_search_results_success.png](C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/test_output/webbook_acceptance/18_search_results_success.png) |

详情内容采用同页滚动结构：点击搜索结果后，向下滚动可看到详情、目录预览和“加入书架”。这不是数据丢失；在窄屏上没有溢出。后续若需要更强可发现性，可另立 UI 任务，本轮不扩展行为。

删除书源不会删除已加入书架的书，确认文案已在实际对话框中验证。

## 安全边界

真实来源发生跨域重定向时，现有跨域重定向安全策略要求更新来源 endpoint 后才允许访问；fixture 不包含真实 host。未加入任何站点特判，策略仍由通用 transport / source contract 执行。

验收 fixture 的搜索 endpoint 固定为青山样本查询，因此输入一个不存在的关键词仍会返回样本结果；这是 fixture 数据限制，不是生产搜索器或 Parser 的缺陷，不能据此判定产品失败。

## Windows Smoke / UI

- Release 构建成功：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- 启动后窗口标题为 `XAOCEN Reader`，进程响应正常，随后已正常关闭。
- Windows 详细鼠标点击链路本轮未逐项人工操作，标记为 `MANUAL REQUIRED`；构建与启动冒烟为 PASS。

## Gate

| Gate | 结果 |
|---|---|
| `flutter analyze --no-pub` | PASS — No issues found |
| WebBook 定向 tests | PASS — All tests passed |
| 全量 `flutter test` | PASS — 739 passed, 2 skipped |
| `git diff --check` | PASS |
| Android APK build/install | PASS |
| Windows Release build/launch smoke | PASS |

## 结论

`M5.9d-8.1 = PASS / FROZEN`

本轮没有修改 Reader、Locator、Progress，也没有加入 Sudugu/Shudugu 特判。当前剩余的 Windows 逐项视觉操作和真实网络环境差异属于 `MANUAL REQUIRED`，不阻塞本阶段冻结。
