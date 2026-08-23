# M5.7s.8e-2 — Windows Font Selector UI

## Scope

本轮仅收口 Windows 阅读设置中的字体选择器滚动体验；未修改字体加载、字体名称解析、fontId、Reader 排版、Android UI 或透明度能力。

## 实现

- 字体列表固定在 `190` logical px 高度，超出内容使用独立 `ScrollController`。
- Windows 字体列表的 `Scrollbar` 固定在左侧；列表使用 `primary: false`，不会把滚轮事件连接到外层主滚动器。
- 设置内容使用独立 `_settingsScrollController`，Windows 外层 `Scrollbar` 固定在右侧。
- 设置根部关闭自动生成的隐式 scrollbar，避免 Flutter 默认滚动条与显式滚动条重叠。
- 字体候选项使用 `ListTile.selected` 高亮当前 `fontId`；显示名使用 localized `displayName`，过长文本采用单行省略并通过 Tooltip 查看完整名称。
- 字体列表与外层设置滚动控制器在 sheet dispose 时分别释放。

## 验证

### Automated

- `flutter analyze`：PASS
- `flutter test test/widget/reader_settings_responsive_test.dart`：PASS（14 tests；包含 Windows target-platform 变体）
- `flutter test`：PASS（587 tests）
- `flutter build windows --release`：PASS
- `git diff --check`：PASS

新增/覆盖的 widget assertions：

- Windows 外层 scrollbar orientation = right
- Windows 字体列表 scrollbar orientation = left
- 字体列表为非 primary、固定高度不超过 190
- 当前字体存在 selected tile
- 360px 窄窗口无测试异常
- 原有 360/480/600/800/1024/1440 responsive settings tests 全部通过

## 结果

```
FONT INNER SCROLL = PASS (automated)
SETTINGS OUTER SCROLL = PASS (automated)
SCROLL CONFLICT = PASS (separate controllers/rails; automated)
NARROW WINDOW = PASS (automated)
FONT SELECTION REGRESSION = PASS (automated)
```

本轮未进行人工 Windows 鼠标/触控板验收；滚轮优先级和视觉轨道位置仍建议在 Release EXE 上做一次本地人工确认。

## 产物与工作区

- Windows Release EXE：
  `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- HEAD（未提交）：`af454b5b81d546cd33d720b7e3ec90395e8755b8`
- 保留此前用户已有的 dirty/untracked 文件；本轮只新增/修改字体选择器代码、对应 widget test 与本报告。
