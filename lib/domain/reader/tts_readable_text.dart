/// Platform-neutral readable text for speech output.
///
/// Segments keep the original UTF-16 range.  The segment text is only an
/// ephemeral speech input; the normalized document is never changed.
library;

import 'package:flutter/foundation.dart';

@immutable
class ReadableTextSegment {
  const ReadableTextSegment({
    required this.index,
    required this.startCharacterOffset,
    required this.endCharacterOffset,
    required this.text,
  });

  final int index;
  final int startCharacterOffset;
  final int endCharacterOffset;
  final String text;

  bool contains(int offset) =>
      offset >= startCharacterOffset && offset < endCharacterOffset;

  @override
  String toString() =>
      'ReadableTextSegment#$index[$startCharacterOffset,$endCharacterOffset)';
}

/// Builds speech-sized paragraphs from any normalized/readable text source.
///
/// This intentionally does not know about TXT, chapters, or persistence, so
/// EPUB/RSS adapters can provide the same contract later.
final class ReadableTextSource {
  const ReadableTextSource._(this.segments);

  final List<ReadableTextSegment> segments;

  factory ReadableTextSource.fromText(
    String text, {
    int maxSegmentLength = 1600,
  }) {
    if (maxSegmentLength < 8) {
      throw ArgumentError.value(maxSegmentLength, 'maxSegmentLength');
    }
    final result = <ReadableTextSegment>[];
    var cursor = 0;
    var index = 0;
    while (cursor < text.length) {
      while (cursor < text.length && text.codeUnitAt(cursor).isWhitespace) {
        cursor++;
      }
      if (cursor >= text.length) break;

      final paragraphEnd = _paragraphEnd(text, cursor);
      var start = cursor;
      while (start < paragraphEnd) {
        final remaining = paragraphEnd - start;
        final end = remaining <= maxSegmentLength
            ? paragraphEnd
            : _breakpoint(text, start, paragraphEnd, maxSegmentLength);
        final spoken = text.substring(start, end).trim();
        if (spoken.isNotEmpty) {
          result.add(
            ReadableTextSegment(
              index: index++,
              startCharacterOffset: start,
              endCharacterOffset: end,
              text: spoken,
            ),
          );
        }
        start = end;
      }
      cursor = paragraphEnd;
    }
    return ReadableTextSource._(List.unmodifiable(result));
  }

  static int _paragraphEnd(String text, int start) {
    final lf = text.indexOf('\n', start);
    return lf < 0 ? text.length : lf;
  }

  static int _breakpoint(
    String text,
    int start,
    int paragraphEnd,
    int maxSegmentLength,
  ) {
    final target = (start + maxSegmentLength)
        .clamp(start + 1, paragraphEnd)
        .toInt();
    const punctuation = '。！？!?；;，,、：:）)」』”"';
    // Prefer a natural sentence boundary close to the maximum size.
    final forwardLimit = (target + 160).clamp(target, paragraphEnd);
    for (var i = target; i < forwardLimit; i++) {
      if (punctuation.contains(String.fromCharCode(text.codeUnitAt(i)))) {
        return i + 1;
      }
    }
    for (var i = target - 1; i > start; i--) {
      if (punctuation.contains(String.fromCharCode(text.codeUnitAt(i)))) {
        return i + 1;
      }
    }
    return target;
  }
}

extension on int {
  bool get isWhitespace =>
      this == 0x09 || this == 0x0A || this == 0x0D || this == 0x20;
}
