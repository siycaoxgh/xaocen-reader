/// 文本编码枚举 —— 检测与解码的编码标识。
///
/// GBK 作为 GB18030 的兼容子集处理（GB18030 超集解码覆盖全部 GBK 文件）；
/// 诊断信息通过 [TxtEncodingResult.reason] 记录候选来源与置信度。
enum TextEncoding {
  utf8,
  utf8Bom,
  utf16Le,
  utf16Be,
  gb18030,
  unknown;

  /// 人类可读名称。
  String get label => switch (this) {
    utf8 => 'UTF-8',
    utf8Bom => 'UTF-8 (BOM)',
    utf16Le => 'UTF-16 LE',
    utf16Be => 'UTF-16 BE',
    gb18030 => 'GB18030/GBK',
    unknown => 'unknown',
  };
}
