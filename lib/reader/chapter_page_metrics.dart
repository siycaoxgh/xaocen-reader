import 'dart:collection';

import '../domain/library/chapter_boundary_resolver.dart';
import '../domain/library/library_entities.dart';
import '../domain/reader/reader_locator.dart';
import '../domain/reader/paged_text_range.dart';
import 'paged_layout_engine.dart';

/// The chapter page indicator is derived from the active layout. It is never
/// persisted and must never be used as a ReaderLocator restore anchor.
enum ChapterPageMetricsStatus { ready }

final class ChapterPageMetrics {
  const ChapterPageMetrics({
    required this.boundary,
    required this.currentPageNumber,
    required this.totalPageCount,
    required this.currentPage,
    required this.layoutSignature,
    required this.status,
    required this.elapsed,
    required this.fromCache,
  });

  final CurrentChapterBoundary boundary;
  final int currentPageNumber;
  final int totalPageCount;
  final PagedTextRange currentPage;
  final PagedLayoutSignature layoutSignature;
  final ChapterPageMetricsStatus status;
  final Duration elapsed;
  final bool fromCache;
}

/// Bounded, layout-signature keyed chapter page range cache.
///
/// The cache deliberately stores only a few chapters. It is not a whole-book
/// pagination cache and does not affect PageWindow's bounded interaction
/// window.
final class ChapterPageMetricsCache {
  ChapterPageMetricsCache({this.capacity = 3}) : assert(capacity > 0);

  final int capacity;
  final LinkedHashMap<String, List<PagedTextRange>> _entries =
      LinkedHashMap<String, List<PagedTextRange>>();

  int hits = 0;
  int misses = 0;

  List<PagedTextRange>? read(String key) {
    final value = _entries.remove(key);
    if (value == null) {
      misses++;
      return null;
    }
    hits++;
    _entries[key] = value;
    return value;
  }

  void write(String key, List<PagedTextRange> pages) {
    _entries.remove(key);
    _entries[key] = List.unmodifiable(pages);
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}

/// Computes the current chapter's page range without touching PageWindow.
///
/// TextPainter-backed pagination must run on Flutter's UI isolate, so the
/// resolver yields between small page batches. The caller supplies a
/// generation guard; stale requests stop before appending to the cache or
/// publishing a result.
final class ChapterPageMetricsResolver {
  ChapterPageMetricsResolver({ChapterPageMetricsCache? cache})
    : cache = cache ?? ChapterPageMetricsCache();

  final ChapterPageMetricsCache cache;

  Future<ChapterPageMetrics?> resolve({
    required PagedLayoutEngine engine,
    required ReaderLocator locator,
    required List<LibraryTocEntry> toc,
    required int normalizedLength,
    required String collectionId,
    String? normalizedHash,
    required bool Function() isCurrent,
  }) async {
    if (!isCurrent()) return null;
    final boundary = ChapterBoundaryResolver.resolve(
      locatorOffset: locator.absoluteCharacterOffset,
      toc: toc,
      normalizedLength: normalizedLength,
    );
    if (boundary == null || boundary.endOffset <= boundary.startOffset) {
      return null;
    }

    final signature = engine.signature;
    final key = _cacheKey(
      collectionId: collectionId,
      normalizedHash: normalizedHash,
      boundary: boundary,
      signature: signature,
    );
    final stopwatch = Stopwatch()..start();
    var fromCache = true;
    var pages = cache.read(key);
    if (pages == null) {
      fromCache = false;
      pages = await _paginateChapter(
        engine: engine,
        boundary: boundary,
        isCurrent: isCurrent,
      );
      if (pages == null || pages.isEmpty || !isCurrent()) return null;
      cache.write(key, pages);
    }
    if (!isCurrent()) return null;

    final target = locator.absoluteCharacterOffset.clamp(
      boundary.startOffset,
      boundary.endOffset - 1,
    );
    var pageIndex = pages.indexWhere((page) => page.contains(target));
    if (pageIndex < 0) {
      // A malformed/stale locator must not crash or produce page zero. Clamp
      // to the last derived page while retaining the original locator as the
      // only position truth.
      pageIndex = pages.length - 1;
    }
    stopwatch.stop();
    return ChapterPageMetrics(
      boundary: boundary,
      currentPageNumber: pageIndex + 1,
      totalPageCount: pages.length,
      currentPage: pages[pageIndex],
      layoutSignature: signature,
      status: ChapterPageMetricsStatus.ready,
      elapsed: stopwatch.elapsed,
      fromCache: fromCache,
    );
  }

  Future<List<PagedTextRange>?> _paginateChapter({
    required PagedLayoutEngine engine,
    required CurrentChapterBoundary boundary,
    required bool Function() isCurrent,
  }) async {
    final pages = <PagedTextRange>[];
    var page = engine.layoutForwardPage(boundary.startOffset);
    var batch = 0;
    while (page != null && isCurrent()) {
      final start = page.startCharacterOffset;
      final end = page.endCharacterOffset.clamp(start, boundary.endOffset);
      if (end <= start) break;
      pages.add(
        PagedTextRange(startCharacterOffset: start, endCharacterOffset: end),
      );
      if (end >= boundary.endOffset) break;
      final next = engine.layoutForwardPage(end);
      if (next == null || next.startCharacterOffset <= start) break;
      page = next;
      batch++;
      if (batch >= 8) {
        batch = 0;
        await Future<void>.delayed(Duration.zero);
      }
    }
    return isCurrent() ? pages : null;
  }

  String _cacheKey({
    required String collectionId,
    required String? normalizedHash,
    required CurrentChapterBoundary boundary,
    required PagedLayoutSignature signature,
  }) =>
      '$collectionId|${normalizedHash ?? '-'}|'
      '${boundary.startOffset}:${boundary.endOffset}|${signature.cacheKey}';
}
