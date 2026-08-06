# M0_RESULT.md

> **XAOCEN Reader v4 · M0 工程骨架初始化结果**
> 日期：2026-08-06 · 阶段：M0（仅工程骨架，未实现 TXT/Reader/UI 功能）

---

## 1. 项目路径

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\`

（与三份权威规范 `AAA/`、`README_ENGINE_DECISION.md`、`SPIKE_RESULT.md` 同父目录；规范文件未被修改）

## 2. Flutter 与 Dart 版本

- Flutter 3.44.7 stable（revision 84fc5cbb22, 2026-07-17）
- Dart SDK 3.12.2（随 Flutter 分发）

## 3. 应用版本

`0.1.0-dev.1+1`（全新版本代际，不沿用旧项目 0.14.x）

## 4. 数据代际

`v4-local-1`（常量定义于 `lib/app/constants.dart`；本轮仅定义常量，不创建数据库迁移；不兼容旧 XAOCEN 运行数据，无迁移入口）

## 5. 实际目录树

```
xaocen_reader/
├── assets/
│   └── encoding/
│       └── README.md              # GB18030 索引格式约定（M0 占位，无虚假数据）
├── docs/
│   └── README.md                  # 权威文档索引
├── integration_test/
│   └── m0_smoke_test.dart         # 最小启动测试（待真实流程后可运行）
├── lib/
│   ├── main.dart                  # 入口 → bootstrap()
│   ├── app/
│   │   ├── bootstrap.dart         # 启动引导（Riverpod ProviderScope）
│   │   ├── app.dart               # XaocenApp 根 Widget（主题+路由）
│   │   ├── router.dart            # 空路由表（仅根路由 /）
│   │   ├── constants.dart         # 版本/数据代际/数据库文件名常量
│   │   └── placeholder_page.dart  # M0 占位页（明确标注非最终 UI）
│   └── design/
│       ├── tokens/
│       │   └── app_tokens.dart    # V3 品牌色板令牌
│       └── theme/
│           └── app_theme.dart     # 深色主题入口
├── test/
│   └── unit/
│       └── m0_skeleton_test.dart  # 6 项骨架测试
├── tool/
│   └── verify.ps1                 # 统一验证门禁
├── windows/                       # Flutter 生成的 Windows 壳（含 1 处 CMake 修复）
├── android/                       # Flutter 生成的 Android 壳
└── pubspec.yaml                   # 唯一 pubspec（单项目单包）
```

**有意未创建**（无 M0 职责，按任务书 §5 不提前生成空文件）：`lib/domain`、`lib/data`、`lib/sources`、`lib/reader`、`lib/features`、`test/contracts`、`test/fixtures`。

## 6. 依赖列表及用途

| 依赖 | 版本 | 用途 |
|---|---|---|
| flutter_riverpod | ^2.6.1 | 状态管理（第一版手写 Provider，不启用 codegen） |
| drift | ^2.28.1 | 数据库（M1 起建立 schema；build_runner 仅 Drift 确有需要时使用） |
| sqlite3_flutter_libs | ^0.5.36（解析到 0.5.42） | SQLite 原生库（Windows/Android） |
| path | ^1.9.1 | 路径处理 |
| flutter_lints | ^6.0.0 | 静态分析规则 |
| drift_dev / build_runner | dev | Drift 代码生成（本轮未运行） |
| integration_test | dev (SDK) | 集成测试 |

**明确未引入**：RSS / 网络书源 / TTS / 同步 / 插件 / EPUB 依赖。**无多 package**（单一 pubspec.yaml）。

## 7. 验证结果（tool/verify.ps1 全量通过）

| 步骤 | 结果 | 耗时 |
|---|---|---|
| flutter pub get | ✅ | ~2s |
| dart format --set-exit-if-changed | ✅（0 changed） | ~1s |
| flutter analyze | ✅（No issues found） | ~11s |
| flutter test | ✅ 6/6 passed | ~5s |
| flutter build windows --release | ✅ | ~25s |
| flutter build apk --debug | ✅ | ~14s |
| git diff --check | ✅ | <1s |

Windows exe 冒烟：启动 6 秒无崩溃（`build\windows\x64\runner\Release\xaocen_reader.exe`）。

## 8. 构建产物路径

- Windows Release：`build\windows\x64\runner\Release\xaocen_reader.exe`
- Android Debug：`build\app\outputs\flutter-apk\app-debug.apk`

（build/ 已被 .gitignore 排除，未提交）

## 9. 所有提交

| Commit | 说明 |
|---|---|
| `7ce51fe` | chore(project): initialize xaocen reader v4 |
| `ce5db68` | chore(tooling): add verification gate |
| `8c7d3ae` | docs(project): record m0 foundation |
| `7532f2f` | chore(tooling): fix verify gate and format sources |

## 10. 最终 HEAD

`7532f2f766655bcc62726b9ce5e67d1ace48ebda`

## 11. 工作区状态

`git status` 干净（clean）。无未提交变更；build 产物已被忽略；三份权威规范未修改。

## 12. 下一阶段 M1 建议

1. **GB18030 二进制索引生成器**：实现 `tool/generate_gb18030_index.dart`，生成 `assets/encoding/gb18030_index.bin` + `.meta.json`（记录 WHATWG 来源版本、entryCount、anchorCount、SHA-256；二进制格式约定已写入 `assets/encoding/README.md`）
2. **GB18030 解码器落地**：按 Spike 1 已验证合同（锚点表查询、0x80→U+FFFD、双端一致）在 `lib/reader/engine/` 建立正式实现
3. **TXT 接入引擎**：文件读取/身份确认、编码检测、BOM 移除、CRLF→LF（Spike 2 合同：仅去 BOM + CRLF/CR→LF）
4. **完整卷章扫描**：后台 Isolate O(n) 单次顺序扫描 → 卷—章两级目录 → 去重 → UTF-16 偏移索引 → 原子写缓存（Spike 2 合同）
5. **性能合同红线**：打开 Reader 前完成扫描与索引缓存；不预排整本书页面，仅预排首屏/恢复页/邻近页
6. 大文件三级阈值（≤20MB 正常 / ≤50MB 确认后扫描 / >50MB 不支持）随 M1 落地为集中常量

**M1 完成标准建议**：`verify.ps1` 全过 + 真实 TXT 文件（有章节/无章节/GBK）走通"导入→扫描→索引缓存→打开"，与 Spike 结果对照一致。
