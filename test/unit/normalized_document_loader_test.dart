import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';

void main() {
  late Directory tmp;
  late LibraryFileManager fileManager;
  late NormalizedDocumentLoader loader;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('xaocen_reader_norm');
    fileManager = LibraryFileManager(libraryRoot: tmp);
    loader = NormalizedDocumentLoader(fileManager: fileManager);
    // 准备 normalized.txt（无 BOM UTF-8）
    final contentDir = Directory('${tmp.path}/local_txt/abc');
    await contentDir.create(recursive: true);
    final text = '第一章 开端\n正文内容\n第二章 发展\n';
    await File(
      '${contentDir.path}/normalized.txt',
    ).writeAsBytes(utf8.encode(text));
    final hash = sha256.convert(utf8.encode(text)).toString();
    await File('${contentDir.path}/manifest.json').writeAsString(
      '{"manifestVersion":1,"normalizedHash":"$hash",'
      '"normalizedCharacterLength":${text.length},'
      '"normalizationVersion":"v1","parserVersion":"1",'
      '"indexFormatVersion":"1","originalFileName":"test.txt"}',
    );
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  group('NormalizedDocumentLoader', () {
    test('正常加载（从 manifest 取 hash/length）', () async {
      final doc = await loader.load(
        storagePath: 'library/local_txt/abc/normalized.txt',
      );
      expect(doc.text, '第一章 开端\n正文内容\n第二章 发展\n');
      expect(doc.normalizedHash, isNotEmpty);
      expect(doc.normalizationVersion, 'v1');
      expect(doc.sourceFileName, 'test.txt');
    });

    test('显式传入 hash/length 覆盖 manifest', () async {
      final text = '第一章 开端\n正文内容\n第二章 发展\n';
      final hash = sha256.convert(utf8.encode(text)).toString();
      final doc = await loader.load(
        storagePath: 'library/local_txt/abc/normalized.txt',
        expectedHash: hash,
        expectedLength: text.length,
      );
      expect(doc.text, text);
    });

    test('hash 不匹配抛异常', () async {
      expect(
        () => loader.load(
          storagePath: 'library/local_txt/abc/normalized.txt',
          expectedHash: 'wrong-hash',
        ),
        throwsA(
          isA<NormalizedDocumentException>().having(
            (e) => e.code,
            'code',
            'hash_mismatch',
          ),
        ),
      );
    });

    test('长度不匹配抛异常', () async {
      expect(
        () => loader.load(
          storagePath: 'library/local_txt/abc/normalized.txt',
          expectedLength: 999,
        ),
        throwsA(
          isA<NormalizedDocumentException>().having(
            (e) => e.code,
            'code',
            'length_mismatch',
          ),
        ),
      );
    });

    test('文件不存在抛异常', () async {
      await expectLater(
        loader.load(storagePath: 'library/local_txt/zzz/normalized.txt'),
        throwsA(
          isA<NormalizedDocumentException>().having(
            (e) => e.code,
            'code',
            'file_missing',
          ),
        ),
      );
    });

    test('路径穿越拒绝', () async {
      await expectLater(
        loader.load(storagePath: '../evil/normalized.txt'),
        throwsA(
          isA<NormalizedDocumentException>().having(
            (e) => e.code,
            'code',
            'unsafe_path',
          ),
        ),
      );
    });

    test('带 BOM 拒绝', () async {
      final f = File('${tmp.path}/local_txt/abc/normalized.txt');
      final orig = await f.readAsBytes();
      await f.writeAsBytes([0xEF, 0xBB, 0xBF, ...orig]);
      await expectLater(
        loader.load(storagePath: 'library/local_txt/abc/normalized.txt'),
        throwsA(
          isA<NormalizedDocumentException>().having(
            (e) => e.code,
            'code',
            'bom_present',
          ),
        ),
      );
      // 恢复（后续测试不再用该文件）
      await f.writeAsBytes(orig);
    });

    test('非法 UTF-8 拒绝', () async {
      final f = File('${tmp.path}/local_txt/abc/normalized.txt');
      await f.writeAsBytes([0x80, 0x81, 0x82]); // 非法 UTF-8
      await expectLater(
        loader.load(storagePath: 'library/local_txt/abc/normalized.txt'),
        throwsA(
          isA<NormalizedDocumentException>().having(
            (e) => e.code,
            'code',
            'invalid_utf8',
          ),
        ),
      );
    });

    test('UTF-16 长度与 text.length 一致', () async {
      // 含 surrogate pair 的文本：UTF-16 码元长度 = String.length
      final contentDir = Directory('${tmp.path}/local_txt/xyz');
      await contentDir.create(recursive: true);
      final text = '𠀀𠀀 测试'; // U+20000 两次 = 4 码元 + 3 = 7
      await File(
        '${contentDir.path}/normalized.txt',
      ).writeAsBytes(utf8.encode(text));
      final hash = sha256.convert(utf8.encode(text)).toString();
      await File('${contentDir.path}/manifest.json').writeAsString(
        '{"manifestVersion":1,"normalizedHash":"$hash",'
        '"normalizedCharacterLength":${text.length}}',
      );
      final doc = await loader.load(
        storagePath: 'library/local_txt/xyz/normalized.txt',
      );
      expect(doc.characterLength, text.length);
    });
  });
}
