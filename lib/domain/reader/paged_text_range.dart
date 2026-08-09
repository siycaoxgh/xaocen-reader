/// 分页文本范围 —— M4 派生页面结构。
///
/// Page 是**派生状态**：
/// - 不写入 Drift；
/// - 不写入 manifest；
/// - 不修改 normalized.txt；
/// - 不进入 ReaderLocator（位置真源始终是 UTF-16 码元偏移）。
///
/// 范围合同 [start, end)：
/// - start <= end；
/// - 不拆 UTF-16 surrogate pair；
/// - 页面连续（上一页.end == 下一页.start）；
/// - 不重复正文、不遗漏正文、不插入字符、不删除字符。
library;

import 'package:flutter/painting.dart';

/// 一页正文的 UTF-16 码元范围。
class PagedTextRange {
  const PagedTextRange({
    required this.startCharacterOffset,
    required this.endCharacterOffset,
  }) : assert(
         startCharacterOffset >= 0 &&
             endCharacterOffset >= startCharacterOffset,
         '非法页面范围',
       );

  /// 页首 UTF-16 码元偏移（含）。
  final int startCharacterOffset;

  /// 页尾 UTF-16 码元偏移（不含）。
  final int endCharacterOffset;

  int get length => endCharacterOffset - startCharacterOffset;

  bool contains(int offset) =>
      offset >= startCharacterOffset && offset < endCharacterOffset;

  /// 是否与另一页相邻（this.end == other.start 或 this.start == other.end）。
  bool isAdjacentTo(PagedTextRange other) =>
      endCharacterOffset == other.startCharacterOffset ||
      startCharacterOffset == other.endCharacterOffset;

  @override
  bool operator ==(Object other) =>
      other is PagedTextRange &&
      other.startCharacterOffset == startCharacterOffset &&
      other.endCharacterOffset == endCharacterOffset;

  @override
  int get hashCode => Object.hash(startCharacterOffset, endCharacterOffset);

  @override
  String toString() =>
      'PagedTextRange[$startCharacterOffset,$endCharacterOffset)';
}

/// 分页布局签名 —— Page cache / 重分页判定 key。
///
/// 变化时**必须**使分页窗口失效并重建：
/// - 窗口尺寸（width/height）；
/// - TextStyle metrics（fontSize/height/fontFamily/fontWeight/letterSpacing/
///   wordSpacing/textBaseline）；
/// - textScale；
/// - padding policy；
/// - paginationPolicyVersion。
///
/// 单纯颜色变化（不改变 metrics）**不得**改变签名（只重绘，不重分页）。

/// 布局签名（不可变，可作 cache key）。
class PagedLayoutSignature {
  const PagedLayoutSignature({
    required this.width,
    required this.height,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingLeft,
    required this.paddingRight,
    required this.textScale,
    required this.styleMetricsKey,
    required this.paginationPolicyVersion,
  });

  /// 内容区宽度（viewport 宽）。
  final double width;

  /// 内容区高度（viewport 高）。
  final double height;

  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;

  /// 文本缩放（TextScaler 的 scale 值）。
  final double textScale;

  /// TextStyle 度量维度 key（不含颜色）。
  final String styleMetricsKey;

  final int paginationPolicyVersion;

  /// 稳定签名值（用作缓存 key / 变化检测）。
  String get cacheKey =>
      'w=${width.toStringAsFixed(1)};h=${height.toStringAsFixed(1)};'
      'pt=$paddingTop;pb=$paddingBottom;pl=$paddingLeft;pr=$paddingRight;ts=$textScale;'
      'sm=$styleMetricsKey;pv=$paginationPolicyVersion';

  @override
  bool operator ==(Object other) =>
      other is PagedLayoutSignature && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}

/// 从 TextStyle 提取度量维度 key（颜色等绘制属性不参与）。
///
/// 显示与测量必须使用同一参数（§八），此 key 用于检测度量变化。
String textStyleMetricsKey(TextStyle style) {
  return [
    style.fontSize?.toString() ?? '-',
    style.height?.toString() ?? '-',
    style.fontFamily ?? '-',
    (style.fontFamilyFallback ?? const []).join(','),
    style.fontWeight?.toString() ?? '-',
    style.fontStyle?.toString() ?? '-',
    style.letterSpacing?.toString() ?? '-',
    style.wordSpacing?.toString() ?? '-',
    style.textBaseline?.toString() ?? '-',
    style.inherit.toString(),
  ].join('|');
}

/// 分页策略版本：改变切页规则时递增（强制旧缓存失效）。
const int pagedPolicyVersion = 1;
