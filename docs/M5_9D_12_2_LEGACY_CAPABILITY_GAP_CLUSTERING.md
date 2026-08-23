# M5.9d-12.2 — Legacy Capability Gap Clustering

输入 Pack：`docs/M5_9D_12_1_LEGACY_SOURCE_PACK.json`

本报告只分析 Source Pack 中的 `NEEDS_CAPABILITY` 条目；不联网、不执行规则、不修改生产引擎。

## 1. 能力缺口统计

| 缺口 | 覆盖书源 | 覆盖率 |
|---|---:|---:|
| `HEADER_COOKIE_AUTH` | 946 | 78.8% |
| `REGEX_REPLACE` | 401 | 33.4% |
| `DYNAMIC_URL_TEMPLATE` | 343 | 28.6% |
| `@tag.*` | 300 | 25.0% |
| `XPATH` | 227 | 18.9% |
| `NESTED_TOC_OR_SECOND_REQUEST` | 227 | 18.9% |
| `OTHER` | 170 | 14.2% |
| `JSONPATH` | 110 | 9.2% |
| `JS_WEBVIEW` | 0 | 0.0% |

同一书源可以命中多个缺口，因此各行不能相加。

Header/Cookie/Auth 细分使用原始字段证据；扫描器仅因 `enabledCookieJar=false` 产生的误报不计入字段缺口（本批 scanner-only 信号：1）。

## 2. Top 10 高频组合

| 排名 | 组合 | 数量 |
|---:|---|---:|
| 1 | `HEADER_COOKIE_AUTH` | 480 |
| 2 | `OTHER` | 170 |
| 3 | `DYNAMIC_URL_TEMPLATE + JSONPATH + REGEX_REPLACE` | 60 |
| 4 | `@tag.* + DYNAMIC_URL_TEMPLATE + HEADER_COOKIE_AUTH + NESTED_TOC_OR_SECOND_REQUEST + REGEX_REPLACE + XPATH` | 46 |
| 5 | `@tag.* + DYNAMIC_URL_TEMPLATE + HEADER_COOKIE_AUTH + REGEX_REPLACE` | 46 |
| 6 | `HEADER_COOKIE_AUTH + XPATH` | 41 |
| 7 | `@tag.* + DYNAMIC_URL_TEMPLATE + HEADER_COOKIE_AUTH + NESTED_TOC_OR_SECOND_REQUEST + REGEX_REPLACE` | 37 |
| 8 | `@tag.* + HEADER_COOKIE_AUTH + NESTED_TOC_OR_SECOND_REQUEST + REGEX_REPLACE` | 29 |
| 9 | `@tag.* + DYNAMIC_URL_TEMPLATE + HEADER_COOKIE_AUTH + REGEX_REPLACE + XPATH` | 27 |
| 10 | `DYNAMIC_URL_TEMPLATE + HEADER_COOKIE_AUTH + NESTED_TOC_OR_SECOND_REQUEST + REGEX_REPLACE + XPATH` | 26 |

## 3. 单项能力新增转换估算

| 能力 | 命中数（上限） | 仅此单项缺口（保守新增） |
|---|---:|---:|
| `HEADER_COOKIE_AUTH` | 946 | 480 |
| `REGEX_REPLACE` | 401 | 0 |
| `DYNAMIC_URL_TEMPLATE` | 343 | 0 |
| `@tag.*` | 300 | 4 |
| `XPATH` | 227 | 1 |
| `NESTED_TOC_OR_SECOND_REQUEST` | 227 | 1 |
| `JSONPATH` | 110 | 1 |
| `JS_WEBVIEW` | 0 | 0 |

“保守新增”只统计缺口集合恰好只有该项的书源；“上限”不扣除其它组合缺口，不能直接相加。

`OTHER` 的 170 条没有可安全归并到单一能力，暂不做数量承诺；`JS_WEBVIEW` 在本批 `NEEDS_CAPABILITY` 中为 0，相关来源已在前一阶段归为 `UNSUPPORTED`，因此不会被错误计入可转换增量。

## 4. 优先级建议

- **低风险优先**：建立受限的 `@tag.*` → CSS 后代 selector 映射白名单，并为 `@ownText`/`##` 做纯静态、可审计的 transform 试验（不执行正则代码）。
- **低—中风险**：只读、线性的 `REGEX_REPLACE` 语义可单独做白名单 transform；不得把任意正则脚本直接带入抓取 runtime。
- **中风险独立 runtime**：动态 URL/template、嵌套目录/二次请求、XPath、JSONPath；每项都要独立安全边界和 fixture，不能混入当前 CSS runtime。
- **高风险暂缓**：JS/WebView、登录态自动化、复杂 Cookie/认证、图片/音频源；本阶段不实现。

## 5. 推荐下一阶段

1. 只实现受限 `@tag.*` selector 映射，并以离线 fixture 验证；预计立即可新增转换约 4 条（按保守单项口径）。
2. 若第一项通过，再单独评估纯静态 `##`/`||` 内容变换；不要同时引入动态请求或认证。

当前结论：**CAPABILITY GAP ANALYSIS = PASS；生产能力扩展 = NOT STARTED**。

## 6. Gate

- `flutter analyze --no-pub`：PASS（No issues found）
- 能力扫描/转换/Source Pack/聚类定向测试：PASS（16 tests passed）
- 全量 `flutter test`：PASS（761 passed，3 skipped；skipped 为显式网络人工验收）
- `git diff --check`：PASS（仅现有工作区的 LF/CRLF 提示，无 whitespace error）

本轮仅新增只读聚类模型、离线报告与测试；未修改生产规则引擎、未联网、未自动导入或转换书源。
