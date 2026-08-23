# M5.9b-3.1 — EPUB Paged Visual Fix

## 范围

本轮只修复真实 EPUB 验收发现的两个问题：分页超长图片溢出，以及书架导入入口的 TXT 专用文案。没有修改 Reader/Locator/Progress 合同，也没有扩大 EPUB 支持范围。

## 修改文件

- `lib/reader/reader_epub_image.dart`
  - 增加分页图片的可选最大高度和纯布局计算函数。
  - 纵向阅读保持原有图片行为。
- `lib/reader/paged_reader_view.dart`
  - 正文继续使用原分页结果；图片放入页面剩余的有界区域并按图片数量分配高度。
  - 无可用空间时安全隐藏图片，避免 PageView 子树溢出；不插入占位字符、不改变正文偏移。
- `lib/app/library_page.dart`
  - “导入 TXT”改为通用文案“导入书籍”。
- `test/unit/reader_epub_image_test.dart`
  - 覆盖多图片高度分配和无可用空间边界。
- `test/widget/library_page_test.dart`、`integration_test/hash_contract_flow_test.dart`、`integration_test/m2_library_flow_test.dart`
  - 更新通用导入文案断言。

## 真实 EPUB 回归

测试文件：`C:\Users\TOM\Downloads\埃隆·马斯克传 (【美】沃尔特·艾萨克森 （Walter Isaacson）) (Z-Library).epub`

设备：`emulator-5554`（Android 15 / API 35）

- APK 构建：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
- 导入/去重：PASS（保留原有一本书）
- Metadata / TOC / spine：PASS
- Vertical：PASS
- Paged：PASS；图片仍显示，未再出现黄黑 overflow 提示条
- 翻页 / 进度 / 目录跳章：PASS
- 退出重进位置：PASS
- UTF-16 Locator：PASS（实际跳章重进 + 现有定向测试）
- 斜体人工确认：PASS；`Alpha Blaster`、`Blastar` 在分页正文中可见倾斜字形
- 崩溃 / 乱码：未发现

证据截图：

- `test_output/real_epub_reader_paged_fixed_image.png`
- `test_output/real_epub_reader_italic_p6.png`
- `test_output/real_epub_reader_paged_fixed_later.png`

## Gate

- `flutter analyze --no-pub`：PASS
- EPUB / 图片 / Reader 定向测试：PASS（38 tests）
- 全量 Flutter tests：PASS（672 tests）
- `git diff --check`：PASS（仅既有换行格式提示，无 whitespace error）

## 冻结结论

**M5.9b-3 = PASS / FROZEN**。

保留既有兼容边界：复杂 CSS、JavaScript、DRM、远程资源、SVG、音视频和复杂脚注不在本阶段实现。后续若继续增强，应另开阶段，不改变当前 ReaderContent、UTF-16 Locator、Pagination 或 Progress truth。
