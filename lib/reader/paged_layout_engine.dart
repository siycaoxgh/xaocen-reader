/// PagedLayoutEngine —— 横向分页引擎（M4）。
///
/// 合同（§八）：分页测量与页面显示必须共享同一套参数
/// （TextStyle / fontFamily / fontSize / fontWeight / height / letterSpacing /
/// textScale / textDirection / width / viewport height / padding policy）。
/// 本引擎只负责「测量」，渲染复用同一 TextStyle 的 RenderReaderTextBlock。
///
/// 惰性（§九/§十二）：不预分页全文。pageContaining 使用 ReaderBlockIndex
/// 定位附近文本区域（有限安全 anchor），再有限次数向目标偏移分页；
/// 结果对同一 (document, layout signature, target offset) 确定。
///
/// 行粒度（视觉连续）：页面边界落在**渲染行行尾**（getLineBoundary），
/// 每页从行首开始排版，页面间无半行跳变。
// ignore_for_file: prefer_initializing_formals
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/reader/paged_text_range.dart';
import '../domain/reader/reader_block.dart';

/// 分页引擎。
class PagedLayoutEngine {
  PagedLayoutEngine({
    required this.text,
    required this.style,
    required this.textDirection,
    required this.width,
    required this.height,
    this.horizontalPadding = 16,
    this.verticalPadding = 8,
    this.textScale = 1.0,
    this.policyVersion = pagedPolicyVersion,
  }) : _tp = TextPainter(
         textDirection: textDirection,
         // 与渲染（RenderReaderTextBlock）完全一致：noScaling。
         // textScale 本轮恒 1.0（未来阅读设置放开时经 signature 重分页）。
         textScaler: TextScaler.noScaling,
       );

  /// 规范化正文（引用 NormalizedDocument.text，不复制全文）。
  final String text;

  /// 显示与测量共用的正文样式（必须与渲染完全一致）。
  final TextStyle style;

  final TextDirection textDirection;

  /// 内容区宽度（viewport 宽）。
  final double width;

  /// 内容区高度（viewport 高）。
  final double height;

  final double horizontalPadding;
  final double verticalPadding;
  final double textScale;
  final int policyVersion;

  /// 复用的 TextPainter（同一实例逐次 layout，避免频繁创建）。
  final TextPainter _tp;

  double get contentWidth => math.max(1.0, width - horizontalPadding * 2);
  double get contentHeight => math.max(1.0, height - verticalPadding * 2);

  /// 布局签名（resize / orientation / 字体度量变化的判定依据）。
  PagedLayoutSignature get signature => PagedLayoutSignature(
    width: width,
    height: height,
    horizontalPadding: horizontalPadding,
    verticalPadding: verticalPadding,
    textScale: textScale,
    styleMetricsKey: textStyleMetricsKey(style),
    paginationPolicyVersion: policyVersion,
  );

  /// 候选文本上限（码元）。一次布局 32k 字符足以覆盖任何一屏，
  /// 且与全文页数无关（§九）。
  static const int candidateChars = 32768;

  void _layoutCandidate(String candidate) {
    _tp.text = TextSpan(text: candidate, style: style);
    _tp.layout(maxWidth: contentWidth);
  }

  /// 页尾 surrogate 修正：不拆 UTF-16 surrogate pair（§三十）。
  int _fixSurrogateBoundary(int offset) {
    if (offset > 0 && offset < text.length) {
      final cu = text.codeUnitAt(offset);
      if (cu >= 0xDC00 &&
          cu <= 0xDFFF &&
          text.codeUnitAt(offset - 1) >= 0xD800 &&
          text.codeUnitAt(offset - 1) <= 0xDBFF) {
        return offset - 1;
      }
    }
    return offset;
  }

  /// 正向分页：从 [startOffset] 排版一页（行粒度）。
  ///
  /// 返回页 [startOffset, end)；end 落在渲染行行尾（视觉连续）。
  /// startOffset >= 文本长度返回 null（endReached）。
  PagedTextRange? layoutForwardPage(int startOffset) {
    final len = text.length;
    if (len == 0) return null;
    if (startOffset >= len) return null;

    final take = math.min(len - startOffset, candidateChars);
    final candidate = text.substring(startOffset, startOffset + take);
    _layoutCandidate(candidate);

    // 整块不足一屏（文档尾 / 候选上限内装完）：直接整块一页。
    if (_tp.height <= contentHeight) {
      return PagedTextRange(
        startCharacterOffset: startOffset,
        endCharacterOffset: startOffset + take,
      );
    }

    // 逐渲染行累计高度：取「放得下的最大完整行集合」。
    final lines = _tp.computeLineMetrics();
    var acc = 0.0;
    var lineEnd = 0;
    var lineStart = 0;
    var found = false;
    for (final m in lines) {
      // 严格 ≤ contentHeight（无 ε 容差）：保证页面渲染高度不超 viewport 约束。
      if (acc + m.height > contentHeight) break;
      acc += m.height;
      // lineStart 始终指向「内容行行首」（0 或 LF 后）；getLineBoundary 对
      // 行首求 [行首, 行尾)，行尾在 LF 前（该行以 LF 结束时）。LF 字符本身
      // 归入下一页（页面 end 无 trailing LF → 渲染无额外空行，行数与引擎
      // 累计一致——'a\n' 渲染高 = 2 行，而引擎候选上累计不含 trailing 空行）。
      final b = _tp.getLineBoundary(TextPosition(offset: lineStart));
      var end = b.end;
      // 零宽防御（正常不触发：lineStart 非 LF）：至少推进一个字符。
      if (end <= lineStart) {
        end = lineStart + 1;
      }
      lineEnd = end;
      // 下一行行首：跳过 LF（lineEnd 是 LF 位置时 +1；wrap 行行尾即行首）。
      if (lineEnd < candidate.length && candidate.codeUnitAt(lineEnd) == 0x0A) {
        lineStart = lineEnd + 1;
      } else {
        lineStart = lineEnd;
      }
      found = true;
    }
    if (!found) {
      // 首行放不下（极端小 viewport）：至少一页 = 首行。
      final b = _tp.getLineBoundary(const TextPosition(offset: 0));
      lineEnd = b.end;
    }

    var end = _fixSurrogateBoundary(startOffset + math.min(lineEnd, take));
    if (end <= startOffset) {
      // 防御：永不返回空页 / 造成死循环。
      end = math.min(startOffset + 1, len);
      end = _fixSurrogateBoundary(end);
    }
    return PagedTextRange(
      startCharacterOffset: startOffset,
      endCharacterOffset: end,
    );
  }

  /// 反向分页：求上一页（§十三）。
  ///
  /// 返回页 [start, endOffset)，保证 **previous.end == endOffset**
  /// （与正向同构：同一文本、同一参数、同一行划分）。
  /// endOffset <= 0 返回 null（startReached）。
  PagedTextRange? layoutPreviousPage(int endOffset) {
    final len = text.length;
    if (len == 0) return null;
    if (endOffset <= 0) return null;

    final take = math.min(endOffset, candidateChars);
    var start = endOffset - take;
    // 候选起点回退到 LF 位置（上一行的换行符）：候选首字符 = LF（首行 =
    // LF 空行）——与 forward 页首（LF 位置）同一行边界，getLineBoundary
    // 往回数行精确对称（100 页往返）。无 LF（超长段/纯 wrap）：保持原
    // 起点（wrap 行由宽度决定，行数不变）。
    if (start > 0) {
      final lf = text.lastIndexOf('\n', start - 1);
      if (lf >= 0) {
        start = lf;
      }
    }
    final candidate = text.substring(start, endOffset);
    _layoutCandidate(candidate);

    // 整块不足一屏：从候选起点到 endOffset 一页。
    if (_tp.height <= contentHeight) {
      return PagedTextRange(
        startCharacterOffset: start,
        endCharacterOffset: endOffset,
      );
    }

    // 从末尾往回累计渲染行（getLineBoundary，与 forward 的
    // computeLineMetrics 行划分一致——同布局同文本）：
    // 取「放得下的最大完整行集合」。
    final lines = _tp.computeLineMetrics();
    var acc = 0.0;
    var lineStartRel = candidate.length;
    var found = false;
    for (var i = lines.length - 1; i >= 0; i--) {
      final m = lines[i];
      // 严格 ≤ contentHeight（无 ε 容差）。
      if (acc + m.height > contentHeight) break;
      acc += m.height;
      final b = _tp.getLineBoundary(
        TextPosition(offset: math.max(0, lineStartRel - 1)),
      );
      lineStartRel = b.start;
      found = true;
    }
    if (!found) {
      // 一整屏都放不下（极端）：取末尾一行。
      final b = _tp.getLineBoundary(
        TextPosition(offset: math.max(0, candidate.length - 1)),
      );
      lineStartRel = b.start;
    }
    // 页首 = 候选内行首；行首前是 LF → 页首 = LF 位置（与 forward 页
    // start = LF 一致）。行首为 0（文档首）时保持 0。
    if (lineStartRel > 0 && candidate.codeUnitAt(lineStartRel - 1) == 0x0A) {
      lineStartRel -= 1;
    }
    var pageStart = start + lineStartRel;
    pageStart = _fixSurrogateBoundary(pageStart);
    if (pageStart >= endOffset) {
      // 防御：至少回退一码元。
      pageStart = math.max(0, endOffset - 1);
      pageStart = _fixSurrogateBoundary(pageStart);
    }
    return PagedTextRange(
      startCharacterOffset: pageStart,
      endCharacterOffset: endOffset,
    );
  }

  /// 任意偏移 → 覆盖该偏移的页面（§十一/§十二）。
  ///
  /// 保证 page.start <= target < page.end（clamp 后）。
  /// 使用 [blockIndex] 定位附近文本区域（有限安全 anchor），
  /// 从 anchor 向前有限次数分页；**不**从 offset 0 逐页排版。
  PagedTextRange? pageContaining(
    int targetOffset, {
    ReaderBlockIndex? blockIndex,
  }) {
    final len = text.length;
    if (len == 0) {
      return const PagedTextRange(
        startCharacterOffset: 0,
        endCharacterOffset: 0,
      );
    }
    final target = targetOffset.clamp(0, len);

    final anchor =
        blockIndex?.blockForOffset(target)?.startCharacterOffset ?? 0;

    var page = layoutForwardPage(anchor);
    var guard = 0;
    while (page != null && !page.contains(target) && guard < 64) {
      page = layoutForwardPage(page.endCharacterOffset);
      guard++;
    }
    if (page == null) {
      // 防御：文本非空但分页失败时退回整文一页。
      return PagedTextRange(startCharacterOffset: 0, endCharacterOffset: len);
    }
    return page;
  }

  /// 文本末尾是否为页面末尾（endReached 判定辅助）。
  bool isDocumentEnd(int endOffset) => endOffset >= text.length;

  void dispose() {
    _tp.dispose();
  }
}
