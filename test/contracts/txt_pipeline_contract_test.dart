// 合同测试：验证 TXT 管线满足 M1 合同（任务书 §17）。
//
// 覆盖：
//  1. 同一文件重复索引结果一致；
//  2. Windows 与 Android 相同章节 offset（纯 Dart，同向量验证跨平台确定性）；
//  3. 缓存命中不重新扫描（cacheHit=true）；
//  4. mtime 变化但内容 hash 不变仍可安全命中；
//  5. 内容变化时缓存失效；
//  6. 473 章文件结果正确（真实文件，仅本机只读验收，不提交）；
//  7. 无章节文件结果为 0 章；
//  8. 取消不会留下正式缓存；
//  9. 缓存损坏不会伪装成功；
// 10. 所有 offset 都是 UTF-16 码元坐标。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/sources/local_txt/gb18030_index_loader.dart';
import 'package:xaocen_reader/sources/local_txt/txt_cancellation.dart';
import 'package:xaocen_reader/sources/local_txt/txt_import_request.dart';
import 'package:xaocen_reader/sources/local_txt/txt_import_service.dart';

late Directory tmpCache;

Future<TxtImportService> makeService() async {
  final binFile = File(p.join('assets', 'encoding', 'gb18030_index.bin'));
  final bytes = await binFile.readAsBytes();
  final index = const Gb18030IndexLoader().parse(bytes);
  return TxtImportService(encodingTableLoader: () async => index);
}

void main() {
  setUpAll(() async {
    tmpCache = await Directory.systemTemp.createTemp('xaocen_contract');
  });

  tearDownAll(() async {
    if (await tmpCache.exists()) await tmpCache.delete(recursive: true);
  });

  File fixture(String name) => File('test/fixtures/txt/$name');

  test('合同1+3+10: 重复索引结果一致 + 缓存命中 + UTF-16 偏移', () async {
    final service = await makeService();
    final f = fixture('utf8_chapters.txt');
    final req = TxtImportRequest(file: f, cacheDirectory: tmpCache);

    final r1 = await service.import(req);
    expect(r1.cacheHit, isFalse);
    final r2 = await service.import(req);
    expect(r2.cacheHit, isTrue, reason: '第二次必须命中缓存');

    // 结果一致
    expect(r2.index.chapterCount, r1.index.chapterCount);
    expect(
      r2.index.normalizedCharacterLength,
      r1.index.normalizedCharacterLength,
    );
    for (var i = 0; i < r1.index.tocEntries.length; i++) {
      expect(
        r2.index.tocEntries[i].startCharacterOffset,
        r1.index.tocEntries[i].startCharacterOffset,
      );
    }
    // 偏移是 UTF-16 码元（对 utf8_chapters.txt 手工验证第1章偏移）
    // 文本: 第一章 开端\n第一行正文。\n\n第二章 发展\n...
    // 偏移: 第=0
    expect(r1.index.tocEntries.first.startCharacterOffset, 0);
  });

  test('合同2: 平台无关确定性（纯 Dart 同向量）', () async {
    // 同一输入两次处理结果字节级一致（模拟跨平台确定性）
    final service = await makeService();
    final f = fixture('gbk.txt');
    final req = TxtImportRequest(file: f, cacheDirectory: tmpCache);
    final r1 = await service.import(req);
    final cache2 = await Directory.systemTemp.createTemp('xaocen_contract2');
    final service2 = await makeService();
    final r2 = await service2.import(
      TxtImportRequest(file: f, cacheDirectory: cache2),
    );
    expect(r1.index.sourceContentHash, r2.index.sourceContentHash);
    expect(r1.index.encoding, TextEncoding.gb18030);
    expect(
      r2.index.tocEntries.map((e) => e.startCharacterOffset).toList(),
      r1.index.tocEntries.map((e) => e.startCharacterOffset).toList(),
    );
    await cache2.delete(recursive: true);
  });

  test('合同4: mtime 变化但 hash 不变仍命中', () async {
    final service = await makeService();
    final f = fixture('gb18030.txt');
    final req = TxtImportRequest(file: f, cacheDirectory: tmpCache);
    await service.import(req);
    // 改 mtime（不碰内容）
    await f.setLastModified(DateTime(1999));
    final r = await service.import(req);
    expect(r.cacheHit, isTrue);
  });

  test('合同5: 内容变化时缓存失效', () async {
    final service = await makeService();
    final f = fixture('no_chapters.txt');
    final req = TxtImportRequest(file: f, cacheDirectory: tmpCache);
    await service.import(req);
    // 追加内容
    final orig = await f.readAsString();
    await f.writeAsString('$orig\n新增一行。\n');
    final r = await service.import(req);
    expect(r.cacheHit, isFalse);
    // 恢复
    await f.writeAsString(orig);
  });

  test('合同7: 无章节文件结果为 0 章', () async {
    final service = await makeService();
    final f = fixture('no_chapters.txt');
    final req = TxtImportRequest(file: f, cacheDirectory: tmpCache);
    final r = await service.import(req);
    expect(r.index.chapterCount, 0);
    expect(r.index.volumeCount, 0);
    expect(r.index.encoding, TextEncoding.utf8);
    // 不伪造目录
    expect(r.index.tocEntries, isEmpty);
  });

  test('合同8: 取消不会留下正式缓存', () async {
    final service = await makeService();
    final f = fixture('utf8_chapters.txt');
    final token = TxtImportCancellationToken();
    // 提前取消
    token.cancel();
    final req = TxtImportRequest(file: f, cacheDirectory: tmpCache);
    await expectLater(
      service.import(req, token: token),
      throwsA(isA<TxtImportCancelledException>()),
    );
    // 取消路径本身不新增正式缓存：用独立缓存目录验证
    final fresh = await Directory.systemTemp.createTemp('xaocen_cancel');
    final token2 = TxtImportCancellationToken()..cancel();
    await expectLater(
      service.import(
        TxtImportRequest(file: f, cacheDirectory: fresh),
        token: token2,
      ),
      throwsA(isA<TxtImportCancelledException>()),
    );
    expect(
      fresh.listSync().whereType<File>().where((e) => e.path.endsWith('.json')),
      isEmpty,
    );
    await fresh.delete(recursive: true);
  });

  test('合同9: 缓存损坏不伪装成功（由缓存单元测试覆盖，此处验证管线行为）', () async {
    final service = await makeService();
    final f = fixture('adjacent_dup.txt');
    final req = TxtImportRequest(file: f, cacheDirectory: tmpCache);
    final r1 = await service.import(req);
    // 定位缓存文件并损坏
    final cacheFiles = tmpCache
        .listSync()
        .whereType<File>()
        .where((e) => e.path.endsWith('.json'))
        .toList();
    expect(cacheFiles, isNotEmpty);
    await cacheFiles.first.writeAsString('garbage');
    // 重新导入：应能恢复（重扫）而非失败或返回损坏数据
    final r2 = await service.import(req);
    expect(r2.index.chapterCount, r1.index.chapterCount);
  });

  test('合同10: 公告误匹配排除 + 去重（fixture 级）', () async {
    final service = await makeService();
    final r = await service.import(
      TxtImportRequest(
        file: fixture('notice_false_positive.txt'),
        cacheDirectory: tmpCache,
      ),
    );
    expect(r.index.chapterCount, 2);
    final titles = r.index.tocEntries.map((e) => e.title).toList();
    expect(titles, ['第1章', '第2章']);
  });

  test('合同10b: 相邻重复去重 + 远距同名保留（fixture 级）', () async {
    final service = await makeService();
    final dup = await service.import(
      TxtImportRequest(
        file: fixture('adjacent_dup.txt'),
        cacheDirectory: tmpCache,
      ),
    );
    expect(dup.index.chapterCount, 2); // 第1章(去重后1) + 第2章

    final far = await service.import(
      TxtImportRequest(file: fixture('far_same.txt'), cacheDirectory: tmpCache),
    );
    // 序章 缘起 / 第1章 / 第2章 / 序章 回归 / 第3章 = 5 章，远距同名序章保留
    expect(far.index.chapterCount, 5);
  });

  test('合同10c: 卷层级 fixture', () async {
    final service = await makeService();
    final r = await service.import(
      TxtImportRequest(file: fixture('volumes.txt'), cacheDirectory: tmpCache),
    );
    expect(r.index.volumeCount, 2);
    expect(r.index.chapterCount, 4);
    // 卷内重新编号
    final chapters = r.index.tocEntries.where((e) => e.isChapter).toList();
    expect(chapters[0].order, 1); // 第一卷 第1章
    expect(chapters[1].order, 2); // 第一卷 第2章
    expect(chapters[2].order, 1); // 第二卷 第1章（重新编号）
    expect(chapters[3].order, 2); // 第二卷 第3章 → 卷内 order 2
  });
}
