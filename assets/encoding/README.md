# assets/encoding/ — GB18030 索引资产

## 正式文件（M1 生成，勿手工编辑）

| 文件 | 说明 |
|---|---|
| `gb18030_index.bin` | 紧凑二进制索引（懒加载 Asset） |
| `gb18030_index.meta.json` | 元数据：来源版本 / entryCount / anchorCount / SHA-256 |

生成器：`tool/generate_gb18030_index.dart`
（运行 `dart run tool/generate_gb18030_index.dart --input <whatwg.txt> --out assets/encoding`）

生成器重复运行产生相同字节（entries 按 pointer 升序、anchors 固定顺序）。

## 二进制格式 v1（小端）

```
offset  size  field
0       4     magic "GBIX"
4       1     formatVersion (1)
5       1     flags (0)
6       4     entryCount (u32 LE = 23940)
10      n     entries: entryCount × [pointer u16 LE, codepoint u16 LE]
10+n    4     anchorCount (u32 LE = 209)
14+n    m     anchors: anchorCount × [pointer u32 LE, codepoint u32 LE]
```

运行时加载（`lib/sources/local_txt/gb18030_index_loader.dart`）验证：
magic、formatVersion、长度与 entryCount/anchorCount 一致性；失败抛
`Gb18030IndexException`（明确报错，不静默回退乱码）。

## 数据来源与许可证

- **双字节映射**：WHATWG Encoding Standard `index-gb18030.txt`
  （2024-09-18 snapshot，23940 项）。WHATWG 文档采用 CC BY 4.0 / BSD 兼容许可。
- **四字节锚点表**：209 项，经 Python 内置 gb18030 codec 逐 pointer 验证
  （Python 的 gb18030 映射本身来自国家标准 GB 18030-2005，Python 软件基金会许可）。
- 解码时对 0x80 字节输出 U+FFFD（与 Python/Java/Windows 一致，不采用 WHATWG 的
  U+20AC 特殊映射），保证 Windows/Android 输出一致。

## 更新方式

上游 index 变更时：重新获取 WHATWG 文件 → 运行生成器 → 提交 bin + meta。
禁止手工编辑二进制或 meta。
