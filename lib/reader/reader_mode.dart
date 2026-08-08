/// 阅读模式（UI/Reader 层）。
///
/// 两种模式共享同一位置真源：ReaderLocator.absoluteCharacterOffset
/// （normalized.txt UTF-16 码元偏移）。
/// Page / pageIndex / PageView index / scroll pixels 全部只是派生状态。
///
/// 持久化用 domain 层 `ReadingMode`（见 reader_progress_state.dart）：
/// [ReaderMode] 在此仅是别名，保证 UI 层既有用法不变。
library;

import '../../domain/reader/reading_mode.dart';

export '../../domain/reader/reading_mode.dart' show ReadingMode;

/// 阅读模式（= domain ReadingMode 别名）。
typedef ReaderMode = ReadingMode;

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
