# M3.1 Hash 合同修复结果

日期：2026-08-07
分支：fix/m3-normalized-hash-contract
基线：ab866d7（M3 最终 HEAD）

## 1. 根因

**Drift `content_documents.content_hash` 误存 sourceHash，而 ReaderPage 把它当作 expectedHash 传给 Loader 校验 normalized.txt 落盘字节。**

- M2 `_writeDatabase` 写入 `contentHash: sourceHash`（源文件 hash），注释称"文档范围内容 hash"，但实际从未存 normalizedHash；
- M3 `reader_page.dart` `setDocumentSource(expectedHash: doc.contentHash)` 把这个 sourceHash 传给 Loader；
- `NormalizedDocumentLoader` 用 expectedHash 校验 normalized.txt 实际字节 SHA-256 → source≠normalized 时必然 `hash_mismatch`；
- manifest.normalizedHash 一直是**正确**的（写入顺序本身无误），问题只在 Drift 记录与 Loader 取值。

## 2. 失败 collection 是旧导入还是新导入

**新导入（fresh M3 import）必然失败，旧导入同理**——两者共用同一 `_writeDatabase` 写入路径。现场 4 个 collection（created_at 1786058144~1786058474，2026-08-06 23:15~23:21）均为用户手动导入的新数据，全部中招。

## 3. expected hash 对应的实际对象

`2528925c0ee3946ccedd5911b10d6acaba6e4c592c53feb230d317a5a4aa79db`
= **source.txt 字节 SHA-256**（= managed 目录名 = Drift content_hash 记录值）。

## 4. actual hash 对应的实际对象

`d37db97a98372402b0379db75d0624bac4f65d42b7762c28bc94851b59102770`
= **normalized.txt 落盘字节 SHA-256**（= manifest.normalizedHash 正确值）。

## 5. 首个差异位置

不适用（不是内容差异——两个 hash 本就是不同对象的 hash）。文件层完全健康：
`manifest.normalizedHash == normalized.txt 实际 hash == regenerated（从 source 重跑）`，全部为 True。

## 6. 为什么小文件正常、大文件失败

小 TXT（如 6160f6a4，657901B）本身无 CRLF/BOM，规范化后**字节不变** → sourceHash == normalizedHash → 即使拿 sourceHash 校验也碰巧通过。真实大 TXT 是 CRLF 行尾，规范化（CRLF→LF）改变字节 → sourceHash ≠ normalizedHash → 必然失败。**与文件大小无关，与"规范化是否改变字节"有关**；大文件必然含 CRLF 所以必现。

## 7. 最终 normalizedHash 合同

```
normalizedHash = 最终落盘 normalized.txt（无 BOM UTF-8 文件字节）的 SHA-256
```

- 所有位置必须使用同一值：manifest.normalizedHash / Drift content_documents.content_hash / NormalizedDocumentLoader 校验 / 导入完成检查 / repair 完成检查；
- 禁止：String.hashCode、UTF-16 码元转字节 hash、source.txt hash、内存字符串另一套编码 hash、index.json hash、局部范围 hash；
- 共享强类型 `NormalizedArtifact`（filePath/utf8ByteLength/utf16CharacterLength/sha256/normalizationVersion）已建立，导入器、manifest 写入器、Drift 写入器、Loader 消费同一结果；
- 写入顺序（§六）：生成文本 → 写 tmp → flush → close → 从落盘字节算 SHA-256 → 重解码验证 UTF-16 长度 → 原子 rename → 同一 artifact 写 manifest → Drift 事务写同一 hash/长度 → 重读最终校验 → completed；
- Loader 以 **manifest.normalizedHash 为权威**（manifest 与文件原子写入），expectedHash 仅作 manifest 缺失回退。

## 8. 已有数据 repair 结果

`CollectionRepairService` + `ManagedCollectionHealthCheck` 对真实库执行：

| collection | 修复前 | 修复后 |
|---|---|---|
| 2528925c（青山501-809，294章） | sourceOk✓ normalizedOk✓ **dbConsistent✗** | ok✓ dbConsistent✓ |
| 12b6e8af（无章节数字测试，1 whole） | 同上 | ok✓ dbConsistent✓ |
| 9ace0b9b（苟在初圣魔门，473章） | 同上 | ok✓ dbConsistent✓ |
| 6160f6a4（因果快递，53章） | 全健康 | 无需修复 |

821 条 document 记录 hash 已全部更新为 normalizedHash；外部 TXT 未被修改（hash 前后一致）；修复前后源库已备份（sqlite + library 目录）。

## 9. 两个真实 TXT 结果

- 苟在初圣魔门(1-500章).txt（3707874B，UTF-8，473章）：修复后 Reader 打开成功，目录 473 章；
- 无章节数字测试.txt（8054340B，UTF-8，0章）：修复后健康（不伪造目录）。
- 另验证青山(501-809章).txt（用户报错的 2528925c）：**Reader 打开成功、正文渲染、无 hash_mismatch、目录 294 章、跳到第31章@192296 成功**。

## 10. Windows 结果

- verify.ps1 全绿：pub get / format / analyze / **185 单元+widget** / 5 集成测试 / Windows Release（38.4s）/ APK Debug（22.7s）/ git diff --check；
- 真实验收：真实库 4 本修复 → Reader 打开 + 目录跳转集成测试通过；
- hash_contract_flow_test（大 fixture 导入→关闭→重开→Loader→Reader 首屏）通过。

## 11. Android 结果

设备离线未执行（无线 ADB 未连接）。APK Debug 已重新构建（verify 通过后保证正常应用入口，非 test runner）。Android 与 Windows 共用同一 Dart 代码路径（hash 来自落盘字节、manifest 权威），待设备恢复后执行真机验证（§十二 9 项）。

## 12. 测试数量

单元+widget：**185**（原 160 + 新增 25：hash_contract 11 + repair_service 12 + loader 语义更新 2）
集成：**5 个文件全过**（accept_real_files / hash_contract_flow / m2_android_verify / m2_library_flow / vertical_reader_flow）
覆盖 §十一 全部 20 项：13/13b/14/15/17/18（hash 合同+跨块+8MB）、2（8MB 闭环）、5/6/7/8（Loader 各损坏场景）、9/10/11/12/19/20（repair 全场景）、alreadyImported 三种分支。

## 13. 构建结果

- Windows Release：`build\windows\x64\runner\Release\xaocen_reader.exe` ✅
- Android Debug：`build\app\outputs\flutter-apk\app-debug.apk` ✅（verify 后重新构建，正常应用入口）

## 14. 最终 HEAD

```
76cc82c tool(fix): add readonly managed txt inspector and sqlite3 dep
6652c32 test(fix): cover hash contract, repair flows and cross-session reopen
ef3c4f4 fix(import): add managed health check and collection repair service
b96d338 fix(reader): trust manifest normalizedHash and add repair entry on mismatch
26d74e5 fix(storage): derive normalizedHash from on-disk bytes and store it in drift
（基线 ab866d7）
```

## 15. 工作区状态

clean（5 个 commit 已提交，分支 fix/m3-normalized-hash-contract）。

## 附带交付

- `tool/inspect_managed_txt.dart`：只读诊断（--dir / --db --collection，输出各 hash/长度/一致性 + regenerated 对比，不输出正文）；
- `lib/domain/library/normalized_artifact.dart`：共享强类型；
- `lib/data/repositories/managed_collection_health.dart` + `collection_repair_service.dart`；
- Reader 错误页：hash_mismatch 显示"书籍文件需要修复"+[返回书架][修复并重试]（Debug 保留 expected/actual/collectionId，Release 不显示内部路径）；
- alreadyImported：健康→alreadyImported / 不健康但 source 有效→repairExisting / source 无效→corruptedManagedCopy。
