# M5.9d-6 — XAOCEN WebBook Source Definition

## 目标与边界

本阶段定义 XAOCEN 自有的、版本化 WebBook Source JSON。它只是导入/校验/映射边界，不是 UI、Registry 或网络权限系统：不执行 JavaScript，不支持 XPath、WebView、Legado JSON 兼容、登录或复杂 Cookie，也不改变 Reader、Locator、Progress 或数据库 schema。

## JSON schema（v1）

顶层字段如下：

- `schema`：固定为 `xaocen.webBook`
- `version`：定义格式版本，当前为 `1`
- `sourceId`：稳定的来源标识（字母、数字、`.`、`_`、`-`）
- `name`：用户可读名称
- `endpoint`：书籍详情/目录入口，必须为 `http`/`https`
- `searchEndpoint`：可选的独立搜索入口；未使用时为 `null`
- `bookKey`：稳定书籍 identity，必须由定义提供
- `ruleVersion`：规则版本，正整数
- `rules`：搜索、详情、TOC、正文四组 CSS 规则

最小示例（Sudugu fixture 的同形定义）：

```json
{
  "schema": "xaocen.webBook",
  "version": 1,
  "sourceId": "sudugu-qingshan",
  "name": "速读谷 · 青山",
  "endpoint": "https://fixture.invalid/books/qingshan/",
  "searchEndpoint": null,
  "bookKey": "5",
  "ruleVersion": 1,
  "rules": {
    "search": {
      "itemSelector": "#search article.book",
      "title": {"selector": ".title"},
      "author": {"selector": ".author", "removePrefix": "作者："},
      "linkSelector": ".title",
      "keyAttribute": "data-book-key"
    },
    "detail": {
      "selector": ".container",
      "title": {"selector": "h1 a"},
      "author": {"selector": "a[href*=\"/zuozhe/\"]"},
      "description": {"selector": ".des"},
      "keyAttribute": "data-book-key"
    },
    "toc": {
      "entrySelector": "#list.dir a[href$=\".html\"]",
      "title": {},
      "keyAttribute": "data-chapter-key",
      "hrefAttribute": "href"
    },
    "chapter": {"bodySelector": ".con"}
  }
}
```

字段 selector 可以读取元素文本/HTML，也可以通过 `attribute` 读取属性；`removePrefix` 只做保守前缀清理。空对象 `{}` 表示读取当前元素文本。

## 映射规则

`XaocenWebBookSourceDefinition` 提供三个明确投影：

```text
XAOCEN JSON
  → validated XaocenWebBookSourceDefinition
  → WebBookSource (sourceId / endpoint / searchEndpoint / bookKey / ruleSetId)
  → WebBookCssRuleSet (search / detail / TOC / chapter selectors)
  → WebBookExtractionRules (ruleSetId + ruleVersion)
  → existing WebBookHttpRuntime
  → CanonicalContent → ReaderContent
```

`ruleSetId` 由 `sourceId-v<ruleVersion>` 稳定生成。搜索结果缺少配置 key 时，既有规则引擎仍按 canonical detail URI 生成稳定 hash；章节缺少 key 时按 canonical chapter URI + title 生成稳定 hash。TOC 只保留 CSS selector 返回的原始文档顺序，不按显示章号重新排序。

## 导入校验

`XaocenWebBookSourceDefinition.fromJson` / `fromJsonString` / `canDecode` 会拒绝：

- 未知 schema 或不支持的 schema version
- 非法/空 sourceId、name、bookKey 或非正 ruleVersion
- 非 `http`/`https` 的 endpoint，及跨来源的 searchEndpoint
- 缺失或空的四组核心 CSS selector
- XPath（`//`）、JavaScript selector、非法 CSS selector
- 非法 HTML 属性名和未知字段

认证、Cookie、Header、请求超时等仍由既有 `RemoteSource` / `RemoteRequestCapabilities` 管理，JSON 不承载秘密值，也不建立第二套网络权限 truth。

## Sudugu fixture 验证

`test/unit/xaocen_web_book_source_definition_test.dart` 使用 Sudugu 形状的离线 HTML fixture，覆盖：

- JSON decode、encode、round-trip 与 schema 拒绝
- `sourceId`、`bookKey`、`ruleSetId` 与 rule version
- 搜索/详情/作者/简介/TOC/正文 CSS 规则映射
- 原始 TOC 顺序与既有 WebBook runtime 投影

`test/manual/sudugu_web_book_poc_test.dart` 的真实站点验收已改为从同一 XAOCEN JSON 定义构造 runtime，继续验证 Sudugu《青山》的详情、首章、中间章节、最新章节、正文净化和 `ReaderContent` 投影。

## 修改文件

- `lib/sources/remote/xaocen_web_book_source_definition.dart`
- `test/unit/xaocen_web_book_source_definition_test.dart`
- `test/manual/sudugu_web_book_poc_test.dart`
- `docs/M5_9D_6_XAOCEN_WEBBOOK_SOURCE_DEFINITION.md`

没有修改 Reader、Locator、Progress、数据库 schema、UI 或 Registry。

## Gate

- `flutter analyze --no-pub`：PASS（No issues found）
- 定向 XAOCEN/WebBook tests：PASS（3 个 XAOCEN definition + 4 个既有 WebBook tests）
- 真实 Sudugu POC：PASS（通过同一 XAOCEN JSON definition）
- 全量 Flutter tests：PASS（734 passed，2 skipped）
- `git diff --check`：PASS

## 结论

JSON schema、校验和到现有 `WebBookCssRuleSet` 的映射已形成单一实现；未发现需要大规模重构的 Architecture Blocker。本阶段可冻结；真实来源的 UI/Registry 接入属于后续阶段。
