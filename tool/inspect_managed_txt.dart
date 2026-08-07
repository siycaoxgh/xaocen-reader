/// inspect_managed_txt —— 托管 TXT collection 只读诊断工具（纯 Dart CLI）。
///
/// 用法：
///   dart run tool/inspect_managed_txt.dart --dir <managed collection 目录>
///   dart run tool/inspect_managed_txt.dart --db <sqlite路径> --collection <collectionId>
///
/// 输出（不输出正文）：
///   collectionId / sourceHash(manifest+实际) / normalizedHash(manifest+Drift+实际) /
///   normalized 字节长度 / UTF-16 字符长度 / index 长度 / detectedEncoding /
///   normalizationVersion / import 状态 / 各字段一致性。
///
/// 仅只读：不修改任何文件或数据库。
// ignore_for_file: avoid_print, unintended_html_in_doc_comment, deprecated_member_use
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  String? dir;
  String? dbPath;
  String? collectionId;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--dir' && i + 1 < args.length) {
      dir = args[i + 1];
    } else if (args[i] == '--db' && i + 1 < args.length) {
      dbPath = args[i + 1];
    } else if (args[i] == '--collection' && i + 1 < args.length) {
      collectionId = args[i + 1];
    }
  }
  if (dir == null && (dbPath == null || collectionId == null)) {
    stderr.writeln(
      '用法: dart run tool/inspect_managed_txt.dart '
      '--dir <managed目录> | --db <sqlite> --collection <collectionId>',
    );
    exitCode = 2;
    return;
  }
  final inspector = ManagedTxtInspector();
  try {
    if (dir != null) {
      inspector.inspectDir(Directory(dir));
    } else {
      inspector.inspectDb(dbPath!, collectionId!);
    }
  } catch (e) {
    stderr.writeln('inspect 失败: $e');
    exitCode = 1;
  }
}

/// 只读诊断器。
class ManagedTxtInspector {
  /// 检查单个 managed collection 目录。
  void inspectDir(Directory dir) {
    final hash = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    print('=== managed collection 目录诊断 ===');
    print('collectionId      : local-txt:$hash');
    print('目录              : ${dir.path}');
    _inspectContent(dir, hash);
  }

  /// 从 DB 定位并检查 collection。
  void inspectDb(String dbPath, String collectionId) {
    final hash = collectionId.replaceFirst('local-txt:', '');
    print('=== DB + managed collection 诊断 ===');
    print('collectionId      : $collectionId');
    print('DB                : $dbPath');
    final db = sqlite3.open(dbPath);
    try {
      // Drift 列名快照（snake_case）
      final srcRows = db.select('SELECT * FROM content_sources WHERE id = ?', [
        'local-txt-source:$hash',
      ]);
      final srcCols = db.select('PRAGMA table_info(content_sources)');
      final srcColNames = srcCols.map((r) => r['name'] as String).toList();
      for (final row in srcRows) {
        for (final name in srcColNames) {
          print('source.$name       : ${row[name]}');
        }
      }
      if (srcRows.isEmpty) {
        print('content_sources    : 无记录');
      }

      final colRows = db.select(
        'SELECT * FROM content_collections WHERE id = ?',
        [collectionId],
      );
      final colCols = db.select('PRAGMA table_info(content_collections)');
      final colNames = colCols.map((r) => r['name'] as String).toList();
      for (final row in colRows) {
        for (final name in colNames) {
          print('collection.$name    : ${row[name]}');
        }
      }
      if (colRows.isEmpty) {
        print('content_collections: 无记录');
      }

      final docRows = db.select(
        'SELECT DISTINCT content_hash, normalization_version '
        'FROM content_documents WHERE storage_path LIKE ?',
        ['%$hash%'],
      );
      for (final row in docRows) {
        print('document.content_hash (Drift): ${row['content_hash']}');
        print(
          'document.normalization_version: ${row['normalization_version']}',
        );
      }
      if (docRows.isEmpty) {
        print('content_documents  : 无记录');
      }

      final recRows = db.select(
        'SELECT state, started_at, completed_at, error_code, error_message '
        'FROM import_records WHERE source_hash = ? ORDER BY started_at',
        [hash],
      );
      print('import_records     : ${recRows.length} 条');
      for (final row in recRows) {
        print(
          '  state=${row['state']} started=${row['started_at']} '
          'completed=${row['completed_at']} err=${row['error_code']} '
          'msg=${row['error_message']}',
        );
      }
    } finally {
      db.dispose();
    }

    // 定位 managed 目录（DB 记录 managed_source_path）
    final managedSourcePath = _findManagedSourcePath(dbPath, hash);
    if (managedSourcePath == null) {
      print('managed 目录       : 未找到（DB 无 managed_source_path）');
      return;
    }
    // managedSourcePath 存的是 `library\local_txt\<hash>\source.txt`（相对 support）
    // 工具无法确知 support 根，输出相对路径提示
    print('managed source rel : $managedSourcePath');
    final parent = File(managedSourcePath).parent;
    print('managed 目录(推测): ${parent.path}');
    if (parent.existsSync()) {
      _inspectContent(parent, hash);
    } else {
      print('managed 目录不存在 : ${parent.path}');
    }
  }

  String? _findManagedSourcePath(String dbPath, String hash) {
    final db = sqlite3.open(dbPath);
    try {
      final rows = db.select(
        'SELECT managed_source_path FROM content_sources WHERE content_hash = ?',
        [hash],
      );
      if (rows.isEmpty) return null;
      return rows.first['managed_source_path'] as String?;
    } finally {
      db.dispose();
    }
  }

  /// 检查 content 目录内的派生文件（不输出正文）。
  void _inspectContent(Directory dir, String hash) {
    final sourceFile = File(p.join(dir.path, 'source.txt'));
    final normFile = File(p.join(dir.path, 'normalized.txt'));
    final indexFile = File(p.join(dir.path, 'index.json'));
    final manifestFile = File(p.join(dir.path, 'manifest.json'));

    print('--- 派生文件 ---');
    String? sourceHash;
    if (sourceFile.existsSync()) {
      sourceHash = sha256.convert(sourceFile.readAsBytesSync()).toString();
      print('source.txt 实际SHA : $sourceHash');
      print('source.txt 字节数  : ${sourceFile.lengthSync()}');
    } else {
      print('source.txt         : 缺失');
    }

    String? normHash;
    int? normBytes;
    int? normUtf16;
    if (normFile.existsSync()) {
      final bytes = normFile.readAsBytesSync();
      normHash = sha256.convert(bytes).toString();
      normBytes = bytes.length;
      normUtf16 = utf8.decode(bytes).length;
      print('normalized.txt 实际SHA : $normHash');
      print('normalized.txt 字节数  : $normBytes');
      print('normalized.txt UTF-16  : $normUtf16');
    } else {
      print('normalized.txt     : 缺失');
    }

    Map<String, dynamic>? manifest;
    if (manifestFile.existsSync()) {
      try {
        manifest =
            jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      } catch (_) {
        print('manifest.json      : 解析失败');
      }
    } else {
      print('manifest.json      : 缺失');
    }
    if (manifest != null) {
      print('manifest.sourceHash        : ${manifest['sourceHash']}');
      print('manifest.normalizedHash    : ${manifest['normalizedHash']}');
      print(
        'manifest.normalizedBytes   : ${manifest['normalizedUtf8ByteLength']}',
      );
      print(
        'manifest.normCharLen       : ${manifest['normalizedCharacterLength']}',
      );
      print('manifest.detectedEncoding  : ${manifest['detectedEncoding']}');
      print('manifest.normalizationVer  : ${manifest['normalizationVersion']}');
      print('manifest.parserVersion     : ${manifest['parserVersion']}');
      print('manifest.indexFormatVersion: ${manifest['indexFormatVersion']}');
      print('manifest.importedAt        : ${manifest['importedAt']}');
    }

    Map<String, dynamic>? index;
    if (indexFile.existsSync()) {
      try {
        index =
            jsonDecode(indexFile.readAsStringSync()) as Map<String, dynamic>;
      } catch (_) {
        print('index.json         : 解析失败');
      }
    } else {
      print('index.json         : 缺失');
    }
    if (index != null) {
      print('index.normCharLen  : ${index['normalizedCharacterLength']}');
      print('index.chapterCount : ${index['chapterCount']}');
      print('index.volumeCount  : ${index['volumeCount']}');
    }

    // ---- 一致性 ----
    print('--- 一致性 ---');
    if (sourceHash != null) {
      print('sourceHash==目录名  : ${sourceHash == hash}');
    }
    if (manifest != null && sourceHash != null) {
      print(
        'manifest.sourceHash==实际: '
        '${manifest['sourceHash'] == sourceHash}',
      );
    }
    if (manifest != null && normHash != null) {
      print(
        'manifest.normalizedHash==实际: '
        '${manifest['normalizedHash'] == normHash}',
      );
    }
    if (manifest != null && normBytes != null) {
      print(
        'manifest.normBytes==实际    : '
        '${manifest['normalizedUtf8ByteLength'] == normBytes}',
      );
    }
    if (manifest != null && normUtf16 != null) {
      print(
        'manifest.normCharLen==实际  : '
        '${manifest['normalizedCharacterLength'] == normUtf16}',
      );
    }
    if (index != null && normUtf16 != null) {
      print(
        'index.normCharLen==实际     : '
        '${index['normalizedCharacterLength'] == normUtf16}',
      );
    }

    // ---- 从 source.txt 重跑 M1 管线对比（regenerated）----
    print('--- regenerated 对比 ---');
    if (sourceFile.existsSync() && manifest != null) {
      try {
        final regen = _regenerate(sourceFile, manifest);
        print('regenerated norm SHA  : ${regen.sha256}');
        print('regenerated UTF-16    : ${regen.utf16Len}');
        print('regenerated 字节数    : ${regen.utf8Bytes}');
        final sameAsExisting = normHash != null && regen.sha256 == normHash;
        print('与现有 normalized 相同: $sameAsExisting');
        if (!sameAsExisting && normHash != null) {
          final diff = _firstDiffOffset(sourceFile, normFile);
          print('首个不同字节 offset  : ${diff.byteOffset}');
          print('首个不同 UTF-16 off  : ${diff.utf16Offset}');
        }
      } catch (e) {
        print('regenerated 失败     : $e');
      }
    } else {
      print('（缺 source.txt 或 manifest，跳过）');
    }
  }

  /// 从 managed source.txt 重跑 M1 管线（解码→规范化），返回规范化产物。
  /// 复用 TxtImportService 会引入 Flutter 依赖（encoding provider），
  /// 这里仅对 UTF-8 文件做轻量重放（diagnostic 用途）；
  /// GB18030 文件需走正式管线（见 integration_test 版）。
  _RegenResult _regenerate(File sourceFile, Map<String, dynamic> manifest) {
    final bytes = sourceFile.readAsBytesSync();
    final encoding = manifest['detectedEncoding']?.toString() ?? 'utf8';
    String raw;
    switch (encoding) {
      case 'utf8':
      case 'utf8Bom':
        raw = utf8.decode(bytes);
        break;
      case 'utf16Le':
        raw = _decodeUtf16(bytes, Endian.little);
        break;
      case 'utf16Be':
        raw = _decodeUtf16(bytes, Endian.big);
        break;
      case 'gb18030':
        throw StateError('GB18030 需正式管线（integration_test 版 inspect）');
      default:
        throw StateError('未知编码: $encoding');
    }
    // 去 BOM + CRLF/CR→LF（与 M1 TxtNormalizer 一致）
    var text = raw;
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    final sb = StringBuffer();
    var i = 0;
    final n = text.length;
    while (i < n) {
      final c = text.codeUnitAt(i);
      if (c == 0x0D) {
        if (i + 1 < n && text.codeUnitAt(i + 1) == 0x0A) {
          sb.writeCharCode(0x0A);
          i += 2;
        } else {
          sb.writeCharCode(0x0A);
          i++;
        }
        continue;
      }
      if (c == 0x0A) {
        sb.writeCharCode(0x0A);
        i++;
        continue;
      }
      sb.writeCharCode(c);
      i++;
    }
    final normalized = sb.toString();
    final out = utf8.encode(normalized);
    return _RegenResult(
      sha256: sha256.convert(out).toString(),
      utf16Len: normalized.length,
      utf8Bytes: out.length,
    );
  }

  static String _decodeUtf16(List<int> bytes, Endian endian) {
    final buf = Uint8List.fromList(bytes);
    final n = buf.length ~/ 2;
    final units = <int>[];
    final bd = ByteData.sublistView(buf);
    for (var i = 0; i < n; i++) {
      units.add(bd.getUint16(i * 2, endian));
    }
    var start = 0;
    if (units.isNotEmpty && units[0] == 0xFEFF) start = 1;
    return String.fromCharCodes(units.sublist(start));
  }

  _DiffOffset _firstDiffOffset(File sourceFile, File normFile) {
    // 用重放对比现有 normalized 的字节
    final bytes = sourceFile.readAsBytesSync();
    final raw = utf8.decode(bytes);
    var text = raw;
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    final sb = StringBuffer();
    var i = 0;
    final n = text.length;
    while (i < n) {
      final c = text.codeUnitAt(i);
      if (c == 0x0D) {
        if (i + 1 < n && text.codeUnitAt(i + 1) == 0x0A) {
          sb.writeCharCode(0x0A);
          i += 2;
        } else {
          sb.writeCharCode(0x0A);
          i++;
        }
        continue;
      }
      if (c == 0x0A) {
        sb.writeCharCode(0x0A);
        i++;
        continue;
      }
      sb.writeCharCode(c);
      i++;
    }
    final regenBytes = utf8.encode(sb.toString());
    final existing = normFile.readAsBytesSync();
    final limit = regenBytes.length < existing.length
        ? regenBytes.length
        : existing.length;
    var byteOffset = -1;
    for (var j = 0; j < limit; j++) {
      if (regenBytes[j] != existing[j]) {
        byteOffset = j;
        break;
      }
    }
    if (byteOffset == -1 && regenBytes.length != existing.length) {
      byteOffset = limit;
    }
    // UTF-16 offset（解码后首个不同字符）
    var utf16Offset = -1;
    if (byteOffset >= 0) {
      final regenStr = utf8.decode(regenBytes, allowMalformed: true);
      final existStr = utf8.decode(existing, allowMalformed: true);
      final rl = regenStr.length;
      final el = existStr.length;
      final ul = rl < el ? rl : el;
      for (var k = 0; k < ul; k++) {
        if (regenStr.codeUnitAt(k) != existStr.codeUnitAt(k)) {
          utf16Offset = k;
          break;
        }
      }
      if (utf16Offset == -1 && rl != el) utf16Offset = ul;
    }
    return _DiffOffset(byteOffset: byteOffset, utf16Offset: utf16Offset);
  }
}

class _RegenResult {
  const _RegenResult({
    required this.sha256,
    required this.utf16Len,
    required this.utf8Bytes,
  });
  final String sha256;
  final int utf16Len;
  final int utf8Bytes;
}

class _DiffOffset {
  const _DiffOffset({required this.byteOffset, required this.utf16Offset});
  final int byteOffset;
  final int utf16Offset;
}
