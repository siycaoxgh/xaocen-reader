/// 大文件阈值 —— 集中定义，禁止散落在 UI 或服务中。
///
/// - ≤20MB：正常处理；
/// - >20MB 且 ≤50MB：需要调用方确认（requiresLargeFileConfirmation）；
/// - >50MB：0.1.x 不支持打开（unsupportedLargeFile）。
abstract final class LargeFilePolicy {
  /// 正常处理上限（字节）。
  static const int normalMaxBytes = 20 * 1024 * 1024; // 20MB

  /// 确认后处理上限（字节）。
  static const int confirmedMaxBytes = 50 * 1024 * 1024; // 50MB

  /// 判断给定文件大小属于哪一档。
  static LargeFileClass classify(int sizeBytes) {
    if (sizeBytes <= normalMaxBytes) return LargeFileClass.normal;
    if (sizeBytes <= confirmedMaxBytes) {
      return LargeFileClass.requiresConfirmation;
    }
    return LargeFileClass.unsupported;
  }
}

enum LargeFileClass {
  /// ≤20MB：正常处理。
  normal,

  /// >20MB 且 ≤50MB：需调用方确认后才开始完整处理。
  requiresConfirmation,

  /// >50MB：0.1.x 不尝试打开。
  unsupported,
}
