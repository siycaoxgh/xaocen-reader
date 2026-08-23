# M5.9c-1 — Content Transform Contract

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 阶段结论

**CONTENT TRANSFORM CONTRACT = PASS / FROZEN**

本阶段只建立平台中立契约，没有接入净化、查找替换、翻译服务，也没有修改 Reader、Locator、Pagination、Progress 或数据库 schema。

## 修改文件

- `lib/domain/reader/content_transform.dart`
  - `CanonicalContent`：不可变的源文本、content identity 与 source revision。
  - `DerivedContent`：带 transform provenance 的临时/缓存结果。
  - `ContentTransform`：未来净化、替换、翻译实现的统一接口。
  - `ContentPositionMap` / `ContentPositionAnchor`：canonical ↔ derived UTF-16 范围映射。
  - `ContentMappingQuality`：`exact`、`coarse`、`unavailable` 三种边界语义。
  - `IdentityContentTransform`：验证适配器的无变换边界。
- `test/unit/content_transform_contract_test.dart`
  - UTF-16 长度、精确映射、删除空洞、替换粗粒度映射、provenance 与重叠 anchor 校验。

## Contract 设计

```text
CanonicalContent (唯一 ReaderLocator 坐标空间)
        │
        ▼
ContentTransform.apply()
        │
        ▼
DerivedContent + ContentPositionMap
```

### Canonical 与 Derived 分离

`CanonicalContent.text` 是当前来源的规范文本；`DerivedContent.text` 只用于展示、净化、替换或翻译后的派生视图。派生文本携带原始 `contentId`、`sourceRevision`、transform id/version，不拥有进度或数据库写入权。

### Locator 边界

所有长度和范围均使用 Dart `String.length`，即 UTF-16 code-unit 坐标。`ContentPositionMap` 明确描述每个派生范围对应的 canonical 范围：

- `exact`：等长、逐码元对应，可以安全得到 canonical offset；
- `coarse`：只能定位到源范围，不能伪装成精确 offset；
- `unavailable`：删除或无对应内容，不能生成 Locator。

`DerivedContent.canPersistCanonicalLocator` 只有在全量 exact、无缺口、等长映射时为 true。调用方必须继续保存 canonical `ReaderLocator`，不得把 derived offset 当作位置真源。

### 未来实现边界

净化/广告移除、查找替换和翻译都实现同一个 `ContentTransform`，但必须提供可审计的映射质量。若无法可靠映射，必须保留 canonical 位置并标记不可精确回写，而不是静默移动书签、进度或阅读位置。

## 验证

- `flutter analyze --no-pub`：PASS
- `test/unit/content_transform_contract_test.dart`：PASS（6 项）
- Reader / Locator / Progress / Pagination / 数据库 schema：未修改
- 全量 Flutter tests：PASS（686 项）
- `git diff --check`：PASS（仅现有换行格式提示，无 whitespace error）

## 是否可冻结

契约边界已足够支撑下一阶段，不需要大规模重构；本阶段可冻结并进入 M5.9c-2。
