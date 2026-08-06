import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/domain/local_txt/toc_entry.dart';
import 'package:xaocen_reader/domain/local_txt/txt_index.dart';
import 'package:xaocen_reader/sources/local_txt/txt_index_cache.dart';

void main() {
  late Directory tmpDir;
  late TxtIndexCache cache;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('xaocen_cache_test');
    cache = TxtIndexCache(
      cacheDirectory: tmpDir,
      parserVersion: '1.0.0',
      normalizationVersion: '1.0.0',
    );
  });

  tearDown(() async {
    if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
  });

  TxtIndex makeIndex({String hash = 'abc', String fileName = 'test.txt'}) {
    return TxtIndex(
      indexFormatVersion: 1,
      parserVersion: '1.0.0',
      normalizationVersion: '1.0.0',
      sourceFileName: fileName,
      sourceSize: 100,
      sourceContentHash: hash,
      encoding: TextEncoding.utf8,
      normalizedCharacterLength: 90,
      volumeCount: 0,
      chapterCount: 2,
      tocEntries: [
        TocEntry(
          id: 'c1',
          parentId: null,
          kind: TocEntryKind.chapter,
          level: 2,
          title: '第1章',
          order: 1,
          startCharacterOffset: 0,
          endCharacterOffset: 50,
        ),
        TocEntry(
          id: 'c2',
          parentId: null,
          kind: TocEntryKind.chapter,
          level: 2,
          title: '第2章',
          order: 2,
          startCharacterOffset: 50,
          endCharacterOffset: 90,
        ),
      ],
      generatedAt: DateTime.now(),
    );
  }

  group('缓存写入与命中', () {
    test('写入后命中', () async {
      await cache.write(makeIndex());
      final (index, check) = await cache.readIfValid(
        sourceFileName: 'test.txt',
        sourceSize: 100,
        sourceContentHash: 'abc',
        encodingName: 'utf8',
        indexFormatVersion: 1,
      );
      expect(check.hit, isTrue);
      expect(index, isNotNull);
      expect(index!.chapterCount, 2);
    });

    test('内容 hash 变化 → 缓存失效', () async {
      await cache.write(makeIndex(hash: 'abc'));
      final (index, check) = await cache.readIfValid(
        sourceFileName: 'test.txt',
        sourceSize: 100,
        sourceContentHash: 'def', // 内容变了
        encodingName: 'utf8',
        indexFormatVersion: 1,
      );
      expect(check.hit, isFalse);
      expect(index, isNull);
    });

    test('size 变化 → 缓存失效', () async {
      await cache.write(makeIndex());
      final (_, check) = await cache.readIfValid(
        sourceFileName: 'test.txt',
        sourceSize: 101,
        sourceContentHash: 'abc',
        encodingName: 'utf8',
        indexFormatVersion: 1,
      );
      expect(check.hit, isFalse);
    });

    test('parserVersion 变化 → 缓存失效', () async {
      await cache.write(makeIndex());
      final otherCache = TxtIndexCache(
        cacheDirectory: tmpDir,
        parserVersion: '2.0.0',
        normalizationVersion: '1.0.0',
      );
      final (_, check) = await otherCache.readIfValid(
        sourceFileName: 'test.txt',
        sourceSize: 100,
        sourceContentHash: 'abc',
        encodingName: 'utf8',
        indexFormatVersion: 1,
      );
      expect(check.hit, isFalse);
    });

    test('mtime 变化但内容 hash 不变 → 仍命中（不依赖 mtime）', () async {
      await cache.write(makeIndex());
      final file = File(
        '${tmpDir.path}${Platform.pathSeparator}test.txt.abc.json',
      );
      // 修改 mtime（不碰内容）
      final old = DateTime(2000);
      await file.setLastModified(old);
      final (index, check) = await cache.readIfValid(
        sourceFileName: 'test.txt',
        sourceSize: 100,
        sourceContentHash: 'abc',
        encodingName: 'utf8',
        indexFormatVersion: 1,
      );
      expect(check.hit, isTrue);
      expect(index, isNotNull);
    });

    test('缓存损坏不伪装成功', () async {
      final file = File(
        '${tmpDir.path}${Platform.pathSeparator}test.txt.abc.json',
      );
      await file.writeAsString('{ not valid json ');
      final (index, check) = await cache.readIfValid(
        sourceFileName: 'test.txt',
        sourceSize: 100,
        sourceContentHash: 'abc',
        encodingName: 'utf8',
        indexFormatVersion: 1,
      );
      expect(check.hit, isFalse);
      expect(index, isNull);
      expect(check.reason, contains('corrupt'));
    });
  });

  group('原子写入', () {
    test('成功写入无 tmp 残留', () async {
      await cache.write(makeIndex());
      final leftovers = tmpDir
          .listSync()
          .where((e) => e.path.endsWith('.tmp'))
          .toList();
      expect(leftovers, isEmpty);
    });

    test('正文不入缓存', () async {
      await cache.write(makeIndex());
      final content = await File(
        '${tmpDir.path}${Platform.pathSeparator}test.txt.abc.json',
      ).readAsString();
      expect(content.contains('正文'), isFalse);
      expect(content.contains('第1章'), isTrue); // 目录在，正文不在
    });

    test('损坏后重新写入覆盖', () async {
      final file = File(
        '${tmpDir.path}${Platform.pathSeparator}test.txt.abc.json',
      );
      await file.writeAsString('corrupt');
      await cache.write(makeIndex());
      final (index, check) = await cache.readIfValid(
        sourceFileName: 'test.txt',
        sourceSize: 100,
        sourceContentHash: 'abc',
        encodingName: 'utf8',
        indexFormatVersion: 1,
      );
      expect(check.hit, isTrue);
      expect(index, isNotNull);
    });
  });
}
