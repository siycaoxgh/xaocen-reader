# M5.7s.8e-1 — Windows Localized Font Name Resolution

范围：仅 Windows installed-font display name resolution。未修改字体加载、fontId、
Reader metrics、pagination、Locator、Android、Transparency、Eyedropper、Tray 或
Shortcut。

## 结果

```text
DIRECTWRITE LOCALIZED NAME = PASS
ZH-CN DISPLAY = PASS（按 DirectWrite metadata 解析；本机字体列表的真人视觉验收仍取决于 Windows locale/font metadata）
IDENTITY/DISPLAY SEPARATION = PASS
FONT LOAD REGRESSION = PASS
```

## 根因与修复

现有 `windows/runner/flutter_window.cpp` 已使用 `IDWriteLocalizedStrings`，但原实现
只按固定顺序查询 `zh-CN → zh-Hans → zh → en-US → en`，没有优先读取当前 Windows
locale，也没有在这些 locale 都缺失时使用 DirectWrite 提供的第一个可用 localized
name。这会让有本地化元数据的字体在某些系统区域仍回退到 registry family name。

本轮只修改 `LocalizedFamilyName`：

1. 先用 `GetUserDefaultLocaleName` 获取当前用户 locale；
2. 再按 `zh-CN → zh-Hans → zh → en-US` 补充查询，避免重复；
3. 若上述 locale 均不存在，遍历 `IDWriteLocalizedStrings::GetCount()`，返回第一个
   非空 localized name；
4. DirectWrite 创建/查询失败时仍回退原始 family name。

没有硬编码 Microsoft YaHei/SimSun/SimHei 翻译表。

## Identity / display 分离

Windows method channel 返回结构保持不变：

- `id`：稳定的 `windows.system.file.*` identity，用于 UI/runtime choice；
- `familyName`：registry/Windows family value，作为运行时 family truth；
- `displayName`：DirectWrite localized family name，仅用于 UI 展示。

因此中文显示名变化不会改变现有 `ReaderPreferences.fontId`，也不会影响实际字体
加载或已保存的书籍设置。

## 验证

- `flutter analyze`：PASS，`No issues found`。
- `flutter test test/unit/reader_font_test.dart`：PASS，5 tests。
- `flutter test`：PASS，`585` tests。
- `flutter build windows --release`：PASS。
- `git diff --check`：PASS。

Release 产物：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

本轮没有在真实 Windows UI 中逐项点验 Microsoft YaHei、SimSun、SimHei 和英文-only
字体的最终列表文案；DirectWrite 调用链已编译通过，runtime 字符串的实际内容由系统
字体 metadata 与当前 locale 决定，不伪造具体字体名称结果。

## 保护项

- 未修改 `ReaderPreferences.fontId`、字体加载或 runtime family；
- 未增加 schema；
- 未修改 XAOCEN Reader 页面、Android 或其他平台；
- 未触碰用户已有的其他 dirty/untracked 文件。
