# M5_1B_RESULT.md — Reader metrics 保位重新布局

> 日期：2026-08-08  
> 基线：`6c85a49694dcb271ab0f761e0d4972e7cf090af4`  
> 状态：**IMPLEMENTATION COMPLETE / ANDROID DEVICE VALIDATION PENDING**

## 已完成

- Reader 订阅强类型 ReaderPreferences；未修改 M5.1a 设置数据模型。
- MetricsSignature 只包含 fontSize、lineHeight、horizontalPadding、verticalPadding。
- 固定流程：freeze writes → capture active confirmed ReaderLocator → apply metrics →
  invalidate layout → vertical 精确字符恢复 / paged 有限 PageWindow 重建 →
  visible/page contains 校验 → confirm → unfreeze。
- 分页重排继续从 block anchor 附近求包含 locator 的页面，不全文预分页；旧窗口和
  PagedLayoutSignature 失效。
- operation generation 拒绝旧代；快速 18→20→24→22 最终只保留 22。
- route pop、lifecycle、模式切换、resize/orientation、dispose 期间冻结的旧 Reader
  不允许写 progress。
- 未保存 scrollPixels、pageIndex、百分比或章节比例；ReaderLocator 合同未变。
- ThemeMode 未接入，留给 M5.1c。

## Synthetic 验证

- vertical fontSize / lineHeight 重排：原 locator 精确恢复且位于 visible range；
- paged fontSize / padding 重排：新 page 包含原 locator；
- metrics signature、PageWindow invalidation、generation、有限窗口、write freeze；
- 快速四连改最终 generation 生效；logical error = 0。

## Real corpus（Windows）

使用 `C:\Users\TOM\Desktop\测试` 当前全部 4 个 TXT：

- 因果快递-20260625.txt；
- 无章节数字测试.txt（7.68MB）；
- 苟在初圣魔门当人材(1-500章).txt（识别 473 章）；
- 青山(501-809章).txt。

每本验证前/中/后 3 个锚点，共 12 组。每组记录修改前 locator/page range、修改后
locator/page range；全部 `logicalError = 0`，新页面包含原 locator，窗口不超过 6 页。

## 自动验证

- `flutter analyze`：0 issues；
- `flutter test`：342/342 PASS；
- Windows real-corpus integration：1/1 PASS（4 文件、12 锚点）；
- Android Debug APK：build PASS。

## 尚待外部设备

本轮执行时 `flutter devices` 只有 Windows 与 Edge，没有 Android 设备。因此 Android
真机的 4 文件 metrics 重排尚未执行，不能宣称双平台验证完成。测试入口
`reader_metrics_real_corpus_test.dart` 支持用 `XAOCEN_REAL_TXT_DIR` 指向设备上的语料目录。

本阶段停止，不进入 M5.1c。
