import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/library/library_entities.dart';
import '../domain/reader/reading_history.dart';
import '../domain/reader/reading_session.dart';
import '../reader/reader_page.dart';
import 'providers.dart';

class ReadingHistoryPage extends ConsumerStatefulWidget {
  const ReadingHistoryPage({super.key});

  @override
  ConsumerState<ReadingHistoryPage> createState() => _ReadingHistoryPageState();
}

class _ReadingHistoryPageState extends ConsumerState<ReadingHistoryPage> {
  late Future<List<_HistoryRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_HistoryRow>> _load() async {
    final history = ref.read(readingHistoryRepositoryProvider);
    final library = ref.read(libraryRepositoryProvider);
    final sessions = ref.read(readingSessionRepositoryProvider);
    final rows = <_HistoryRow>[];
    for (final entry in await history.loadAll()) {
      rows.add(
        _HistoryRow(
          entry,
          await sessions.aggregate(entry.id),
          entry.collectionId == null
              ? null
              : await library.getCollection(entry.collectionId!),
        ),
      );
    }
    return rows;
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(title: const Text('阅读历史')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: desktop ? 900 : double.infinity,
            ),
            child: FutureBuilder<List<_HistoryRow>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('加载失败：${snapshot.error}'));
                }
                final rows = snapshot.data ?? const <_HistoryRow>[];
                if (rows.isEmpty) {
                  return Center(
                    child: Card(
                      margin: const EdgeInsets.all(24),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '还没有阅读历史',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '打开一本书并完成首次阅读后，记录会显示在这里。',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 24 : 16,
                    20,
                    desktop ? 24 : 16,
                    32,
                  ),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _HistoryCard(
                    row: rows[index],
                    onContinue: rows[index].collection == null
                        ? null
                        : () => _openReader(rows[index].collection!),
                    onDelete: () async {
                      await ref
                          .read(readingHistoryRepositoryProvider)
                          .delete(rows[index].entry.id);
                      _refresh();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReader(LibraryCollection collection) async {
    final repo = ref.read(libraryRepositoryProvider);
    final docs = await repo.getDocuments(collection.id);
    final toc = await repo.getToc(collection.id);
    if (!mounted || docs.isEmpty) return;
    await openReader(
      context,
      ReaderLaunchContext(
        collection: collection,
        documents: docs,
        toc: toc,
        normalizedCharacterLength: collection.normalizedCharacterLength,
        documentLoader: ref.read(documentLoaderProvider),
        progressRepository: ref.read(readingProgressRepositoryProvider),
        bookmarkRepository: ref.read(readerBookmarkRepositoryProvider),
        preferencesRepository: ref.read(readerPreferencesRepositoryProvider),
        appearanceAssetRepository: ref.read(
          readerAppearanceAssetRepositoryProvider,
        ),
        readingHistoryRepository: ref.read(readingHistoryRepositoryProvider),
        readingSessionRepository: ref.read(readingSessionRepositoryProvider),
        inputBindingsRepository: ref.read(
          readerInputBindingsRepositoryProvider,
        ),
        autoReadPreferencesRepository: ref.read(
          autoReadPreferencesRepositoryProvider,
        ),
      ),
    );
    _refresh();
  }
}

class _HistoryRow {
  const _HistoryRow(this.entry, this.aggregate, this.collection);
  final ReadingHistoryEntry entry;
  final ReadingSessionAggregate aggregate;
  final LibraryCollection? collection;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.row,
    required this.onContinue,
    required this.onDelete,
  });
  final _HistoryRow row;
  final VoidCallback? onContinue;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(row.entry.bookTitleSnapshot),
      subtitle: Text(
        readingHistoryDetailLines(
          row.entry,
          row.aggregate,
          isInLibrary: row.collection != null,
        ).join('\n'),
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (_) => onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'delete', child: Text('删除历史')),
        ],
      ),
      onTap: onContinue,
    ),
  );
}

@visibleForTesting
List<String> readingHistoryDetailLines(
  ReadingHistoryEntry entry,
  ReadingSessionAggregate aggregate, {
  required bool isInLibrary,
}) {
  final minutes = aggregate.totalReadingSeconds ~/ 60;
  return [
    '首次 ${_historyDate(entry.firstReadAt)}',
    '最后 ${_historyDate(entry.lastReadAt)}',
    '阅读 $minutes 分钟 · ${aggregate.sessionCount} 次会话',
    if (entry.lastChapterTitleSnapshot?.trim().isNotEmpty == true)
      '最后章节：${entry.lastChapterTitleSnapshot!.trim()}',
    if (entry.lastProgressSnapshot?.trim().isNotEmpty == true)
      '进度快照：${entry.lastProgressSnapshot!.trim()}',
    if (!isInLibrary) '已移出书架',
  ];
}

String _historyDate(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
