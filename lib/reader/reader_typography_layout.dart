import 'dart:math' as math;

import 'package:flutter/painting.dart';

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
      text: TextSpan(text: text, style: style),
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
      final remaining = text.substring(cursor, contentEnd);
      final probe = TextPainter(
        text: TextSpan(text: remaining, style: style),
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
    final painter = TextPainter(
      text: TextSpan(text: paintText.isEmpty ? ' ' : paintText, style: style),
      textDirection: textDirection,
      textScaler: TextScaler.noScaling,
      textAlign: textAlign,
    )..layout(maxWidth: math.max(1.0, width - x));
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
      painter.paint(canvas, offset);
      return;
    }
    for (final line in lines) {
      line.painter.paint(canvas, offset + Offset(line.x, line.top));
    }
  }

  void updatePaintStyle(TextStyle value) {
    if (_fastPainter case final painter?) {
      painter.text = TextSpan(text: text, style: value);
      painter.layout(maxWidth: width);
      return;
    }
    for (final line in lines) {
      line.painter.text = TextSpan(
        text: line.displayText.isEmpty ? ' ' : line.displayText,
        style: value,
      );
      line.painter.layout(maxWidth: math.max(1.0, width - line.x));
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
