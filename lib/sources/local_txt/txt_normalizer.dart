/// 规范化结果 —— 唯一坐标基准文本与行偏移辅助结构。
class NormalizedText {
  const NormalizedText({
    required this.text,
    required this.lineStarts,
    required this.bomRemovedLength,
    required this.sourceEncodingBomLength,
  });

  /// 规范化后的全文（仅去 BOM + CRLF/CR→LF，不删任何字符/空白）。
  final String text;

  /// 每行起始的 UTF-16 码元偏移（lineStarts[0] == 0；行数 = lineStarts.length）。
  /// 提供 O(1) 行定位，避免逐行重复计算前缀长度。
  final List<int> lineStarts;

  /// 因 BOM 移除的字符数（0 或 1）。
  final int bomRemovedLength;

  /// 源编码 BOM 字节数（用于解码时跳过；无 BOM 为 0）。
  final int sourceEncodingBomLength;

  int get length => text.length;

  int get lineCount => lineStarts.length;

  /// 将字符偏移定位到行（返回行号，O(log n) 二分）。
  int lineOf(int charOffset) {
    var lo = 0;
    var hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (lineStarts[mid] <= charOffset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}

/// TXT 规范化器。
///
/// 合同（唯一允许的预处理）：
/// 1. 移除 BOM（UTF-8 BOM 在解码前处理；此处处理解码后字符串开头的 U+FEFF）；
/// 2. CRLF → LF；
/// 3. CR → LF。
///
/// 禁止：删除段首空格、压缩空行、删除正文字符、替换全角空格、添加缩进、重排段落、
/// 删除重复标题正文行。
///
/// 复杂度 O(n)，单次遍历构建 lineStarts。
abstract final class TxtNormalizer {
  /// 规范化文本。若文本以 BOM 字符开头则移除（[bomRemoved] 返回是否移除）。
  /// [bomBytes] 为源编码的 BOM 字节长度（UTF-8=3 / UTF-16=2 / 无=0），仅记录用。
  static NormalizedText normalize(
    String raw, {
    int sourceEncodingBomLength = 0,
  }) {
    var text = raw;
    var bomRemoved = 0;
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
      bomRemoved = 1;
    }

    // 单次遍历：替换 CRLF/CR 为 LF 并同时构建 lineStarts。
    final sb = StringBuffer();
    final lineStarts = <int>[0];
    var i = 0;
    final n = text.length;
    while (i < n) {
      final c = text.codeUnitAt(i);
      if (c == 0x0D) {
        // CR；检查是否 CRLF
        if (i + 1 < n && text.codeUnitAt(i + 1) == 0x0A) {
          sb.writeCharCode(0x0A);
          lineStarts.add(sb.length);
          i += 2;
        } else {
          sb.writeCharCode(0x0A);
          lineStarts.add(sb.length);
          i++;
        }
        continue;
      }
      if (c == 0x0A) {
        sb.writeCharCode(0x0A);
        lineStarts.add(sb.length);
        i++;
        continue;
      }
      sb.writeCharCode(c);
      i++;
    }

    return NormalizedText(
      text: sb.toString(),
      lineStarts: lineStarts,
      bomRemovedLength: bomRemoved,
      sourceEncodingBomLength: sourceEncodingBomLength,
    );
  }
}
