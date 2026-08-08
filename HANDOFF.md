# HANDOFF.md — XAOCEN Reader v4 交接说明

> 创建：2026-08-08（模型切换交接检查）
> 分支：`feat/m4-horizontal-reader` ｜ HEAD：`3d0fba5` ｜ 工作区：**clean**

---

## 1. 当前状态总览

- **M4（横向分页 Reader + 双模式切换）已完成代码与自动化验证**；
- **M4 P1（模式 + Locator 持久化闭环）已修复并提交**（见 §3）；
- **剩余唯一事项：P1 修复后的 Windows + Android 真人验证**（见 §4）；
- M4 只有在「退出重开仍保持最后阅读模式 + 最后 confirmed Locator」真人验证通过后，
  才能真正标记 COMPLETE。

## 2. Git 状态

- 分支：`feat/m4-horizontal-reader`（基于 M3 分支 ff 合并后的 main，未合并回 main）
- HEAD：`3d0fba5 docs(m41): record mode and locator persistence fix`
- 工作区：clean（无未提交修改、无 untracked）
- 最近提交（M4 全链）：
  ```
  3d0fba5 docs(m41): record mode and locator persistence fix
  4faae01 test(reader): cover mode persistence, reopen restore and overwrite race
  7a4d077 fix(reader): flush only active mode on dispose and lifecycle
  b389a6a feat(storage): add reading mode to progress state with schema 3 migration
  cd9478d docs(m42): record android device verification results
  c3cda3a docs(m42): record paged reader result and reference research
  （…M4.1 六个提交、M3 全链…）
  ```

## 3. M4 P1 状态（用户点名项）

**问题**：纵向 → 切分页 → 翻到新位置 → 退出 Reader/App → 重开：
1. 阅读模式恢复成纵向；
2. 位置恢复成之前纵向的位置，而非分页最新位置。

**状态：已修复并提交（b389a6a / 7a4d077 / 4faae01 / 3d0fba5），自动化验证全绿。**

根因（诊断确认，非猜测）：
1. **P0 覆盖竞态**：`ReaderPage.dispose()` 中 `paged.flush()`（保存分页 B）之后
   **无条件 `_controller.flush()`（纵向）**用旧位置 A 覆盖 B；
   `didChangeAppLifecycleState`（App 后台）同样无条件纵向 flush。
2. **P0 mode 未持久化**：`_mode = ReaderMode.vertical` 硬编码（session state），
   schema 2 无 readingMode 列 → 重开永远纵向。
3. 无「只有激活模式可提交」约束。

修复内容：
- `ReaderProgressState`（collectionId + absoluteCharacterOffset 唯一真源 +
  readingMode 表现状态 + itemIdHint + updatedAt）；domain `ReadingMode` enum；
- Drift **schema 2→3**：`reading_progress.readingMode` TEXT DEFAULT 'vertical'，
  旧数据默认 vertical，不删任何数据；
- **只有 active 模式可提交**：dispose / lifecycle 按 `_mode` 路由 flush
  （`paged → paged.flush()`；`vertical → _controller.flush()`），切换本身零写入；
- **重开恢复**：`_start` 读 state → 纵向恢复位置 → mode==paged 自动切分页（anchor 不变）；
- **paged 守卫**：纵向跳转/对齐/finishRestore 在 paged 模式下跳过
  （防 visibleRange 测量失败误设 state=failed 错误页）；
- 顺带修复：`removeCollection` 显式删 reading_progress + ReadingProgress 表
  `customConstraint` 生成真 `REFERENCES ... ON DELETE CASCADE`
  （Drift `references()` 未产出 FK，删书残留进度 bug）。

验证（全绿）：
- **327 项单元+widget**（新增 14 项 P1 专项：state 合同 3、迁移 1、repo mode 4、
  模式+Locator 合同 4、widget 层 3）；
- **8 个集成测试**全过（含 paged_reader_flow、reader_mode_switch 零写入、真实文件）；
- **verify.ps1 全绿**（pub get / format / analyze / test / 8 integration /
  Windows Release / APK Debug / git diff --check）；
- 合同场景（自动化覆盖）：
  1. vertical A → 切 paged → 不翻页立即退出 → 重开 = **paged + A**；
  2. vertical A → 切 paged → 翻 5 页到 B → 退出 → 重开 = **paged + B**；
  3. paged B → 切 vertical → 滚到 C → 退出 → 重开 = **vertical + C**；
  4. route pop / App 后台 / force-stop（lifecycle flush active）/ dispose 只写激活模式；
  5. page swipe 未 settle 退出只保存最后 confirmed；
  6. inactive Reader 不覆盖 active Reader 状态。

## 4. Next Actions（未完成事项）

### 4.1 【必须】P1 修复后真人验证（Windows + Android）
用户要求 Windows 和 Android 都必须真人验证。构建产物（正常入口版）：
- **Windows**：`build\windows\x64\runner\Release\xaocen_reader.exe`
- **Android**：`build\app\outputs\flutter-apk\app-debug.apk`（覆盖安装，数据保留）

验证场景：
1. 打开书（纵向）→ 切分页 → 翻几页 → 退出 Reader / 退出 App → 重开 →
   **应保持分页模式 + 最后位置**；
2. 分页 → 切回纵向 → 滚动 → 退出 → 重开 → **应保持纵向 + 新位置**；
3. force-stop / 进程重启后同样保持；
4. 覆盖安装时旧数据（书架/进度）保留，schema 2→3 迁移正常。

### 4.2 可选
- M4 分支合并回 main（当前 ff 链，`git switch main && git merge --ff-only feat/m4-horizontal-reader`）；
- M5 候选（待用户确认）：完整阅读设置页、搜索、书签、EPUB、RSS。

## 5. 工具链要点（真机验证时用，避免踩坑）

- **无线 adb 连接不稳定**：mDNS 双通道频繁轮换（`adb-ce8df63f-GoufFG` 短名 /
  `..._adb-tls-connect._tcp` 长名），serial/transport_id 每次查询可能变化；
  **每次操作单进程内**「等设备 → 取当前 transport_id → 立即执行」；
  断开时 `adb kill-server; adb start-server` 等待 mDNS 重新广播。
- **uiautomator dump 可拿 Flutter 控件 bounds**（content-desc），
  但 PopupMenu 菜单项 bounds 与实际 hit 区域可能偏移 → 用集成测试验证 UI 行为最可靠。
- **`flutter test` 集成测试会卸载 app 并清空 app 数据**（外部 TXT 不受影响）；
  验证后必须重新 `flutter build apk --debug` 得到正常入口 APK 再安装。
- 设备：Redmi K60（23013RK75C / mondrian，Android 15 / API 35），无线调试。
- PowerShell 中文/转义问题多，命令执行建议用 Python 脚本（`C:\Users\TOM\.qclaw\workspace\research\`）。

## 6. 长期文档索引

- `M4_RESULT.md`（双层报告 + §10 P1 修复详情）
- `M4_REFERENCE_RESEARCH.md`（参考项目研究，10 节）
- `M4_1_RESULT.md`（分页核心引擎）
- `docs/ARCHITECTURE_CURRENT.md`（含分页架构 + 进度持久化合同）
- `docs/ENGINEERING_LESSONS.md`（M4 教训 §1-§10，含 P1 覆盖竞态、FK 未生成）
- `docs/KNOWN_ISSUES.md`（分页 backward 页首漂移 ≤2 屏/100 页；其余已解决）
- `docs/TEST_VALIDATION_MATRIX.md`、`docs/PROJECT_HISTORY.md`、`docs/CHANGELOG.md`
- 会话记忆：`C:\Users\TOM\.qclaw\workspace\memory\2026-08-08.md`
