import 'dart:typed_data';

import 'gb18030_index_data.dart';

/// 纯 Dart GBK/GB18030 解码器（WHATWG 算法 + 标准索引表）。
///
/// 行为合同（Spike 1 已验证）：
/// - 双字节：pointer = (b1-0x81)*190 + trailIdx（0x40-0x7E 用 -0x40，0x80-0xFE 用 -0x41）；
/// - 四字节：pointer = (b1-0x81)*12600 + (b2-0x30)*1260 + (b3-0x81)*10 + (b4-0x30)；
/// - 0x80 字节 → U+FFFD（跨端一致，不采用 WHATWG 的 U+20AC 特殊映射）；
/// - replace 模式输出 U+FFFD；strict 模式抛 [FormatException]；
/// - 支持分段输入与多字节序列跨输入块边界（增量状态机）。
class Gb18030Decoder {
  Gb18030Decoder(this._index);

  final Gb18030IndexData _index;

  /// 增量解码状态（供分段输入使用）。
  /// 0 = 空闲；1 = 已读 lead（_pendingLead 保存）；2 = 已读 lead+2nd（等第三字节）；
  /// 3 = 已读 lead+2nd+3rd（等第四字节）。
  int _state = 0;
  int _pendingLead = 0;
  int _pendingSecond = 0;
  int _pendingThird = 0;
  bool _finished = false;

  /// 解码完整字节流。等价于新建状态机后一次 [addBytes] + [finish]。
  String decode(Uint8List bytes, {bool allowMalformed = true}) {
    final decoder = Gb18030Decoder(_index);
    final out = decoder.addBytes(bytes, allowMalformed: allowMalformed);
    out.write(decoder.finish(allowMalformed: allowMalformed));
    return out.toString();
  }

  /// 分段输入：追加一段字节，返回本段可输出的文本。
  /// 多字节序列跨块时，跨块部分缓存在内部状态，下一段继续。
  StringBuffer addBytes(Uint8List bytes, {bool allowMalformed = true}) {
    final sb = StringBuffer();
    var i = 0;
    final n = bytes.length;
    while (i < n) {
      if (_state == 3) {
        // 已缓存 lead+2nd+3rd，等第四字节（跨块续接）
        final b4 = bytes[i];
        if (!(b4 >= 0x30 && b4 <= 0x39)) {
          _emitError(
            sb,
            allowMalformed,
            'invalid GB18030 4th byte 0x${b4.toRadixString(16)}',
          );
          _state = 0;
          i++;
          continue;
        }
        final lead = _pendingLead;
        final second = _pendingSecond;
        final third = _pendingThird;
        final pointer =
            (lead - 0x81) * 12600 +
            (second - 0x30) * 1260 +
            (third - 0x81) * 10 +
            (b4 - 0x30);
        final cp = _index.lookupAnchor(pointer);
        if (cp != null) {
          sb.writeCharCode(cp);
        } else {
          _emitError(sb, allowMalformed, 'invalid GB18030 pointer $pointer');
        }
        _state = 0;
        i++;
        continue;
      }
      if (_state == 0) {
        final b = bytes[i];
        if (b <= 0x7F) {
          sb.writeCharCode(b);
          i++;
          continue;
        }
        if (b == 0x80) {
          _emitError(sb, allowMalformed, 'invalid byte 0x80');
          i++;
          continue;
        }
        if (b >= 0x81 && b <= 0xFE) {
          _pendingLead = b;
          _state = 1;
          i++;
          continue;
        }
        // 0xFF 等
        _emitError(sb, allowMalformed, 'invalid byte 0x${b.toRadixString(16)}');
        i++;
        continue;
      }
      if (_state == 1) {
        // 等第二个字节
        if (i >= n) break;
        final b2 = bytes[i];
        if (b2 >= 0x30 && b2 <= 0x39) {
          // 可能是四字节：暂存第二个字节，等第三
          _pendingSecond = b2;
          _state = 2;
          i++;
          continue;
        }
        // 双字节 trail
        final lead = _pendingLead;
        final int pointer;
        if (b2 >= 0x40 && b2 <= 0x7E) {
          pointer = (lead - 0x81) * 190 + (b2 - 0x40);
        } else if (b2 >= 0x80 && b2 <= 0xFE) {
          pointer = (lead - 0x81) * 190 + (b2 - 0x41);
        } else {
          _emitError(
            sb,
            allowMalformed,
            'invalid GBK trail 0x${b2.toRadixString(16)}',
          );
          _state = 0;
          i++;
          continue;
        }
        final cp = _index.lookupEntry(pointer);
        if (cp != null) {
          sb.writeCharCode(cp);
        } else {
          _emitError(sb, allowMalformed, 'invalid GBK pointer $pointer');
        }
        _state = 0;
        i++;
        continue;
      }
      // _state == 2：四字节，等第三字节
      if (i >= n) break;
      final b3 = bytes[i];
      if (!(b3 >= 0x81 && b3 <= 0xFE)) {
        // b3 非法：回退——把 (lead, second) 当非法序列，b3 重新处理
        _emitError(
          sb,
          allowMalformed,
          'invalid GB18030 3rd byte 0x${b3.toRadixString(16)}',
        );
        _state = 0;
        // b3 不消费，下一轮重新处理（i 不前进）
        continue;
      }
      // 等第四字节
      if (i + 1 >= n) {
        // 第四字节在下一块：保持 state=3，已消费到 b3
        _pendingThird = b3;
        _state = 3;
        i++;
        continue;
      }
      final b4 = bytes[i + 1];
      if (!(b4 >= 0x30 && b4 <= 0x39)) {
        _emitError(
          sb,
          allowMalformed,
          'invalid GB18030 4th byte 0x${b4.toRadixString(16)}',
        );
        _state = 0;
        i++;
        continue;
      }
      final lead = _pendingLead;
      final second = _pendingSecond;
      final pointer =
          (lead - 0x81) * 12600 +
          (second - 0x30) * 1260 +
          (b3 - 0x81) * 10 +
          (b4 - 0x30);
      final cp = _index.lookupAnchor(pointer);
      if (cp != null) {
        sb.writeCharCode(cp);
      } else {
        _emitError(sb, allowMalformed, 'invalid GB18030 pointer $pointer');
      }
      _state = 0;
      i += 2;
      continue;
    }
    return sb;
  }

  /// 结束输入：处理尾部截断序列，返回剩余输出。
  /// 调用后解码器不可再使用。
  String finish({bool allowMalformed = true}) {
    if (_finished) {
      throw StateError('decoder already finished');
    }
    _finished = true;
    final sb = StringBuffer();
    if (_state == 3) {
      // 已有 3 字节，缺第 4 字节 → 截断
      _emitError(sb, allowMalformed, 'truncated GB18030 4-byte sequence');
      _state = 0;
    } else if (_state == 2) {
      _emitError(sb, allowMalformed, 'truncated GB18030 4-byte sequence');
      _state = 0;
    } else if (_state == 1) {
      _emitError(sb, allowMalformed, 'truncated GBK sequence');
      _state = 0;
    }
    return sb.toString();
  }

  void _emitError(StringBuffer sb, bool allowMalformed, String message) {
    if (allowMalformed) {
      sb.writeCharCode(0xFFFD);
    } else {
      throw FormatException(message);
    }
  }

  /// 重置解码器状态（可复用实例）。
  void reset() {
    _state = 0;
    _pendingLead = 0;
    _pendingSecond = 0;
    _pendingThird = 0;
    _finished = false;
  }
}
