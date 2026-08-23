import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/library/library_entities.dart';
import '../domain/library/library_import_models.dart';
import '../domain/local_txt/large_file_policy.dart';
import '../domain/local_txt/pipeline_progress.dart';
import '../domain/reader/reading_history.dart';
import '../domain/reader/reader_progress_state.dart';
import '../domain/reader/reader_locator.dart';
import '../design/tokens/app_tokens.dart';
import '../data/repositories/collection_repair_service.dart';
import '../reader/reader_page.dart';
import 'providers.dart';
import 'reading_history_page.dart';
import 'metadata_edit_page.dart';
import 'product_identity.dart';
import 'app_shell_contract.dart';
import '../domain/remote/web_source_contracts.dart';
import '../sources/remote/web_book_runtime.dart';
import '../sources/remote/web_book_chapter_cache_service.dart';

bool isOnlineBookCollection(LibraryCollection collection) =>
    collection.sourceId.startsWith('web-book-source:');

String collectionSourceLabel(LibraryCollection collection) =>
    isOnlineBookCollection(collection) ? '在线书源' : '本地书籍';

String collectionDeleteMessage(LibraryCollection collection) =>
    isOnlineBookCollection(collection)
    ? '将移除书架记录和本地缓存，不影响在线书源及网站原文。'
    : '将删除书库记录与应用管理副本，不影响外部原文件。';

/// M2 最小书架 —— 本地书库（功能性界面，非 V3 统一 UI）。
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, this.embedded = false});

  /// The shell owns navigation chrome when this page is embedded.
  final bool embedded;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final importState = ref.watch(importProgressProvider);

    final shellSurface = Theme.of(context).colorScheme.surface;
    return Scaffold(
      // Embedded library pages must use the shell's effective surface for
      // their large canvas. Cards and list items retain their own surfaces.
      backgroundColor: shellSurface,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(productNameForPlatform()),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReadingHistoryPage(),
                      ),
                    );
                    if (mounted) {
                      ref.invalidate(collectionsProvider);
                      ref.invalidate(recentReadingProvider);
                    }
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('阅读历史'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('我的'),
                ),
              ],
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本地书库', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                if (!importState.running)
                  FilledButton.icon(
                    onPressed: _pickAndImport,
                    icon: const Icon(Icons.add),
                    label: const Text('导入书籍'),
                  )
                else
                  _ImportProgressPanel(state: importState),
                if (importState.error != null &&
                    importState.error == 'large_file_confirmation_required')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _LargeFileConfirmBar(onConfirm: _importConfirmed),
                  ),
                if (importState.error != null &&
                    importState.error != 'large_file_confirmation_required')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      importState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (importState.done)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      importState.alreadyImported ? '该书已导入（未重复添加）' : '导入完成',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          if (!widget.embedded)
            RecentReadingSection(onOpen: (entry) => _openHistoryEntry(entry)),
          Expanded(
            child: collections.when(
              data: (list) => list.isEmpty
                  ? const _LibraryEmptyState()
                  : _buildCollectionSurface(context, list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionSurface(
    BuildContext context,
    List<LibraryCollection> collections,
  ) {
    final desktop = widget.embedded && AppShellLayout.isDesktop(context);
    if (!desktop) {
      return ListView.separated(
        itemCount: collections.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          clipBehavior: Clip.antiAlias,
          child: _CollectionTile(collection: collections[i]),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 440,
            mainAxisExtent: 140,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: collections.length,
          itemBuilder: (context, index) => Card(
            clipBehavior: Clip.antiAlias,
            child: _CollectionTile(collection: collections[index]),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'epub'],
      dialogTitle: '选择 TXT 或 EPUB 文件',
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    final size = await file.length();
    final fileClass = LargeFilePolicy.classify(size);
    if (fileClass == LargeFileClass.unsupported) {
      ref
          .read(importProgressProvider.notifier)
          .setError('文件超过 50MB，不支持导入（${_fmtSize(size)}）');
      return;
    }
    final extension = file.uri.pathSegments.last.toLowerCase();
    if (extension.endsWith('.epub')) {
      ref.read(importProgressProvider.notifier).startEpub(file);
    } else {
      // 启动 TXT 导入；>20MB 会抛 confirmation，UI 显示确认条
      ref
          .read(importProgressProvider.notifier)
          .start(ImportTxtRequest(externalFile: file, confirmLargeFile: false));
    }
  }

  void _importConfirmed() {
    final notifier = ref.read(importProgressProvider.notifier);
    notifier.retryWithConfirmation();
  }

  String _fmtSize(int size) {
    if (size >= 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(1)}MB';
    }
    return '${(size / 1024).toStringAsFixed(0)}KB';
  }

  Future<void> _openHistoryEntry(ReadingHistoryEntry entry) async {
    final collectionId = entry.collectionId;
    if (collectionId == null) return;
    final collection = await ref
        .read(libraryRepositoryProvider)
        .getCollection(collectionId);
    if (collection == null || !mounted) return;
    final docs = await ref
        .read(libraryRepositoryProvider)
        .getDocuments(collection.id);
    final toc = await ref.read(libraryRepositoryProvider).getToc(collection.id);
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
        fontRepository: ref.read(readerFontRepositoryProvider),
        readingHistoryRepository: ref.read(readingHistoryRepositoryProvider),
        readingSessionRepository: ref.read(readingSessionRepositoryProvider),
        inputBindingsRepository: ref.read(
          readerInputBindingsRepositoryProvider,
        ),
        autoReadPreferencesRepository: ref.read(
          autoReadPreferencesRepositoryProvider,
        ),
        ttsPreferencesRepository: ref.read(ttsPreferencesRepositoryProvider),
      ),
    );
    ref.invalidate(recentReadingProvider);
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books_outlined, size: 42, color: scheme.primary),
            const SizedBox(height: 12),
            Text('书架还是空的', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '书库为空，点击“导入书籍”开始',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentReadingSection extends ConsumerWidget {
  const RecentReadingSection({
    super.key,
    required this.onOpen,
    this.showEmpty = false,
  });
  final ValueChanged<ReadingHistoryEntry> onOpen;
  final bool showEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentReadingProvider);
    return recent.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) {
          if (!showEmpty) return const SizedBox.shrink();
          return Card(
            child: ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('暂无最近阅读'),
              subtitle: const Text('打开一本书后，会在这里显示继续阅读入口'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '最近阅读',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...entries.map(
              (entry) => ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(entry.bookTitleSnapshot),
                subtitle: Text(
                  '${entry.lastChapterTitleSnapshot ?? '全文'} · ${entry.lastProgressSnapshot ?? '未记录进度'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpen(entry),
              ),
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}

class _LargeFileConfirmBar extends ConsumerWidget {
  const _LargeFileConfirmBar({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Icon(Icons.warning_amber, color: Colors.orange),
        const SizedBox(width: 8),
        const Expanded(child: Text('文件超过 20MB，处理需要较长时间，确认继续？')),
        TextButton(onPressed: onConfirm, child: const Text('确认导入')),
      ],
    );
  }
}

class _ImportProgressPanel extends ConsumerWidget {
  const _ImportProgressPanel({required this.state});
  final ImportProgressState state;

  static const _phaseLabels = {
    PipelinePhase.validatingFile: '校验文件',
    PipelinePhase.readingBytes: '读取文件',
    PipelinePhase.detectingEncoding: '检测编码',
    PipelinePhase.loadingEncodingTable: '加载编码表',
    PipelinePhase.decoding: '解码',
    PipelinePhase.normalizing: '规范化',
    PipelinePhase.scanningToc: '扫描卷章',
    PipelinePhase.writingCache: '保存索引',
    PipelinePhase.completed: '完成',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = state.progress;
    final label = p == null ? '准备中…' : _phaseLabels[p.phase] ?? p.phase.name;
    final percent = p?.percent ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Text('${(percent * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: percent),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => ref.read(importProgressProvider.notifier).cancel(),
          icon: const Icon(Icons.close),
          label: const Text('取消'),
        ),
      ],
    );
  }
}

/// Image-free, deterministic cover shown until a real local/online cover is
/// available.  The title-derived colors remain stable across rebuilds.
class BookCoverPlaceholder extends StatelessWidget {
  const BookCoverPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hash = _stableTextHash(title);
    final first = Color.lerp(
      scheme.primary,
      scheme.secondary,
      (hash % 100) / 100,
    )!;
    final second = Color.lerp(
      scheme.secondary,
      scheme.tertiary,
      ((hash ~/ 100) % 100) / 100,
    )!;
    return Semantics(
      label: '封面 $title',
      image: true,
      child: SizedBox(
        width: 72,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [first, second],
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 3,
                  offset: Offset(1, 2),
                  color: Colors.black26,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Center(
                child: Text(
                  title.characters.take(1).toString(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.15,
                    shadows: const [
                      Shadow(blurRadius: 2, color: Colors.black38),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookCardDetails extends ConsumerWidget {
  const _BookCardDetails({
    required this.title,
    required this.author,
    required this.collection,
    required this.progress,
  });

  final String title;
  final String? author;
  final LibraryCollection collection;
  final AsyncValue<ReaderProgressState?> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final online = isOnlineBookCollection(collection);
    final remote = online
        ? ref.watch(webBookSnapshotMetadataProvider(collection.id))
        : const AsyncValue<WebBookSnapshotMetadata?>.data(null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (online
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                collectionSourceLabel(collection),
                style: textTheme.labelSmall,
              ),
            ),
            if (online) ...[
              const SizedBox(width: 6),
              Expanded(
                child: remote.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => Text(
                    '在线内容',
                    style: textTheme.labelSmall?.copyWith(color: muted),
                  ),
                  data: (metadata) => Text(
                    _onlineSourceSummary(metadata),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          author == null || author!.isEmpty ? '作者未知' : '作者：$author',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(color: muted),
        ),
        Text(
          '${collection.itemCount} 章 · ${collection.detectedEncoding.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 8),
        progress.when(
          loading: () =>
              Text('读取进度…', style: textTheme.bodySmall?.copyWith(color: muted)),
          error: (_, _) => Text(
            '尚未开始阅读',
            style: textTheme.bodySmall?.copyWith(color: muted),
          ),
          data: (value) => Text(
            _progressLabel(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }

  String _onlineSourceSummary(WebBookSnapshotMetadata? metadata) {
    if (metadata == null) return '在线内容';
    final source = metadata.sourceName?.trim();
    final host = metadata.sourceEndpoint?.host ?? metadata.detailUri.host;
    final mode = switch (metadata.cacheMode) {
      'chapterCache' => '章节缓存',
      'fullSnapshot' => '完整本地快照',
      _ => '在线内容',
    };
    final sourceLabel = source == null || source.isEmpty ? '在线书源' : source;
    return '$sourceLabel · $host · $mode';
  }

  String _progressLabel(ReaderProgressState? value) {
    if (value == null || value.absoluteCharacterOffset <= 0) return '尚未开始阅读';
    final length = collection.normalizedCharacterLength;
    if (length <= 0) return '已有阅读进度';
    final percent = (value.absoluteCharacterOffset / length * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);
    return '阅读进度 $percent%';
  }
}

int _stableTextHash(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

class BookCover extends ConsumerWidget {
  const BookCover({super.key, required this.collection, required this.title});

  final LibraryCollection collection;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref
        .watch(localBookCoverRepositoryProvider)
        ?.resolve(collection.coverPath);
    if (file == null) return BookCoverPlaceholder(title: title);
    return SizedBox(
      width: 72,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => BookCoverPlaceholder(title: title),
        ),
      ),
    );
  }
}

class _CollectionTile extends ConsumerWidget {
  const _CollectionTile({required this.collection});
  final LibraryCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildBookCard(context, ref);
  }

  Widget _buildBookCard(BuildContext context, WidgetRef ref) {
    final title = _safeTitle(collection);
    final progress = ref.watch(collectionProgressProvider(collection.id));
    return InkWell(
      key: ValueKey('book-card-${collection.id}'),
      onTap: () => _openReader(context, ref),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BookCover(collection: collection, title: title),
            const SizedBox(width: 14),
            Expanded(
              child: _BookCardDetails(
                title: title,
                author: collection.author?.trim(),
                collection: collection,
                progress: progress,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: () => _confirmDelete(context, ref),
            ),
            PopupMenuButton<String>(
              tooltip: '书籍操作',
              onSelected: (value) async {
                if (value == 'edit') {
                  final updated = await Navigator.of(context)
                      .push<LibraryCollection>(
                        MaterialPageRoute(
                          builder: (_) =>
                              MetadataEditPage(collection: collection),
                        ),
                      );
                  if (updated != null && context.mounted) {
                    ref.invalidate(collectionsProvider);
                  }
                } else if (value == 'update') {
                  await _checkWebBookUpdates(context, ref);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('编辑书籍信息')),
                if (collection.sourceId.startsWith('web-book-source:'))
                  const PopupMenuItem(value: 'update', child: Text('检查新章节')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _safeTitle(LibraryCollection value) {
    final title = value.title.trim();
    if (title.isNotEmpty) return title;
    final fileName = value.fileName?.trim();
    if (fileName != null && fileName.isNotEmpty) return fileName;
    return '未命名书籍';
  }

  Future<void> _openReader(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(libraryRepositoryProvider);
      final docs = await repo.getDocuments(collection.id);
      final toc = await repo.getToc(collection.id);
      if (docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('该书没有可用文档')));
        return;
      }
      if (!context.mounted) return;
      await openReader(
        context,
        _readerLaunch(ref, collection: collection, documents: docs, toc: toc),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打开失败: $e')));
    }
  }

  ReaderLaunchContext _readerLaunch(
    WidgetRef ref, {
    required LibraryCollection collection,
    required List<LibraryDocument> documents,
    required List<LibraryTocEntry> toc,
    ReaderLocator? initialLocatorOverride,
  }) {
    return ReaderLaunchContext(
      collection: collection,
      documents: documents,
      toc: toc,
      normalizedCharacterLength: collection.normalizedCharacterLength,
      documentLoader: ref.read(documentLoaderProvider),
      progressRepository: ref.read(readingProgressRepositoryProvider),
      bookmarkRepository: ref.read(readerBookmarkRepositoryProvider),
      preferencesRepository: ref.read(readerPreferencesRepositoryProvider),
      appearanceAssetRepository: ref.read(
        readerAppearanceAssetRepositoryProvider,
      ),
      fontRepository: ref.read(readerFontRepositoryProvider),
      readingHistoryRepository: ref.read(readingHistoryRepositoryProvider),
      readingSessionRepository: ref.read(readingSessionRepositoryProvider),
      inputBindingsRepository: ref.read(readerInputBindingsRepositoryProvider),
      autoReadPreferencesRepository: ref.read(
        autoReadPreferencesRepositoryProvider,
      ),
      ttsPreferencesRepository: ref.read(ttsPreferencesRepositoryProvider),
      repair: () => _repairCollection(ref, collection.id),
      initialLocatorOverride: initialLocatorOverride,
      loadUncachedChapter: isOnlineBookCollection(collection)
          ? (entry) => _loadUncachedChapter(ref, entry)
          : null,
    );
  }

  Future<ReaderLaunchContext> _loadUncachedChapter(
    WidgetRef ref,
    LibraryTocEntry entry,
  ) async {
    const marker = ':toc:';
    final markerIndex = entry.id.indexOf(marker);
    if (markerIndex < 0) {
      throw const LibraryException('chapter_not_found', '无法识别在线章节');
    }
    final chapterKey = entry.id.substring(markerIndex + marker.length);
    final result = await WebBookChapterCacheService(
      repository: ref.read(libraryRepositoryProvider),
      registry: ref.read(webBookSourceRegistryProvider),
      transport: ref.read(webBookTransportProvider),
    ).ensureChapter(collectionId: collection.id, chapterKey: chapterKey);
    final repository = ref.read(libraryRepositoryProvider);
    final updatedCollection = result.collection;
    final docs = await repository.getDocuments(updatedCollection.id);
    final toc = await repository.getToc(updatedCollection.id);
    if (docs.isEmpty) {
      throw const LibraryException('source_missing', '章节缓存后没有可读文档');
    }
    return _readerLaunch(
      ref,
      collection: updatedCollection,
      documents: docs,
      toc: toc,
    );
  }

  /// 修复 managed collection（返回 null 成功，否则错误信息）。
  Future<String?> _repairCollection(WidgetRef ref, String collectionId) async {
    try {
      final repo = ref.read(libraryRepositoryProvider);
      final repair = await CollectionRepairService(
        database: repo.database,
        fileManager: repo.fileManager,
        encodingIndexProvider: repo.encodingIndexProvider,
      ).repair(collectionId);
      ref.invalidate(collectionsProvider);
      return repair.repaired ? null : repair.error;
    } catch (e) {
      return '$e';
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isOnlineBookCollection(collection) ? '移除在线书源书籍？' : '删除这本书？',
        ),
        content: Text(collectionDeleteMessage(collection)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isOnlineBookCollection(collection) ? '移除' : '删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(libraryRepositoryProvider).removeCollection(collection.id);
      ref.invalidate(collectionsProvider);
    }
  }

  Future<void> _checkWebBookUpdates(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('正在检查新章节…')));
    try {
      final repository = ref.read(libraryRepositoryProvider);
      final snapshot = await repository.getWebBookSnapshotMetadata(
        collection.id,
      );
      final sourceEntry = await ref
          .read(webBookSourceRegistryProvider)
          .find(snapshot.sourceId);
      if (sourceEntry == null) {
        throw const LibraryException('source_missing', '原书源未注册，无法检查更新');
      }
      if (!sourceEntry.enabled) {
        throw const LibraryException('source_disabled', '原书源已禁用，请先启用后再检查更新');
      }
      final source = sourceEntry.definition.toSource();
      final detail = WebBookDetail(
        bookKey: snapshot.bookKey,
        title: collection.title,
        detailUri: snapshot.detailUri,
        author: collection.author,
        description: collection.description,
        ruleSet: WebRuleSetRef(
          id: sourceEntry.definition.ruleSetId,
          version: sourceEntry.definition.ruleVersion,
        ),
      );
      final runtime = WebBookHttpRuntime(
        transport: ref.read(webBookTransportProvider),
        rules: sourceEntry.definition.toExtractionRules(),
      );
      final tocResult = await runtime.tryLoadTableOfContents(
        source: source,
        detail: detail,
      );
      if (!tocResult.isSuccess || tocResult.value == null) {
        throw StateError(tocResult.failure?.message ?? '目录加载失败');
      }
      final toc = tocResult.value!;
      final plan = await repository.planWebBookUpdate(
        collectionId: collection.id,
        toc: toc,
      );
      if (plan.status == WebBookUpdateStatus.noChanges) {
        if (!context.mounted) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(plan.message ?? '当前已是最新章节')));
        return;
      }
      if (plan.status == WebBookUpdateStatus.failed) {
        throw StateError(plan.message ?? '无法安全更新书籍');
      }
      final chapters = <WebBookChapter>[];
      for (final entry in plan.newEntries) {
        final result = await runtime.tryOpenChapter(
          source: source,
          detail: detail,
          entry: entry,
        );
        if (!result.isSuccess || result.value == null) {
          throw StateError(result.failure?.message ?? '章节加载失败：${entry.title}');
        }
        chapters.add(result.value!);
      }
      final result = await repository.updateWebBook(
        plan: plan,
        chapters: chapters,
        toc: toc,
      );
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message ?? '在线书籍更新完成')));
      ref.invalidate(collectionsProvider);
    } catch (error) {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('检查新章节失败：$error')));
    }
  }
}
