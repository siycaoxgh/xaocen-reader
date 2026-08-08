# M5_1C_RESULT.md — Theme control + paint-only contract

> 日期：2026-08-09  
> 基线：`e37e593916cd8eb4dff5ea314f7b065f8b95b2d6`  
> 状态：**COMPLETE**

## 实现

- `XaocenApp` 通过强类型 `readerPreferencesProvider` 监听
  `ReaderPreferencesRepository.watch()`；MaterialApp 不再固定 system。
- `ReaderThemeMode.system/light/dark` 映射到 Material `ThemeMode`，数据库更新后实时生效，
  App 重建后仍从 schema 4 AppSettings 恢复。
- Reader 继续只通过 `ReaderResolvedAppearance` / `ColorScheme` 解析背景、正文、标题、
  次要文本与选中颜色；vertical 与 paged 均即时重绘。
- theme-only 变化不进入 M5.1b metrics 流程：不重建 ReaderBlockIndex、不改变 metrics
  signature、不 invalidate PageWindow、不重新分页、不 restore Locator、不写 progress。
- 未实现完整 V3 Reader UI；未进入 M5.1d。

## 验证

- system → light → dark → system 实时切换；
- Reader 打开状态下 vertical/paged 颜色更新；
- Locator 前后相同，reading_progress 零额外写入；
- paged PageWindow generation 与 controller generation 不变；
- App 重建后持久化主题仍生效；
- light/dark Reader 正文、背景与 Flat TOC 基础组件沿用 ColorScheme，可读性测试通过。

自动结果：

- `flutter analyze`：0 issues；
- `flutter test`：346/346 PASS；
- Windows integration：9/9 PASS；
- Windows Release：PASS；
- Android Debug 正常应用入口构建：PASS；
- Android 真机：**NOT-RUN / deferred to M5.1 final validation**。

## 最终构建产物

- Windows：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

Android APK 在全部 flutter test / integration test 完成后，最后通过
`flutter build apk --debug` 重新生成，不是 test runner APK。

## P1 addendum — paged → vertical 非零 Locator 恢复

- 根因来自 M4 双模式首版：纵向恢复调度时 `_mode` 仍为 paged，保护分支直接跳过恢复，
  随后过早 idle/unfreeze；非零 X 因此显示为纵向顶部。
- 修复顺序固定为 capture X → freeze → generation → 激活 vertical → 两阶段精确恢复 →
  `ReaderVisibleRange.contains(X)` → confirm X → idle → 下一帧解除程序化滚动抑制并最后 unfreeze。
- 旧 generation 在再次切换、metrics、lifecycle、route pop/dispose 时失效；不保存 pixels、
  pageIndex、百分比或 page.start，也没有 offset 0 fallback / 固定 delay。
- ReaderPreferences 仍是全局外观；ReaderProgressState 仍按 collectionId 独立保存 mode + Locator。
- 新增非零 v→p→v、p→v→p、快速切换与多书反向重复读取回归；integration 菜单改为
  强类型 `PopupMenuButton<ReaderMode>.onSelected`，不再依赖不稳定的浮层坐标 tap。
- P1 最终自动验证：`flutter analyze` 0 issues；349/349 unit/widget PASS；9/9 Windows
  integration 文件 PASS；真实目录全部 4 个 TXT、12 个 metrics anchor logical error=0，
  并对全部 4 本执行独立 mode+Locator 多轮交叉读取。
