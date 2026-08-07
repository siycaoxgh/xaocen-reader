# M3.3 目录打开定位当前章节 + P1 深色可读性 — 结果报告

- 分支：`fix/m3-toc-current-item-scroll`
- 基线：`da1a13d`（M3.2 HEAD）
- 版本：`0.1.0-dev.3+3`（M3.3 未升版本；M4 起按里程碑升）
- 日期：2026-08-07

## 1. 交付内容

### 目录打开时定位当前章节（P1）
- `lib/domain/library/toc_index.dart`（新）：`TocIndexLogic` 纯逻辑 — `currentChapterFor`（最后一个 `startCharacterOffset <= 顶部可见` 的 chapter，位置在第一章前/无章节返回 null）、`parentVolumeIdsOf`（父卷链）、`visibleIndexFor`（折叠展开后的可见索引）。
- `_TocSheet` 重构为 StatefulWidget：
  - 卷折叠（`_collapsed` Set，volume 点击切换；当前章父卷强制展开）；
  - 自动定位（每次打开最多一次，`_autoLocated`）：initState 算 `currentChapterId`（真实可见范围顶部，`_openToc` 时实时测量）→ 父卷展开 → post-frame 两阶段定位（阶段一估算行高 jumpTo 带入构建区 → 阶段二 `ensureVisible` 对齐视口 35%）；
  - **bounded 重试**：extent 未稳定（`maxScrollExtent==0`）重试 ≤10 次；目标未进入构建区时用**实测行高**（`_measuredItemExtent`，从已构建项 RenderBox 读取）重算目标位置，重试 ≤8 次；无固定延迟；
  - 用户手动滚动后显示「定位当前章节」按钮（`_locatePressed`），不自动拉回；
  - 当前章节高亮基于真实可见范围顶部，非点击/恢复位置。
- `ReaderController`：`lastTopVisibleOffset`（真实可见顶部，供目录高亮）；`markRestoreFailed`；删除 `_postJumpTimer`（100ms 固定延迟移除）。

### 正文可见范围精确化（M3.3 附带修复）
- `_visibleRangeForScroll`：不再用 block 起始近似，改为**块内真实顶部/底部字符** — 视口顶/底与块全局坐标比对 → `RenderReaderTextBlock.characterOffsetAtLocalY` → 精确 UTF-16 偏移；布局进行中（`RenderObject.debugActiveLayout != null`）与未 attach 的 render 安全回退 block 级。
- 该修复同时提升 M3.2 目录高亮与进度保存的顶部字符精度。

### P1 深色可读性
- `lib/reader/reader_appearance.dart`（新）：`ReaderResolvedAppearance` 合同 — backgroundColor=surface、textColor=onSurface、secondaryTextColor=onSurfaceVariant、headingColor=onSurface、selectionColor=primaryContainer、baseTextStyle；对比度工具（WCAG 相对亮度、`isReadable` ≥4.5:1）。
- `lib/design/tokens/app_tokens.dart`：扩展浅色令牌；`lib/design/theme/app_theme.dart`：新增 `AppTheme.light()`；`lib/app/app.dart`：system mode 双主题。
- `RenderReaderTextBlock.style` setter：**度量变化 markNeedsLayout、仅颜色变化同步重排 + markNeedsPaint**（同一 TextPainter 显示与测量，颜色显式含在 TextSpan，不依赖 DefaultTextStyle）。
- ReaderPage 三个 Scaffold 加 backgroundColor；主题切换（didChangeDependencies 检测 `_lastTheme`）只重绘不重建 block 索引、不写进度、不改变 ReaderLocator。

## 2. 测试

- 单元：`toc_index_test`（9 项，§五/§六/§七 纯逻辑）、`reader_appearance_test`（7 项，P1 解析与对比度）— 全过。
- Widget：`toc_scroll_test`（12 项，§十）— 打开定位 258/473/450 章、折叠卷父卷自动展开、高亮可见、35% 对齐、用户滚动不拉回、关闭重开重定位、正文滚动后定位新章节、无章节「全文」、dispose 无残留、快速开关无异常；`reader_dark_mode_test`（8 项，P1）— 浅/深可读（≥4.5:1）、TextPainter 用解析色、主题切换 block 颜色更新、不改变 Locator、不写进度、全主题矩阵、loading+error 深色可见。
- **全量 250 项单元+widget 全过**；5 个保留集成测试全过（accept_real_files / hash_contract_flow / m2_android_verify / m2_library_flow / vertical_reader_flow）。
- `tool/verify.ps1` 全绿（pub get / format / analyze / 250 测试 / 5 集成 / Windows Release / APK Debug / git diff --check）。

## 3. 真实大 TXT 验收（Windows，临时验收测试已删除）

「苟在初圣魔门当人材(1-500章).txt」（473 章 3.7MB，应用真实库）：

| 请求章节 | 请求 offset | 目录高亮 | 结论 |
|---|---|---|---|
| 第1章 | 54 | 第1章 百世书 | ✅ |
| 第19章 | 49208 | 第18章（12px 安全区显示上一章尾部） | ✅ ±1 |
| 第112章 | 298039 | 第111章 | ✅ ±1 |
| 第258章 | 685040 | 第257章 | ✅ ±1 |
| 第400章 | 1062206 | 第399章 | ✅ ±1 |
| 第473章 | 1257817 | 第472章（末章前） | ✅ ±1 |

- 全部章节恢复成功、目录自动定位到目标附近（±1 章为 12px 安全区合同行为：标题行对齐视口顶部安全区后顶部可见字符属于上一章尾部）。
- 期间修复真实缺陷：目录 autoLocate 在 sheet 打开动画早期 `maxScrollExtent=0` 时 jumpTo 被 clamp 到 0（bounded 重试）；估算行高 48 与实际 dense ListTile 高度不符导致远跳偏出构建区（实测行高方案）。

## 4. 待办

- **Android 真机验证（9 项）**：设备离线（无线调试未开启），待用户开启后补做 — 书架数据存留/打开已导入书/触摸滚动/返回重开/force-stop 重开/第 400 章跳转/无章节滚动/横竖屏仍可见/0 crash。
- M3.3 停止，不自动进入 M4。

## 5. 提交

（提交列表见 git log，分支 fix/m3-toc-current-item-scroll）
