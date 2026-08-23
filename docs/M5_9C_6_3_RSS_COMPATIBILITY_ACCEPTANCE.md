# M5.9c-6.3 — RSS Compatibility Acceptance + Freeze

项目根目录：`C:\\Users\\TOM\\Desktop\\xaocen-reader-v4\\xaocen_reader`

日期：2026-08-17

本阶段只做 RSS/Atom 兼容性验收和冻结，不新增 WebArticleSource，不修改 Reader、Locator、Pagination、Progress 或数据库结构。

## 1. 实际来源验收

使用统一 `RemoteHttpTransport → StandardFeedParser → ReaderContent` 链路做真实 HTTP/HTTPS 快照检查。

| 来源 | 实测结果 | 结论 |
|---|---|---|
| 阮一峰 Atom | HTTP 200；Atom；3 条；首条正文 8868 字符；31 个图片引用 | **PASS**：完整 HTML、CDATA、图片缓存和 Reader 图片渲染正常 |
| Solidot | HTTP 200；RSS；19 条；首条正文 175 字符 | **PASS**：RSS 顺序、正文和 ReaderContent 投影正常 |
| GitHub Changelog | HTTP 200；RSS；10 条；首条正文 3775 字符；图片引用可提取 | **PASS**：RSS HTML/链接/图片 sidecar 正常 |
| 少数派 | HTTP 200；RSS；10 条；首条正文 66 字符；内容为摘要和“查看全文”链接 | **SOURCE LIMITATION**：源未提供全文，不抓取网页 |
| China Daily | HTTP 200；RSS；历史条目可能只有标题/极短正文；当前 feed 可返回完整条目 | **SOURCE LIMITATION**：历史数据缺正文，不篡改源数据 |
| 小众软件 | 配置的公开 feed 返回 HTTP 200；此前用户环境曾出现连接超时 | **NETWORK/SOURCE AVAILABILITY**：不因单源可用性修改 Parser |

小众软件的“超时”属于来源、网络路径或临时可用性问题；当前探测成功不代表所有网络环境都稳定，因此仍按来源可用性记录，不判定为 Parser 缺陷。

## 2. 兼容性确认

- HTML 标签、实体、段落和基础链接经过 `FeedHtmlNormalizer` 后进入 Reader，不显示原始 `<p>`、`<img>` 等标签。
- Atom 多段 CDATA 按节点值拼接，避免 `]]>` XML 边界泄漏到正文。
- 远程图片 URL 作为 sidecar metadata 保存，不写入 canonical text；缓存失败不会阻塞文章打开。
- 删除订阅入口和二次确认保持可用。
- 手动刷新成功/失败会显示可理解状态；失败按 HTTP status、timeout、network、parse 等类型分类。
- RSS 摘要与网页全文严格分离；少数派“查看全文”不会被 RSS Parser 冒充为正文。
- 文章仍通过现有 `ReaderContent` 和 Reader 打开，未建立第二套 Locator/Progress。

## 3. Gate

| Gate | 结果 |
|---|---|
| `flutter analyze --no-pub` | PASS |
| RSS/Atom 定向测试 | PASS |
| 全量 Flutter tests | PASS — 717 tests |
| `git diff --check` | PASS；仅有既有 LF/CRLF 提示 |
| Android Release build | PASS |
| Windows Patched Release build | PASS |

真实 HTTP 快照日志保存在：
`artifacts\\rss_audit\\real_acceptance.log`

## 4. 冻结结论

`M5.9c-6.3 = PASS / FROZEN`

`M5.9c-6 = PASS / FROZEN`

冻结范围包括：订阅入口、RSS/Atom 自动识别、订阅持久化、文章去重、手动刷新、错误提示、HTML/CDATA 清理、远程图片 sidecar 缓存和现有 Reader 接入。

不属于本阶段完成内容、继续保持待规划：

- WebArticleSource / 网页全文抓取
- WebBookSource / 在线书源
- 后台刷新、通知、OPML、账号和云同步
- 已读/未读模型

这些能力不标记为失败，也不改变当前 RSS 冻结边界。
