# M5.7s.9c-5 — Book Metadata Editor Responsive Layout

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\aocen_reader`

## 实现

- 保存动作移到编辑页 AppBar 右侧，页面正文不再放置底部主保存按钮。
- 使用 `LayoutBuilder` 按 available width 响应式切换，阈值为 720 logical px；没有使用平台特判。
- 宽布局：左侧为书名、作者、简介及只读来源信息，右侧为较小的 2:3 封面预览和封面操作。
- 窄布局：书名、作者、简介 → 封面与操作 → 原文件名/来源；正文可滚动但保存始终在顶部。
- 封面预览宽度固定为 128 logical px（2:3，192 logical px 高），避免旧版大面积封面占据页面。
- 保存、取消、恢复自动识别、选择/移除封面的既有回调和数据路径保持不变；未修改 metadata 模型、cover repository、collection identity 或阅读状态。
- Light/Dark 继续使用当前 App Theme，没有新增固定背景色。

## 验证

| 项目 | 结果 | 证据 |
|---|---|---|
| WIDE LAYOUT | PASS | `test/widget/metadata_edit_page_test.dart`：1200×800 下字段与封面并排 |
| NARROW LAYOUT | PASS | 同测试：390×844 下纵向排列且无异常 |
| COVER SIZE | PASS | 测试断言 128×192（2:3） |
| TOP SAVE ACTION | PASS | 测试断言 `metadata-editor-save` 位于 AppBar |
| METADATA EDIT REGRESSION | PASS | 全量 Flutter tests：603 passed |
| COVER ACTION REGRESSION | PASS | 既有书架 metadata 编辑测试及全量测试通过 |

执行结果：

- `flutter analyze`：PASS（No issues found）
- `flutter test --no-pub`：PASS（603 tests）
- Windows Release：PASS
- Android Debug：PASS
- `git diff --check`：PASS（仅有既有 CRLF 提示，无 whitespace error）

构建产物：

- Windows：`C:\Users\TOM\Desktop\xaocen-reader-v4\aocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android：`C:\Users\TOM\Desktop\xaocen-reader-v4\aocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

本轮未提交 Git commit，保留工作区原有用户修改。
