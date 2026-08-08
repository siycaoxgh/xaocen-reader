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
