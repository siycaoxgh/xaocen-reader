# M5.9d-9.2 — On-Demand Chapter Fetch & Cache

项目：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 结论

**ON-DEMAND CHAPTER FETCH = PASS（fixture + Sudugu/Shudugu live）**

未修改数据库 schema、ReaderController、Locator、Pagination 或 ReaderProgress。

## 实现链路

1. 书架/Reader 目录点击 `itemId == null` 的在线章节。
2. `WebBookChapterCacheService` 读取现有 WebBook manifest、目录和实际 DB 缓存状态。
3. 已缓存章节直接继续使用现有 normalized document，不发起网络请求。
4. 未缓存章节从已缓存前缀的下一章开始，按原始目录顺序只获取到目标章节；不下载目标之后的章节。
5. 所有目标范围章节获取成功后，`LocalLibraryRepository.appendWebBookChapterCache` 原子追加到既有 normalized 快照，并更新：
   - content item / document
   - TOC itemId 与 UTF-16 start/end offset
   - normalized length / source size
   - manifest cachedChapterKeys / cache metadata
6. Reader 用更新后的同一 collection、documents、TOC 和一次性目标 locator 替换启动上下文；既有 progress/bookmark/preferences 不变。
7. 失败不写入部分章节，界面显示具体错误并保留再次点击重试入口。

由于 Reader 的绝对 UTF-16 offset 必须稳定，按需缓存采用“连续前缀追加”规则，避免把新章节插入旧正文中间而移动已有 offset。加入书架仍只预缓存有限章节，不会预下载整本书。

## 修改文件

- `lib/sources/remote/web_book_chapter_cache_service.dart`
  - 新增按需章节获取、来源注册表校验、失败信息映射与缓存命中判断。
- `lib/data/repositories/local_library_repository.dart`
  - 新增连续章节缓存追加事务；保留已有正文前缀和 Locator 偏移。
  - manifest 读取/写入补充 source-ordered catalog 与 cachedChapterKeys。
- `lib/domain/library/library_import_models.dart`
  - `WebBookSnapshotMetadata` 增加只读 catalog 元数据。
- `lib/reader/reader_page.dart`
  - 增加可选的书源层按需加载回调；只在未缓存章节点击时替换 launch context，不改变 Reader 核心状态机。
- `lib/app/library_page.dart`
  - 在线书籍注入按需加载回调，加载完成后刷新文档/目录并进入目标章节。
- `test/unit/web_book_library_import_test.dart`
  - fixture：未缓存第三章首次获取并写入；再次打开命中本地缓存且不重复请求。
- `test/manual/sudugu_on_demand_chapter_cache_test.dart`
  - Sudugu/Shudugu 真实网络验收脚本（默认跳过，显式启用）。

## 验证

- `flutter analyze --no-pub`：PASS
- WebBook fixture 定向测试：PASS
- `flutter test`：PASS（745 passed，2 skipped；含既有手动网络测试跳过项）
- `git diff --check`：PASS（仅工作区既有 CRLF 提示，无 whitespace error）
- Sudugu/Shudugu Runtime POC：
  - 真实来源发生跨域重定向时，按跨域/同源安全合同直接拒绝，不绕过策略。
  - 通过本地环境变量配置的来源完成目录、初始缓存、未缓存章节按需获取及再次打开本地缓存：PASS。

## 兼容边界

- 仍不支持 JS/WebView、登录/Cookie/反爬绕过、后台预取和整本下载。
- 来源目录发生删除/插入导致已有顺序变化时，安全拒绝改写并保留原快照。
- 原书源未注册/已禁用、HTTP/网络/解析失败时不污染缓存，提示可重试。

## 冻结判断

**可冻结本阶段。** 后续若要支持任意位置插入式缓存，必须先单独设计 Locator 偏移迁移协议；本阶段不扩大该范围。
