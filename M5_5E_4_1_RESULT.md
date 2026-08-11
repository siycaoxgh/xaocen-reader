# M5.5e.4.1 Result — 主题/Palette 与 Aa Windows 宽度修正

状态：COMPLETE  
日期：2026-08-11

## 修正

- 根因：解析器此前只检查颜色覆盖是否存在，没有把“预设/自定义”作为互斥选择状态；
  迁移后的旧颜色和保留的 custom 值可能继续遮住主题或新 Palette。
- `ReaderPaletteId.custom` 现在是明确的持久化选择状态。选择任意预设立即使用该预设的
  当前亮度颜色；自定义颜色只在 custom 状态参与绘制，浅色/深色覆盖仍分别保留。
- 旧 schema 7 颜色迁移会将有旧颜色的书标记为 custom；无颜色的书保持 paperWhite。
- 预设“夜间”改名为“浅灰”，“墨黑”保持不变。
- Windows Aa 通过平台识别使用固定桌面外层宽度（受可用屏幕宽度上限约束）、固定 132px
  分类栏和填充剩余空间的内容区；Android 继续使用全宽触控布局。

## 合同影响

主题 system/light/dark 仍由有效 Reader Theme 驱动；preset/custom 只决定 Reader paint
颜色来源。颜色变化仍是 paint-only，不触发 relayout、分页、Locator、progress 或 session。
Drift schema 保持 8，未修改 Reader engine、PageWindow 或 AutoRead。

## 验证

- `flutter analyze`：PASS。
- 相关 Palette/appearance/migration tests：PASS。
- 全量 Flutter unit/contract/widget：468/468 PASS。
- integration：11 个文件 / 14 个场景 PASS。
- `C:\Users\TOM\Desktop\测试` 全部 4 个 TXT：PASS，logical error = 0。
- Windows Release：PASS。
- Android Debug：PASS（真机本轮未执行）。
- `git diff --check`：PASS。

构建产物：

- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
