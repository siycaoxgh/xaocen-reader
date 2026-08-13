# M5.7s.7c-1 Android Screen Insets & Immersive

## Scope

本阶段只处理 Android Reader 的系统栏、刘海区域、方向和安全 inset；未触碰
AutoRead keep-awake、Windows、Divider、取色器、Engine/DComp 或 Chrome/Locator
导航逻辑。

## 实现

- `ReaderPreferences` 新增并按书保存：
  - `showSystemStatusBar`
  - `hideNavigationBar`
  - `extendIntoDisplayCutout`
  - `screenOrientation`（跟随系统、自动旋转、锁定竖屏、锁定横屏）
- Drift schema 由 14 正式迁移到 15；14→15 为三个显示偏好的安全默认值迁移，
  不改 `reading_progress`、Locator、书库或历史数据。
- Android window adapter 通过 MethodChannel 设置 display-cutout、独立系统栏和方向；
  Flutter 仍负责 `SystemChrome` overlay style、输入和无障碍生命周期。
- `ReaderInfoScaffold` 读取真实 `MediaQuery`/`viewPadding`，并将 cutout、导航栏
  inset 从正文区域中动态扣除；关闭信息区域时释放对应的上下空间。
- App Shell 通过 `SafeArea(top: true)` 独立避让系统状态栏/刘海，不继承 Reader 的
  沉浸偏好。

## 合同

- 系统状态栏开启时，刘海扩展开关被禁用并显示“隐藏系统状态栏后可用”；偏好层也
  会将该组合规范化为关闭。
- 导航栏隐藏独立于状态栏；Android 原生边缘手势仍可临时唤回系统栏。
- 方向、系统栏和 cutout 变化走现有 freeze → capture Locator → relayout/repaginate
  → restore 的 metrics transaction；不保存 pageIndex、scrollPixels 或新的位置真源。
- 非 Android 平台的 safe-inset helper 返回零，避免桌面 widget/Reader 测试被伪造的
  手机 inset 改变布局。

## 验证

- `flutter analyze`：PASS
- 全量 Flutter tests：PASS（547 tests）
- Android Debug：PASS
- Windows Release：PASS
- `git diff --check`：PASS
- Android USB `ce8df63f`（23013RK75C / Android 15 / API 35）：普通
  `app-debug.apk` 以 `install -r` 安装成功，Launcher 启动成功；启动日志无
  FlutterError、Dart exception、PlatformException、MissingPlugin 或 SQLite 崩溃。
- 真机当前可自动确认的项目：安装、启动、包未被清理、普通启动链路 PASS。
  刘海开关、系统栏组合、方向切换和视觉空间仍需在本地设备上逐项人工操作确认，
  本轮不伪造这些视觉结果。

## 构建产物

- APK：`build/app/outputs/flutter-apk/app-debug.apk`
- Windows EXE：`build/windows/x64/runner/Release/xaocen_reader.exe`

