# M5.9d-11 — Legacy Source Capability Scanner

项目：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
测试数据：`C:\Users\TOM\Desktop\测试\新建文件夹`
扫描日期：2026-08-19

## 结论

只读扫描器已完成并运行在全量 3,587 条旧书源上。扫描不执行规则、不运行
JavaScript、不打开 WebView、不读取凭据、不发起网络请求，也不写入 XAOCEN
书源 Registry、Reader、Locator、Progress 或数据库。

**STATIC TEXT CONVERTER STAGE = READY / CONDITIONAL**：扫描发现 292 条满足
当前静态文本转换器的初步安全门槛（完整四段规则、静态正文、无 JS/XPath/JSON/API/
登录等额外能力）。这不是已转换结果；下一阶段仍需逐源生成草稿并通过离线 fixture
和同源规则校验。

## 扫描输入与去重

| 项目 | 结果 |
|---|---:|
| JSON 文件 | 3 |
| 读取记录 | 7,174 |
| 唯一记录 | **3,587** |
| 子集重复副本 | 3,587 |
| 批量网络抓取 | **NOT RUN** |
| 根结构 | JSON 数组；Legado/阅读记录对象 |
| 格式版本 | UNKNOWN（记录没有统一根级版本字段） |

`阅读书源(全书源) 3587.json` 是 3,587 条的完整集合；另外两个分类文件是重复的
子集。扫描器使用 URL、名称和规则内容指纹去重，不会把不同规则的同 URL 源误合并。

## 能力统计（能力可重叠）

| Capability | 数量 | 说明 |
|---|---:|---|
| STATIC_TEXT | 2,471 | 存在正文规则；其中一部分同时含动态能力 |
| JSON_API | 796 | JSONPath、JSON API 或 POST 请求迹象 |
| XPATH | 135 | 规则中发现 XPath 选择器 |
| JS | 1,540 | `@js`、`<js>`、脚本动作或脚本字段 |
| WEBVIEW | 340 | 明确 WebView/动态页面字段 |
| LOGIN | 2,060 | 登录、Cookie 或认证状态字段 |
| IMAGE | 704 | 图片章节/图集或 `bookSourceType=2` |
| AUDIO | 76 | 有声/音乐或音频资源迹象 |
| INVALID | 0 | 本批唯一记录均能识别为 Legado-like 记录 |

## 处理建议统计

| 标记 | 数量 | 规则 |
|---|---:|---|
| AUTOMATICALLY_CONVERTIBLE | **292** | 纯静态文本、四段核心规则完整、静态 GET、无高风险能力 |
| MANUAL_REVIEW | **1,320** | 需要 XPath/JSON API/登录处理或规则不完整 |
| UNSUPPORTED | **1,975** | JS、WebView、图片、音频或 INVALID；本阶段不执行/不转换 |

这些标记是能力边界，不是对网站当前可用性的判断。网站失效、网络失败与规则不兼容
仍须在后续 fixture/单源验收阶段分别记录。

## 代表样本

| 能力/标记 | 样本 | 结果与原因 |
|---|---|---|
| 静态文本候选 | 新笔趣阁(biqugezw) | 292 条候选中的代表；可进入转换器草稿阶段 |
| 静态文本但人工复核 | 笔趣阁22biqu（目录获取有延迟） | 搜索请求包含 POST/动态动作，不能自动导入 |
| JSON_API | 🔰 纵横中文网 | JSONPath/API 与脚本动作；需独立 API 能力，当前 UNSUPPORTED |
| XPATH | 88小说网m站 | XPath 与登录/Cookie；当前 MANUAL_REVIEW |
| JS | 笔趣网 | 检测到 `@js`/脚本动作，不执行脚本 |
| WEBVIEW | ✏️铅笔小说[免登录] | WebView/动态页面，不进入静态转换 |
| IMAGE | 🎉 起点中文 | 图片/动态规则，不能伪装成纯文本 WebBook |
| AUDIO | 腐小说网🎃 | 有声/音频来源，不属于文本 ReaderContent |
| INVALID | 无 | 全量记录未发现 INVALID；未来坏文件仍会单独输出 INVALID |

## 实现与测试

新增：

- `lib/sources/remote/legacy_source_capability_scanner.dart`：纯只读扫描模型、能力
  识别、理由、处理标记、目录扫描与精确副本去重。
- `tool/legacy_source_capability_scan.dart`：本地扫描入口；输出统计与代表样本 JSON。
- `test/unit/legacy_source_capability_scanner_test.dart`：静态 CSS、XPath、JSON API、
  JS/WebView、登录、图片、音频、INVALID、去重及“无网络”边界测试。
- `docs/M5_9D_11_LEGACY_SOURCE_CAPABILITY_SCAN.json`：本次 3,587 条扫描的机器可读摘要。

自动转换器尚未实现；扫描结果不会自动导入 Registry。未知字段、Legado 动作 DSL、
XPath/JSONPath、登录态和图片/音频语义均保留为诊断原因，不做猜测。

## Gate

| Gate | 结果 |
|---|---|
| `flutter analyze --no-pub` | **PASS** |
| Legacy scanner 定向测试（5 tests） | **PASS** |
| 全量 Flutter tests（750 passed，3 skipped） | **PASS** |
| `git diff --check` | **PASS**（仅有现有 CRLF 提示，无 diff error） |

阶段状态：**可进入 M5.9d-10.1 静态文本转换器设计/草稿阶段**，但转换结果必须经过
fixture 和人工确认后才能进入 XAOCEN Registry。JS、WebView、登录、图片、音频等能力
保持“暂不支持/待规划”，不作为本阶段失败。
