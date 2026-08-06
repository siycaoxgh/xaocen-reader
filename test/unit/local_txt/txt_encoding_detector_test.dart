import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/sources/local_txt/txt_encoding_detector.dart';

void main() {
  const detector = TxtEncodingDetector();

  group('BOM 检测', () {
    test('UTF-8 BOM', () {
      final r = detector.detect(Uint8List.fromList([0xEF, 0xBB, 0xBF, 0x41]));
      expect(r.encoding, TextEncoding.utf8Bom);
      expect(r.bomLength, 3);
    });

    test('UTF-16 LE BOM', () {
      final r = detector.detect(Uint8List.fromList([0xFF, 0xFE, 0x41, 0x00]));
      expect(r.encoding, TextEncoding.utf16Le);
      expect(r.bomLength, 2);
    });

    test('UTF-16 BE BOM', () {
      final r = detector.detect(Uint8List.fromList([0xFE, 0xFF, 0x00, 0x41]));
      expect(r.encoding, TextEncoding.utf16Be);
      expect(r.bomLength, 2);
    });
  });

  group('无 BOM UTF-8', () {
    test('纯 ASCII 是合法 UTF-8', () {
      final r = detector.detect(utf8.encode('hello world'));
      expect(r.encoding, TextEncoding.utf8);
    });

    test('中文 UTF-8', () {
      final r = detector.detect(utf8.encode('中文测试'));
      expect(r.encoding, TextEncoding.utf8);
    });

    test('含多字节序列的 UTF-8', () {
      final bytes = Uint8List.fromList([0xE4, 0xB8, 0xAD, 0xE6, 0x96, 0x87]);
      expect(detector.detect(bytes).encoding, TextEncoding.utf8);
    });
  });

  group('GB18030 候选', () {
    test('GBK 中文内容', () {
      // 中文测试 GBK：D6 D0 CE C4 B2 E2 CA D4
      final bytes = Uint8List.fromList([
        0xD6,
        0xD0,
        0xCE,
        0xC4,
        0xB2,
        0xE2,
        0xCA,
        0xD4,
      ]);
      final r = detector.detect(bytes);
      expect(r.encoding, TextEncoding.gb18030);
    });
  });

  group('未知编码', () {
    test('垃圾字节（无 BOM 歧义）', () {
      // 0xFF 后跟非 BOM 组合：避免误判 UTF-16 BOM
      final r = detector.detect(Uint8List.fromList([0xFF, 0x61, 0xFE, 0x41]));
      expect(r.encoding, TextEncoding.unknown);
      expect(r.usedFallback, isTrue);
    });
  });

  group('真实 fixture 编码识别', () {
    test('所有 fixture 识别正确', () {
      final cases = <String, TextEncoding>{
        'utf8_chapters.txt': TextEncoding.utf8,
        'utf8_bom.txt': TextEncoding.utf8Bom,
        'utf16le.txt': TextEncoding.utf16Le,
        'utf16be.txt': TextEncoding.utf16Be,
        'gbk.txt': TextEncoding.gb18030,
        'gb18030.txt': TextEncoding.gb18030,
        'no_chapters.txt': TextEncoding.utf8,
        'invalid_encoding.txt': TextEncoding.unknown,
      };
      cases.forEach((name, expected) {
        final bytes = File('test/fixtures/txt/$name').readAsBytesSync();
        final r = detector.detect(bytes);
        expect(r.encoding, expected, reason: '$name: ${r.reason}');
      });
    });
  });
}
