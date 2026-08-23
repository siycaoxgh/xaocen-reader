# M5.9c-6 — RSS Product Loop / UI

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 结果

| Gate | 结果 |
|---|---|
| RSS / Atom 订阅入口 | PASS |
| Feed 列表 / 文章列表 | PASS |
| 手动刷新与状态提示 | PASS |
| 文章复用现有 Reader | PASS |
| Windows / Android 响应式代码路径 | PASS（共享 Flutter Shell，窄屏 Widget Gate 通过） |
| 真实 RSS / Atom transport + parser | PASS |
| Windows/Android 实机/桌面视觉验收 | MANUAL REQUIRED |

代码与自动 Gate 已完成；本轮未覆盖真实 Windows/Android 设备上的鼠标触控、系统返回和窗口尺寸人工操作，因此这些项目不能伪造为自动 PASS。

## 产品链路

```text
首页 → RSS / Atom 订阅
             ├─ 添加 HTTP/HTTPS 地址（RSS 2.0 / Atom）
             ├─ 订阅列表（添加、删除、刷新单个/全部）
             └─ 订阅文章 → 文章列表 → 现有 ReaderPage
```

- 订阅保存于当前 `DataRoot` 的 `settings/rss_subscriptions.json`，并带 `profileId`、`rootId` 保护；没有新增 Drift schema。
- 添加订阅后立即尝试第一次刷新；刷新失败时仍保留订阅并显示失败状态。
- 手动刷新通过现有 `FeedSubscriptionService → RemoteHttpTransport → StandardFeedParser` 完成；没有后台 Timer、通知、账号或同步行为。
- 文章使用稳定 `sourceId + item identity` 合并；已保存文章不因 feed 窗口变化而无条件丢失。
- 点击文章创建临时阅读会话，注入现有 `ReaderPage`。临时内存数据库只提供 Reader 需要的 FK/进度上下文，关闭页面即释放；不会写入生产书库，也不建立第二套 Locator/Progress truth。

## UI 与响应式

- 首页增加轻量 `RSS / Atom 订阅` 入口，不改变首页/书架/我的一级导航。
- 订阅页和文章页使用普通 `Scaffold`、`ListView`、`RefreshIndicator`，宽度达到 720 logical px 时增加内容边距，窄屏保持列表可操作。
- 订阅卡片提供刷新、删除和整卡打开；文章条目显示标题、作者/日期/摘要，并整行打开 Reader。
- 空列表、加载、错误、刷新完成/失败均有明确中文状态提示。

## 真实 RSS / Atom 验收

使用真实公开端点完成一次只读 transport/parser 验收（不依赖测试 fixture）：

- 两个公开 Feed 测试地址仅保存在本地验收环境变量中：HTTP 200，分别识别为 `rss` 与 `feed` 根节点，并解析出文章。
- 两个结果均成功生成 `ReaderContent` navigation 与正文映射；一次性验收 harness 未纳入正式测试套件，避免网络波动影响 CI。

## 修改文件

- `lib/app/providers.dart`
- `lib/app/router.dart`
- `lib/app/app_shell_page.dart`
- `lib/app/feed_subscriptions_page.dart`
- `lib/app/feed_article_reader_page.dart`
- `test/widget/feed_subscriptions_page_test.dart`

## Gate

- `flutter analyze --no-pub`：PASS（No issues found）
- `flutter test test/widget/feed_subscriptions_page_test.dart`：PASS（4）
- 全量 `flutter test`：PASS（711）
- `git diff --check`：PASS（仅工作树既有 LF/CRLF 提示，无 whitespace error）

## 冻结判断

RSS 产品闭环的代码边界可以冻结：不需要改 Reader、Locator、Progress、数据库 schema 或远程来源架构。完成 Windows Release 与 Android Debug/Release 的实际人工操作验收（添加、刷新、删除、文章打开、系统返回、窄窗口/手机宽度）后，可将本阶段标记为完全冻结；在此之前状态为 **AUTOMATED PASS / MANUAL REQUIRED**。
