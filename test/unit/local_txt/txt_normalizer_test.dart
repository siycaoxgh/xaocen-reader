import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/sources/local_txt/txt_normalizer.dart';

void main() {
  group('TxtNormalizer', () {
    test('移除 BOM', () {
      final r = TxtNormalizer.normalize('\uFEFFhello');
      expect(r.text, 'hello');
      expect(r.bomRemovedLength, 1);
    });

    test('CRLF → LF', () {
      final r = TxtNormalizer.normalize('a\r\nb\r\nc');
      expect(r.text, 'a\nb\nc');
    });

    test('CR → LF', () {
      final r = TxtNormalizer.normalize('a\rb\rc');
      expect(r.text, 'a\nb\nc');
    });

    test('混合 CRLF/CR/LF', () {
      final r = TxtNormalizer.normalize('a\r\nb\rc\nd');
      expect(r.text, 'a\nb\nc\nd');
    });

    test('不删除段首空格/全角空格/空行', () {
      final raw = '  缩进开头\n\u3000\u3000全角缩进\n\n空行保留\n';
      final r = TxtNormalizer.normalize(raw);
      expect(r.text, raw);
    });

    test('不删除重复标题正文行', () {
      final raw = '第1章 标题\n\u3000\u3000第1章 标题\n';
      final r = TxtNormalizer.normalize(raw);
      expect(r.text, raw); // 规范化不删行
    });

    test('lineStarts 正确', () {
      final r = TxtNormalizer.normalize('ab\ncd\nef');
      expect(r.lineStarts, [0, 3, 6]);
      expect(r.lineCount, 3);
    });

    test('lineOf 定位（O(log n)）', () {
      final r = TxtNormalizer.normalize('ab\ncd\nef');
      expect(r.lineOf(0), 0);
      expect(r.lineOf(2), 0);
      expect(r.lineOf(3), 1);
      expect(r.lineOf(5), 1);
      expect(r.lineOf(6), 2);
    });

    test('复杂度合同：不重复前缀计算（lineStarts 单次构建）', () {
      // 构造大文本验证性能（O(n) 单次遍历）
      final big = List.generate(10000, (i) => '第$i行内容').join('\n');
      final sw = Stopwatch()..start();
      final r = TxtNormalizer.normalize(big);
      sw.stop();
      expect(r.lineCount, 10000);
      // 10k 行应在 ~100ms 内
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });
  });
}
