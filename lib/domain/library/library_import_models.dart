import 'dart:io';

import '../../domain/library/library_entities.dart';
import '../../domain/local_txt/pipeline_progress.dart';
import '../../sources/local_txt/txt_cancellation.dart';
import '../../domain/remote/web_source_contracts.dart';
import '../../domain/remote/remote_source.dart';
import '../../sources/remote/web_book_runtime.dart';

/// 导入请求。
class ImportTxtRequest {
  const ImportTxtRequest({
    required this.externalFile,
    required this.confirmLargeFile,
  });

  /// 外部 TXT（只读；将被复制到应用管理目录）。
  final File externalFile;

  /// 是否确认 >20MB ≤50MB 大文件。
  final bool confirmLargeFile;
}

/// EPUB import request. The source archive is copied into the app-managed
/// library; the user's original file is never modified.
class ImportEpubRequest {
  const ImportEpubRequest({required this.externalFile});

  final File externalFile;
}

/// Result of importing an EPUB package into the existing library tables.
class ImportEpubResult {
  const ImportEpubResult({
    required this.collection,
    required this.alreadyImported,
    this.outcome = ImportOutcome.imported,
  });

  final LibraryCollection collection;
  final bool alreadyImported;
  final ImportOutcome outcome;
}

/// A persisted snapshot of a remote WebBook. The snapshot is intentionally
/// written through the existing ContentSource/Collection/Document tables;
/// no WebBook-specific database schema is required.
class ImportWebBookResult {
  const ImportWebBookResult({
    required this.collection,
    required this.alreadyImported,
  });

  final LibraryCollection collection;
  final bool alreadyImported;
}

/// Runtime projection handed to the existing library writer when a user adds
/// a WebBook from the source browser.
class ImportWebBookRequest {
  const ImportWebBookRequest({
    required this.source,
    required this.detail,
    required this.projection,
    this.sourceName,
    this.catalogEntries,
  });

  final WebBookSource source;
  final WebBookDetail detail;
  final WebBookReaderContentProjection projection;

  /// Full source order received from the remote TOC. Only chapters present in
  /// [projection] are written as local documents; the remaining entries stay
  /// as catalog metadata for future on-demand loading.
  final String? sourceName;
  final List<WebBookTocEntry>? catalogEntries;
}

/// The outcome of checking a persisted WebBook against its source TOC.
///
/// `failed` is reserved for a source-side change which cannot be applied
/// without rewriting existing UTF-16 offsets (for example, an existing
/// chapter disappearing or being moved before another chapter).  In that
/// case the snapshot is left untouched.
enum WebBookUpdateStatus { updated, noChanges, failed }

/// A validated, append-only update plan.  Existing chapter order and offsets
/// are never rewritten; only entries after the last persisted chapter may be
/// added by the current implementation.
class WebBookUpdatePlan {
  const WebBookUpdatePlan({
    required this.collection,
    required this.status,
    required this.newEntries,
    this.message,
  });

  final LibraryCollection collection;
  final WebBookUpdateStatus status;
  final List<WebBookTocEntry> newEntries;
  final String? message;

  bool get canApply => status == WebBookUpdateStatus.updated;
}

/// Result returned after applying a validated WebBook update.
class WebBookUpdateResult {
  const WebBookUpdateResult({
    required this.collection,
    required this.status,
    required this.addedChapterCount,
    this.message,
  });

  final LibraryCollection collection;
  final WebBookUpdateStatus status;
  final int addedChapterCount;
  final String? message;

  bool get updated => status == WebBookUpdateStatus.updated;
}

/// The small manifest boundary needed to refresh a persisted WebBook after a
/// source definition has been kept in, or removed from, the local registry.
class WebBookSnapshotMetadata {
  const WebBookSnapshotMetadata({
    required this.sourceId,
    required this.bookKey,
    required this.detailUri,
    this.sourceName,
    this.sourceEndpoint,
    this.cacheMode = 'fullSnapshot',
    this.cachedChapterKeys = const <String>[],
    this.totalChapterCount,
    this.catalog = const <WebBookTocEntry>[],
  });

  final String sourceId;
  final String bookKey;
  final Uri detailUri;
  final String? sourceName;
  final Uri? sourceEndpoint;
  final String cacheMode;
  final List<String> cachedChapterKeys;
  final int? totalChapterCount;

  /// The source ordered catalog persisted beside the normalized snapshot.
  /// This is metadata only; chapter bodies remain in the existing normalized
  /// document/cache and are loaded on demand.
  final List<WebBookTocEntry> catalog;
}

/// 导入结果。
class ImportTxtResult {
  const ImportTxtResult({
    required this.collection,
    required this.alreadyImported,
    this.outcome = ImportOutcome.imported,
  });

  final LibraryCollection collection;

  /// 同 hash 重复导入时为 true（不复制第二份、不产生第二本）。
  final bool alreadyImported;

  /// 导入/重复导入最终结果分类。
  final ImportOutcome outcome;
}

/// 导入结果分类。
enum ImportOutcome {
  /// 新导入成功。
  imported,

  /// 重复导入且 managed 数据健康（直接复用）。
  alreadyImported,

  /// 重复导入但 managed 派生数据不健康，已自动修复。
  repairedExisting,

  /// 重复导入但 managed source.txt 也损坏，需要用户明确重新导入。
  corruptedManagedCopy,
}

/// 取消令牌（复用 M1 语义，直接使用 M1 类型）。
/// 保留此别名避免 UI 层依赖 sources 层细节。
typedef ImportCancellationToken = TxtImportCancellationToken;

/// 取消异常。
class ImportCancelledException implements Exception {
  const ImportCancelledException();
  @override
  String toString() => 'ImportCancelledException: import cancelled';
}

/// 业务异常。
class LibraryException implements Exception {
  const LibraryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'LibraryException($code): $message';
}

/// 大文件需要确认。
class LargeFileConfirmationRequired implements Exception {
  const LargeFileConfirmationRequired(this.size);
  final int size;
  @override
  String toString() => 'LargeFileConfirmationRequired: $size bytes';
}

/// 超过 50MB 不支持。
class LargeFileUnsupported implements Exception {
  const LargeFileUnsupported(this.size);
  final int size;
  @override
  String toString() => 'LargeFileUnsupported: $size bytes';
}

/// 进度回调类型。
typedef ImportProgressCallback = void Function(PipelineProgress progress);
