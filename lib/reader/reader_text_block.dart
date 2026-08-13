import 'package:flutter/widgets.dart';

// ignore_for_file: prefer_initializing_formals, unnecessary_getters_setters

import 'reader_typography_layout.dart';

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

class ReaderTextBlock extends LeafRenderObjectWidget {
  const ReaderTextBlock({
    super.key,
    required this.text,
    required this.style,
    required this.styleVersion,
    required this.textDirection,
    required this.maxWidth,
    this.paragraphSpacing = 0,
    this.firstLineIndent = 0,
    this.textAlign = TextAlign.left,
    this.startsAtParagraphBoundary = true,
    this.onLayout,
  });
  final String text;
  final TextStyle style;
  final int styleVersion;
  final TextDirection textDirection;
  final double maxWidth;
  final double paragraphSpacing;
  final double firstLineIndent;
  final TextAlign textAlign;
  final bool startsAtParagraphBoundary;
  final ValueChanged<ReaderBlockLayout>? onLayout;

  @override
  RenderReaderTextBlock createRenderObject(BuildContext context) =>
      RenderReaderTextBlock(
        text: text,
        style: style,
        styleVersion: styleVersion,
        textDirection: textDirection,
        maxWidth: maxWidth,
        paragraphSpacing: paragraphSpacing,
        firstLineIndent: firstLineIndent,
        textAlign: textAlign,
        startsAtParagraphBoundary: startsAtParagraphBoundary,
        onLayout: onLayout,
      );

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
      ..paragraphSpacing = paragraphSpacing
      ..firstLineIndent = firstLineIndent
      ..textAlign = textAlign
      ..startsAtParagraphBoundary = startsAtParagraphBoundary
      ..onLayout = onLayout;
  }
}

class RenderReaderTextBlock extends RenderBox {
  RenderReaderTextBlock({
    required String text,
    required TextStyle style,
    required int styleVersion,
    required TextDirection textDirection,
    required double maxWidth,
    double paragraphSpacing = 0,
    double firstLineIndent = 0,
    TextAlign textAlign = TextAlign.left,
    bool startsAtParagraphBoundary = true,
    ValueChanged<ReaderBlockLayout>? onLayout,
  }) : _text = text,
       _style = style,
       _styleVersion = styleVersion,
       _textDirection = textDirection,
       _maxWidth = maxWidth,
       _paragraphSpacing = paragraphSpacing,
       _firstLineIndent = firstLineIndent,
       _textAlign = textAlign,
       _startsAtParagraphBoundary = startsAtParagraphBoundary,
       _onLayout = onLayout;

  String _text;
  TextStyle _style;
  int _styleVersion;
  TextDirection _textDirection;
  double _maxWidth;
  double _paragraphSpacing;
  double _firstLineIndent;
  TextAlign _textAlign;
  bool _startsAtParagraphBoundary;
  ValueChanged<ReaderBlockLayout>? _onLayout;
  ReaderTypographyLayout? _layout;

  String get text => _text;
  set text(String value) {
    if (value != _text) {
      _text = value;
      markNeedsLayout();
    }
  }

  TextStyle get style => _style;
  set style(TextStyle value) {
    if (value == _style) return;
    final metrics = !_sameMetrics(_style, value);
    _style = value;
    if (metrics) {
      markNeedsLayout();
    } else {
      _layout?.updatePaintStyle(value);
      markNeedsPaint();
    }
  }

  static bool _sameMetrics(TextStyle a, TextStyle b) =>
      a.fontSize == b.fontSize &&
      a.height == b.height &&
      a.fontFamily == b.fontFamily &&
      _sameFallback(a.fontFamilyFallback, b.fontFamilyFallback) &&
      a.fontWeight == b.fontWeight &&
      a.fontStyle == b.fontStyle &&
      a.letterSpacing == b.letterSpacing &&
      a.wordSpacing == b.wordSpacing &&
      a.textBaseline == b.textBaseline &&
      a.inherit == b.inherit;

  static bool _sameFallback(List<String>? a, List<String>? b) =>
      a == null && b == null || a != null && b != null && _sameStrings(a, b);

  static bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int get styleVersion => _styleVersion;
  set styleVersion(int value) {
    if (value != _styleVersion) {
      _styleVersion = value;
      markNeedsLayout();
    }
  }

  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value != _textDirection) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  double get maxWidth => _maxWidth;
  set maxWidth(double value) {
    if (value != _maxWidth) {
      _maxWidth = value;
      markNeedsLayout();
    }
  }

  double get paragraphSpacing => _paragraphSpacing;
  set paragraphSpacing(double value) {
    if (value != _paragraphSpacing) {
      _paragraphSpacing = value;
      markNeedsLayout();
    }
  }

  double get firstLineIndent => _firstLineIndent;
  set firstLineIndent(double value) {
    if (value != _firstLineIndent) {
      _firstLineIndent = value;
      markNeedsLayout();
    }
  }

  TextAlign get textAlign => _textAlign;
  set textAlign(TextAlign value) {
    if (value != _textAlign) {
      _textAlign = value;
      markNeedsLayout();
    }
  }

  bool get startsAtParagraphBoundary => _startsAtParagraphBoundary;
  set startsAtParagraphBoundary(bool value) {
    if (value != _startsAtParagraphBoundary) {
      _startsAtParagraphBoundary = value;
      markNeedsLayout();
    }
  }

  ValueChanged<ReaderBlockLayout>? get onLayout => _onLayout;
  set onLayout(ValueChanged<ReaderBlockLayout>? value) => _onLayout = value;

  bool get layoutCompleted => _layout != null;
  double get textWidth => size.width;
  int get currentStyleVersion => _styleVersion;
  int get lineCount => _layout?.lines.length ?? 0;
  double get contentHeight => _layout?.height ?? 0;

  ReaderTypographyLayout _create(double width) => ReaderTypographyLayout(
    text: _text,
    style: _style,
    textDirection: _textDirection,
    width: width,
    paragraphSpacing: _paragraphSpacing,
    firstLineIndent: _firstLineIndent,
    textAlign: _textAlign,
    startsAtParagraphBoundary: _startsAtParagraphBoundary,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final layout = _create(
      constraints.maxWidth.isFinite ? constraints.maxWidth : _maxWidth,
    );
    final result = Size(constraints.maxWidth, layout.height);
    layout.dispose();
    return result;
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : _maxWidth;
    _layout?.dispose();
    _layout = _create(width);
    size = Size(width, _layout!.height);
    _onLayout?.call(
      ReaderBlockLayout(
        height: size.height,
        layoutCompleted: true,
        textWidth: width,
        styleVersion: _styleVersion,
        lineCount: _layout!.lines.length,
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      _layout?.paint(context.canvas, offset);

  Rect? rectForCharacterOffset(int localOffset) {
    if (_layout == null) return null;
    if (localOffset < 0 || localOffset > _text.length) return null;
    if (_text.isEmpty) return Rect.zero;
    final line = _layout?.lineForOffset(localOffset);
    if (line == null) return null;
    return Rect.fromLTWH(line.x, line.top, size.width - line.x, line.height);
  }

  TextPosition? textPositionAtLocalY(double localY) {
    final layout = _layout;
    if (layout == null) return null;
    return TextPosition(offset: layout.offsetForY(localY));
  }

  int characterOffsetAtLocalY(double localY) =>
      textPositionAtLocalY(localY)?.offset ?? 0;

  @override
  void dispose() {
    _layout?.dispose();
    super.dispose();
  }
}
