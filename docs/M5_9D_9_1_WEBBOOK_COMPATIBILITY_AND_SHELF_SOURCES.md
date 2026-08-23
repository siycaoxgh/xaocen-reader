# M5.9d-9.1 WebBook compatibility and bookshelf source distinction

日期：2026-08-18

## 范围

本阶段只补齐 WebBook 运行时兼容边界、加入书架的有限缓存语义、书架来源展示及 Android UIAutomator 测试产物路径。Reader、Locator、Progress 和数据库 schema 未重构。

## 实际修改

- `WebBookSource.searchQueryParameter`：默认 `q`，书源可以声明 `key` 等真实参数。XAOCEN JSON 通过可选 `searchRequest.queryParameter` 保存该能力；旧 JSON 缺失时仍按 `q` 兼容。
- `WebBookExtractionRules` / `WebBookCssRuleSet`：增加可选 `nextPageSelector`、`maxChapterPages`（默认 8）。分页请求保持原顺序，并做已访问 URL 去重、同源校验、上限保护；带“下一章”语义的链接不会当作同章下一页。
- WebBook 加入书架改为保存完整目录元数据，只缓存首批最多 3 个章节；单章失败会跳过并保留书架记录（全部初始章节都失败时仍拒绝创建不可读记录）。manifest 记录 source、目录、缓存章节和缓存模式，为后续按需加载提供边界。
- 书架卡片按 `sourceId` 显示 `本地书籍` / `在线书源`。在线卡片读取 manifest 显示书源名称、网站主机和 `章节缓存` / `完整本地快照` / `在线内容` 状态；不依据书名猜来源。
- 删除本地书籍继续只删除应用管理副本；删除在线书源书籍显示“将移除书架记录和本地缓存，不影响在线书源及网站原文。”，独立书源 Registry 不受影响。
- Android UIAutomator dump 改用 `test_output/android-emulator` 本地目录和 `/data/local/tmp` 临时远端文件，finally 清理远端文件，不再写 `/storage/emulated/0/` 根目录。

## 验证结论

- 搜索参数：Sudugu 使用 `key`，青山和其他关键词均映射到同一个配置参数；空关键词在请求前返回可理解错误。
- 三页章节 fixture：`20.html → 20-2.html → 20-3.html` 正文按顺序合并；重复 URL、跨源链接、最大页数和下一章误判均受保护。
- 部分缓存导入：目录 3 章、初始正文 2 章时，书架记录保留 3 章目录，第三章 `itemId=null` 表示尚未缓存；manifest 为 `chapterCache`。
- 在线 Registry 与书架记录解耦：移除书架记录后 Registry 仍保留；本地删除路径不触碰外部原始文件（既有回归测试覆盖）。
- Android 测试脚本的 UI dump 远端临时文件始终在清理分支执行。

## 未支持/边界

- 本阶段没有引入 JS/WebView、登录、反爬或网页全文抓取。
- Reader 核心仍是现有规范化文档加载器；未在冻结 Reader 内插入网络请求。目录和缓存 manifest 已准备好供后续独立的按需章节缓存适配器使用，避免伪造“已经实现后台抓取”。

## 状态

定向 WebBook、书架来源语义和分页测试通过。全量 Gate 以本轮最终命令结果为准；若全量测试无回归，可将本补充阶段冻结，后续按需章节加载应作为独立任务，不修改 Locator/Progress truth。
