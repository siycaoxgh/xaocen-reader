# M5.5e.3 Reader 操作层级与 AutoRead 状态 UI

## 结果

- 顶部阅读模式图标改为只读状态提示，显示“滚动”或“分页”，不再打开菜单或承担模式修改。
- 底栏固定为“目录 / 自动阅读 / 书签 / Aa / 更多”；AutoRead 从“更多”移出，Search 等低频功能仍保留在“更多”。
- AutoRead 运行或暂停时，在正文与底栏之间显示非模态状态条，提供暂停/继续和停止操作；状态条不随 Chrome 隐藏而消失。
- 状态文案使用当前运行参数：纵向为“自动阅读中 · N px/s”，分页为“自动翻页中 · N 秒/页”，暂停为“自动阅读已暂停”。
- Aa 的唯一可写模式入口改为“阅读行为”，当前仅提供滚动/分页；页面布局和翻页效果只作后续预留，不新增枚举或持久化字段。
- 既有手动滚动、滑页、键盘、音量、章节/目录/搜索/书签跳转的 AutoRead pause 合同保持不变；ReaderLocator、PageWindow、AutoRead driver、ReadingSession 未修改。

## 验证

- `flutter analyze`：PASS
- Flutter unit/contract/widget：460 PASS
- integration：11 个文件、14 个场景 PASS
- Windows Release：PASS
- Android Debug：PASS
- `git diff --check`：PASS
- Drift schema：7，未变化

构建产物：

- `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- `build\\app\\outputs\\flutter-apk\\app-debug.apk`

Android 真机本轮未执行；此前设备验证按既有计划另行记录。
