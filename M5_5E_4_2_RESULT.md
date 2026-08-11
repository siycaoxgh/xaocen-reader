# M5.5e.4.2 Result — Palette 真人测试 Bug 修正

状态：COMPLETE  
日期：2026-08-11

## 根因与修正

- `paletteId` 点击和 watch/重绘链路均正常；问题不是 Palette 状态丢失。
- 原六组亮色变体过于接近白色，尤其“墨黑”浅色值实际为近白背景，名称与视觉语义冲突。
- 重新拉开各预设亮/暗变体的颜色差异。`墨黑`在浅色和深色模式都保持黑色背景与浅色文字；
  `浅灰`使用明确的灰色背景。preset/custom 互斥合同不变。
- Reader body 与分页/纵向正文继续消费同一 `ReaderPaletteResolver`；Chrome 保持 App Theme
  语义，不另建颜色真源。
- 检查 Reader/Aa 图标及 Logo 未发现错误资源或错误引用；仅有风格统一项留待后续 UI polish。

## 最终颜色合同

| Palette | Light | Dark |
|---|---|---|
| 浅灰 | 背景 `#D9D9D9`，文字 `#303238` | 背景 `#4A4A4A`，文字 `#F0F0F0` |
| 墨黑 | 背景 `#000000`，文字 `#F2F2F2` | 背景 `#000000`，文字 `#F2F2F2` |

主题模式只决定所选 Palette 的亮/暗 variant；`墨黑`是有意保持黑底的稳定阅读配色。
自定义颜色只有 `paletteId == custom` 时参与绘制，且不静默替换用户选择。

## 验证

- `flutter analyze`：PASS。
- 全量 Flutter unit/contract/widget：470/470 PASS。
- integration：11 个文件 / 14 个场景 PASS。
- `C:\Users\TOM\Desktop\测试` 全部 4 个 TXT：PASS，logical error = 0。
- Windows Release：PASS。
- Android Debug：PASS（真机本轮未执行）。
- `git diff --check`：PASS。

构建产物：

- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
