import '../../domain/local_txt/large_file_policy.dart';
import '../../domain/local_txt/txt_index.dart';

/// 导入结果 —— 含索引与管线统计。
class TxtImportResult {
  const TxtImportResult({
    required this.index,
    required this.cacheHit,
    required this.stats,
  });

  final TxtIndex index;

  /// 是否命中缓存（第二次打开同一文件必须为 true，不重新扫描）。
  final bool cacheHit;

  final TxtImportStats stats;
}

/// 管线各阶段耗时统计（毫秒）。
class TxtImportStats {
  const TxtImportStats({
    this.fileReadMs = 0,
    this.decodeMs = 0,
    this.normalizeMs = 0,
    this.scanMs = 0,
    this.dedupeMs = 0,
    this.cacheWriteMs = 0,
    this.cacheReadMs = 0,
    this.totalMs = 0,
  });

  final int fileReadMs;
  final int decodeMs;
  final int normalizeMs;
  final int scanMs;
  final int dedupeMs;
  final int cacheWriteMs;
  final int cacheReadMs;
  final int totalMs;
}

/// 大文件确认要求结果。
class TxtLargeFileNotice {
  const TxtLargeFileNotice({
    required this.fileClass,
    required this.size,
    required this.message,
  });

  final LargeFileClass fileClass;
  final int size;
  final String message;
}
