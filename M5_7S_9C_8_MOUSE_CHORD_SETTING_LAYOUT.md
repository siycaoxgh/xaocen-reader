# M5.7s.9c-8 — MouseChord Setting Copy & Layout Cleanup

正确项目目录：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## MouseChord 设置

Windows“窗口、托盘与老板键”中的固定手势现在使用标准两行设置项：

第一行：

`左右键同时按下显示/隐藏窗口`

第二行：

`鼠标左右键为固定手势，不参与普通快捷键录入。`

第二行使用当前 `ColorScheme.onSurfaceVariant` 和 `bodySmall`，不固定灰色，随 Light / Dark 主题更新。`SwitchListTile.adaptive` 负责窄窗口下的自然换行和开关空间，不改变 MouseChord 的 30ms 判定、Raw Input、Boss command 或恢复行为。

## 补充 UI 一致性筛查

按本轮追加要求，检查了取色浮层和书籍信息编辑页：

- Windows 取色预览原生浮层提示改为中文：`左键选取   Esc / 右键取消`；
- 取色预览窗口增加统一圆角区域，保留非激活、跨应用取样和原有监听生命周期；
- Metadata 编辑页的输入框和只读来源框统一为圆角 OutlineInputBorder；
- Metadata 编辑页输入区域增加主题派生的轻微 surface 对比，避免浅色/深色下边界不明显；
- 本地封面预览使用圆角裁剪，书架 placeholder 半径统一使用 `AppTokens.radiusSmall`；
- 未发现需要修改的 MouseChord、Boss、Shortcut Registry、Tray 或 Reader 行为。

## Verification

| Gate | Result | Evidence |
|---|---|---|
| MOUSE CHORD COPY | PASS | 主文案/辅助文案分层，固定手势语义保留 |
| RESPONSIVE LAYOUT | PASS | 标准 `SwitchListTile.adaptive`，说明文字可换行且不挤压开关 |
| LIGHT/DARK | PASS | 辅助文案使用当前 `onSurfaceVariant`；Metadata surface 使用当前 ColorScheme |
| MOUSE CHORD REGRESSION | PASS | 未修改 MouseChord/native timing；全量测试通过 |
| BOSS KEY REGRESSION | PASS | 未修改 Keyboard Boss；全量测试通过 |
| EYEDROPPER COPY/SHAPE | PASS | 原生预览提示中文化并设置圆角窗口区域 |
| METADATA FORM SHAPE/CONTRAST | PASS | 输入框、只读框、封面预览统一圆角并改善主题对比 |

已执行：

- `flutter analyze --no-pub` — PASS
- `flutter test --no-pub` — PASS（604 tests）
- `flutter build windows --release` — PASS
- `git diff --check` — PASS（仅工作区既有换行风格提示）

Windows Release：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

本轮未提交 Git commit，也未修改或删除其他用户未提交文件。
