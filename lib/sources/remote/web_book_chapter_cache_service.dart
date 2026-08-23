import '../../data/repositories/local_library_repository.dart';
import '../../data/repositories/web_book_source_registry.dart';
import '../../domain/library/library_import_models.dart';
import '../../domain/remote/web_source_contracts.dart';
import 'remote_http_transport.dart';
import 'web_book_runtime.dart';

/// Loads only the contiguous source prefix required by a requested chapter.
///
/// The first WebBook import deliberately stores a small prefix. Since Reader
/// uses one normalized UTF-16 document, an uncached chapter cannot be inserted
/// in the middle without shifting every later offset. This service therefore
/// fetches the missing prefix between the last cached chapter and the target,
/// then appends it atomically. It never preloads the remaining catalog.
final class WebBookChapterCacheService {
  WebBookChapterCacheService({
    required this.repository,
    required this.registry,
    required this.transport,
  });

  final LocalLibraryRepository repository;
  final WebBookSourceRegistry registry;
  final RemoteHttpTransport transport;

  Future<WebBookUpdateResult> ensureChapter({
    required String collectionId,
    required String chapterKey,
  }) async {
    final snapshot = await repository.getWebBookSnapshotMetadata(collectionId);
    final catalog = snapshot.catalog;
    if (catalog.isEmpty) {
      throw const LibraryException('source_missing', '在线书籍目录缓存缺失，请重新检查书源');
    }
    final targetIndex = catalog.indexWhere(
      (entry) => entry.chapterKey == chapterKey,
    );
    if (targetIndex < 0) {
      throw const LibraryException('chapter_not_found', '目录中未找到该章节');
    }
    // A stale diagnostic manifest must not make us claim a cache hit: verify
    // the actual TOC rows, which are the persisted navigation truth.
    final persistedToc = await repository.getToc(collectionId);
    final actualCachedKeys = persistedToc
        .where((entry) => entry.kind == 'chapter' && entry.itemId != null)
        .map((entry) => _chapterKeyFromItemId(entry.itemId!))
        .toSet();
    if (actualCachedKeys.contains(chapterKey)) {
      final collection = await repository.getCollection(collectionId);
      if (collection == null) {
        throw const LibraryException('not_found', '书库记录不存在');
      }
      return WebBookUpdateResult(
        collection: collection,
        status: WebBookUpdateStatus.noChanges,
        addedChapterCount: 0,
        message: '章节已在本地缓存',
      );
    }

    // Only a contiguous prefix is safe for the single normalized document.
    final cachedPrefixLength = _cachedPrefixLength(catalog, actualCachedKeys);
    if (targetIndex < cachedPrefixLength) {
      // This can only happen with a corrupted manifest/TOC. Do not rewrite
      // offsets silently.
      throw const LibraryException(
        'invalid_webbook_cache',
        '章节缓存顺序异常，未改写现有阅读数据',
      );
    }
    final missingEntries = catalog
        .skip(cachedPrefixLength)
        .take(targetIndex - cachedPrefixLength + 1)
        .toList(growable: false);
    if (missingEntries.isEmpty) {
      throw const LibraryException('invalid_webbook_cache', '无法确定待缓存章节范围');
    }
    final sourceEntry = await registry.find(snapshot.sourceId);
    if (sourceEntry == null) {
      throw const LibraryException('source_missing', '原书源未注册，无法获取章节');
    }
    if (!sourceEntry.enabled) {
      throw const LibraryException('source_disabled', '原书源已禁用，请启用后重试');
    }
    final source = sourceEntry.definition.toSource();
    final collection = await repository.getCollection(collectionId);
    if (collection == null) {
      throw const LibraryException('not_found', '书库记录不存在');
    }
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
      transport: transport,
      rules: sourceEntry.definition.toExtractionRules(),
    );
    final chapters = <WebBookChapter>[];
    for (final entry in missingEntries) {
      final result = await runtime.tryOpenChapter(
        source: source,
        detail: detail,
        entry: entry,
      );
      if (!result.isSuccess || result.value == null) {
        final failure = result.failure;
        final detailMessage = failure?.statusCode == null
            ? failure?.message
            : '${failure!.message}（HTTP ${failure.statusCode}）';
        throw LibraryException(
          'chapter_fetch_failed',
          detailMessage ?? '章节加载失败，可重试',
        );
      }
      chapters.add(result.value!);
    }
    return repository.appendWebBookChapterCache(
      collectionId: collectionId,
      chapters: chapters,
      toc: WebBookTableOfContents(bookKey: snapshot.bookKey, entries: catalog),
    );
  }

  int _cachedPrefixLength(
    List<WebBookTocEntry> catalog,
    Set<String> cachedKeys,
  ) {
    var count = 0;
    for (final entry in catalog) {
      if (!cachedKeys.contains(entry.chapterKey)) break;
      count++;
    }
    return count;
  }

  String _chapterKeyFromItemId(String itemId) {
    final marker = ':item:';
    final index = itemId.indexOf(marker);
    return index < 0 ? itemId : itemId.substring(index + marker.length);
  }
}
