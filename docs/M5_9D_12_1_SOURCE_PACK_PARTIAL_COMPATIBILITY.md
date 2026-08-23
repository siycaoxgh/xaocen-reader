# M5.9d-12.1 — Source Pack + Partial Compatibility Model

项目：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
输入：`C:\Users\TOM\Desktop\测试\新建文件夹`
扫描日期：2026-08-19

## 1. Source Pack schema

新增版本化容器 `xaocen.webBook.source-pack`，当前 `version = 1`：

```json
{
  "schema": "xaocen.webBook.source-pack",
  "version": 1,
  "packId": "legacy-static-text-pack-v1",
  "name": "Legacy Static Text Source Pack",
  "generatedAt": "...",
  "sources": [
    {
      "sourceId": "legacy-...",
      "legacySourceId": "legado:...",
      "sourceName": "...",
      "compatibility": "RUNNABLE_PARTIAL",
      "sourceFile": "...",
      "source": { "schema": "xaocen.webBook", "version": 1 },
      "legacy": {
        "sourceId": "legado:...",
        "sourceFile": "...",
        "fields": { "ruleSearch.coverUrl": "..." }
      },
      "reasons": []
    }
  ]
}
```

`source` 只有在当前 XAOCEN runtime 可以运行核心规则时才存在；`legacy.fields`
保留未映射 Legacy 字段和原始来源信息。Pack 是文档/传输边界，不会自动写入
WebBook Registry，也不会发起网络请求。单条 source 的解析或校验失败只记录在该
entry，不阻断其他 entries。

输出文件：

- [Source Pack](/C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/docs/M5_9D_12_1_LEGACY_SOURCE_PACK.json)
- [Pack 统计报告](/C:/Users/TOM/Desktop/xaocen-reader-v4/xaocen_reader/docs/M5_9D_12_1_LEGACY_SOURCE_PACK_REPORT.json)

## 2. 四档兼容判定

| 等级 | 判定 | 是否含可执行 source |
|---|---|---|
| `FULL` | 搜索、详情、TOC、正文核心规则全部可映射，且没有未映射语义 | 是 |
| `RUNNABLE_PARTIAL` | 核心四段可以运行；cover、kind、lastChapter、explore 等可选 Legacy 字段未映射，但已原样保留 | 是 |
| `NEEDS_CAPABILITY` | 需要补充能力才能可靠执行核心链路，例如 XPath、JSON API、认证、复杂 selector 或动态请求 | 否 |
| `UNSUPPORTED` | 依赖 JS/WebView/音频/图片章节，记录无效，或属于当前纯文本 WebBook 明确不支持的类型 | 否 |

旧的 `AUTOMATICALLY_CONVERTIBLE` 只作为扫描器证据，不再直接等同于可转换成功。
转换器会二次验证核心 selector、endpoint 和请求语义；可选字段不会单独使核心草稿
失败。

## 3. 3,587 条唯一记录重新分类

输入目录共读取 7,174 条记录，去除重复导出后为 3,587 条唯一记录。

| 兼容等级 | 数量 |
|---|---:|
| `FULL` | **0** |
| `RUNNABLE_PARTIAL` | **0** |
| `NEEDS_CAPABILITY` | **1,201** |
| `UNSUPPORTED` | **2,386** |
| 合计 | **3,587** |

本批没有可直接执行的 FULL/PARTIAL 实际书源。旧扫描器标记的静态候选在二次核心
验证中仍普遍包含 `@tag.*`、`##`、嵌套目录链接、无效 endpoint 等核心阻断，因而
被记录为 `NEEDS_CAPABILITY`，没有把它们误报成可运行部分转换。

需要特别说明：转换器对可运行核心 + 可选字段的逻辑已由离线 fixture 验证；fixture
带有 `ruleSearch.coverUrl` 时得到 `RUNNABLE_PARTIAL`，cover 字段被保留而不影响
搜索/详情/TOC/正文草稿。真实 3,587 条样本中没有同时满足这一条件的记录。

## 4. 代码与测试

新增/修改：

- `lib/sources/remote/xaocen_source_pack.dart`
- `lib/sources/remote/legacy_source_pack_converter.dart`
- `lib/sources/remote/legacy_static_text_converter.dart`（增加非强制 scanner gate，仅供 Pack 层复用）
- `tool/legacy_source_pack_convert.dart`
- `test/unit/legacy_source_pack_test.dart`

保持不变：Registry、Reader、Locator、Progress、数据库 schema、JS/WebView/登录能力。

离线定向 fixture：**14 tests PASS**（scanner、旧严格转换器、Pack/Partial 模型）。

## 5. Gate

- `flutter analyze --no-pub`：**PASS**
- 定向测试：**PASS**（14 tests）
- 全量 `flutter test`：**PASS**（759 passed，3 skipped）
- `git diff --check`：**PASS**（无 diff 检查错误；仅有既存换行提示）

## 6. 下一步建议

1. 从 `NEEDS_CAPABILITY` 中人工挑选少量 CSS 核心规则样本，确定是否值得增加有限
   的 Legacy selector 转换（仍不做 XPath/JS 通用执行）。
2. 对 `RUNNABLE_PARTIAL` fixture/未来样本做单源真实 HTTP 抽样；不得批量导入。
3. 只有人工确认通过后，才考虑一个显式的“从 Pack 选择性导入”流程；本阶段不导入。

当前状态：**PARTIAL COMPATIBILITY MODEL = PASS；真实源抽样 = READY FOR MANUAL REVIEW**。
