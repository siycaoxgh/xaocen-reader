/// 阅读模式 —— 纵向滚动（M3）与横向分页（M4）。
///
/// 两种模式共享同一位置真源：ReaderLocator.absoluteCharacterOffset
/// （normalized.txt UTF-16 码元偏移）。
/// Page / pageIndex / PageView index / scroll pixels 全部只是派生状态。
library;

/// 阅读模式。
enum ReaderMode {
  /// 纵向虚拟滚动（M3 基线，默认）。
  vertical,

  /// 横向分页（M4 新增）。
  paged,
}

/// 模式切换状态机（§二十一）。
///
/// 切换期间旧组件禁止写进度；过期异步结果必须被 generation/token 拒绝。
enum ReaderModeTransitionState {
  /// 无切换进行中。
  idle,

  /// 纵向 → 分页进行中。
  verticalToPaged,

  /// 分页 → 纵向进行中。
  pagedToVertical,
}
