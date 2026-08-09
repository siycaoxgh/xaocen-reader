import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reader/reading_history.dart';
import '../domain/reader/reading_session.dart';
import '../domain/library/library_entities.dart';
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
    final entries = await history.loadAll();
    final rows = <_HistoryRow>[];
    for (final entry in entries) {
      final aggregate = await sessions.aggregate(entry.id);
      final collection = entry.collectionId == null
          ? null
          : await library.getCollection(entry.collectionId!);
      rows.add(_HistoryRow(entry, aggregate, collection));
    }
    return rows;
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('阅读历史')),
      body: FutureBuilder<List<_HistoryRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }
          final rows = snapshot.data ?? const <_HistoryRow>[];
          if (rows.isEmpty) return const Center(child: Text('还没有阅读历史'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
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
        readingHistoryRepository: ref.read(readingHistoryRepositoryProvider),
        readingSessionRepository: ref.read(readingSessionRepositoryProvider),
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
  Widget build(BuildContext context) {
    final e = row.entry;
    final minutes = row.aggregate.totalReadingSeconds ~/ 60;
    return Card(
      child: ListTile(
        title: Text(e.bookTitleSnapshot),
        subtitle: Text(
          [
            '首次 ${_date(e.firstReadAt)}',
            '最后 ${_date(e.lastReadAt)}',
            '阅读 $minutes 分钟 · $row.aggregate.sessionCount 次会话',
            if (e.lastChapterTitleSnapshot != null)
              '最后章节：$e.lastChapterTitleSnapshot',
            if (e.lastProgressSnapshot != null) '进度快照：$e.lastProgressSnapshot',
            if (row.collection == null) '已移出书架',
          ].join('\n'),
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

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
