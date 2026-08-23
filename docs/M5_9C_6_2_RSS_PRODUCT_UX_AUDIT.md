# M5.9c-6.2 — RSS Product UX Audit + Rework

项目根目录：`C:\\Users\\TOM\\Desktop\\xaocen-reader-v4\\xaocen_reader`

日期：2026-08-17

本阶段只整理 RSS / Atom 的产品闭环，不改变 Reader、Locator、Progress、Windows 真透明或数据库 schema。

## 1. Android 实机审计

设备：`emulator-5554`（`com.xaocen.xaocen_reader`，Android Release APK）。

修改前截图保存在：
`artifacts/rss_audit/before/`

覆盖了启动、首页、订阅列表、添加订阅、刷新结果/失败、删除确认和返回流程：

- `03_home.png`
- `04_rss_list.png`
- `05_add_dialog.png`
- `11_refresh_failure.png`
- `13_delete_confirm.png`

审计确认的问题：

1. 首页和页面标题暴露了“RSS / Atom”等实现术语，普通用户不需要先理解格式差异。
2. 添加订阅对话框暴露格式下拉框和可选 source ID，增加了不必要的决策。
3. 订阅卡片缺少最近更新时间，刷新后用户难以确认数据是否更新。
4. 文章列表原来只显示基础标题/摘要，缺少来源数量、作者/日期等层次；有文章时刷新失败状态也不会稳定显示在列表中。
5. 空状态文案偏技术化；删除确认本身清晰，保留原有二次确认。
6. 当前模型没有 `isRead` 字段或已读状态真值；本阶段不新增第二套阅读状态，已读/未读列为后续能力。

## 2. 参考项目结论

只参考产品结构，没有复制代码：

- [ReadYou](https://github.com/ReadYouApp/ReadYou)：订阅入口以用户任务为中心，隐藏 RSS/Atom 实现细节，并把订阅、全文阅读和账户范围分层。
- [Feeder](https://github.com/spacecowboy/Feeder)：以 Feed → 文章 → 阅读为主层级，强调本地保存/离线阅读、清晰刷新和来源管理。
- [Fluent Reader](https://github.com/yang991178/fluent-reader)：订阅管理、计数、去重和刷新状态是独立产品信息，不应混入 Reader 内容层。

因此本次采用“订阅 → 文章 → Reader”的最小产品路径：格式自动识别，用户只需粘贴地址；技术错误以可理解状态提示呈现；阅读仍复用现有 ReaderContent 和 Reader 页面。

## 3. 本次修改

### 页面与文案

- 首页入口由“RSS / Atom 订阅”改为“订阅”。
- 订阅页标题改为“我的订阅”，说明改为普通用户可理解的“手动管理订阅内容”。
- 空状态改为“粘贴订阅地址即可”。
- 添加对话框只保留“订阅地址”，明确提示系统会自动识别订阅格式。
- 内部仍根据 endpoint 生成稳定 source identity，并让 parser 从文档根节点识别 RSS 2.0/Atom；没有创建新的数据 schema。

### 订阅列表

- 卡片显示文章数、来源主机和最近更新时间。
- 全部刷新时禁用卡片级刷新，避免同一来源并发刷新。
- 保留明确的删除按钮和原有确认对话框。

### 文章列表与状态

- 增加 Feed 描述、文章总数/来源、作者、发布时间和摘要层次。
- 文章使用统一的可点击列表项进入现有 Reader。
- 刷新成功/失败使用主题化状态横幅；即使已有文章，失败原因也会留在当前列表中可见。
- 空 Feed 仍只提示“暂无已保存文章”，不抓取仅有链接的网页全文。

### 保护边界

- 未修改 TXT/EPUB 内容模型、ReaderContent、Locator、Pagination、ReaderProgress。
- 未修改数据库 schema、后台刷新、通知、WebArticleSource、WebBookSource、账号或同步。
- 未新增已读/未读 truth；该能力保持待规划。

## 4. 修改后截图

修改后截图保存在：
`artifacts/rss_audit/after/`

- `00_launch.png`：首页，入口显示为“订阅”。
- `01_subscriptions.png`：我的订阅列表，卡片显示文章数/来源/更新时间。
- `02_add_dialog_clean.png`：简化后的添加订阅对话框，无格式下拉和 source ID。
- `05_articles.png`：文章列表，显示来源计数、日期、摘要和统一箭头入口。
- `06_reader.png`：文章进入现有 Reader，正文不显示原始 HTML 标签。
- `07_refresh_success.png`：文章列表中可见“刷新完成”状态横幅。

修改前后截图均来自同一个 `emulator-5554`，未清除应用数据，未删除现有订阅。

## 5. Gate 结果

| Gate | 结果 |
|---|---|
| `flutter analyze --no-pub` | PASS — No issues found |
| RSS/Atom 定向测试 | PASS — 18 tests passed |
| 全量 Flutter tests | PASS — 717 tests passed |
| `git diff --check` | PASS — 仅有现有 LF/CRLF 提示，无 whitespace error |
| Android Release build | PASS — `build/app/outputs/flutter-apk/app-release.apk` |
| Android Release install/smoke | PASS — 已安装至 `emulator-5554` |
| Windows Patched Release build | PASS |
| Windows Patched Release launch smoke | PASS |

Windows 当前正式构建输出仍为：
`C:\\Users\\TOM\\Desktop\\xaocen-reader-v4\\xaocen_reader\\artifacts\\windows\\current\\Release\\`

## 6. 人工验收结论

当前 RSS 最小闭环达到“可人工验收”状态：

- 首页可进入订阅。
- 添加订阅只需要地址，RSS/Atom 自动识别。
- 订阅列表、文章列表、手动刷新、删除确认和 Reader 入口可用。
- HTML 正文由现有 normalize 链路处理，文章列表/Reader 不展示原始标签。
- 刷新失败原因由现有错误分类转换为可理解中文，并在当前页面显示。

仍待后续阶段：

- 已读/未读模型与批量操作（待规划，不判定为失败）。
- Feed 图标/封面、OPML、后台刷新、通知、全文网页抓取（未实现，超出本阶段范围）。
- 真实硬件/复杂网络环境的长期刷新稳定性（需要人工环境验收）。

结论：`M5.9c-6.2 = PASS / 可人工验收`；兼容性冻结由 `M5.9c-6.3` 完成。

## 7. 真实订阅内容诊断与补充

### China Daily：解析缺口已修复

实时 XML 的条目同时包含短 `<description>` 与完整普通 `<content>`。旧解析器只读取
`content:encoded`，因此 Reader 只得到一句摘要。现在 RSS 解析优先读取
`content:encoded`，其次读取普通 `<content>`，最后才回退到 `<description>`；新增单元测试覆盖该结构。

结论：`BUG`（XAOCEN 解析缺口），已修复。

### 少数派：源站只提供摘要

实时条目只有摘要正文和“查看全文”链接，没有完整文章 HTML。RSS 解析无法凭空补齐全文，
本轮不把它误判为 Reader 丢文；正文会保留可读链接信息。需要在应用内抓取并净化网页全文时，
应另立 `WebArticleSource`，不混入 RSS parser。

结论：`SOURCE LIMITATION / DEFERRED`，不是 RSS 解析失败。

### 阮一峰：正文完整，图片是远程资源

Atom `content` 含完整 HTML 和远程 `img` URL。旧 normalizer 为安全起见只输出 `[图片]`，没有发起
下载请求，因此这是当前 RSS 图片渲染能力缺失，不是“图片下载失败”。本轮新增：

- 解析并持久化 HTTP(S) 图片引用（不写入 canonical 文本）；
- 打开文章时按 8MB、12 秒、`image/*` 响应限制下载到 profile DataRoot 的
  `books/remote_feeds/images/`；
- 复用既有 `ReaderRenderingMetadata` / `ReaderEpubImage` 本地图片渲染通道；
- 下载失败继续显示正文和图片占位，不影响 Reader/Locator。

结论：图片路径已接入；刷新订阅后 Android 模拟器已实际显示远程图片，失败时属于单图资源不可用，
不应导致文章或应用崩溃。

### 真实模拟器证据（2026-08-17）

- `after/17_ruanyifeng_reader_final.png`：刷新阮一峰订阅后，封面图和正文在 Reader 中正常显示；
  原先的 `[图片]` 占位不再遮蔽真实图片。
- `after/14_china_daily_reader_post_patch.png`：China Daily 2017 历史条目只有标题/极短源内容，
  进入 Reader 只有标题，归类为 `TEST DATA ISSUE`，不是 Reader 丢正文。
- `after/16_ruanyifeng_reader_refreshed_cdata_clean.png`：用于定位旧 Atom 多段 CDATA 残留；最终版本
  通过按节点值拼接并清除所有 CDATA 边界，避免 `]]>` 泄漏到正文。

最终结论：阮一峰图片问题属于 XAOCEN 原有渲染能力缺口，已修复并通过模拟器验收；China Daily
历史内容仍按源数据限制记录，不自动抓取网页全文。
