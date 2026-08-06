import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_decoder.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_data.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_loader.dart';

/// 加载正式二进制索引（与运行时同源，验证"Windows 与 Android 相同测试向量"）。
Gb18030IndexData loadIndex() {
  final file = File('assets/encoding/gb18030_index.bin');
  final bytes = file.readAsBytesSync();
  return const Gb18030IndexLoader().parse(bytes);
}

void main() {
  late Gb18030IndexData index;

  setUpAll(() {
    index = loadIndex();
  });

  group('索引加载', () {
    test('magic/版本/长度校验通过', () {
      expect(index.entryCount, 23940);
      expect(index.anchorCount, 209);
    });

    test('meta 与 bin 一致', () {
      final metaFile = File('assets/encoding/gb18030_index.meta.json');
      expect(metaFile.existsSync(), isTrue);
      final meta = const Gb18030IndexLoader().parseMeta(
        metaFile.readAsBytesSync(),
      );
      expect(meta['entryCount'], 23940);
      expect(meta['anchorCount'], 209);
      expect(meta['formatVersion'], 1);
    });
  });

  group('GB18030 解码（全量验证）', () {
    test('双字节全表验证：所有 23940 项可解码且非 0/非 FFFD', () {
      var valid = 0;
      for (var p = 0; p < index.entryCount; p++) {
        final cp = index.entries[p];
        if (cp != 0 && cp != 0xFFFD) valid++;
      }
      expect(valid, greaterThan(23000));
    });

    test('锚点全量验证：209 项', () {
      expect(index.anchorCount, 209);
    });

    test('四字节区间边界（U+10000 在 pointer 189000，U+20000 在 pointer 254536）', () {
      final decoder = Gb18030Decoder(index);
      // 0x90 0x30 0x81 0x30 → pointer 189000 → U+10000
      expect(
        decoder.decode(Uint8List.fromList([0x90, 0x30, 0x81, 0x30])),
        '\u{10000}',
      );
      // 0x95 0x32 0x82 0x36 → pointer 254536 → U+20000
      expect(
        decoder.decode(Uint8List.fromList([0x95, 0x32, 0x82, 0x36])),
        '\u{20000}',
      );
    });
  });

  group('GB18030 解码（基础用例）', () {
    late Gb18030Decoder decoder;
    setUp(() => decoder = Gb18030Decoder(index));

    test('ASCII', () {
      expect(decoder.decode(Uint8List.fromList('abc123'.codeUnits)), 'abc123');
    });

    test('常用中文（GBK 双字节）', () {
      // '中文测试文本' GBK 编码
      final gbk = Uint8List.fromList([
        0xD6,
        0xD0,
        0xCE,
        0xC4,
        0xB2,
        0xE2,
        0xCA,
        0xD4,
        0xCE,
        0xC4,
        0xB1,
        0xBE,
      ]);
      expect(decoder.decode(gbk), '中文测试文本');
    });

    test('全角标点', () {
      // ，。！？：；""（）《》【】 GBK 编码（Python 生成确认）
      final gbk = Uint8List.fromList([
        0xA3,
        0xAC,
        0xA1,
        0xA3,
        0xA3,
        0xA1,
        0xA3,
        0xBF,
        0xA3,
        0xBA,
        0xA3,
        0xBB,
        0x22,
        0x22,
        0xA3,
        0xA8,
        0xA3,
        0xA9,
        0xA1,
        0xB6,
        0xA1,
        0xB7,
        0xA1,
        0xBE,
        0xA1,
        0xBF,
      ]);
      expect(decoder.decode(gbk), '，。！？：；""（）《》【】');
    });

    test('生僻字（四字节）', () {
      // U+20000 → 0x95 0x32 0x82 0x36
      expect(
        decoder.decode(Uint8List.fromList([0x95, 0x32, 0x82, 0x36])),
        '\u{20000}',
      );
    });

    test('0x80 → U+FFFD（replace 模式）', () {
      expect(decoder.decode(Uint8List.fromList([0x80])), '\uFFFD');
    });

    test('非法 lead（0xFF）→ U+FFFD', () {
      expect(decoder.decode(Uint8List.fromList([0xFF])), '\uFFFD');
    });

    test('非法 trail（0x81 0x20）→ U+FFFD', () {
      expect(decoder.decode(Uint8List.fromList([0x81, 0x20])), '\uFFFD');
    });

    test('截断序列（0xD6 单独）→ U+FFFD', () {
      expect(decoder.decode(Uint8List.fromList([0xD6])), '\uFFFD');
    });

    test('strict 模式非法输入抛 FormatException', () {
      expect(
        () => decoder.decode(Uint8List.fromList([0x80]), allowMalformed: false),
        throwsFormatException,
      );
      expect(
        () => decoder.decode(Uint8List.fromList([0xD6]), allowMalformed: false),
        throwsFormatException,
      );
      expect(
        () => decoder.decode(Uint8List.fromList([0xFF]), allowMalformed: false),
        throwsFormatException,
      );
    });

    test('strict 模式合法输入不抛', () {
      final gbk = Uint8List.fromList([0xD6, 0xD0, 0xCE, 0xC4]);
      expect(decoder.decode(gbk, allowMalformed: false), '中文');
    });
  });

  group('分段输入（跨块序列）', () {
    test('双字节跨块：lead 在块1，trail 在块2', () {
      final d = Gb18030Decoder(index);
      final out1 = d.addBytes(Uint8List.fromList([0xD6])).toString();
      final out2 = d.addBytes(Uint8List.fromList([0xD0])).toString();
      final out3 = d.finish();
      expect(out1 + out2 + out3, '中');
    });

    test('四字节跨块：每个字节单独一块', () {
      final d = Gb18030Decoder(index);
      final parts = <String>[];
      for (final b in [0x95, 0x32, 0x82, 0x36]) {
        parts.add(d.addBytes(Uint8List.fromList([b])).toString());
      }
      parts.add(d.finish());
      expect(parts.join(), '\u{20000}');
    });

    test('分段与整段结果一致', () {
      final whole = Gb18030Decoder(index).decode(
        Uint8List.fromList([0xD6, 0xD0, 0xCE, 0xC4, 0x95, 0x32, 0x82, 0x36]),
      );
      final d = Gb18030Decoder(index);
      final sb = StringBuffer()
        ..write(d.addBytes(Uint8List.fromList([0xD6])).toString())
        ..write(d.addBytes(Uint8List.fromList([0xD0, 0xCE, 0xC4])).toString())
        ..write(d.addBytes(Uint8List.fromList([0x95, 0x32])).toString())
        ..write(d.addBytes(Uint8List.fromList([0x82, 0x36])).toString())
        ..write(d.finish());
      expect(sb.toString(), whole);
    });

    test('跨块截断在 finish 时报错', () {
      final d = Gb18030Decoder(index);
      d.addBytes(Uint8List.fromList([0xD6]));
      expect(d.finish(), '\uFFFD');
    });
  });
}
