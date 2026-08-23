# M5.9b-3 — EPUB Reader Rendering Upgrade

## 结论

本阶段完成统一 Reader 的 EPUB 基础渲染升级，可冻结。实现采用“规范化正文 + 渲染旁路元数据”：正文文本、UTF-16 偏移、分页和进度仍使用现有链路；样式与图片只作为可选 presentation metadata，不改变 Locator truth。

## 修改文件

- `lib/domain/reader/reader_rendering.dart`
  - 新增 source-neutral `ReaderRenderingMetadata`、`ReaderInlineStyleRun` 和 `ReaderImagePlacement`。
  - 元数据使用 UTF-16 范围/锚点和受管本地路径，不保存 EPUB 外部路径或远程 URL。
- `lib/sources/epub/epub_models.dart`
  - 为 spine 文档增加样式区间、图片引用和受支持的 EPUB 资源模型。
- `lib/sources/epub/epub_parser.dart`
  - 在保留原始 spine 顺序的同时提取标题/段落/换行、基础粗体/斜体、heading 标记和本地图片引用。
  - 仅映射安全的 `font-weight` / `font-style`，支持标签、class、id 和 inline style；不执行脚本。
- `lib/sources/epub/epub_reader_content_adapter.dart`
  - 将 spine 的 presentation annotations 转换为全书统一 UTF-16 偏移的渲染元数据。
- `lib/data/repositories/local_library_repository.dart`
  - 导入时把引用的 PNG/JPEG/GIF/WebP 复制到 `library/epub/<contentHash>/images/`，并把受管路径写入现有 manifest。
  - 没有新增 Drift 表或第二套正文存储。
- `lib/reader/normalized_document_loader.dart`
  - 从现有 manifest 可选读取渲染元数据；旧 TXT/旧 EPUB manifest 无该字段时保持原行为。
- `lib/reader/reader_typography_layout.dart`
  - TextPainter 以区间 TextSpan 绘制粗体/斜体；测量和绘制使用同一组 runs。
- `lib/reader/reader_text_block.dart`
  - 将样式区间传入现有文本 RenderObject，保持 paint-only。
- `lib/reader/paged_layout_engine.dart`、`lib/reader/paged_reader_controller.dart`、`lib/reader/paged_reader_view.dart`
  - 分页测量复用同一样式 runs；图片作为旁路元数据按当前页锚点显示，不写入正文字符。
- `lib/reader/reader_page.dart`、`lib/reader/reader_epub_image.dart`
  - 纵向正文按图片锚点分块并显示受管本地图片；损坏/缺失图片回退 alt 文本或空占位。
- `lib/domain/reader/reader_block.dart`
  - 可选按图片锚点切分视觉块；默认 TXT 行为不变。

## 渲染能力

- **标题/段落/换行：PASS** — block 元素产生稳定换行，spine 连接仍为原顺序。
- **基础粗体/斜体：PASS** — `<b>/<strong>`、`<i>/<em>/<cite>`，以及安全 CSS 的 `font-weight` / `font-style`。
- **基础标题层级：PASS** — h1–h6 被记录为 heading run 并以粗体呈现；本轮不引入新的排版尺寸体系。
- **内嵌图片：PASS** — 支持本地 EPUB 内的 PNG/JPEG/GIF/WebP；导入后使用受管路径。纵向按锚点显示，分页在图片锚点所在页显示图片。资源损坏时不会崩溃。
- **基础 CSS：PASS（有限范围）** — 只处理可证明安全的标签/class/id/inline 规则以及字体粗斜体声明。

## Locator / Progress 保护

`normalized.txt` 的文本内容仍是 Reader 的唯一正文输入。样式范围和图片锚点都不插入、删除或重排正文字符，因此：

- absolute UTF-16 Locator：PASS
- ReaderProgress / TOC document ranges：PASS
- Vertical / Paged 现有导航合同：PASS
- 旧 TXT（没有 rendering sidecar）：保持原渲染路径

图片本身不消耗字符偏移；分页只改变图片的展示位置，不改变文本页范围或持久化偏移。

## 兼容边界

本轮明确不支持：

- JavaScript、脚本事件和 DRM
- 远程 URL、网络资源和 data URL 图片
- SVG、音视频和复杂媒体
- 复杂 CSS（布局、浮动、颜色、字体文件、选择器组合、伪元素等）
- 复杂脚注、交互式注释和 EPUB 特殊阅读系统

这些内容会被安全忽略或回退为可读文本，不会阻断导入或 Reader 启动。EPUB / RSS / 在线书源仍复用同一 `ReaderContent` 扩展点，不创建第二套 Reader。

## 验证

- `flutter analyze --no-pub`：PASS（No issues found）
- EPUB parser / persistence / typography / paged rendering 定向测试：PASS（51 tests）
- 全量 Flutter tests：PASS（670 tests）
- `git diff --check`：PASS（仅工作树既有 LF/CRLF 转换提示，无 whitespace error）

## 阶段状态

**EPUB READER RENDERING = PASS / FROZEN WITH DOCUMENTED LIMITS**

## M5.9b-3.1 Closure

分页图片布局已完成最小修复：正文先使用已测量的页面高度，图片仅使用页面剩余的有界空间；图片仍是 presentation sidecar，不进入 normalized text，不改变 UTF-16 Locator、分页索引或 ReaderProgress。书架导入入口已改为通用文案“导入书籍”。

真实 EPUB 回归确认：分页图片不再出现黄黑 overflow 提示条；斜体英文 `Alpha Blaster` / `Blastar` 已在 Android 模拟器中人工确认；完整 Flutter tests 为 672 tests，全部通过。

因此 M5.9b-3 可完全冻结，复杂 CSS、脚本、DRM、远程资源等既有兼容边界保持不变。
