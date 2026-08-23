import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../domain/reader/reader_rendering.dart';

/// Visual paragraph layout over the original UTF-16 text.
/// No character is inserted, deleted, or persisted.
final class ReaderTypographyLayout {
  ReaderTypographyLayout({
    required this.text,
    required this.style,
    required this.textDirection,
    required this.width,
    required this.paragraphSpacing,
    required this.firstLineIndent,
    this.textAlign = TextAlign.left,
    required this.startsAtParagraphBoundary,
    this.highlightStart,
    this.highlightEnd,
    this.highlightColor,
    this.styleRuns = const <ReaderInlineStyleRun>[],
    this.buildFastLineRecords = true,
  }) {
    _layout();
  }

  final String text;
  final TextStyle style;
  final TextDirection textDirection;
  final double width;
  final double paragraphSpacing;
  final double firstLineIndent;
  final TextAlign textAlign;
  final bool startsAtParagraphBoundary;
  int? highlightStart;
  int? highlightEnd;
  Color? highlightColor;
  final List<ReaderInlineStyleRun> styleRuns;
  final bool buildFastLineRecords;
  final List<ReaderTypographyLine> lines = [];
  double height = 0;
  TextPainter? _fastPainter;
  TextPainter? get fastPainter => _fastPainter;

  void _layout() {
    if (paragraphSpacing == 0 && firstLineIndent == 0) {
      _layoutFast();
      return;
    }
    var paragraphStart = 0;
    var firstParagraph = true;
    while (paragraphStart < text.length) {
      final lf = text.indexOf('\n', paragraphStart);
      final contentEnd = lf < 0 ? text.length : lf;
      final logicalEnd = lf < 0 ? contentEnd : lf + 1;
      _layoutParagraph(
        paragraphStart,
        contentEnd,
        logicalEnd,
        indent: !firstParagraph || startsAtParagraphBoundary,
      );
      paragraphStart = logicalEnd;
      firstParagraph = false;
      if (paragraphStart < text.length) height += paragraphSpacing;
    }
    if (text.isEmpty) height = 0;
  }

  void _layoutFast() {
    final painter = TextPainter(
      text: _spanForRange(0, text.length, style),
      textDirection: textDirection,
      textScaler: TextScaler.noScaling,
      textAlign: textAlign,
    )..layout(maxWidth: width);
    _fastPainter = painter;
    height = painter.height;
    if (!buildFastLineRecords) return;
    final metrics = painter.computeLineMetrics();
    var cursor = 0;
    var top = 0.0;
    for (final metric in metrics) {
      final boundary = painter.getLineBoundary(TextPosition(offset: cursor));
      var end = boundary.end;
      if (end < text.length && text.codeUnitAt(end) == 0x0A) end++;
      if (end <= cursor) end = math.min(text.length, cursor + 1);
      lines.add(
        ReaderTypographyLine(
          start: cursor,
          end: end,
          top: top,
          height: metric.height,
          x: 0,
          painter: painter,
          displayLength: end - cursor,
          displayText: '',
        ),
      );
      cursor = end;
      top += metric.height;
    }
  }

  void _layoutParagraph(
    int start,
    int contentEnd,
    int logicalEnd, {
    required bool indent,
  }) {
    if (contentEnd == start) {
      _addLine(start, logicalEnd, '', 0, isLastLine: true);
      return;
    }
    var cursor = start;
    var first = true;
    while (cursor < contentEnd) {
      // A character unit follows the existing Reader contract (the current
      // font's nominal em width), not a fixed pixel distance.
      final characterWidth = style.fontSize ?? 17;
      final rawX = first && indent ? firstLineIndent * characterWidth : 0.0;
      // Negative em indentation is a hanging indent. Keep the content width
      // stable and let the line paint into the leading margin instead of
      // clipping it to the viewport.
      final x = rawX.clamp(-width + 1, width - 1).toDouble();
      final available = math.max(1.0, width - math.max(0, x));
      final probe = TextPainter(
        text: _spanForRange(cursor, contentEnd, style),
        textDirection: textDirection,
        textScaler: TextScaler.noScaling,
        textAlign: textAlign,
      )..layout(maxWidth: available);
      final boundary = probe.getLineBoundary(const TextPosition(offset: 0));
      probe.dispose();
      final take = math.max(1, boundary.end);
      var end = math.min(contentEnd, cursor + take);
      if (end == contentEnd) end = logicalEnd;
      _addLine(
        cursor,
        end,
        text.substring(cursor, math.min(end, contentEnd)),
        x,
        isLastLine: end >= logicalEnd,
      );
      cursor = math.min(end, contentEnd);
      first = false;
    }
  }

  void _addLine(
    int start,
    int end,
    String displayText,
    double x, {
    required bool isLastLine,
  }) {
    // TextPainter applies justification only to non-final paragraph lines.
    // A synthetic newline is paint/layout-only; the source UTF-16 offsets and
    // ReaderLocator remain anchored to the original text.
    final paintText = textAlign == TextAlign.justify && !isLastLine
        ? '$displayText\n'
        : displayText;
    final lineWidth = x < 0 ? width : math.max(1.0, width - x);
    final painter = TextPainter(
      text: _spanForRange(
        start,
        math.min(end, text.length),
        style,
        appendNewline: paintText.endsWith('\n'),
        forceSpace: paintText.isEmpty,
      ),
      textDirection: textDirection,
      textScaler: TextScaler.noScaling,
      textAlign: textAlign,
    )..layout(maxWidth: lineWidth);
    final lineHeight =
        painter.computeLineMetrics().firstOrNull?.height ??
        (style.fontSize ?? 17) * (style.height ?? 1);
    lines.add(
      ReaderTypographyLine(
        start: start,
        end: end,
        top: height,
        height: lineHeight,
        x: x,
        painter: painter,
        displayLength: displayText.length,
        displayText: paintText,
      ),
    );
    height += lineHeight;
  }

  ReaderTypographyLine? lineForOffset(int offset) {
    if (lines.isEmpty) return null;
    return lines.firstWhere(
      (line) => offset >= line.start && offset < line.end,
      orElse: () => lines.last,
    );
  }

  ReaderTypographyLine? lineForY(double y) {
    if (lines.isEmpty) return null;
    return lines.firstWhere(
      (line) => y < line.top + line.height,
      orElse: () => lines.last,
    );
  }

  int offsetForY(double y) {
    if (_fastPainter case final painter?) {
      return painter.getPositionForOffset(Offset(0, y)).offset;
    }
    final line = lineForY(y);
    if (line == null) return 0;
    final relative = line.painter
        .getPositionForOffset(Offset(0, y - line.top))
        .offset;
    return line.start + relative.clamp(0, line.displayLength);
  }

  void paint(Canvas canvas, Offset offset) {
    if (_fastPainter case final painter?) {
      _paintHighlights(canvas, offset);
      painter.paint(canvas, offset);
      return;
    }
    for (final line in lines) {
      _paintHighlightForLine(canvas, offset, line);
      line.painter.paint(canvas, offset + Offset(line.x, line.top));
    }
  }

  void _paintHighlights(Canvas canvas, Offset offset) {
    final start = highlightStart;
    final end = highlightEnd;
    final color = highlightColor;
    if (start == null || end == null || color == null || start >= end) return;
    for (final line in lines) {
      if (line.end <= start || line.start >= end) continue;
      canvas.drawRect(
        Rect.fromLTWH(
          line.x,
          line.top,
          width - line.x,
          line.height,
        ).shift(offset),
        Paint()..color = color,
      );
    }
  }

  void _paintHighlightForLine(
    Canvas canvas,
    Offset offset,
    ReaderTypographyLine line,
  ) {
    final start = highlightStart;
    final end = highlightEnd;
    final color = highlightColor;
    if (start == null || end == null || color == null || start >= end) return;
    if (line.end <= start || line.start >= end) return;
    canvas.drawRect(
      Rect.fromLTWH(
        line.x,
        line.top,
        width - line.x,
        line.height,
      ).shift(offset),
      Paint()..color = color,
    );
  }

  void updateHighlight({int? start, int? end, Color? color}) {
    highlightStart = start;
    highlightEnd = end;
    highlightColor = color;
  }

  void updatePaintStyle(TextStyle value) {
    if (_fastPainter case final painter?) {
      painter.text = _spanForRange(0, text.length, value);
      painter.layout(maxWidth: width);
      return;
    }
    for (final line in lines) {
      line.painter.text = _spanForRange(
        line.start,
        math.min(line.end, text.length),
        value,
        appendNewline: line.displayText.endsWith('\n'),
        forceSpace: line.displayText.isEmpty,
      );
      line.painter.layout(
        maxWidth: line.x < 0 ? width : math.max(1.0, width - line.x),
      );
    }
  }

  void dispose() {
    if (_fastPainter case final painter?) {
      painter.dispose();
      return;
    }
    for (final line in lines) {
      line.painter.dispose();
    }
  }

  TextSpan _spanForRange(
    int start,
    int end,
    TextStyle base, {
    bool appendNewline = false,
    bool forceSpace = false,
  }) {
    final safeStart = start.clamp(0, text.length).toInt();
    final safeEnd = end.clamp(safeStart, text.length).toInt();
    final relevant = styleRuns
        .where(
          (run) =>
              run.endCharacterOffset > safeStart &&
              run.startCharacterOffset < safeEnd,
        )
        .toList(growable: false);
    if (relevant.isEmpty) {
      return TextSpan(
        text: forceSpace
            ? ' '
            : text.substring(safeStart, safeEnd) + (appendNewline ? '\n' : ''),
        style: base,
      );
    }
    final boundaries = <int>{safeStart, safeEnd};
    for (final run in relevant) {
      boundaries.add(
        run.startCharacterOffset.clamp(safeStart, safeEnd).toInt(),
      );
      boundaries.add(run.endCharacterOffset.clamp(safeStart, safeEnd).toInt());
    }
    final sorted = boundaries.toList()..sort();
    final children = <TextSpan>[];
    for (var index = 0; index + 1 < sorted.length; index++) {
      final segmentStart = sorted[index];
      final segmentEnd = sorted[index + 1];
      if (segmentEnd <= segmentStart) continue;
      final bold = relevant.any(
        (run) =>
            run.bold &&
            run.startCharacterOffset <= segmentStart &&
            run.endCharacterOffset >= segmentEnd,
      );
      final italic = relevant.any(
        (run) =>
            run.italic &&
            run.startCharacterOffset <= segmentStart &&
            run.endCharacterOffset >= segmentEnd,
      );
      children.add(
        TextSpan(
          text: text.substring(segmentStart, segmentEnd),
          style: base.copyWith(
            fontWeight: bold ? FontWeight.bold : base.fontWeight,
            fontStyle: italic ? FontStyle.italic : base.fontStyle,
          ),
        ),
      );
    }
    if (appendNewline) children.add(TextSpan(text: '\n', style: base));
    if (children.isEmpty && forceSpace) {
      children.add(TextSpan(text: ' ', style: base));
    }
    return TextSpan(children: children);
  }
}

final class ReaderTypographyLine {
  const ReaderTypographyLine({
    required this.start,
    required this.end,
    required this.top,
    required this.height,
    required this.x,
    required this.painter,
    required this.displayLength,
    required this.displayText,
  });
  final int start;
  final int end;
  final double top;
  final double height;
  final double x;
  final TextPainter painter;
  final int displayLength;
  final String displayText;
}
