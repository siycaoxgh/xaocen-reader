# M5.9d-12 — Legacy Static Text Converter

项目：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
输入：`C:\Users\TOM\Desktop\测试\新建文件夹`
扫描日期：2026-08-19

## 结论

已实现保守的 Legacy 静态文本转换器。它只接受上一阶段扫描器标记为
`AUTOMATICALLY_CONVERTIBLE` 的记录，并把可无损映射的规则交给现有
`XaocenWebBookSourceDefinition` 校验。任何不在 XAOCEN schema 中的规则、动态动作、
无效 endpoint 或可能改变语义的 selector 都降级为 `MANUAL_REVIEW`。

本次真实 3,587 条记录中没有生成正式草稿：292 条候选均触发了无损转换门槛，因而
全部降级人工复核。这是安全结果，不是把不完整规则伪装成可用书源。离线 fixture
已成功生成并验证一份 XAOCEN 草稿，因此转换器本身可以进入人工样本复核阶段。

## 实际转换统计

| 项目 | 数量 |
|---|---:|
| 读取记录 | 7,174 |
| 去重后唯一记录 | 3,587 |
| 扫描器 AUTOMATICALLY_CONVERTIBLE | 292 |
| 成功生成 XAOCEN 草稿 | **0** |
| 降级 MANUAL_REVIEW | **292** |
| 非候选 SKIPPED | 3,295 |
| Registry 自动导入 | **NOT RUN** |
| 网络抓取 | **NOT RUN** |

### 降级原因

| 原因 | 数量 |
|---|---:|
| 无效/不安全 HTTP(S) endpoint | 110 |
| `ruleSearch.coverUrl` 未有 XAOCEN 等价字段 | 87 |
| `ruleSearch.checkKeyWord` 未有等价字段 | 26 |
| `ruleSearch.lastChapter` 未有等价字段 | 25 |
| `ruleSearch.kind` 未有等价字段 | 22 |
| `ruleSearch.intro` 未有等价字段 | 7 |
| `ruleBookInfo.coverUrl` 未有等价字段 | 6 |
| `ruleBookInfo.lastChapter` 未有等价字段 | 2 |
| `ruleBookInfo.author` 含动态替换语法 | 2 |
| 缺失/非法 `bookList` | 2 |
| `exploreUrl` 无 XAOCEN 等价字段 | 2 |
| `ruleContent.replaceRegex` 无等价 Transform | 1 |

原因统计按首次阻断原因归类；一条记录可能同时存在多个问题。转换器没有删除或
改写这些原始规则。

## 映射边界

可映射的最小静态集合：

- `bookSourceName` / `bookSourceUrl` → XAOCEN `name` / `endpoint`
- `searchUrl` 静态 GET → `searchEndpoint`；从 `{{key}}` 推断查询参数，默认 `q`
- `ruleSearch.bookList/name/author/bookUrl@href`
- `ruleBookInfo.name/author/intro`
- `ruleToc.chapterList/chapterName/chapterUrl@href`
- `ruleContent.content` 与可验证的 `nextContentUrl@href`
- `class.foo` → `.foo` 的有限正规化
- 生成稳定、符合 XAOCEN 格式的 `sourceId` 与 `bookKey`

明确拒绝：

- `@js`、`<js>`、XPath、JSONPath、POST、WebView、登录/Cookie
- `##`、`||`、`{{...}}` 动态动作/替换
- 未纳入当前 XAOCEN schema 的封面、分类、最新章节、发现规则、正则替换
- 嵌套目录链接无法映射为当前 `entrySelector + hrefAttribute` 语义的情况

## 离线 fixture 验证

定向测试构造了一份无网络 Legacy 静态源，验证：

1. `keyword={{key}}` 转为 `searchQueryParameter=keyword`；
2. `class.foo` 只做受控 CSS 正规化；
3. 草稿通过 `XaocenWebBookSourceDefinition.fromJson`；
4. 现有 `WebBookRuleEngine` 能完成搜索 → 详情 → TOC → 正文；
5. `replaceRegex`、JS 规则会降级，不生成草稿。

fixture 结果：**PASS**。真实源草稿文件为空数组是预期行为，因为本批没有达到无损门槛
的记录：

- [XAOCEN 草稿集合](/C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/docs/M5_9D_12_LEGACY_STATIC_TEXT_DRAFTS.json)
- [转换机器报告](/C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/docs/M5_9D_12_LEGACY_STATIC_TEXT_CONVERSION.json)

## 新增文件

- `lib/sources/remote/legacy_static_text_converter.dart`
- `test/unit/legacy_static_text_converter_test.dart`
- `tool/legacy_static_text_convert.dart`
- `docs/M5_9D_12_LEGACY_STATIC_TEXT_DRAFTS.json`
- `docs/M5_9D_12_LEGACY_STATIC_TEXT_CONVERSION.json`

转换器只返回 draft，不调用 Registry，也不接触 Reader/Locator/Progress/数据库。

## Gate

| Gate | 结果 |
|---|---|
| `flutter analyze --no-pub` | **PASS** |
| 静态转换器定向测试（5 tests） | **PASS** |
| 全量 Flutter tests | **PASS** — 755 passed, 3 skipped |
| `git diff --check` | **PASS** — 无 diff 检查错误（仅有既存换行提示） |

## 下一步判断

**人工/真实站点抽样验收：CONDITIONAL READY。** 可以从 292 条候选中先人工修订/确认
字段，再对单源做有限真实 GET；当前不能直接批量导入，也不应把 0 条正式草稿标记为
转换成功。JS、XPath、JSON API、WebView、登录、图片、音频保持独立后续能力阶段。
