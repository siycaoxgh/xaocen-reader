# M5.9d-4 — Sudugu Real WebBook POC

## POC 范围

本轮使用真实公开静态 HTML 站点验证《青山》：

- 书籍页：通过 `XAOCEN_LIVE_SOURCE_URL` 本地注入（实际地址不入库）
- 首章：由目录第一项解析得到（当前为 `/5/20.html`）
- 中间章：当前目录中部条目（运行时按 HTML 顺序选择）
- 最新章：当前目录中的“第781章 消息有误”（当前为 `/5/4277639.html`）

本轮不实现 JavaScript/WebView、登录、Cookie、反爬、搜索接口适配或通用书源导入。

## 真实链路结果

```text
Sudugu detail HTML
  → WebBookSource / WebBookHttpRuntime
  → detail metadata
  → ordered TOC
  → selected chapter HTML
  → FeedHtmlNormalizer
  → CanonicalContent
  → ReaderContent projection
```

结果：PASS。

- 书名：`青山`
- 作者：`会说话的肘子`
- 简介：从书籍页 `.des` 摘要区提取
- 目录：当前解析到 824 个 HTML 顺序条目，包含网站原有的请假/卷总结和重复章号；未按数字重排
- 首章正文：成功，正文来自 `.con` 区域
- 中间章节正文：成功
- 最新章节正文：成功
- HTML `<p>` 已转为正文换行，未将原始标签传入 ReaderContent
- `CanonicalContent` 和 `ReaderContent` 投影成功

## 规则缺口与处理

通用 `generic-book-html-v1` 规则无法直接匹配 Sudugu 的页面形状：

1. 书籍页使用 `.container / .item / .des`，没有 `data-book-key`。
2. 目录链接位于 `#list.dir`，章节链接没有 `data-chapter-key`。
3. 章节正文位于 `<div class="con">`。
4. 作者位于可见的“作者：”链接，而不是 `meta author`。

本轮通过 `WebBookExtractionRules` 注入 `sudugu-static-html-v1` 规则，仅用于 POC 测试；通用 runtime 没有任何 Sudugu 域名、路径或分支判断。

章节 identity 在缺少站点 key 时继续使用运行时的稳定 URI + 标题 hash；目录 `orderIndex` 直接沿用 HTML 出现顺序。网站自身存在非连续和重复显示章号，XAOCEN 不擅自修正。

## 未纳入本轮

- Sudugu 搜索表单/搜索接口
- 封面图片下载
- 后台刷新和缓存
- 登录、Cookie、反爬
- Reader UI、Locator、Progress 和数据库接入

这些不是本轮 detail → TOC → chapter 验证的必要条件，留待通用规则引擎阶段单独设计。

## 测试与 Gate

- 真实 POC：通过本地 `XAOCEN_LIVE_SOURCE_URL` 显式注入后运行；仓库默认跳过：PASS
- `flutter analyze --no-pub`：PASS
- 定向 WebBook runtime tests：沿用 M5.9d-3，3 PASS
- 真实 Sudugu POC：PASS（首章、中间章、最新章均成功）
- 全量 Flutter tests：730 PASS，2 项按现有测试标记跳过（包含本 POC 的默认跳过项）
- `git diff --check`：PASS

## 结论

当前 `WebBookHttpRuntime` 与 `WebBookSource` contract 足以承载 Sudugu 这种静态公开 HTML POC，不需要大规模重构。可以进入下一步通用规则引擎阶段，但本 POC 规则应保持为独立配置，不应固化为通用 runtime 特例。
