# M5.9d-13 — Legacy Restricted @tag Mapping

输入：`C:\Users\TOM\Desktop\测试\新建文件夹`

本阶段只实现静态、白名单化的 `@tag.*` 后代 selector 映射；不执行脚本、不联网、不导入 Registry。

## 1. 扫描与转换统计

| 项目 | 数量 |
|---|---:|
| 读取记录 | 7174 |
| 去重后记录 | 3587 |
| Scanner AUTOMATICALLY_CONVERTIBLE | 292 |
| Scanner MANUAL_REVIEW | 1320 |
| Scanner UNSUPPORTED | 1975 |
| 含 `@tag.*` 规则的来源 | 1261 |
| `@tag.*` 规则出现次数 | 6827 |
| 成功映射次数 | 2525 |
| 拒绝映射次数 | 4302 |

### 转换结果

Pack 兼容等级：`{UNSUPPORTED: 2386, NEEDS_CAPABILITY: 1201}`

Scanner 自动候选转换：`{MANUAL_REVIEW: 292}`

本次没有新增 `FULL` 或 `RUNNABLE_PARTIAL`；映射后的完整核心规则仍被其它缺口（规则不完整、索引/分支、认证、动态请求等）阻断，未伪造可运行书源。

## 2. 支持边界

支持：
- `class.foo@tag.li@tag.a@text` → `.foo li a`
- `@tag.article@tag.*@html` → `article *`
- `@href`、`@src`、`@content` 等现有受限属性动作

拒绝：
- 索引（`.0`、`.1`、`!-0` 等）与分支（`||`）
- `##` 替换、模板、`@js`、WebView
- XPath、JSONPath、登录/Cookie/Auth

## 3. 主要拒绝原因

| 原因 | 数量 |
|---|---:|
| `ruleBookInfo.kind: 规则包含替换、模板或脚本语法，@tag 映射拒绝猜测` | 255 |
| `ruleBookInfo.lastChapter: 规则包含替换、模板或脚本语法，@tag 映射拒绝猜测` | 233 |
| `ruleSearch.lastChapter: 规则包含替换、模板或脚本语法，@tag 映射拒绝猜测` | 221 |
| `ruleSearch.coverUrl: 规则包含替换、模板或脚本语法，@tag 映射拒绝猜测` | 206 |
| `ruleBookInfo.author: 规则包含替换、模板或脚本语法，@tag 映射拒绝猜测` | 158 |
| `ruleSearch.name: 不支持的 @tag 片段：@a.0（索引/分支/复合动作需人工确认）` | 131 |
| `ruleSearch.name: 规则包含替换、模板或脚本语法，@tag 映射拒绝猜测` | 127 |
| `ruleSearch.bookUrl: 不支持的 @tag 片段：@a.0（索引/分支/复合动作需人工确认）` | 120 |
| `ruleSearch.bookList: 不支持的 @tag 片段：@tr!0（索引/分支/复合动作需人工确认）` | 117 |
| `ruleToc.chapterList: 不支持的 @tag 动作：@a` | 105 |

## 4. 转换阻断概览

| 原因 | 数量 |
|---|---:|
| `包含登录、Cookie 或认证状态，不能自动导入凭据` | 2060 |
| `当前来源依赖 XAOCEN 尚未执行的能力，未生成可运行 source` | 1975 |
| `检测到 JavaScript/脚本动作，扫描器不会执行脚本` | 1540 |
| `检测到 JSONPath/JSON API 或 POST 请求，需要独立 API 规则能力` | 796 |
| `搜索、详情、目录、正文规则不完整` | 728 |
| `检测到图片章节/图集能力，不当作纯文本 WebBook 转换` | 704 |
| `缺少可确认的静态正文规则` | 467 |
| `ruleSearch 必须是对象` | 413 |
| `依赖 WebView/动态页面，当前静态运行时不支持` | 340 |
| `bookSourceUrl 不是安全的 HTTP(S) endpoint` | 338 |

## 5. Gate

- `flutter analyze --no-pub`：PASS
- @tag 映射/Legacy 转换定向测试：PASS（20 tests）
- 全量 `flutter test`：PASS（765 passed，3 skipped）
- `git diff --check`：PASS（仅现有 LF/CRLF 提示）

Registry 导入：`NOT_RUN`；网络抓取：`NOT_RUN`。
