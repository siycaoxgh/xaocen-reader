import 'dart:convert';
import 'dart:typed_data';

import 'gb18030_index_data.dart';

/// GB18030 二进制索引 Asset 格式（v1）：
///
/// ```
/// offset  size  field
/// 0       4     magic "GBIX"
/// 4       1     formatVersion (1)
/// 5       1     flags (0)
/// 6       4     entryCount (u32 LE, 23940)
/// 10      n     entries: entryCount × [pointer u16 LE, codepoint u16 LE]
/// 10+n    4     anchorCount (u32 LE, 209)
/// 14+n    m     anchors: anchorCount × [pointer u32 LE, codepoint u32 LE]
/// ```
///
/// 运行时验证：magic、formatVersion、长度与 entryCount/anchorCount 一致性。
/// 加载失败抛出 [Gb18030IndexException]（明确报错，不静默回退）。
class Gb18030IndexException implements Exception {
  const Gb18030IndexException(this.message);
  final String message;

  @override
  String toString() => 'Gb18030IndexException: $message';
}

class Gb18030IndexLoader {
  const Gb18030IndexLoader();

  static const int formatVersion = 1;
  static const List<int> magic = [0x47, 0x42, 0x49, 0x58]; // 'GBIX'

  /// 从二进制字节解析索引数据。
  Gb18030IndexData parse(Uint8List bytes) {
    if (bytes.length < 10) {
      throw const Gb18030IndexException('file too short (<10 bytes)');
    }
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < 4; i++) {
      if (bytes[i] != magic[i]) {
        throw const Gb18030IndexException('bad magic (not GBIX)');
      }
    }
    final version = bytes[4];
    if (version != formatVersion) {
      throw Gb18030IndexException(
        'unsupported formatVersion $version (expected $formatVersion)',
      );
    }
    final entryCount = bd.getUint32(6, Endian.little);
    final entries = Uint16List(entryCount);
    var offset = 10;
    if (bytes.length < offset + entryCount * 4) {
      throw const Gb18030IndexException('truncated entries section');
    }
    for (var i = 0; i < entryCount; i++) {
      final pointer = bd.getUint16(offset, Endian.little);
      final cp = bd.getUint16(offset + 2, Endian.little);
      // 校验：pointer 必须与下标一致（生成器保证顺序）
      if (pointer != i) {
        throw Gb18030IndexException('entry $i pointer mismatch ($pointer)');
      }
      entries[i] = cp;
      offset += 4;
    }
    final anchorCount = bd.getUint32(offset, Endian.little);
    offset += 4;
    if (bytes.length < offset + anchorCount * 8) {
      throw const Gb18030IndexException('truncated anchors section');
    }
    final anchors = Uint32List(anchorCount * 2);
    for (var i = 0; i < anchorCount; i++) {
      anchors[i * 2] = bd.getUint32(offset, Endian.little);
      anchors[i * 2 + 1] = bd.getUint32(offset + 4, Endian.little);
      offset += 8;
    }
    // 长度校验：不允许多余尾部数据
    if (offset != bytes.length) {
      throw Gb18030IndexException(
        'trailing bytes: offset=$offset len=${bytes.length}',
      );
    }
    return Gb18030IndexData(entries: entries, anchors: anchors);
  }

  /// 解析 meta.json（记录来源版本/entryCount/anchorCount/SHA-256）。
  Map<String, dynamic> parseMeta(Uint8List bytes) {
    final s = utf8.decode(bytes);
    final obj = jsonDecode(s);
    if (obj is! Map<String, dynamic>) {
      throw const Gb18030IndexException('meta.json root is not an object');
    }
    return obj;
  }
}
