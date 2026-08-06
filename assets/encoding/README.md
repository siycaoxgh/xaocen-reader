# assets/encoding/ — GB18030 索引资产（M0 占位）

本目录在 M0 阶段**不包含任何数据文件**（禁止放置虚假数据）。

## 正式文件（M1 生成）

| 文件 | 说明 |
|---|---|
| `gb18030_index.bin` | 紧凑二进制索引（懒加载 Asset） |
| `gb18030_index.meta.json` | 元数据：来源版本 / entryCount / anchorCount / SHA-256 |

生成器：`tool/generate_gb18030_index.dart`（M1 完成，正式实现；数据由标准来源 WHATWG
`index-gb18030.txt` + Python gb18030 codec 锚点表生成，禁止手工维护巨大 Dart 常量）。

## 二进制格式约定（v1）

- magic: `GBIX` (4B)
- version: u8 = 1
- flags: u8 = 0
- entryCount: u32 LE（双字节条目数，预期 23940）
- entries: entryCount × [pointer u16 LE, codepoint u16 LE]
- anchorCount: u32 LE（四字节锚点数，预期 209）
- anchors: anchorCount × [pointer u32 LE, codepoint u32 LE]

详细加载与校验逻辑在 M1 随 `tool/generate_gb18030_index.dart` 一并落地。
