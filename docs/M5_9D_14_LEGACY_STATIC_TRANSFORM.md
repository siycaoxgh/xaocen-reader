# M5.9d-14 — Legacy Static `##` / `||` Transform

输入：`C:\Users\TOM\Desktop\测试\新建文件夹`

本阶段只允许字面前缀移除和同动作 CSS fallback；不执行正则、脚本、模板、网络请求或 Registry 导入。

## 统计

| 项目 | 数量 |
|---|---:|
| 读取记录 | 7174 |
| 去重后记录 | 3587 |
| Scanner 自动候选 | 292 |
| 含 `##`/`||` 来源 | 2531 |
| 变换规则出现次数 | 11276 |
| 字面前缀映射 | 883 |
| fallback 映射 | 1530 |
| 拒绝（正则/动态/不一致） | 8862 |

Scanner 分布：`{MANUAL_REVIEW: 1320, UNSUPPORTED: 1975, AUTOMATICALLY_CONVERTIBLE: 292}`

严格转换结果：`{SKIPPED: 3295, MANUAL_REVIEW: 292}`

Pack 兼容结果：`{UNSUPPORTED: 2370, NEEDS_CAPABILITY: 1217}`

本轮未把任何 Legacy 记录自动导入 Registry；核心字段仍不完整的来源继续保持 `NEEDS_CAPABILITY`/`UNSUPPORTED`，没有为了统计变绿而猜测规则。

## 支持边界

- `selector@text##字面前缀` → `removePrefix`（只在结果以该前缀开头时移除）
- `selectorA@text||selectorB@text` → 有序 fallback selector
- 顶层 `bookList`/目录节点、正文节点的 `||`/`##` 不强行转换，因为现有契约只有单一节点 selector
- 正则替换、多段 `##`、索引、脚本、模板、XPath/JSONPath、登录/Cookie/Auth 保留为人工复核

## 代表拒绝原因
- `ruleContent.content: ## 内容包含正则元字符，需人工确认`：618
- `ruleBookInfo.kind: ## 内容包含正则元字符，需人工确认`：603
- `ruleContent.replaceRegex: ## 前缺少字段规则`：593
- `ruleBookInfo.lastChapter: ## 内容包含正则元字符，需人工确认`：449
- `ruleBookInfo.intro: ## 多段替换属于正则/替换语法，需人工确认`：374
- `ruleSearch.kind: ## 内容包含正则元字符，需人工确认`：373
- `ruleSearch.lastChapter: ## 内容包含正则元字符，需人工确认`：341
- `ruleBookInfo.name: ## 内容包含正则元字符，需人工确认`：317
- `ruleSearch.name: ## 内容包含正则元字符，需人工确认`：304
- `ruleSearch.author: ## 内容包含正则元字符，需人工确认`：244

## Gate

- `flutter analyze --no-pub`：PASS（No issues found）
- 静态变换/Legacy 定向测试：PASS（22 tests）
- 全量 `flutter test`：PASS（770 passed，3 skipped）
- `git diff --check`：PASS（仅现有 LF/CRLF 工作区提示，无 whitespace error）

Registry 导入：`NOT_RUN`；网络抓取：`NOT_RUN`。
