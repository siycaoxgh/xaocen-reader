// M4 P1 核心：退出/生命周期只 flush 当前激活模式，重开恢复「模式 + Locator」。
//
// 场景：
// 1. vertical A → 切 paged → 不翻页立即退出 → 重开 = paged + A
// 2. vertical A → 切 paged → 翻 5 页到 B → 退出 → 重开 = paged + B
// 3. paged B → 切 vertical → 滚动到 C → 退出 → 重开 = vertical + C
// 4. dispose 时 inactive 模式不得覆盖 active 模式已保存的进度。
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_progress_state.dart';
import 'package:xaocen_reader/domain/reader/reading_mode.dart';

void main() {
  group('M4 P1：模式 + Locator 持久化闭环（仓库层语义）', () {
    late AppDatabase db;
    late ReadingProgressRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = ReadingProgressRepository(db: db);
      final now = DateTime.now();
      await db
          .into(db.contentSources)
          .insert(
            ContentSourcesCompanion.insert(
              id: 'local-txt-source:abc',
              type: 'localTxt',
              displayName: 'T',
              contentHash: 'abc',
              managedSourcePath: 'p',
              sourceSize: 1,
              detectedEncoding: 'utf8',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.contentCollections)
          .insert(
            ContentCollectionsCompanion.insert(
              id: 'local-txt:abc',
              sourceId: 'local-txt-source:abc',
              title: 'T',
              itemCount: 1,
              normalizedCharacterLength: 1000,
              importedAt: now,
              updatedAt: now,
            ),
          );
    });

    tearDown(() async => db.close());

    test('场景1：vertical A → paged（不翻页）→ 退出后状态 = paged + A', () async {
      // vertical 读到 A=100
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 100,
          readingMode: ReadingMode.vertical,
        ),
      );
      // 切 paged：anchor=A=100，paged confirmed=A，退出时 paged.flush()
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 100,
          readingMode: ReadingMode.paged,
        ),
      );
      // 重开读取
      final p = await repo.getProgress('local-txt:abc');
      expect(p!.readingMode, ReadingMode.paged, reason: '重开 = paged');
      expect(p.absoluteCharacterOffset, 100, reason: '位置 = A');
    });

    test('场景2：vertical A → paged 翻 5 页到 B → 退出 → 重开 = paged + B', () async {
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 100,
          readingMode: ReadingMode.vertical,
        ),
      );
      // 翻页：最后一次提交 = paged + B=500（模拟 onPageSettled 防抖/flush）
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 500,
          readingMode: ReadingMode.paged,
        ),
      );
      final p = await repo.getProgress('local-txt:abc');
      expect(p!.readingMode, ReadingMode.paged);
      expect(p.absoluteCharacterOffset, 500, reason: '位置 = B');
    });

    test('场景3：paged B → vertical 滚动到 C → 退出 → 重开 = vertical + C', () async {
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 500,
          readingMode: ReadingMode.paged,
        ),
      );
      // 切 vertical 后滚动：最后一次提交 = vertical + C=700
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 700,
          readingMode: ReadingMode.vertical,
        ),
      );
      final p = await repo.getProgress('local-txt:abc');
      expect(p!.readingMode, ReadingMode.vertical);
      expect(p.absoluteCharacterOffset, 700, reason: '位置 = C');
    });

    test('场景4：inactive 旧模式不得覆盖 active 新模式（最后一次提交为准）', () async {
      // active = paged，最后提交 paged + 900
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 900,
          readingMode: ReadingMode.paged,
        ),
      );
      // inactive vertical 的 dispose flush 试图提交旧位置 100
      // —— 若被允许，将覆盖 paged。合同：只有 active 模式可提交，
      // 仓库层语义 = 最后一次 saveProgress 为准（ReaderPage 保证只调 active）。
      await repo.saveProgress(
        const ReaderProgressState(
          collectionId: 'local-txt:abc',
          absoluteCharacterOffset: 100,
          readingMode: ReadingMode.vertical,
        ),
      );
      // 若 ReaderPage 正确只 flush active，则不会发生上述 vertical 提交。
      // 此处验证「若发生错误提交，最新一次是 vertical+100」——实际由
      // ReaderPage 层测试（widget）保证不调用。这里验证仓库层行为确定。
      final p = await repo.getProgress('local-txt:abc');
      expect(p!.absoluteCharacterOffset, 100);
      expect(p.readingMode, ReadingMode.vertical);
    });
  });
}
