import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/reader/reader_typography_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paragraph metrics preserve original UTF-16 ranges', () {
    const text = '第一段😀正文内容，用于换行。\n第二段正文。';
    final layout = ReaderTypographyLayout(
      text: text,
      style: const TextStyle(fontSize: 20, height: 1.8, letterSpacing: .2),
      textDirection: TextDirection.ltr,
      width: 150,
      paragraphSpacing: 9,
      firstLineIndent: 2,
      startsAtParagraphBoundary: true,
    );
    addTearDown(layout.dispose);

    expect(layout.lines.first.start, 0);
    expect(layout.lines.last.end, text.length);
    for (var i = 1; i < layout.lines.length; i++) {
      expect(layout.lines[i].start, layout.lines[i - 1].end);
    }
    expect(layout.lines.first.x, 40);
    final secondParagraph = layout.lines.firstWhere(
      (line) => line.start == text.indexOf('\n') + 1,
    );
    expect(secondParagraph.x, 40);
    for (var offset = 0; offset < text.length; offset++) {
      final line = layout.lineForOffset(offset)!;
      expect(offset, inInclusiveRange(line.start, line.end - 1));
    }
  });

  test('paragraph spacing affects paint height without changing text', () {
    const text = '甲段\n乙段\n丙段';
    ReaderTypographyLayout build(double spacing) => ReaderTypographyLayout(
      text: text,
      style: const TextStyle(fontSize: 18, height: 1.6),
      textDirection: TextDirection.ltr,
      width: 300,
      paragraphSpacing: spacing,
      firstLineIndent: 2,
      startsAtParagraphBoundary: true,
    );
    final compact = build(0);
    final spaced = build(8);
    addTearDown(compact.dispose);
    addTearDown(spaced.dispose);

    expect(spaced.height, greaterThan(compact.height));
    expect(spaced.text, text);
    expect(spaced.lines.last.end, text.length);
  });
}
