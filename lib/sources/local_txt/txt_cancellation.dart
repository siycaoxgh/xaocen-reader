/// 取消令牌 —— 供 UI 消费的取消请求。
///
/// 取消后：Isolate 停止、临时缓存清理、外部 TXT 不受影响、不返回半成品索引。
class TxtImportCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// 取消异常。
class TxtImportCancelledException implements Exception {
  const TxtImportCancelledException();

  @override
  String toString() => 'TxtImportCancelledException: import cancelled';
}
