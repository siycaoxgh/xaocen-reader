# M5.5e.6 Result — 现有字体体系统一

状态：COMPLETE  
日期：2026-08-11

## 字体合同

- 新增 `AppTypography`：统一 Material 3 type scale、标题/正文/辅助文字/标签权重及跨平台 fallback。
- 新增 `ReaderTypography`：Reader 正文不指定 `fontFamily`，继续使用系统默认字体；统一附加
  `Noto Sans CJK SC / Microsoft YaHei / Noto Sans / sans-serif` fallback。
- 首页、书架、我的、设置、Reader Chrome 统一消费 ThemeData 的 type scale；预览 swatch、调试条等
  特殊文字也收口到 ReaderTypography。
- ReaderTextBlock 将 fallback 纳入 metrics 比较，未来字体变化会走既有 relayout/repaginate + Locator restore 合同。
- 未枚举系统字体、未导入字体、未修改分页算法或 schema。

## 验证

- `flutter analyze`：PASS。
- 全量 Flutter unit/contract/widget：472/472 PASS。
- integration：11 个文件 / 14 个场景 PASS。
- `C:\Users\TOM\Desktop\测试` 全部 4 个 TXT：PASS，logical error = 0。
- Windows Release：PASS。
- Android Debug：PASS（本轮未执行 Android 真机）。
- `git diff --check`：PASS。

构建产物：

- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
