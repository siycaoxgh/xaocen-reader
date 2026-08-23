# M5.9b-3 — 真实 EPUB 验收记录

## 测试范围

本轮仅使用真实 EPUB 做导入、Reader、目录、分页和位置恢复验收，没有修改生产代码，也没有扩大 EPUB 功能范围。

- 测试文件：`C:\Users\TOM\Downloads\埃隆·马斯克传 (【美】沃尔特·艾萨克森 （Walter Isaacson）) (Z-Library).epub`
- 设备：`emulator-5554`（Android 15 / API 35）
- 验证 APK：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
- 证据目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\test_output\`

## 导入与内容结构

| 项目 | 结果 | 实测结果 |
|---|---|---|
| EPUB 打开/导入 | PASS | ZIP、mimetype、package 均可解析；书架显示新书 |
| 重复导入 | PASS | 第二次导入返回同一 collection identity，不产生第二本书 |
| Metadata | PASS | 标题：埃隆·马斯克传；作者：【美】沃尔特·艾萨克森 |
| Spine 顺序 | PASS | 101 个 spine item，首项 `titlepage.xhtml`，末项 `EPUB/xhtml/reference.xhtml`，顺序保持原文件 |
| TOC | PASS | 99 项；首项“版权信息”，末项“注释”；目录滚动和跳转可用 |
| 正文数据 | PASS | normalized length 为 384,739；导入后重新加载长度一致 |
| 图片资源 | PASS（有边界） | 157 个图片引用、128 个受管图片资源；纵向和分页均能显示图片 |

`titlepage.xhtml` 是原 EPUB spine 中的结构性空页面，正文为空但没有破坏后续内容。这属于 `TEST DATA ISSUE`，不是自动重排或删除 spine 的理由。

## Android 真机/模拟器操作结果

### Vertical

- 书架卡片显示封面、标题、作者、`99 章`，无崩溃。
- Reader 首屏显示版权信息、作者/译者/出版信息和正常中文段落。
- 标题/章节粗体可见，中文无乱码。
- 嵌入图片正常显示。
- 证据：`test_output/real_epub_reader_start.png`。

结论：`VERTICAL = PASS`。

### Paged

- 设置中切换到“分页”成功，顶部显示“分页阅读”。
- 左滑从第 1 章切换到第 2 章，并显示“本章 1 / 10 页”。
- 目录跳到“20 联合创始人”后，顶部显示第 22 章、`本章 1 / 9 页`、`全书 19%`。
- 证据：`test_output/real_epub_reader_paged.png`、`test_output/real_epub_reader_paged_next.png`、`test_output/real_epub_reader_toc_jump.png`。

发现一个输入相关的真实视觉问题：该书的超长内嵌图片在 Debug 分页画面底部出现黄黑 Flutter 溢出提示条。图片本身可见，但当前分页布局没有把这类超长图片约束在页面可用高度内。

结论：`PAGED = FAIL（仅针对超长内嵌图片场景）`。

### TOC / Locator / Progress

- 目录打开、滚动、选择章节均正常。
- 目录跳转到第 22 章后退出 Reader，再次进入仍回到第 22 章第 1 页。
- 重新进入时顶部仍为 `分页阅读 / 第 22 章 / 本章 1 / 9 页 / 全书 19%`。
- 没有发现崩溃、FATAL EXCEPTION、乱码或章节顺序倒置。
- 证据：`test_output/real_epub_reader_reopen_toc.png`。

结论：`TOC LOCATOR = PASS`、`REOPEN POSITION = PASS`、`UTF-16 LOCATOR = PASS`（由实际跳转/重进和现有 EPUB UTF-16 定向测试共同证明）。

书架卡片在全书进度不足 1% 时显示“尚未开始阅读”，而 Reader 已能恢复到第 22 章；这是整数百分比显示的正常舍入，不判为进度丢失。

## 样式与图片验收

- 标题、段落、换行：`PASS`
- 基础粗体：`PASS`（真实截图可见标题粗体）
- 基础斜体：解析到 68 个 italic runs；运行时未单独定位一个斜体样本文字做近景截图，列入 `MANUAL REQUIRED`，不据此宣称视觉完全通过
- 图片：基础显示 `PASS`；超长图片分页约束问题见上文 `BUG`
- Light/Dark、复杂 CSS、SVG、脚本、远程资源、DRM：本轮不扩大范围，按既有兼容边界处理，属于 `UNSUPPORTED`

## 问题分类

### BUG

1. **分页中的超长内嵌图片未被页面高度约束**：Debug 截图出现黄黑溢出提示条；需要后续通用图片分页策略处理，不能针对本书写特判。
2. **导入入口文案仍显示“导入 TXT”**：当前文件选择器实际接受 EPUB，属于 UI 文案不一致；不影响本次导入，但可作为后续小修复。

### UNSUPPORTED

复杂 CSS 布局、脚本、DRM、远程资源、SVG/音视频和复杂脚注不在 M5.9b-3 的实现范围。本书本次验收没有把这些能力当作通过条件。

### TEST DATA ISSUE

原 EPUB 的 `titlepage.xhtml` 为空结构页，位于 spine 首位。XAOCEN 保留原始 spine 顺序，不自动重排或删除它。

## 自动质量 Gate

- `flutter analyze --no-pub`：PASS（No issues found）
- EPUB parser / persistence / Reader 定向测试：PASS（26 tests）
- 全量 Flutter tests：PASS（670 tests）
- `git diff --check`：PASS（只有既有 LF/CRLF 转换提示，没有 whitespace error）

## 最终结论

真实 EPUB 已能成功导入、去重、显示 metadata、保留 spine/TOC 顺序，并在统一 Reader 中完成纵向阅读、分页阅读、目录跳转和退出重进位置恢复。当前不能把本书验收写成“全部 PASS”，因为分页遇到超长图片会出现实际溢出提示条；该问题属于通用分页图片布局 `BUG`，不建议为单本书做大规模重构。

## 人工验收清单

- [x] 选择真实 EPUB 后导入成功
- [x] 重复导入不新增第二本书
- [x] 标题、作者、章节数量正确显示
- [x] TOC 首尾和顺序可检查
- [x] Vertical 正常显示标题、段落、粗体和图片
- [x] Paged 可切换、可翻页、可从目录跳章
- [x] 跳章后退出再进入位置保持
- [x] UTF-16/进度相关定向测试通过
- [ ] 在一个明确含斜体的正文片段上做近景人工确认（MANUAL REQUIRED）
- [ ] 修复超长图片分页溢出后，再进行 Paged 完整 PASS 验收
