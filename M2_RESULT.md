# M2_RESULT — Local TXT Library (feat/m2-local-library)

- **日期**: 2026-08-06
- **基线**: feat/m1-local-txt-pipeline @ 89fe10d（M1 完成，工作区 clean）
- **分支**: feat/m2-local-library（基于 89fe10d）
- **应用版本**: 0.1.0-dev.2+2
- **数据代际**: v4-local-1（不兼容旧 XAOCEN 运行数据，无迁移入口）

## 1. 范围完成情况

| 任务书项 | 状态 | 说明 |
|---|---|---|
| TXT 选择→大小预检→复制原文件→M1 索引→规范化正文→Drift 四层模型→最小书架→重启持久→删除 | ✅ | 全链路实现 |
| 不实现 Reader/分页/搜索/书签/TTS/RSS/网络书源/统一 UI/旧数据迁移 | ✅ | 未触碰 |
| 文件布局 `<support>/library/local_txt/<hash>/` | ✅ | source.txt / normalized.txt / index.json / manifest.json |
| 原子导入 13 步 + 两阶段提交 | ✅ | prepared→filesCommitted→databaseCommitted→completed |
| 内容 SHA-256 稳定身份 + 确定性 ID | ✅ | `local-txt-source:<hash>` 等 5 种 ID 格式 |
| Drift schema 1（6 表 + FK + 唯一约束 + 6 索引） | ✅ | 无 reading_progress/bookmarks/FTS5 等 |
| LocalLibraryRepository 6 方法 | ✅ | 注入 M1 管线，不重写扫描器 |
| AssetBundle 抽象（正式/测试双实现） | ✅ | FlutterAsset / File / Memory 三实现 |
| 最小 UI（导入按钮+书架+进度+取消+大文件确认） | ✅ | 点击书籍显示"M3 实现"占位 |
| 文件安全删除保护 | ✅ | 路径前缀/目录名/.. 校验 |
| 版本 0.1.0-dev.2+2 | ✅ | constants.dart + pubspec.yaml |

## 2. 测试结果

### 单元/Widget 测试（flutter test）
- **109/109 通过**（M1 82 + M2 新增 27：数据库 14 / 文件 8 / 仓库 8 / Widget 8 中新增部分）
- M2 新增：`test/unit/local_library_test.dart`（20 项）、`test/widget/library_page_test.dart`（8 项，纯 UI 状态机）、`test/unit/m0_skeleton_test.dart`（更新为 M2 断言）

### 集成测试（flutter test integration_test，Windows + Android 真机）
- `m2_library_flow_test.dart`：导入→书架→重启→删除→外部文件保留 全链路 **Windows ✅ / Android 真机 ✅**
- `m2_android_verify_test.dart`（新增）：AssetBundle 加载+UUID 名导入+alreadyImported+取消不留半成品 **Windows ✅ / Android 真机 ✅**

### Android 真机 9 项验证（Redmi K60 / Android 15 / 无线 adb）
1. ✅ Debug APK 安装启动（com.xaocen.xaocen_reader）
2. ✅ AssetBundle 加载 GB18030 索引（23940 entries / 209 anchors，并发去重 identical）
3. ✅ 小文件直接导入（utf8_chapters + gb18030 两编码）
4. ✅ 导入后书架显示（标题/编码正确）
5. ✅ 重启持久（重建 db/scope 后数据可再读）
6. ✅ 删除 collection（级联清理 + 外部文件保留）
7. ✅ 重复导入 alreadyImported（UUID 风格名二次导入同 ID）
8. ✅ 取消导入不留半成品（importing 目录空、书库空、UI 无残留）
9. ✅ GB18030 解码真实链路（生僻字 𠀀 U+20000 四字节序列正确导入）

### 真实验收（真实外部 TXT，只读）
- `苟在初圣魔门当人材(1-500章).txt`：UTF-8、473 章、9 个指定章节偏移全部命中（#1=54、#19=49208、#42=108790、#112=298039、#195=516559、#258=685040、#300=795861、#400=1062206、#473=1257817）、二次 cacheHit=true
- `无章节数字测试.txt`：0 章、不伪造目录、二次 cacheHit=true
- 外部文件 SHA-256 前后不变（9ace0b9b…a5d6 / 12b6e8af…a78b3）

## 3. 构建

- **Windows Release**: ✅（`build\windows\x64\runner\Release\xaocen_reader.exe`）
- **Android Debug APK**: ✅（`build\app\outputs\flutter-apk\app-debug.apk`）

## 4. verify.ps1 全绿（8 步）

pub get / format check / analyze / test / integration_test（逐文件）/ Windows Release / APK Debug / git diff --check — **VERIFY PASSED**

## 5. 关键工程决策与踩坑

1. **Widget 测试用 provider override 而非真实 DB**：flutter_test 的 FakeAsync 不推进真实 IO（Drift/SQLite 查询挂起），真实链路归 integration_test。
2. **Windows Directory.uri.pathSegments 尾随空段**：删除安全校验用 `where((s) => s.isNotEmpty).last` 取目录名。
3. **Android 工具链（重要）**：Flutter 3.44 模板 AGP 9.0.1 + `android.builtInKotlin=false`。file_picker 11.0.3 在 AGP 9 下跳过 KGP apply（依赖 AGP 内置 Kotlin）导致其 .kt 不编译；而 flutter_plugin_android_lifecycle 2.0.35 仍用 KGP，与 builtInKotlin=true 冲突。**解决：降级 AGP 至 8.7.3 + 传统 KGP（builtInKotlin=false）**。
4. **sqlite3 3.5.1 native assets hook 从 github.com 下载被墙**：pubspec `hooks.user_defines.sqlite3.url_pattern` 指向 ghproxy.net 镜像（`https://ghproxy.net/https://github.com/...`）。
5. **集成测试 fixture 内嵌**：Android 真机 cwd 是沙箱，相对路径不可用；fixture 字节直接内嵌为 Dart 常量（utf8_chapters 110B / gb18030 48B），索引经 FlutterAssetEncodingIndexProvider 加载。

## 6. 工作区状态

- 分支 feat/m2-local-library，提交见 git log
- 工作区 clean（构建产物与 .m2cache 已 gitignore）
- 不提交真实正文/外部 TXT

## 7. 下一阶段建议（M3）

- Reader 核心：TextPainter 分页 + UTF-16 偏移坐标（已由 Spike 3/4 验证）
- 打开书籍从 normalized.txt 按偏移范围读取，不预排全书
- 阅读位置持久化（reading_progress 表，progressType 区分 position/completion）
