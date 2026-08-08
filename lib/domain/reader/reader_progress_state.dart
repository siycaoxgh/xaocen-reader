/// 阅读进度状态（持久化合同，M4 P1）。
///
/// ```
/// ReaderProgressState =
///   collectionId
///   absoluteCharacterOffset   ← 唯一位置真源（UTF-16 码元偏移）
///   readingMode               ← 阅读表现状态（vertical/paged），绝不替代 Locator
///   itemIdHint                ← 章节快速提示（非位置真源）
///   updatedAt
/// ```
///
/// 只有「当前激活的 Reader 模式」允许提交阅读位置；
/// inactive / disposed 的 VerticalReader 或 PagedReader 不得覆盖。
/// 统一由 ReaderSession 层（ReaderPage）管理 activeMode + confirmedLocator，
/// 最终持久化只经此 State。
library;

import 'reader_locator.dart';
import 'reading_mode.dart';

/// 阅读进度状态。
class ReaderProgressState {
  const ReaderProgressState({
    required this.collectionId,
    required this.absoluteCharacterOffset,
    required this.readingMode,
    this.itemIdHint,
    this.updatedAt,
  });

  final String collectionId;

  /// 唯一位置真源：normalized.txt UTF-16 码元偏移。
  final int absoluteCharacterOffset;

  /// 阅读表现状态（vertical / paged）。
  final ReadingMode readingMode;

  /// 快速识别章节的提示（非位置真源），可空。
  final String? itemIdHint;

  final DateTime? updatedAt;

  /// 转换为位置真源 Locator。
  ReaderLocator toLocator() => ReaderLocator(
    collectionId: collectionId,
    absoluteCharacterOffset: absoluteCharacterOffset,
    itemIdHint: itemIdHint,
  );

  ReaderProgressState copyWith({
    int? absoluteCharacterOffset,
    ReadingMode? readingMode,
    String? itemIdHint,
    DateTime? updatedAt,
    bool clearItemIdHint = false,
  }) {
    return ReaderProgressState(
      collectionId: collectionId,
      absoluteCharacterOffset:
          absoluteCharacterOffset ?? this.absoluteCharacterOffset,
      readingMode: readingMode ?? this.readingMode,
      itemIdHint: clearItemIdHint ? null : (itemIdHint ?? this.itemIdHint),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderProgressState &&
      other.collectionId == collectionId &&
      other.absoluteCharacterOffset == absoluteCharacterOffset &&
      other.readingMode == readingMode &&
      other.itemIdHint == itemIdHint;

  @override
  int get hashCode => Object.hash(
    collectionId,
    absoluteCharacterOffset,
    readingMode,
    itemIdHint,
  );

  @override
  String toString() =>
      'ReaderProgressState($collectionId, off=$absoluteCharacterOffset, '
      'mode=$readingMode)';
}
