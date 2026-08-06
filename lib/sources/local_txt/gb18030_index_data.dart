import 'dart:typed_data';

/// GB18030 索引数据 —— 从二进制 Asset 加载后的内存表示。
class Gb18030IndexData {
  const Gb18030IndexData({required this.entries, required this.anchors});

  /// 双字节映射：pointer -> code point（23940 项）。
  /// 使用 Uint16List 而非 Map 以获得 O(1) 随机访问与低内存。
  final Uint16List entries;

  /// 四字节锚点表：(pointer, codePoint) 209 项。
  final Uint32List anchors;

  int get entryCount => entries.length;
  int get anchorCount => anchors.length ~/ 2;

  /// 查询双字节映射。
  int? lookupEntry(int pointer) {
    if (pointer < 0 || pointer >= entries.length) return null;
    final cp = entries[pointer];
    return cp == 0 ? null : cp;
  }

  /// 四字节锚点查询：取最后一个 pointer <= p 的锚点，cp = anchorCp + (p - anchorP)。
  int? lookupAnchor(int pointer) {
    int? lastP;
    int? lastCp;
    for (var i = 0; i < anchors.length; i += 2) {
      final anchorP = anchors[i];
      final anchorCp = anchors[i + 1];
      if (anchorP <= pointer) {
        lastP = anchorP;
        lastCp = anchorCp;
      } else {
        break;
      }
    }
    if (lastP == null || lastCp == null) return null;
    return lastCp + (pointer - lastP);
  }
}
