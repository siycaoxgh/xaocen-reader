import 'dart:io';

import '../../domain/local_txt/pipeline_progress.dart';

/// TXT 导入请求 —— 管线入口参数。
class TxtImportRequest {
  const TxtImportRequest({
    required this.file,
    required this.cacheDirectory,
    this.allowLargeFileConfirmation = false,
    this.progressSink,
  });

  /// 源 TXT 文件（全程只读）。
  final File file;

  /// 缓存目录（应用管理目录；不写到原 TXT 旁边）。
  final Directory cacheDirectory;

  /// 是否允许大文件确认后处理（>20MB ≤50MB 时需为 true 才开始完整处理）。
  final bool allowLargeFileConfirmation;

  /// 进度回调（可空；纯业务模型，不依赖 UI）。
  final void Function(PipelineProgress progress)? progressSink;
}
