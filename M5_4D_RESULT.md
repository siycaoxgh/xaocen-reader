# M5.4d — AutoRead UI 收口

本阶段将 Vertical / Paged 自动阅读统一接入现有 Reader 控制区与
`AutoReadController`，没有新增第二套自动阅读或位置写入逻辑。

## 功能合同

- Vertical 面板提供开始、暂停/继续、停止、五档速度和 12–120 px/s 自定义滑杆。
- Paged 面板提供开始、暂停/继续、停止和 3/5/8/10/15 秒间隔。
- 状态标签显示当前模式和参数；暂停显示“自动阅读已暂停”。
- Aa、目录、书签、搜索及其他需要集中操作的面板会暂停自动阅读；仅显示/隐藏 Reader controls 不暂停；关闭面板不会自动恢复。
- 模式切换、生命周期中断、route/dispose 会暂停并使旧 generation 失效；App 重启状态仍为 idle。
- Windows 新增 `toggleAutoRead` 语义命令，不加入默认绑定。Android 仍只保留既有 Volume Up/Down/disabled 合同。

## Keep-awake

新增 `ReaderKeepAwake` 抽象。Android 通过现有 MethodChannel 设置/清除
`FLAG_KEEP_SCREEN_ON`；running 开启，paused/stopped/dispose 释放。Windows、测试宿主未实现该平台能力时安全降级为 no-op，未引入第三方依赖。

## 位置与数据

Paged 自动阅读只调用 `PagedReaderController.nextPage()`；Vertical 继续使用
现有 Ticker 驱动和 visible-range confirm。ReaderLocator、ReadingSession、
ReaderPreferences、PageWindow 和 Drift schema 6 均保持原合同。

## 验证

Targeted UI/router tests: 11/11 PASS（其中新增 Paged interval/status 与
`toggleAutoRead` 路由覆盖）。全量 Flutter tests: 451/451 PASS；11 个
integration 文件、14 个场景 PASS，包含全部真实 TXT 和 logical error = 0。
`flutter analyze`、Windows Release、Android Debug、`git diff --check` PASS。

构建产物：

- Windows Release: `build/windows/x64/runner/Release/xaocen_reader.exe`
- Android Debug: `build/app/outputs/flutter-apk/app-debug.apk`
