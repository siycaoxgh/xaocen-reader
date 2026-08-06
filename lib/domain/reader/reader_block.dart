/// 派生渲染块 —— ReaderBlock 与 ReaderBlockIndex。
///
/// ReaderBlock 是**渲染派生结构**：
/// - 不写入 Drift；
/// - 不写入 ReaderLocator；
/// - 字体变化时不改变；
/// - 窗口变化时不改变；
/// - 可根据 blockPolicyVersion 重建。
///
/// 不要在索引中永久保存所有 substring（避免复制整本正文）。
library;

/// 一个连续文本块（UTF-16 码元范围）。
class ReaderBlock {
  const ReaderBlock({
    required this.index,
    required this.startCharacterOffset,
    required this.endCharacterOffset,
  });

  /// 块序号（从 0 开始）。
  final int index;

  /// 起始 UTF-16 码元偏移（含）。
  final int startCharacterOffset;

  /// 结束 UTF-16 码元偏移（不含）。
  final int endCharacterOffset;

  int get length => endCharacterOffset - startCharacterOffset;

  bool contains(int offset) =>
      offset >= startCharacterOffset && offset < endCharacterOffset;

  @override
  String toString() =>
      'ReaderBlock#$index[$startCharacterOffset,$endCharacterOffset)';
}

/// 块策略版本：改变切块规则时递增，用于重建索引。
const int readerBlockPolicyVersion = 1;

/// ReaderBlock 索引（确定性、纯计算、可重建）。
class ReaderBlockIndex {
  ReaderBlockIndex._(this.blocks, this.textLength, this.policyVersion);

  /// 全部块（连续、不重叠、不遗漏）。
  final List<ReaderBlock> blocks;

  /// 文本总长（UTF-16 码元数）。
  final int textLength;

  final int policyVersion;

  int get blockCount => blocks.length;

  /// 定位包含 [offset] 的块。
  ///
  /// 二分查找；offset 越界时 clamp 到首/末块。
  ReaderBlock? blockForOffset(int offset) {
    if (blocks.isEmpty) return null;
    if (offset < 0) return blocks.first;
    if (offset >= textLength) return blocks.last;
    var lo = 0;
    var hi = blocks.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      final b = blocks[mid];
      if (b.contains(offset)) return b;
      if (offset < b.startCharacterOffset) {
        hi = mid - 1;
      } else {
        lo = mid + 1;
      }
    }
    return blocks[lo];
  }

  /// 构建 ReaderBlockIndex。
  ///
  /// 规则：
  /// 1. 优先在目标位置附近的 LF 后切分；
  /// 2. 找不到合理换行时允许按字符边界切；
  /// 3. 不得切在 surrogate pair 中间；
  /// 4. 所有块首尾连续；
  /// 5. 第一个 start=0；最后一个 end=全文长度；
  /// 6. 不重叠、不遗漏。
  static ReaderBlockIndex build({
    required String text,
    required int targetBlockSize,
  }) {
    assert(targetBlockSize >= 1, 'targetBlockSize too small');
    final blocks = <ReaderBlock>[];
    final length = text.length;
    if (length == 0) {
      return ReaderBlockIndex._([], 0, readerBlockPolicyVersion);
    }

    var start = 0;
    var index = 0;
    while (start < length) {
      var end = start + targetBlockSize;
      if (end >= length) {
        end = length;
      } else {
        // 1) 优先在目标位置附近的 LF 后切分：向后搜索 ≤128 码元内的 LF。
        final searchLimit = (end + 128 < length) ? end + 128 : length;
        var lfIndex = -1;
        for (var i = end; i < searchLimit; i++) {
          if (text.codeUnitAt(i) == 0x0A) {
            lfIndex = i + 1; // LF 之后
            break;
          }
        }
        if (lfIndex == -1) {
          // 向前搜索（避免切在长段中间，但不超过 256 码元）
          final backLimit = (end - 256 > start) ? end - 256 : start;
          for (var i = end - 1; i >= backLimit; i--) {
            if (text.codeUnitAt(i) == 0x0A) {
              lfIndex = i + 1;
              break;
            }
          }
        }
        if (lfIndex != -1) {
          end = lfIndex;
        }
      }

      // 3) 不得切在 surrogate pair 中间。
      if (end < length) {
        final cu = text.codeUnitAt(end);
        if (cu >= 0xDC00 && cu <= 0xDFFF) {
          // end 落在 low surrogate → 前一个必须是 high surrogate 的延续
          if (end > start &&
              text.codeUnitAt(end - 1) >= 0xD800 &&
              text.codeUnitAt(end - 1) <= 0xDBFF) {
            end -= 1; // 回退到 high surrogate 之后
          }
        }
      }

      blocks.add(
        ReaderBlock(
          index: index,
          startCharacterOffset: start,
          endCharacterOffset: end,
        ),
      );
      start = end;
      index++;
    }

    return ReaderBlockIndex._(blocks, length, readerBlockPolicyVersion);
  }
}
