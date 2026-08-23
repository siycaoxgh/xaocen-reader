# M5.9a-2 — ReaderContent / Source Adapter Contract

## 状态

本阶段已完成窄接入，可冻结。EPUB、RSS 与在线书源仅保留扩展点，未实现。

## 职责边界

`ContentDocument` 是持久化层的文档行，负责稳定的 `storagePath`、媒体类型、文档范围、内容哈希和规范化版本。`LibraryDocument` 是该行的领域投影。

`ReaderContent` 是 Reader 运行时的、只读的统一内容聚合，负责把现有 collection metadata、document projections、navigation/TOC 和规范化 UTF-16 文本长度组合为 Reader 输入。它不负责数据库写入、文件字节、分页、阅读进度或 Locator 状态。

因此 Reader 的绝对 UTF-16 Locator 仍是唯一位置真相；本契约只传递已有的文档和目录偏移，不重新计算或重排它们。

## 最小契约

- `ReaderContentIdentity`: `contentId`、`sourceId`、`sourceKind`、可选 `sourceRevision`
- `ReaderContentMetadata`: title/author/description 及 metadata/title/author source
- `ReaderContent.documents`: 只读 `LibraryDocument` 投影
- `ReaderContent.navigation`: 只读、保持源顺序的 `LibraryTocEntry` 投影
- `ReaderContent.normalizedCharacterLength`: 已规范化正文的 UTF-16 长度
- `ReaderContent.primaryDocument`: 兼容当前 TXT Reader 首个 normalized document 的启动语义

`ReaderContentAdapter` 是 source-specific 到该契约的唯一转换入口。`ReaderContentAdapterRegistry` 是选择入口；未知来源返回 `unknown`，不会伪装成 TXT。

## TXT 接入

`TxtReaderContentAdapter` 识别现有 `local-txt-source:` source id，复用当前 collection/document/TOC projections，保留 metadata 来源、文档顺序和绝对 UTF-16 偏移。可用时以 normalized document hash 作为 source revision。

`ReaderLaunchContext` 保留原有字段以兼容现有调用方，同时提供惰性 `resolvedContent`。Reader 仅将当前既有的文档加载入口改为从该契约取得 `primaryDocument` 和规范化长度；Locator、分页、进度和 Reader UI 均未重构。

## 后续扩展

后续 EPUB/RSS adapter 只需产出同一 `ReaderContent`，不应创建第二套 Reader、Locator 或 Progress。网络获取、缓存和同步边界不属于本阶段。
