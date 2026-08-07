# PROJECT_AUDIT_RESULT.md — M3 阶段封存与项目全量文档整理报告

> 日期：2026-08-07（M3 冻结点）
> 任务：M3 阶段封存审计 + 全量文档整理。**未开始 M4，未写任何功能代码。**
> 审计方式：以当前仓库真实内容为准（git、源码、既有报告），非聊天记忆。

---

## 1. 审计范围

- Git 全历史审计（48 commits，8 分支，0 tag）。
- 权威输入：`../README_ENGINE_DECISION.md`（12 项决策）、`../SPIKE_RESULT.md`（3 Spike + 真机 8/8）、`AAA/` 三份规范（未修改）。
- 阶段报告：M0 / M1 / M2 / M3 / M3_1 / M3_2 / M3_3 / M3_4 共 8 份（全部存在，均以实际文件为准）。
- 代码结构核对：pubspec.yaml、lib/（39 个 Dart 源文件）、test/（26 个测试文件 + 20 个 fixture）、integration_test/（5 个）、tool/（5 个）、windows/、android/。
- 版本/schema/parser 版本经 `git show <commit>:pubspec.yaml` + 源码实测。
- 旧文档冲突扫描（folded toc / collapsed / expand / sourceHash as contentHash / old parserVersion / page as progress 等关键词）：**无现行规则冲突**（命中项均为历史描述或合同「禁止」上下文，详见 §9）。

## 2. 当前 HEAD

`8b59a02db642aac7a1d31050e5c1e642145a2b42`（`docs(project): add m3 freeze audit and long-term documentation`，本审计任务提交；上一提交为 `f965448`）

## 3. 当前分支

`fix/m3-flat-toc`

## 4. 总 commit 数

**48**（`git rev-list HEAD --count`；`7ce51fe` 为根 commit，即 M0 以来全部 48 个）
tracked files：**159**（其中 Dart 83）；tags：无（建议在 §15 评估后创建）。

## 5. M0～M3.4 commit 表

| Milestone | Start commit | End commit | Commits | Major changes |
|---|---:|---|---|
| M0 工程骨架 | `7ce51fe` | `847641b` | 5 | 单 Flutter 工程、verify gate、CMake install-prefix 修复、M0_RESULT |
| M1 TXT 管线 | `4b6108c` | `89fe10d` | 6 | GB18030 解码器/Asset、编码检测、规范化、O(n) 扫描、原子缓存、inspect |
| M2 本地书库 | `cab2a71` | `e61c8b6` | 6 | Drift schema 1 六表、原子导入两阶段、四层模型、书架 UI、真机 9/9 |
| M3 纵向 Reader | `45ae988` | `ab866d7` | 8 | schema 2 reading_progress、ReaderLocator/Block、恢复状态机、两阶段跳转、真机 9/9 |
| M3.1 hash 修复 | `26d74e5` | `aa73c95` | 6 | NormalizedArtifact、manifest 权威、HealthCheck/Repair、inspect_managed_txt |
| M3.2 标题+跳转 | `9bccab6` | `da1a13d` | 6 | displayTitle/dedupeKey/chapterNumber、parserVersion 2.0.0、字符级二次对齐 |
| M3.3 定位+主题 | `68f4be7` | `ce2ff98` | 5 | TocIndexLogic、目录自动定位、ReaderResolvedAppearance、light 主题 |
| M3.4 平铺目录 | `38575df` | `f965448` | 6 | 删除卷折叠、全局导航合同、合同测试、Android 真机 13/13 |

## 6. 实际版本历史（`git show <commit>:pubspec.yaml` 实测）

| Commit 点 | Version |
|---|---|
| `847641b`（M0）/ `89fe10d`（M1） | 0.1.0-dev.1+1 |
| `e61c8b6`（M2） | 0.1.0-dev.2+2 |
| `882b7ed`（M3）→ `aa73c95`（M3.1）→ `da1a13d`（M3.2）→ `ce2ff98`（M3.3）→ `f965448`（M3.4） | 0.1.0-dev.3+3 |

## 7. schema / parser / index 版本历史

| 维度 | 值 | 依据 |
|---|---|---|
| Drift schema | 1（M2 建 6 表）→ **2**（M3 增 reading_progress，只增不删） | `app_database.dart` schemaVersion=2 + onUpgrade |
| parserVersion | 1.0.0（M1–M3.1）→ **2.0.0**（M3.2 完整标题合同） | `txt_import_service.dart` 默认 2.0.0 |
| normalizationVersion | 1.0.0（全阶段） | `txt_import_service.dart` |
| indexFormatVersion | 1（全阶段） | `txt_import_service.dart` |
| GB18030 asset formatVersion | 1 | `gb18030_index.meta.json`（WHATWG 2024-09-18，23940/209，sha256 aebe263d…） |
| Data generation | `v4-local-1`（M0 起不变，不兼容旧 XAOCEN 数据） | `constants.dart` |

## 8. 新增 6 份长期文档（+1 审计报告）

| 文件 | 内容要点 |
|---|---|
| `docs/CHANGELOG.md` | Keep a Changelog 风格；0.1.0-dev.1/2/3 三段 + Unreleased(Planned M4)；含 breaking/schema/parser/data-generation 标记与 Win/Android 验证列 |
| `docs/PROJECT_HISTORY.md` | 阶段→目标→实现→问题→修复→验证→最终状态全记录；含版本/schema 历史表与 commit 表 |
| `docs/ARCHITECTURE_CURRENT.md` | Runtime chain、四层模型、文本/坐标/hash/Reader/TOC/Theme/Cache 合同、Platform、**Non-negotiable invariants（14 条）** |
| `docs/ENGINEERING_LESSONS.md` | 23 条正式 + 附录小型教训；统一格式（现象/根因/错误做法/正确做法/回归保护/禁止事项） |
| `docs/KNOWN_ISSUES.md` | open（无）/ limitations / Deferred / regression-sensitive / 审计观察记录 |
| `docs/TEST_VALIDATION_MATRIX.md` | 自动 vs 真人、Win vs Android 分列；含测试缺口诚实记录 |
| `PROJECT_AUDIT_RESULT.md` | 本报告 |

另更新 `docs/README.md` 索引（权威输入 / 阶段报告 / 长期文档三节）。

## 9. 发现的文档冲突

- 旧阶段报告（M3.3 卷折叠、M3.4 删除折叠）描述的均为「当时发生过的事」，属历史事实 → **保留不改**。
- `docs/CONTENT_NAVIGATION_CONTRACT.md` 中 collapsed 字样均为「禁止」上下文 → 无冲突。
- 长期文档/现行规则中**无**把已废弃行为（折叠目录、sourceHash 作 contentHash、block 级可见范围、页号进度）写成现行规则的情况。
- 结论：无需修改任何历史报告；未发现文档与源码不一致（唯一接近的观察项见 KNOWN_ISSUES §6 第 1 条 storagePath 冗余前缀——M3 已用 resolveStoragePath 消费，属数据语义冗余而非行为不一致，按任务书仅记录不修改）。

## 10. 未解决问题

无 open bug。记录性观察（storagePath 冗余前缀、fixture 体积、debug APK 内存、>50MB 未真机验证、Android <12 未测）见 `docs/KNOWN_ISSUES.md`。

## 11. 当前测试状态

- 单元 + Widget：**259 项全过**（M3.4 报告 251 + 导航合同 8）。
- 集成测试：**5 文件全过**（Windows；真机侧 m2_* 与 vertical_flow 曾在真机通过）。
- `tool/verify.ps1` 于 M3.4 收尾时全绿（pub get / format / analyze / test / 集成逐文件 / Windows Release / APK Debug / git diff --check）。
- 本审计任务仅新增文档，未改代码 → 未重跑全量 verify（文档不含 Dart 代码；markdown 不参与 format/analyze）。

## 12. Windows 真人状态

✅ 已确认：真实库 4 collection 全链验证（M3.4）；真实文件 473/0 章与 9 个指定 offset（M1/M2/M3）；M3.1 真实库 repair + 821 行更新 + Reader 打开成功；M3.2 完整标题与第 31 章 @192296 跳转；M3.3 六章 ±1 定位；Release exe 构建与冒烟正常。用户长期日常使用正常。

## 13. Android 真人状态

✅ 已确认（Redmi K60 / Android 15 / 无线 adb）：
- Spike 4 受控 Spike 8/8；M2 9/9；M3 9/9（用户 + 自动化，含返回动画等待修复 `ab866d7`）；M3.4 13/13（覆盖安装、数据存留、平铺目录、自动定位、精确跳转、force-stop、横竖屏、0 crash）。
- 用户手动确认：大 TXT 打开/滑动/深色可读/哈希错误消失均正常。

## 14. M3 是否可以正式冻结

**可以。** 理由：
- 双平台真人验证完成（Windows 全链 + Android 13/13）；
- 259 单元/Widget + 5 集成全绿；verify.ps1 全绿；
- P1 数据一致性问题（normalizedHash）已修复并有回归保护；
- 全局内容导航合同已固化（文档 + 合同测试）；
- 工作区 clean，M3.4 全功能用户已验收。

## 15. 开始 M4 前还有没有阻塞项

**无阻塞项。** 建议（非阻塞）：
- 创建 annotated tag `m3-complete`（项目当前无 tag 策略，按任务书仅在报告中建议，**未擅自创建**）。建议 tag message 含：Vertical Reader complete / Windows manual validated / Android Redmi K60 Android 15 validated / Flat TOC / exact locator / managed TXT pipeline。
- M4 开发时继续沿用：无线 adb、测试后重建 APK、verify.ps1 全绿、真实文件 + 真机双验收。

## 16. 最终 HEAD

`8b59a02db642aac7a1d31050e5c1e642145a2b42`（本次文档整理提交，工作区 clean）

## 17. 工作区状态

clean（文档提交后确认；build 产物与缓存已 gitignore）。
