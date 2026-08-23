# M5.9d-5 — Generic WebBook Rule Engine

## 目标与边界

本阶段把 Sudugu POC 中暴露的页面差异抽成通用、可配置的静态 HTML 规则引擎。规则只描述 CSS selector、字段、属性和 URL 关系；不执行 JavaScript，不使用 WebView，不处理登录、反爬、复杂 Cookie 或 Legado 全兼容。

## 规则结构

`WebBookCssRuleSet` 支持：

- 独立搜索结果 selector、标题/作者字段和链接 selector
- 独立详情根 selector、标题、作者、简介字段
- 目录条目 selector、章节标题字段、章节 key 属性
- 章节正文 selector
- `data-*` 或普通属性生成 book/chapter identity；属性缺失时使用 canonical URL（章节同时纳入标题）生成稳定 hash
- selector 字段的文本、HTML 属性和可选前缀清理
- `WebBookSource.searchEndpoint` 独立搜索 endpoint；未配置时回退到 `endpoint`

HTML 使用 `package:html` 解析，CSS selector 由 DOM 查询执行；章节顺序直接采用 selector 返回的文档顺序，不按显示章号排序。

## 运行时链路

```text
searchEndpoint / endpoint
  → RemoteHttpTransport
  → WebBookRuleEngine CSS extraction
  → WebBookSearchResult / WebBookDetail / WebBookTocEntry
  → chapter body selector
  → FeedHtmlNormalizer
  → CanonicalContent
  → existing ReaderContent projection
```

原有正则规则路径仍保留，保证 M5.9d-3 fixture 向后兼容；配置了 `cssRuleSet` 时才使用新引擎。

## Sudugu 验收

Sudugu 只作为规则 fixture，使用 `sudugu-static-html-v1` 配置：

- `.container`：书籍详情
- `h1 a`：书名
- `a[href*="/zuozhe/"]`：作者
- `.des`：简介
- `#list.dir a[href$=".html"]`：目录
- `.con`：章节正文

真实站点验收命令：

```text
flutter test --no-pub --dart-define=XAOCEN_SUDUGU_POC=1 test/manual/sudugu_web_book_poc_test.dart
```

首章、中间章节、最新章节均通过，目录原始顺序和缺失/重复显示章号均保持不变。

## 测试覆盖

- `test/unit/web_book_rule_engine_test.dart`：独立搜索 endpoint、query 参数、CSS selector、属性 identity、详情、目录、章节和 ReaderContent projection
- `test/unit/web_book_runtime_test.dart`：原有正则 fixture 回归
- `test/manual/sudugu_web_book_poc_test.dart`：真实 Sudugu CSS 规则驱动验收

## 保护边界

没有修改 Reader、Locator、Progress 或数据库 schema。`WebBookRuleEngine` 只输出既有 WebBook domain 类型与 `CanonicalContent`，不创建第二套内容或位置 truth。

## Gate

- `flutter analyze --no-pub`：PASS
- 定向 WebBook tests：4 PASS（CSS rule engine 1 + legacy runtime 3）
- 真实 Sudugu POC：已 PASS
- 全量 Flutter tests：731 PASS，2 项按现有测试标记跳过
- `git diff --check`：PASS

## 结论

通用 CSS 规则能力已覆盖 Sudugu POC 暴露的规则缺口；未发现需要大规模重构的 Architecture Blocker。本阶段可冻结。
