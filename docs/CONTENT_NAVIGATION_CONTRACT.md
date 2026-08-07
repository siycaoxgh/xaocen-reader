# 全局内容导航合同（Content Navigation Contract）

> 状态：**长期产品设计约束**（非 0.1.x 临时方案）。
> 适用范围：TXT、EPUB 及未来其他电子书、RSS/Feed、网页文章以及其他统一内容来源。
> 生效版本：0.1.x 起，跨所有未来版本。

## 核心原则

> Content hierarchy is semantic, not interactive.
> Source order is authoritative; navigable entries remain visible.

> 层级负责表达关系，顺序负责导航，折叠不参与内容可见性。

## 规则

1. 内容层级信息允许并应当保留在 Domain/Data 层；
2. `parentId`、`level`、`kind` 等字段继续存在；
3. 层级用于：
   - 语义归属；
   - 视觉分组；
   - 搜索上下文；
   - 内容分析；
   - 导出；
   - 后续功能；
4. 层级不得自动产生 collapse/expand 交互；
5. 所有可导航内容项默认始终可见；
6. `volume/part/category/source/date` 等上级节点作为 Section Header 或视觉分隔处理；
7. 子内容不得因为上级节点状态被隐藏；
8. 不保存 collapsed/expanded 状态；
9. 不显示没有实际功能意义的展开/折叠箭头；
10. 内容导航优先使用：
    - 自动定位当前项；
    - 当前项高亮；
    - 搜索；
    - 筛选；
    - 快速索引；
    而不是折叠来解决长列表问题。

## TXT / EPUB 展示形态

```
第一卷
第1章
第2章
第3章

第二卷
第4章
第5章
```

而不是：

```
▶ 第一卷
▶ 第二卷
```

## RSS / Feed

`source/category/date` 可以作为分组标题（Section Header），
文章条目默认可见。

不得要求用户先展开来源或分类才能看到文章。

## 异常层级

即使出现：

- `parentId` 错误；
- 层级缺失；
- 多个 volume 连续；
- chapter 脱离 volume；
- EPUB 目录层级异常；
- RSS 分类异常；

都不得因此隐藏可导航内容。

稳定的 source/orderIndex 顺序优先于层级关系。

## 边界

本合同只约束「内容导航」。

设置、调试、插件管理等非内容浏览界面未来仍可根据实际交互需要使用折叠组件。

## 实现落点（当前代码）

- `lib/domain/library/toc_index.dart`：`TocIndexLogic`（纯逻辑，无 Flutter 依赖）——
  `currentChapterFor`（最后一个 `startCharacterOffset <= topVisible` 的 chapter，
  遍历全表不提前 break，容忍异常乱序；volume 不算当前章节）、
  `displayIndexFor`（flat 语义：条目在原始有序列表中的位置，无任何折叠过滤）。
- `lib/reader/reader_page.dart` `_TocSheet`：目录始终平铺显示；volume 为
  Section Header 样式（字重 + 类别标识 + 间距，无展开箭头），点击跳卷首；
  chapter 完整标题 + 当前项高亮 + 轻缩进。无 collapsed/expanded 状态。
- 测试：`test/contracts/content_navigation_contract_test.dart`（本合同固化测试）、
  `test/unit/toc_index_test.dart`、`test/widget/toc_scroll_test.dart`
  （含异常层级 fixture：幽灵 parentId / 连续 volume / 脱离 volume 的 chapter /
  无 parent 番外 → 全部平铺可见）。
