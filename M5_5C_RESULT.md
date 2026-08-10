# M5.5c Reader 操作层级

日期：2026-08-11

## 操作层级

- 顶部保留返回、书名、阅读模式和章节/全书进度。
- Android 底栏收敛为目录、模式、书签、界面（Aa）、更多五个高频入口。
- Windows 保持桌面限宽控制区，额外显示搜索和自动阅读；按钮不脱离既有 Reader chrome。
- Android 的搜索和自动阅读位于“更多阅读操作”面板，面板明确说明低频操作集中于此；朗读保持 disabled 且明确未实现。
- 所有按钮保留现有 key/回调语义，使用 InkWell/语义按钮提供点击反馈。

## 行为合同

- 仅显示/隐藏 Reader chrome 不暂停 AutoRead。
- 打开 Aa、目录、书签、搜索或自动阅读面板继续 pause，关闭面板不自动 resume。
- ReaderLocator、PageWindow、AutoRead driver、ReadingSession、章节/全书进度和 Drift schema 6 均未修改。
- 小屏使用紧凑五项底栏；Windows 保持 520 logical-pixel 限宽控制区，避免无限横向扩张。

## 验证

- `flutter analyze`：PASS
- Flutter tests：455/455 PASS
- Windows integration：11 files / 14 scenarios PASS
- Windows Release：`build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android Debug：`build\\app\\outputs\\flutter-apk\\app-debug.apk`
- `git diff --check`：PASS
