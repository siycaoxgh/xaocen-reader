# M5.9b-1 — EPUB Import / Parse Foundation

## 状态

最小 EPUB 本地解析与 `ReaderContent` adapter 已完成，可冻结本阶段。
本轮没有导入 UI、数据库 schema、复杂 CSS、脚注、媒体、DRM、云同步或新的 Reader。

## 解析链路

```text
EPUB bytes/file
  -> ZIP entries
  -> META-INF/container.xml
  -> OPF package
  -> metadata + manifest + spine (原始顺序)
  -> EPUB 3 nav.xhtml 或 EPUB 2 NCX
  -> XHTML/XML 正文纯文本
  -> EpubReaderContentAdapter
  -> ReaderContent
```

正文按 spine 原始顺序拼接，使用 Dart `String.length` 保持现有 UTF-16 offset 语义；adapter 只生成运行时文档/目录投影，不写入数据库，也不改变 Locator、Pagination 或 Progress。

## 当前支持范围

- package metadata：title、creator、description
- manifest 与 spine itemref 顺序
- EPUB3 `nav` TOC
- EPUB2 NCX TOC fallback
- 基础 XHTML 文本提取，忽略 `head`、`script`、`style`、`svg`
- 目录层级与 parent relationship
- 稳定的 source/content identity 与内容 hash

暂不处理 CSS、脚注、媒体、脚本、远程资源和 DRM；后续应继续复用同一 `ReaderContent`，不能创建 EPUB 专用 Reader。
