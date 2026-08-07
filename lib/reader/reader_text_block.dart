/// ReaderTextBlock —— 正文显示与坐标测量使用同一套 TextPainter 参数。
///
/// 职责：
/// - 显示一个 [ReaderBlock] 的文本；
/// - 提供真实布局映射：本地 UTF-16 offset → glyph/line Rect；
///   本地 y 坐标 → TextPosition；block 实际高度；布局是否完成。
///
/// 禁止出现：显示用一种文本控件、测量用另一套 TextPainter 参数。
// ignore_for_file: prefer_initializing_formals
library;

import 'package:flutter/widgets.dart';

/// 块布局映射 —— 由 [RenderReaderTextBlock] 暴露。
class ReaderBlockLayout {
  const ReaderBlockLayout({
    required this.height,
    required this.layoutCompleted,
    required this.textWidth,
    required this.styleVersion,
    required this.lineCount,
  });

  final double height;
  final bool layoutCompleted;
  final double textWidth;
  final int styleVersion;
  final int lineCount;
}

/// ReaderTextBlock —— 显示块文本的 Widget。
class ReaderTextBlock extends LeafRenderObjectWidget {
  const ReaderTextBlock({
    super.key,
    required this.text,
    required this.style,
    required this.styleVersion,
    required this.textDirection,
    required this.maxWidth,
    required this.onLayout,
  });

  final String text;
  final TextStyle style;
  final int styleVersion;
  final TextDirection textDirection;
  final double maxWidth;
  final ValueChanged<ReaderBlockLayout>? onLayout;

  @override
  RenderReaderTextBlock createRenderObject(BuildContext context) {
    return RenderReaderTextBlock(
      text: text,
      style: style,
      styleVersion: styleVersion,
      textDirection: textDirection,
      maxWidth: maxWidth,
      onLayout: onLayout,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderReaderTextBlock renderObject,
  ) {
    renderObject
      ..text = text
      ..style = style
      ..styleVersion = styleVersion
      ..textDirection = textDirection
      ..maxWidth = maxWidth
      ..onLayout = onLayout;
  }
}

/// RenderReaderTextBlock —— 单一 TextPainter 同时负责显示与测量。
class RenderReaderTextBlock extends RenderBox {
  RenderReaderTextBlock({
    required String text,
    required TextStyle style,
    required int styleVersion,
    required TextDirection textDirection,
    required double maxWidth,
    ValueChanged<ReaderBlockLayout>? onLayout,
  }) : _text = text,
       _style = style,
       _styleVersion = styleVersion,
       _textDirection = textDirection,
       _maxWidth = maxWidth,
       _onLayout = onLayout {
    _layoutPainter = TextPainter(
      text: TextSpan(text: _text, style: _style),
      textDirection: _textDirection,
      textScaler: TextScaler.noScaling,
    );
  }

  String _text;
  TextStyle _style;
  int _styleVersion;
  TextDirection _textDirection;
  double _maxWidth;
  ValueChanged<ReaderBlockLayout>? _onLayout;

  late TextPainter _layoutPainter;
  bool _layoutDone = false;

  /// 最近一次布局宽度（仅颜色变化时内部同步重排用）。
  double _lastLayoutWidth = 0;

  String get text => _text;
  set text(String v) {
    if (v == _text) return;
    _text = v;
    _layoutPainter.text = TextSpan(text: v, style: _style);
    markNeedsLayout();
  }

  TextStyle get style => _style;
  set style(TextStyle v) {
    if (v == _style) return;
    final metricsChanged = !_sameMetrics(_style, v);
    _style = v;
    _layoutPainter.text = TextSpan(text: _text, style: v);
    if (metricsChanged) {
      // 字体/字号/行高等度量变化：触发完整重排
      markNeedsLayout();
    } else if (_layoutDone) {
      // 仅颜色变化（P1）：内部同步重排（相同度量），只重绘不重排树。
      _layoutPainter.layout(maxWidth: _lastLayoutWidth);
      markNeedsPaint();
    }
  }

  /// 两个 TextStyle 是否仅绘制属性（颜色类）不同、度量相同。
  static bool _sameMetrics(TextStyle a, TextStyle b) {
    return a.fontSize == b.fontSize &&
        a.height == b.height &&
        a.fontFamily == b.fontFamily &&
        a.fontFamilyFallback == b.fontFamilyFallback &&
        a.fontWeight == b.fontWeight &&
        a.fontStyle == b.fontStyle &&
        a.letterSpacing == b.letterSpacing &&
        a.wordSpacing == b.wordSpacing &&
        a.textBaseline == b.textBaseline &&
        a.inherit == b.inherit;
  }

  int get styleVersion => _styleVersion;
  set styleVersion(int v) {
    if (v == _styleVersion) return;
    _styleVersion = v;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    _layoutPainter.textDirection = v;
    markNeedsLayout();
  }

  double get maxWidth => _maxWidth;
  set maxWidth(double v) {
    if (v == _maxWidth) return;
    _maxWidth = v;
    markNeedsLayout();
  }

  ValueChanged<ReaderBlockLayout>? get onLayout => _onLayout;
  set onLayout(ValueChanged<ReaderBlockLayout>? v) {
    if (identical(v, _onLayout)) return;
    _onLayout = v;
  }

  /// 布局是否已完成。
  bool get layoutCompleted => _layoutDone;

  /// 当前文本宽度。
  double get textWidth => _layoutPainter.width;

  /// 样式版本。
  int get currentStyleVersion => _styleVersion;

  /// 行数。
  int get lineCount => _layoutPainter.computeLineMetrics().length;

  @override
  bool get sizedByParent => false;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final tp = TextPainter(
      text: TextSpan(text: _text, style: _style),
      textDirection: _textDirection,
      textScaler: TextScaler.noScaling,
    );
    tp.layout(maxWidth: constraints.maxWidth);
    final size = Size(constraints.maxWidth, tp.height);
    tp.dispose();
    return size;
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : _maxWidth;
    _lastLayoutWidth = width;
    _layoutPainter.layout(maxWidth: width);
    size = Size(width, _layoutPainter.height);
    _layoutDone = true;
    _onLayout?.call(
      ReaderBlockLayout(
        height: _layoutPainter.height,
        layoutCompleted: true,
        textWidth: _layoutPainter.width,
        styleVersion: _styleVersion,
        lineCount: _layoutPainter.computeLineMetrics().length,
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _layoutPainter.paint(context.canvas, offset);
  }

  /// 本地 UTF-16 offset → glyph/line Rect（相对本 block 顶部）。
  ///
  /// 返回 null 表示 offset 超出本 block 文本范围。
  Rect? rectForCharacterOffset(int localOffset) {
    if (!_layoutDone) return null;
    if (localOffset < 0 || localOffset > _text.length) return null;
    if (_text.isEmpty) return Rect.zero;
    final clamped = localOffset > _text.length ? _text.length : localOffset;
    final pos = _layoutPainter.getOffsetForCaret(
      TextPosition(offset: clamped),
      Rect.zero,
    );
    // caret 高度作为行高近似（真实行 Rect 用 line metrics）
    final metrics = _layoutPainter.computeLineMetrics();
    var lineTop = 0.0;
    var lineHeight = 0.0;
    for (final m in metrics) {
      if (pos.dy >= lineTop && pos.dy <= lineTop + m.height) {
        lineHeight = m.height;
        break;
      }
      lineTop += m.height;
    }
    if (lineHeight == 0 && metrics.isNotEmpty) {
      lineHeight = metrics.last.height;
      lineTop = pos.dy;
    }
    return Rect.fromLTWH(0, pos.dy, _layoutPainter.width, lineHeight);
  }

  /// 本地 y 坐标 → 全文 TextPosition。
  TextPosition? textPositionAtLocalY(double localY) {
    if (!_layoutDone) return null;
    if (_text.isEmpty) return const TextPosition(offset: 0);
    return _layoutPainter.getPositionForOffset(Offset(0, localY));
  }

  /// 本地 y 坐标 → 本地 UTF-16 offset（越界 clamp）。
  int characterOffsetAtLocalY(double localY) {
    final pos = textPositionAtLocalY(localY);
    if (pos == null) return 0;
    return pos.offset;
  }

  /// 文本总高度（布局后）。
  double get contentHeight => _layoutDone ? _layoutPainter.height : 0;

  @override
  void dispose() {
    _layoutPainter.dispose();
    super.dispose();
  }
}
