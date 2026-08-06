/// 阅读位置 —— M3 唯一位置合同。
///
/// 唯一持久化真源：normalized.txt 对应 Dart String 的 **UTF-16 码元偏移**
/// （[absoluteCharacterOffset]）。
///
/// 禁止保存为位置真源：页码、scroll pixels、blockIndex、当前 Widget 索引、
/// 章节百分比、全文百分比、屏幕行号。
library;

/// 位置事件来源（区分程序化恢复与用户滚动）。
enum ReaderPositionEventSource {
  /// 程序化恢复（打开 Reader / 进程重启恢复）。恢复完成前零写入。
  programmaticRestore,

  /// 程序化目录跳转。可见范围确认后保存明确目标 offset。
  programmaticTocJump,

  /// 用户触摸/拖拽滚动。
  userDrag,

  /// 用户鼠标滚轮。
  userWheel,

  /// 用户拖动滚动条。
  userScrollbar,

  /// 生命周期 flush（route pop / inactive / paused / detached / 窗口关闭）。
  lifecycleFlush,
}

/// 阅读定位器 —— 纯 domain 实体。
class ReaderLocator {
  const ReaderLocator({
    required this.collectionId,
    required this.absoluteCharacterOffset,
    this.itemIdHint,
  });

  /// 所属 collection（`local-txt:<hash>`）。
  final String collectionId;

  /// 唯一位置真源：normalized.txt UTF-16 码元偏移。
  final int absoluteCharacterOffset;

  /// 仅用于快速识别章节，**不是**位置真源。
  final String? itemIdHint;

  ReaderLocator copyWith({
    String? collectionId,
    int? absoluteCharacterOffset,
    String? itemIdHint,
    bool clearItemIdHint = false,
  }) {
    return ReaderLocator(
      collectionId: collectionId ?? this.collectionId,
      absoluteCharacterOffset:
          absoluteCharacterOffset ?? this.absoluteCharacterOffset,
      itemIdHint: clearItemIdHint ? null : itemIdHint ?? this.itemIdHint,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderLocator &&
      other.collectionId == collectionId &&
      other.absoluteCharacterOffset == absoluteCharacterOffset;

  @override
  int get hashCode => Object.hash(collectionId, absoluteCharacterOffset);

  @override
  String toString() =>
      'ReaderLocator($collectionId @ $absoluteCharacterOffset${itemIdHint != null ? ' hint=$itemIdHint' : ''})';
}

/// 位置 clamp 结果诊断。
class LocatorClamp {
  const LocatorClamp({
    required this.requested,
    required this.clamped,
    required this.clampedFrom,
    required this.clampedTo,
  });

  final int requested;
  final int clamped;
  final int clampedFrom;
  final int clampedTo;

  bool get wasClamped => clamped != requested;
}

/// 将 offset clamp 到 [0, normalizedLength]，并校验不落在 surrogate pair 中间。
///
/// - 超界时 clamp 并记录诊断；
/// - 若落在代理对中间，向前回退一个码元（避免切半字符）。
LocatorClamp clampLocatorOffset({
  required int requested,
  required int normalizedLength,
  required String text,
}) {
  assert(normalizedLength == text.length);
  var clampedFrom = 0;
  var clampedTo = normalizedLength;
  var value = requested;

  if (value < 0) {
    clampedFrom = value;
    value = 0;
  } else if (value > normalizedLength) {
    clampedTo = value;
    value = normalizedLength;
  }

  // surrogate pair 中间检查：若 value 落在 low surrogate（0xDC00-0xDFFF）
  // 且前一个是 high surrogate，则回退一个码元。
  if (value > 0 && value < normalizedLength) {
    final codeUnit = text.codeUnitAt(value);
    if (codeUnit >= 0xDC00 &&
        codeUnit <= 0xDFFF &&
        text.codeUnitAt(value - 1) >= 0xD800 &&
        text.codeUnitAt(value - 1) <= 0xDBFF) {
      value -= 1;
    }
  }

  return LocatorClamp(
    requested: requested,
    clamped: value,
    clampedFrom: clampedFrom,
    clampedTo: clampedTo,
  );
}
