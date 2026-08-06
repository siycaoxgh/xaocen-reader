/// 管线阶段 —— 纯业务进度模型，不依赖任何 UI。
enum PipelinePhase {
  validatingFile,
  readingBytes,
  detectingEncoding,
  loadingEncodingTable,
  decoding,
  normalizing,
  scanningToc,
  deduplicating,
  writingCache,
  completed,
  failed,
  cancelled,
}

/// 进度快照 —— 可被后续 UI 消费的纯数据。
class PipelineProgress {
  const PipelineProgress({
    required this.phase,
    this.processedBytes = 0,
    this.processedCharacters = 0,
    this.totalBytes = 0,
    this.totalCharacters = 0,
    this.elapsed = Duration.zero,
    this.message = '',
  });

  final PipelinePhase phase;

  /// 已处理字节（读取/解码阶段）或已处理字符（规范化/扫描阶段）。
  final int processedBytes;
  final int processedCharacters;

  /// 总量（0 表示未知/不适用）。
  final int totalBytes;
  final int totalCharacters;

  final Duration elapsed;

  /// 可展示信息（不含正文内容）。
  final String message;

  /// 0..100；总量未知时返回 null。
  double? get percent {
    if (phase == PipelinePhase.completed) return 100;
    if (phase == PipelinePhase.failed || phase == PipelinePhase.cancelled) {
      return null;
    }
    final total = totalBytes > 0 ? totalBytes : totalCharacters;
    final processed = processedBytes > 0 ? processedBytes : processedCharacters;
    if (total <= 0) return null;
    return (processed / total * 100).clamp(0, 100);
  }

  PipelineProgress copyWith({
    PipelinePhase? phase,
    int? processedBytes,
    int? processedCharacters,
    int? totalBytes,
    int? totalCharacters,
    Duration? elapsed,
    String? message,
  }) {
    return PipelineProgress(
      phase: phase ?? this.phase,
      processedBytes: processedBytes ?? this.processedBytes,
      processedCharacters: processedCharacters ?? this.processedCharacters,
      totalBytes: totalBytes ?? this.totalBytes,
      totalCharacters: totalCharacters ?? this.totalCharacters,
      elapsed: elapsed ?? this.elapsed,
      message: message ?? this.message,
    );
  }
}
