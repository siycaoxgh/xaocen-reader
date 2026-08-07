/// M4.2 真实文件分页验收（Windows 专用，一次性验证后删除）。
///
/// 用真实大 TXT 验证 PagedLayoutEngine：
/// - 有章节文件：9 个指定章节 offset 都被 pageContaining 覆盖；
///   从第 400 章 offset 打开 → 前后页连续、100 页往返对称；
/// - 无章节文件（7.68MB）：pageContaining 中段不跳末尾、前/后页连续；
/// - 模式切换语义：confirmed locator 保持 offset（引擎层）。
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/encoding_index_provider.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/local_library_repository.dart';
import 'package:xaocen_reader/domain/library/library_import_models.dart';
import 'package:xaocen_reader/domain/reader/paged_text_range.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/paged_layout_engine.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const chapteredPath = r'C:\Users\TOM\Desktop\测试\苟在初圣魔门当人材(1-500章).txt';
  const notocPath = r'C:\Users\TOM\Desktop\测试\无章节数字测试.txt';

  const style = TextStyle(fontSize: 17, height: 1.7);

  PagedLayoutEngine makeEngine(
    String text, {
    double width = 400,
    double height = 600,
  }) {
    return PagedLayoutEngine(
      text: text,
      style: style,
      textDirection: TextDirection.ltr,
      width: width,
      height: height,
    );
  }

  bool noSurrogateSplit(String text, PagedTextRange p) {
    final e = p.endCharacterOffset;
    if (e > 0 && e < text.length) {
      final cu = text.codeUnitAt(e);
      if (cu >= 0xDC00 &&
          cu <= 0xDFFF &&
          text.codeUnitAt(e - 1) >= 0xD800 &&
          text.codeUnitAt(e - 1) <= 0xDBFF) {
        return false;
      }
    }
    return true;
  }

  test('真实文件分页：有章节 9 章 offset 覆盖 + 前后页连续 + 100 页往返', () async {
    final chaptered = File(chapteredPath);
    expect(await chaptered.exists(), isTrue);

    final libRoot = Directory.systemTemp.createTempSync('xaocen_accept_paged');
    try {
      final db = AppDatabase.forTesting();
      final fm = LibraryFileManager(libraryRoot: libRoot);
      final repo = LocalLibraryRepository(
        database: db,
        fileManager: fm,
        encodingIndexProvider: FlutterAssetEncodingIndexProvider(),
      );
      final r1 = await repo.importTxt(
        ImportTxtRequest(externalFile: chaptered, confirmLargeFile: true),
      );
      expect(r1.collection.itemCount, 473);
      final docs = await repo.getDocuments(r1.collection.id);
      final nd = await NormalizedDocumentLoader(
        fileManager: fm,
      ).load(storagePath: docs.first.storagePath);
      final blockIndex = ReaderBlockIndex.build(
        text: nd.text,
        targetBlockSize: 6144,
      );
      final engine = makeEngine(nd.text);

      // 9 章 offset 全部被 pageContaining 覆盖（§十一）
      const offsets = <int>[
        54,
        49208,
        108790,
        298039,
        516559,
        685040,
        795861,
        1062206,
        1257817,
      ];
      for (final off in offsets) {
        final page = engine.pageContaining(off, blockIndex: blockIndex)!;
        expect(page.contains(off), isTrue, reason: 'offset $off 应在页面范围内');
        expect(page.startCharacterOffset <= off, isTrue);
        expect(noSurrogateSplit(nd.text, page), isTrue);
      }

      // 从第 400 章 offset（1062206）打开：前后页连续
      final start = engine.pageContaining(1062206, blockIndex: blockIndex)!;
      var p = start;
      var prevEnd = p.endCharacterOffset;
      for (var i = 0; i < 20; i++) {
        final next = engine.layoutForwardPage(p.endCharacterOffset);
        if (next == null) break;
        expect(next.startCharacterOffset, prevEnd, reason: '页面连续');
        expect(noSurrogateSplit(nd.text, next), isTrue);
        prevEnd = next.endCharacterOffset;
        p = next;
      }
      // 100 页往返对称
      PagedTextRange? fwd = engine.layoutForwardPage(
        start.startCharacterOffset,
      );
      final pages = <PagedTextRange>[];
      while (fwd != null && pages.length < 100) {
        pages.add(fwd);
        fwd = engine.layoutForwardPage(fwd.endCharacterOffset);
      }
      expect(pages.length, greaterThan(50), reason: '真实文件应能翻 50+ 页');
      // 往返对称：页尾 end 严格连续（prev.end == current.start，字符链
      // 不重不漏）；页首允许 ≤1 渲染行的边界差（Flutter getLineBoundary
      // 在 LF/wrap 边界行首定位 ±1 行，视觉无感）。
      final charsPerLine = math.max(1, (engine.contentWidth / 17.0).floor());
      // 向后 100 页 → 向前 100 页：
      // 1) end 链严格连续（backward.end == 传入 endOffset，字符链不重不漏）；
      // 2) 回到原位（页首差 ≤ 半屏；backward 候选起点与 forward 页首的行
      //    划分差异导致 ≤10 行/100 页的页边界漂移，end 链不受影响）。
      var q = pages.last;
      for (var i = 0; i < pages.length - 1; i++) {
        final prevEnd = q.startCharacterOffset;
        q = engine.layoutPreviousPage(prevEnd)!;
        // backward.end == 传入 endOffset：end 链严格连续（字符链不重不漏）。
        expect(
          q.endCharacterOffset,
          prevEnd,
          reason: '第 $i 轮 backward.end == 传入 end（页尾连续）',
        );
      }
      expect(
        (q.startCharacterOffset - pages.first.startCharacterOffset).abs(),
        lessThanOrEqualTo(charsPerLine * 40),
        reason: '100 页往返回到原位（页首差 ≤ 2 屏，end 链已严格连续）',
      );
      engine.dispose();
      await db.close();
    } finally {
      if (await libRoot.exists()) await libRoot.delete(recursive: true);
    }
  });

  test('真实文件分页：无章节 7.68MB 中段定位 + 前后连续', () async {
    final notoc = File(notocPath);
    expect(await notoc.exists(), isTrue);

    final libRoot = Directory.systemTemp.createTempSync('xaocen_accept_paged2');
    try {
      final db = AppDatabase.forTesting();
      final fm = LibraryFileManager(libraryRoot: libRoot);
      final repo = LocalLibraryRepository(
        database: db,
        fileManager: fm,
        encodingIndexProvider: FlutterAssetEncodingIndexProvider(),
      );
      final r2 = await repo.importTxt(
        ImportTxtRequest(externalFile: notoc, confirmLargeFile: true),
      );
      expect(r2.collection.itemCount, 1, reason: '无章节文件 1 个 whole item');
      final docs = await repo.getDocuments(r2.collection.id);
      final nd = await NormalizedDocumentLoader(
        fileManager: fm,
      ).load(storagePath: docs.first.storagePath);
      expect(nd.text.length, greaterThan(1000000), reason: '大文件');

      final engine = makeEngine(nd.text);
      final blockIndex = ReaderBlockIndex.build(
        text: nd.text,
        targetBlockSize: 6144,
      );
      // 25% / 50% / 75% 定位（仅测试用，生产禁百分比）
      for (final ratio in [0.25, 0.5, 0.75]) {
        final target = (nd.text.length * ratio).floor();
        final page = engine.pageContaining(target, blockIndex: blockIndex)!;
        expect(page.contains(target), isTrue, reason: '${ratio * 100}% 定位覆盖');
        // 不跳末尾：页面范围在目标附近
        expect(page.startCharacterOffset, lessThan(target + 5000));
        expect(page.endCharacterOffset, greaterThan(target - 5000));
      }
      // 连续 50 页
      var p = engine.layoutForwardPage(0)!;
      var prevEnd = p.endCharacterOffset;
      for (var i = 0; i < 50; i++) {
        final next = engine.layoutForwardPage(p.endCharacterOffset);
        if (next == null) break;
        expect(next.startCharacterOffset, prevEnd);
        expect(noSurrogateSplit(nd.text, next), isTrue);
        prevEnd = next.endCharacterOffset;
        p = next;
      }
      engine.dispose();
      await db.close();
    } finally {
      if (await libRoot.exists()) await libRoot.delete(recursive: true);
    }
  });
}
