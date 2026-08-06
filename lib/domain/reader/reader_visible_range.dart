/// 真实可见范围 —— 来自实际已布局内容。
///
/// 计算必须来自实际已布局内容（TextPainter 实测），
/// 禁止使用 scrollOffset 比例 / block 比例 / 章节比例 / 估算行高 / 页码。
library;

/// 真实可见范围（UTF-16 码元偏移）。
class ReaderVisibleRange {
  const ReaderVisibleRange({
    required this.startCharacterOffset,
    required this.endCharacterOffset,
    required this.firstVisibleBlock,
    required this.lastVisibleBlock,
    required this.measuredAt,
  });

  /// 视口顶部可见的 UTF-16 码元偏移（含）。
  final int startCharacterOffset;

  /// 视口底部可见的 UTF-16 码元偏移（不含）。
  final int endCharacterOffset;

  /// 首个可见块序号。
  final int firstVisibleBlock;

  /// 末个可见块序号。
  final int lastVisibleBlock;

  final DateTime measuredAt;

  bool contains(int offset) =>
      offset >= startCharacterOffset && offset < endCharacterOffset;

  @override
  String toString() =>
      'VisibleRange[$startCharacterOffset,$endCharacterOffset) blocks[$firstVisibleBlock..$lastVisibleBlock]';
}

/// 恢复状态机状态。
enum ReaderRestorePhase {
  loadingDocument,
  buildingBlockIndex,
  locatingTargetBlock,
  jumpingToBlock,
  resolvingTargetCharacter,
  confirmingVisibleRange,
  completed,
  failed,
}
