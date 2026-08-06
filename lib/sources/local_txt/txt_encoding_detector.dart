import 'dart:typed_data';

import '../../domain/local_txt/text_encoding.dart';

/// 编码检测结果。
class TxtEncodingResult {
  const TxtEncodingResult({
    required this.encoding,
    required this.reason,
    this.confidence = 1.0,
    this.bomLength = 0,
    this.usedFallback = false,
    this.errorMessage = '',
  });

  final TextEncoding encoding;

  /// 人类可读的检测原因/证据描述。
  final String reason;

  /// 0..1 置信度。
  final double confidence;

  /// BOM 字节数（无 BOM 为 0）。
  final int bomLength;

  /// 是否使用了回退策略。
  final bool usedFallback;

  /// 可展示错误信息（unknown 或回退时提供）。
  final String errorMessage;
}

/// 编码检测器 —— 检测顺序：
/// 1. BOM（UTF-8 / UTF-16 LE / UTF-16 BE）
/// 2. 严格 UTF-8（无 BOM）
/// 3. GB18030 候选（启发式，仅报告候选）
/// 4. unknown
///
/// 规则：
/// - 不根据文件扩展名决定编码；
/// - UTF-8 失败后不静默回退到系统默认编码；
/// - Windows 与 Android 使用相同规则（纯 Dart 实现，与平台无关）。
class TxtEncodingDetector {
  const TxtEncodingDetector();

  /// 检测编码。只读取 [bytes] 的前 [sampleLimit] 字节进行检测。
  TxtEncodingResult detect(Uint8List bytes, {int sampleLimit = 64 * 1024}) {
    final sample = bytes.length <= sampleLimit
        ? bytes
        : Uint8List.sublistView(bytes, 0, sampleLimit);

    // 1. BOM 检测
    if (sample.length >= 3 &&
        sample[0] == 0xEF &&
        sample[1] == 0xBB &&
        sample[2] == 0xBF) {
      return const TxtEncodingResult(
        encoding: TextEncoding.utf8Bom,
        reason: 'UTF-8 BOM detected',
        bomLength: 3,
      );
    }
    if (sample.length >= 2 && sample[0] == 0xFF && sample[1] == 0xFE) {
      return const TxtEncodingResult(
        encoding: TextEncoding.utf16Le,
        reason: 'UTF-16 LE BOM detected',
        bomLength: 2,
      );
    }
    if (sample.length >= 2 && sample[0] == 0xFE && sample[1] == 0xFF) {
      return const TxtEncodingResult(
        encoding: TextEncoding.utf16Be,
        reason: 'UTF-16 BE BOM detected',
        bomLength: 2,
      );
    }

    // 2. 严格 UTF-8
    if (_isStrictUtf8(sample)) {
      return const TxtEncodingResult(
        encoding: TextEncoding.utf8,
        reason: 'strict UTF-8 validation passed',
      );
    }

    // 3. GB18030 候选（启发式：常见双字节分布 + 合法 trail 比率）
    final gbStats = _gb18030CandidateStats(sample);
    if (gbStats.ratio >= 0.85 && gbStats.validPairs > 0) {
      return TxtEncodingResult(
        encoding: TextEncoding.gb18030,
        reason:
            'GB18030 candidate: ${gbStats.validPairs} valid pairs, '
            'ratio ${gbStats.ratio.toStringAsFixed(3)}',
        confidence: gbStats.ratio,
        usedFallback: false,
      );
    }

    // 4. unknown
    return TxtEncodingResult(
      encoding: TextEncoding.unknown,
      reason:
          'no BOM, not strict UTF-8, GB18030 ratio too low '
          '(${gbStats.ratio.toStringAsFixed(3)})',
      confidence: 0,
      usedFallback: true,
      errorMessage: '无法识别编码（无 BOM、非严格 UTF-8、GB18030 特征不足）',
    );
  }

  /// 严格 UTF-8 校验（完整遍历，验证所有序列合法）。
  /// 采样边界处的截断序列视为合法（数据在窗口外延续）。
  bool _isStrictUtf8(Uint8List bytes) {
    var i = 0;
    final n = bytes.length;
    while (i < n) {
      final b = bytes[i];
      if (b <= 0x7F) {
        i++;
        continue;
      }
      int len;
      int cp;
      if (b >= 0xC2 && b <= 0xDF) {
        len = 2;
        cp = b & 0x1F;
      } else if (b >= 0xE0 && b <= 0xEF) {
        len = 3;
        cp = b & 0x0F;
      } else if (b >= 0xF0 && b <= 0xF4) {
        len = 4;
        cp = b & 0x07;
      } else {
        return false; // 0x80-0xC1, 0xF5-0xFF 非法 lead
      }
      if (i + len > n) {
        // 采样边界截断：序列在窗口外延续，视为合法（不判失败）
        return true;
      }
      for (var j = 1; j < len; j++) {
        final cb = bytes[i + j];
        if ((cb & 0xC0) != 0x80) return false;
        cp = (cp << 6) | (cb & 0x3F);
      }
      // 过度编码 / 超出范围校验
      if (len == 2 && cp < 0x80) return false;
      if (len == 3 && cp < 0x800) return false;
      if (len == 4 && cp < 0x10000) return false;
      if (cp > 0x10FFFF) return false;
      if (cp >= 0xD800 && cp <= 0xDFFF) return false;
      i += len;
    }
    return true;
  }

  /// GB18030 候选统计：lead 0x81-0xFE 后跟合法 trail 的配对比率。
  ({int validPairs, double ratio}) _gb18030CandidateStats(Uint8List bytes) {
    var i = 0;
    final n = bytes.length;
    var pairs = 0;
    var valid = 0;
    while (i < n) {
      final b = bytes[i];
      if (b <= 0x7F) {
        i++;
        continue;
      }
      if (b >= 0x81 && b <= 0xFE) {
        if (i + 1 >= n) break; // 截断，忽略
        final b2 = bytes[i + 1];
        final isValidTrail =
            (b2 >= 0x40 && b2 <= 0xFE && b2 != 0x7F) ||
            (b2 >= 0x30 && b2 <= 0x39);
        pairs++;
        if (isValidTrail) valid++;
        i += 2;
        continue;
      }
      // 0x80 / 0xFF 等：非 GB18030 特征，但记一次无效
      pairs++;
      i++;
    }
    if (pairs == 0) return (validPairs: 0, ratio: 0);
    return (validPairs: valid, ratio: valid / pairs);
  }
}
