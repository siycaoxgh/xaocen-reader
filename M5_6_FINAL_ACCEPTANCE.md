# M5.6 Final Automated Acceptance

日期：2026-08-12  
HEAD：`a65fda5904d45a3820c53fa757872ba916b037c0`  
Drift schema：`12`

本轮为远程无人值守验收。人工 Windows UI、Android 真机、字体视觉差异、托盘/Boss Key 实机操作均不作为自动化门禁。

## PASS AUTOMATED

### 全量门禁

| 项目 | 结果 |
|---|---|
| `flutter analyze` | PASS |
| Flutter unit/contract/widget | PASS，506/506 |
| Windows integration | PASS，11 个文件 / 14 个场景（逐文件、`-d windows`） |
| `git diff --check` | PASS |
| Windows Release | PASS |
| Android Debug APK | PASS |

构建产物：

- Windows：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

### Windows Shell

- Native runner 静态审计：bordered/borderless style、`WM_NCHITTEST` 四边四角 resize、拖动区、`WM_SIZE`、`WM_DPICHANGED`、最大化/恢复状态路径均存在。
- taskbar/tray invariant：`SetShellVisibility` 拒绝两者同时关闭；托盘创建失败回退 taskbar；Explorer `TaskbarCreated` 恢复路径存在。
- close-to-tray：启用 tray 时 `WM_CLOSE` 隐藏而非退出；显式退出路径保存状态并退出。
- Boss Key：app-local typed gesture、释放/失焦 reset、tray recovery guard、custom keyboard gesture 均有 domain/widget coverage。
- Windows Release 编译通过，C++ runner 代码可构建。

覆盖来源：`windows_shell_preferences_repository_test.dart`、`reader_input_router_test.dart`、相关 Reader widget/integration，以及 Windows Release runner build。

### AutoRead

- `idle/running/paused/stoppedAtEnd`、幂等转换、generation、stale tick：PASS。
- `toggleAutoRead` Windows/Android 语义路由：PASS（PhysicalInput → ReaderCommand → AutoReadController）。
- 2.5 秒 Chrome 自动隐藏、pause 后显示、stop/EOF 保持显示：PASS widget coverage。
- minimal-info preference、chapter/progress/clock 联动：PASS。
- Vertical ticker、Paged interval、manual navigation pause、bounded PageWindow、EOF/no-chapter：PASS。

### Reader 信息层

- chapter、chapter progress、whole-book progress、separator、六个 fixed slots：PASS。
- 12/24 小时 rendered-string：PASS；隐藏模式不渲染时间。
- Android `MediaQuery` view padding、cutout/landscape/navigation inset 模拟：PASS widget coverage。
- Paged chapter page metrics、chapter-first-page、relayout 后 Locator restore：PASS。

### Font

- system default 与 `fontId` fallback：PASS。
- installed/imported `FontDescriptor`、本地化 displayName、TTF/OTF、SHA-256 去重：PASS。
- candidate/apply/cancel 领域合同、per-book persistence、删除后 system fallback：PASS。
- font metrics 变化的 vertical/paged relayout 与 Locator restore：PASS widget/integration coverage。
- TTC：明确 deferred，存在对应 rejection test；未伪装为已支持。

### DataRoot

- Standard Application Support root：PASS。
- Portable/Instance root、独立 root ID、exclusive lease：PASS。
- root-relative books/backgrounds/fonts/database/settings 路径：PASS。
- manifest/hash、export/import/restore、staged atomic restore：PASS。
- 当前 4 个真实 TXT 参与 DataRoot 恢复回归：PASS。

### 真实 TXT 语料

目录 `C:\Users\TOM\Desktop\测试` 当前 4 个 TXT 均通过 metrics relayout / paged range 合同，所有记录 `logicalError=0`：

- `因果快递-20260625.txt`
- `无章节数字测试.txt`
- `苟在初圣魔门当人材(1-500章).txt`
- `青山(501-809章).txt`

覆盖前/中/后非零 UTF-16 Locator；有章节与无章节文件均通过。

### Schema migration

- 9 → 10：新增 fixed-slot Reader information preferences（chapter/progress/clock/divider visibility + slots），保留旧 progress display choice；由 `reader_preferences_test.dart` 的旧 schema fixture 验证。
- 10 → 11：新增 per-book `showAutoReadMinimalInfo`，默认 enabled；同一组旧 schema fixture 验证。
- 11 → 12：新增 app-managed `reader_font_asset_rows`、font hash index 和 nullable `reader_preferences.font_id`；`reader_font_test.dart` 使用真实 SQLite migration 验证 reading_progress、readingMode 与字体表保留/创建。

最终 schema 为 12；本轮未增加 migration。

## MANUAL VALIDATION DEFERRED

以下不在远程自动化环境执行：

- Windows 手工 resize/maximize/restore 视觉体验。
- Windows 托盘点击、close-to-tray、Explorer 重启后的实际托盘交互。
- Boss Key 鼠标左右键同时按下及自定义快捷键真人体验。
- Windows/Android 字体实际视觉差异与本地化名称的肉眼确认。
- Windows transparency：明确为技术阻塞项，未实现任何整窗 alpha hack。

## DEVICE VALIDATION DEFERRED

- Android ADB：NOT-RUN / DEFERRED。
- Android 真机 Volume、cutout、gesture navigation、portrait/landscape、字体视觉、托盘等设备项目不阻塞本轮自动验收。

## Non-blocking warnings

全量 Flutter 测试期间出现 Drift debug 多实例 warning，以及一个非致命的 widget hit-test warning；均未导致测试失败、数据错误或构建失败。

## Acceptance result

没有发现自动化 P0/P1/P2 阻断问题。  
**M5.6 = AUTOMATED ACCEPTANCE COMPLETE**

核心合同保持不变：`ReaderLocator` 仍是 normalized UTF-16 absolute offset 唯一位置真源；pageIndex、scrollPixels、章节页码和显示百分比均未成为持久化位置真源。
