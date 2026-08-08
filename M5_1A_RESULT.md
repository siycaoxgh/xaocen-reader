# M5_1A_RESULT.md — ReaderPreferences 设置合同 + Drift 持久化

> 日期：2026-08-08
> 分支：`feat/m4-horizontal-reader`
> 范围：仅强类型设置合同、AppSettings、schema 3→4 与测试
> 状态：**COMPLETE**

## 1. 已完成

- 新增强类型 `ReaderPreferences`：fontSize、lineHeight、horizontalPadding、
  verticalPadding、ReaderThemeMode(system/light/dark)；
- 默认值：17 / 1.7 / 16 / 8 / system；合法范围：12–32 / 1.2–2.4 /
  0–64 / 0–48；非法、缺失、解析失败、NaN/Infinity 逐字段回退；
- 变化分类：四个排版字段属于 Metrics，themeMode 属于 Paint；
- 新增 `ReaderPreferencesRepository`：load/watch/update/resetToDefaults；
- schema 4 新增 `app_settings(key, value, updatedAt)`；字符串 key/value 不越过 Repository；
- schema 3→4 为纯增量迁移，保留书库、reading_progress、readingMode、
  ReaderLocator 和 managed TXT；
- 修复 schema 1 直接跨级升级的 readingMode 重复加列风险。

## 2. 保持不变的合同

- readingMode 不进入 ReaderPreferences，仍按书保存在 ReaderProgressState；
- ReaderLocator.absoluteCharacterOffset（normalized.txt UTF-16 code-unit offset）
  仍是唯一阅读位置真源；
- 未修改 Reader UI、未接入字号/行距/边距、未实现实时 relayout、未实现 V3 Reader 壳层。

## 3. 验证

- 新增 11 项 M5.1a 单元测试；
- `flutter analyze`：0 issues；
- `flutter test`：338/338 PASS；
- 既有 integration 测试逐文件运行：8/8 PASS；
- 覆盖默认值、合法范围、强类型接口、Metrics/Paint 分类、保存/读取/watch、
  reset、重启持久化、非法值 fallback、schema 3→4 数据保留、schema 1→4、
  storage key 不泄漏 UI/Controller/Reader。

## 4. 下一阶段边界

M5.1b 才负责 Reader 消费设置与“freeze → capture ReaderLocator → relayout →
精确恢复 → confirm → unfreeze”。本阶段完成后停止，不自动进入 M5.1b。
