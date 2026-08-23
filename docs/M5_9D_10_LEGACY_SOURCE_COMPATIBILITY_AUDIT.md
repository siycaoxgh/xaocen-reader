# M5.9d-10 — Legacy Source Compatibility Audit

审计日期：2026-08-18
项目：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
样本目录：`C:\Users\TOM\Desktop\测试\新建文件夹`
生产代码修改：无

## 结论摘要

这批文件是 **Legado/阅读类应用书源记录的 JSON 导出**，而不是 XAOCEN 自有
`xaocen.webBook` 定义。三个文件都是“根数组 + 记录对象”，没有根级 schema 或
版本字段；其中两个分类文件是全量文件的精确子集，不是三批独立数据。

当前 XAOCEN 的 `XaocenWebBookSourceDefinition` 只接受版本化对象、CSS selector、
静态 HTML 和有限字段提取；现有 `RemoteSourceConfigFormats.legadoJson` 只是未来
codec 扩展点，尚未解析或执行 Legado 规则。因此本批 **没有可直接导入 XAOCEN 的
记录**。可以先做低风险的文本 WebBook 转换器，但必须把 Legado 的 selector/action
语法转换为 XAOCEN 规则并逐源验证，不能把原 JSON 直接塞进 Registry。

## 1. 文件盘点

| 文件 | 条目 | 大小 | 结构结论 |
|---|---:|---:|---|
| `阅读书源(仅小说) 3269.json` | 3,269 | 15,661,879 bytes | 根数组；小说子集 |
| `阅读书源(漫画、图片、搜索、下载、听书、音乐等) 318.json` | 318 | 1,835,519 bytes | 根数组；非小说/混合子集 |
| `阅读书源(全书源) 3587.json` | 3,587 | 17,497,396 bytes | 根数组；上面两个文件的精确并集 |

校验结果：

- 三个文件均可解析为 JSON 数组；每条记录均有 `bookSourceUrl`、`bookSourceName`、
  `bookSourceType`。
- 两个子集无重复记录；全量文件与两个子集的并集为 3,587 条，未发现额外条目。
- 文件时间戳均为 2024-10-31 17:26:21；这只能说明文件时间，不能推断某个网站当前仍有效。

### 观察到的根字段

`bookSourceComment`、`bookSourceGroup`、`bookSourceName`、`bookSourceType`、
`bookSourceUrl`、`bookUrlPattern`、`searchUrl`、`exploreUrl`、`ruleSearch`、
`ruleExplore`、`ruleBookInfo`、`ruleToc`、`ruleContent`、`header`、`loginUrl`、
`loginUi`、`loginCheckJs`、`jsLib`、`coverDecodeJs`、`enabledCookieJar`、
`concurrentRate` 等。字段是按记录可选的，不应假定所有书源都有完整链路。

## 2. 类型与能力统计（全量 3,587 条）

`bookSourceType` 的含义在这批文件中没有显式枚举说明；下面的标签是根据同一记录
的名称/分组得到的**审计推断**，不是 XAOCEN 的正式协议定义：

| 观察到的类型 | 数量 | 记录中常见的名称/分组 | 审计处理 |
|---:|---:|---|---|
| `0` | 3,403 | 小说、正版、笔趣阁、搜索 | 可作为文本 WebBook 候选，但仍需规则转换 |
| `1` | 64 | 听书、音乐、有声 | 不映射到 WebBook；需要音频能力，暂不支持 |
| `2` | 90 | 漫画、图片 | 需要图片章节/多图能力，不能当纯文本 |
| `3` | 30 | 下载、资源、PPT、论坛等混合内容 | 语义不统一，必须逐源确认 |

重要能力标记（记录之间可重叠）：

- 1,489 条包含 `@js:`、`<js>` 或 `javascript:`；
- 765 条包含 JSONPath 风格 `$...`；5 条记录出现 XPath 相关标记（原始文本中 `@XPath`
  字面量仅 1 次）；
- 1,203 条有 `ruleContent.nextContentUrl`（可能是同章分页，也可能是下一章/动态 URL，
  不能直接假定）；864 条有 `ruleToc.nextTocUrl`；
- 672 条有 `imageStyle`，383 条有 `webJs`，388 条有 `sourceRegex`，921 条有
  `replaceRegex`；
- 734 条带非空 `header`，463 条带非空 `loginUrl`，27 条带 `loginUi`，24 条带
  `loginCheckJs`。`enabledCookieJar` 字段在所有记录中存在，但它本身不等于已经具备
  可迁移的登录会话；本审计没有读取或导入任何凭据。
- 819 条缺少至少一个核心规则对象（`ruleSearch` / `ruleBookInfo` / `ruleToc` /
  `ruleContent`）；其中 481 条缺少或为空 `ruleContent`。
- 17 条 `bookSourceUrl` 不是可用的 HTTP/HTTPS 基地址；1,100 条包含 `#` 片段标记，
  36 条含空格或复合标记。片段有时是旧客户端的标签/配置备注，不能未经确认直接拼成 URL。

### 文本规则的转换候选（启发式，不是已转换结果）

- 3,403 条类型 `0` 中，1,441 条同时具备核心规则且未检测到 JS/XPath/JSONPath；
  它们仍大量使用 `@text`、`@href`、`@html`、位置索引、`##` 清洗和 `{{...}}`，只能作为
  **低风险转换候选**，不是“直接可用”。
- 其中 310 条未检测到 `@get:`、`@put:`、`##`、`{{...}}` 等动态/重写标记，是最适合
  第一批人工确认的候选；仍必须把 `class.foo`、`.0` 等 Legado 语法正规化为 CSS selector。
- 1,133 条虽无 JS/XPath/JSONPath，但需要 selector/action 正规化或正则清洗映射。

## 3. 兼容性矩阵

| 能力/来源类别 | 代表样本 | 当前 XAOCEN 结论 | 原因分类 |
|---|---|---|---|
| 低风险静态文本 WebBook | `速读谷吧`、部分类型 `0` 记录 | **可部分转换** | 规则主体是 CSS-ish，但 `@text`、位置索引、`##`、WebView 后缀仍需显式转换 |
| 静态 HTML + JSON/POST | `🔰 纵横中文网` | **需要新增规则能力** | 搜索返回 JSON，规则使用 JSONPath、POST 和 API URL；当前引擎只做静态 HTML/CSS |
| JS/动态规则 | `鸠摩搜书`、`✏️铅笔小说`、起点部分规则 | **暂不支持** | `@js:`/`<js>`、动态 Cookie、脚本生成 URL，不能在当前安全运行时执行 |
| 漫画/多图片 | `🪙YYDS漫画` | **需要新增规则能力** | `bookSourceType=2`、`imageStyle`、图像章节；不能把 `<img>` 当普通正文文本 |
| 有声/音乐 | `有声听书网`、`音乐-酷我` | **需要新增能力** | `bookSourceType=1`，输出音频/播放列表，不属于 ReaderContent 文本 WebBook |
| 搜索/发现/下载聚合 | `鸠摩搜书（下载）`、`🏵乐阅读` | **部分转换或暂不支持** | 可能只有搜索/下载链接，没有详情/TOC/正文；需明确 source kind，不应伪装成 WebBook |
| 登录/Cookie/WebView | 起点、晋江、铅笔小说等 | **暂不支持** | 需要账号、Cookie、WebView 或脚本检查；本轮不导入凭据、不做登录 |
| 失效/乱码/非 URL | `🏵乐阅读`、若干自用源 | **无效/无法判断** | 基地址不是 HTTP(S) 或仅为备注/占位；先记录，不猜测含义 |

因此，“可直接映射 XAOCEN”这一列当前是 **0 条确认记录**；只有经过转换器生成
`xaocen.webBook` 对象并通过 CSS/同源/字段校验后，才可进入 XAOCEN Registry。

## 4. 代表样本真实网络测试

测试日期：2026-08-18。仅对公开 HTTP/HTTPS URL 做有限 GET（自动跟随最多 5 次重定向，
每次最多约 15 秒）；没有 POST、登录、Cookie 注入或 WebView。网络结果只说明当时可达性，
不等于规则已经兼容。

| 样本 | 请求结果 | 内容观察 | 结论 |
|---|---|---|---|
| `速读谷吧`（真实地址仅本地配置） | 根页 200；搜索页 200 | 页面标题为 `Redirecting...`，正文含 `parklogic`，不是旧书源页面 | **网站已停放/内容已变化**；不是 Parser 失败证据 |
| `起点中文`（真实地址仅本地配置；搜索页） | 根页 202/209 bytes；搜索页 200/约 98 KB | 搜索页可返回 HTML，但规则含 `class.*`、脚本、VIP API、WebView | **网站可达 + 规则不兼容/访问受限** |
| `🔰 纵横中文网` | 根页 200；搜索 API 200，`application/json`，约 31 KB | API 返回 `code:0` 和书籍列表；旧规则使用 JSONPath、POST、API 拼接 | **网站可达；当前 CSS-only WebBook 规则不兼容** |
| `🪙YYDS漫画` | 根页 200/约 280 KB；搜索页 200/0 bytes | 站点能响应，搜索结果为空；规则正文为图片区域并带 `imageStyle` | **内容/规则漂移 + 图片能力未支持**，不能归因单一 Parser |
| `有声听书网`（真实地址仅本地配置） | 根页 200；发生域名重定向；API 200 | API 返回 `code=400`、`暂无数据` | **来源域名/接口已变化；且音频类型不在当前 WebBook 范围** |
| `鸠摩搜书` | 根页 200/约 15.8 KB | 页面可达；搜索规则要求 `@js:`、POST 和动态接口 | **网站可达；规则依赖 JS，当前运行时不支持** |
| `笔趣阁22biqu`（真实地址仅本地配置） | 根页与搜索页均连接失败（curl 7，HTTP 000） | 未获得正文 | **网络/站点不可用；无法判断规则兼容性** |
| `🏵乐阅读` | `bookSourceUrl` 为“花间一壶酒，独酌无相亲。” | 不是 HTTP(S) 地址 | **旧数据无效/占位，未进行网络请求** |

### 如何区分网站问题和 XAOCEN 规则问题

1. 先用同一 URL 做裸 HTTP 请求并记录 status、最终 URL、Content-Type、响应大小；
2. 再检查响应是否包含规则预期的 selector/JSON 结构；
3. 最后才运行 XAOCEN 规则提取。

本次已出现三种可区分结果：

- 200 但停放页（速读谷）= **网站内容已变**；
- 200 且返回 JSON/HTML，但规则需要 JSONPath/JS/POST（纵横、鸠摩）= **规则能力不兼容**；
- 连接失败（22biqu）= **网络或网站不可用，不能判 Parser 错**。

## 5. 可转换字段与不可转换能力

### 可转换（需经过显式转换器）

| 旧字段/语义 | XAOCEN 目标 | 约束 |
|---|---|---|
| `bookSourceName` | `name` | 仅显示名称，不作为 identity |
| 规范化 `bookSourceUrl` | `endpoint` | 去除/保留 `#` 片段前必须人工确认；不能把备注当 URL |
| `searchUrl` 的静态 GET + `{{key}}` | `searchEndpoint` + `searchRequest.queryParameter` | 默认 `q`；`key`/`keyword` 等必须显式记录；POST 暂不直转 |
| `ruleSearch.bookList/name/author/bookUrl/coverUrl/intro` | `rules.search` | 仅在 selector/action 可证明是 CSS + text/attribute 时转换 |
| `ruleBookInfo` 的静态字段 | `rules.detail` | `@get/@put/init` 变量链必须展开后再转，否则标记部分转换 |
| `ruleToc.chapterList/chapterName/chapterUrl` | `rules.toc` | 保留 HTML 顺序；`nextTocUrl` 需独立 TOC 分页能力 |
| `ruleContent.content` 静态区域 | `rules.chapter.bodySelector` | `@html` 可映射为正文 HTML；动态内容须拒绝 |
| 简单 `nextContentUrl` | `chapter.nextPageSelector` | 必须有同章判定、已访问 URL、上限和同源校验；不能把下一章链接当分页 |
| `replaceRegex` | Content Transform（未来） | 不能在 source converter 中偷偷改变 Locator truth |

### 不可直接转换/须新能力

- `@js:`、`<js>`、`javascript:`、`webJs`、`loginCheckJs`：需要脚本运行时，当前禁止执行；
- JSONPath（`$.`、`$.[*]` 等）和 JSON API POST：需要独立 JSON extraction/request contract；
- `@XPath`：当前 XAOCEN schema 明确只接受 CSS selector；
- `@get:` / `@put:` / `init` / `formatJs` 等变量与动作 DSL：必须先设计受限、可审计的表达式层；
- `loginUrl`、`loginUi`、Cookie jar、复杂 Header/Token：暂不导入账号状态；
- `imageStyle`、图片数组/画廊、音频 URL/播放列表、下载链接：分别需要 ImageChapter/Audio/Resource source；
- `bookSourceType=3` 的资源/论坛/下载混合语义：当前无法从字段可靠推断产品行为；
- `coverDecodeJs`、自定义 JS 库和任意内嵌资源：未知规则，保持拒绝并记录原因。

## 6. Legado/Legacy → XAOCEN 转换方案

不直接修改现有 WebBook runtime；增加独立、可审计的 **导入前转换器**（未来阶段实施）：

```text
Legacy JSON (root array or one record)
  → shape/version detector
  → source-kind classifier (text/image/audio/resource/search)
  → capability scanner (CSS / JSONPath / JS / XPath / auth / pagination)
  → conservative field normalizer
  → XAOCEN xaocen.webBook object (only when all required rules are safe)
  → existing XaocenWebBookSourceDefinition.fromJson
  → Registry import / manual review result
```

### 转换器边界

1. 只接受单条记录或明确选择的记录；根数组不自动全量导入。
2. 先生成诊断结果：`directCandidate`、`partial`、`unsupported`、`invalid`，并保留
   原始 source id、来源文件、规则版本/未知字段 provenance。
3. 只把明确的静态 CSS + text/attribute + GET 查询转换为 `xaocen.webBook`；任何
   JS/JSONPath/XPath/登录动作都必须阻止自动导入，而不是“猜一个 selector”。
4. selector 正规化需要单独测试：`class.foo`、`a@text`、`a@href`、位置索引、`##` 清洗、
   `{{...}}` 模板不得通过字符串替换静默改变语义。
5. `bookSourceType=2/1/3` 先路由到未实现的能力报告，不映射成文本 WebBook。
6. 转换成功后仍通过现有 `XaocenWebBookSourceDefinition` 的 HTTP、同源、CSS selector、
   ruleVersion 校验；不能绕过 Registry 约束。
7. 网络可达性仅作为测试信息，不影响 source identity；网站失效不能被转换器改写成另一站。

## 7. 值得借鉴的最小新增能力

按风险和复用价值排序：

1. **转换诊断/能力扫描器**：只读解析 Legacy 记录，给出可解释的 unsupported reason；
   不执行脚本、不联网也能先完成大部分审计。
2. **安全 selector 规范化**：有限支持 `@text`、`@html`、`@href/@src`、稳定位置选择，
   严格拒绝动态动作；输出可回溯的转换日志。
3. **请求模板的 GET/JSON 只读扩展**：在单独 request contract 中支持明确的 GET 参数和
   JSON 字段路径；POST、登录和 Cookie 仍作为后续 capability，不混入 CSS WebBook。
4. **同章分页与 TOC 分页的分离规则**：继续使用现有 URL 去重、同源和上限保护；`nextTocUrl`
   不能复用 `nextContentUrl` 语义。
5. **图片章节最小模型**：等文本 WebBook 转换稳定后，再单独定义 image list/content，
   不把图片 HTML 强行转换成纯文本。

以下能力本阶段不建议新增：JS 引擎、WebView 登录、通用 Legado 全兼容、音频播放、下载器。
它们会扩大安全边界并破坏当前 `RemoteSource → ReaderContent` 的清晰分层。

## 8. 后续转换实施顺序

1. **M5.9d-10.1 — Legacy Detector（只读）**：根结构/字段/类型/动态能力扫描；输出报告，
   不写 Registry。
2. **M5.9d-10.2 — Static Text Converter**：仅处理类型 `0`、静态 GET、CSS-ish selector，
   每条生成 `xaocen.webBook` 草稿并人工确认。
3. **M5.9d-10.3 — Rule Fixture Gate**：为每个候选保存离线 HTML/JSON fixture，验证搜索、详情、
   TOC、分页、正文和稳定 identity；网络失效与规则失败分开记录。
4. **M5.9d-10.4 — JSON API Capability（可选）**：只在 contract 明确后支持 JSONPath/GET；
   不执行 JS。
5. **M5.9d-10.5 — Image/Audio/Resource 分层评估**：分别建立能力，不把非文本源塞入 WebBook。
6. 登录、Cookie、WebView、脚本规则和 Legado 全兼容必须另立阶段并单独安全审计。

## 9. 未知规则与明确不做的猜测

- `bookSourceType` 的官方枚举语义未从这批文件自描述字段中确认；本报告只写观察到的
  名称/分组推断，未把数值当作 XAOCEN 协议。
- `#`、`##`、`@` 后的部分片段可能是客户端备注、规则动作或 URL 片段；未统一剥离。
- `@js` 片段引用的 `java.*`、Cookie、WebView 标志、变量生命周期没有执行验证。
- 只看到 `enabledCookieJar` 不代表可以恢复原登录状态；没有读取任何账号/密码/Cookie。
- 网络 200 只证明响应可达，不证明旧 selector 仍能提取目标内容；网络失败也不反向证明
  Parser 有 bug。

## 10. 审计状态

| 项目 | 状态 |
|---|---|
| 文件/字段盘点 | PASS |
| Legado-like 结构识别 | PASS（无根版本字段；版本差异 UNKNOWN） |
| 代表网络样本 | PASS（有限公开 GET；硬件/登录未测） |
| 规则不兼容 vs 网站失效区分 | PASS（见样本表） |
| 生产代码修改 | NONE |
| 自动转换器 | NOT STARTED |
| 直接导入 XAOCEN Registry | NOT ALLOWED |
| 是否可冻结本审计 | PASS / FROZEN（审计阶段） |

本报告不宣称旧书源整体可用，也不把计划中的 JS、WebView、登录、图片/音频源标记为失败；
这些均属于 **待补充/待规划**。生产 WebBook 架构保持不变。
