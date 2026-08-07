import 'dart:io';

import '../../domain/library/library_entities.dart';
import '../../domain/local_txt/pipeline_progress.dart';
import '../../sources/local_txt/txt_cancellation.dart';

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
