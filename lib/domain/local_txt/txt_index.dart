import 'dart:convert';

import 'text_encoding.dart';
import 'toc_entry.dart';

/// 本地 TXT 索引 —— 标准化管线的结构化结果（可序列化缓存）。
///
/// 缓存中**不保存完整正文**（正文不入索引缓存）。
class TxtIndex {
  const TxtIndex({
    required this.indexFormatVersion,
    required this.parserVersion,
    required this.normalizationVersion,
    required this.sourceFileName,
    required this.sourceSize,
    required this.sourceContentHash,
    required this.encoding,
    required this.normalizedCharacterLength,
    required this.volumeCount,
    required this.chapterCount,
    required this.tocEntries,
    required this.generatedAt,
  });

  factory TxtIndex.fromJson(Map<String, dynamic> json) {
    return TxtIndex(
      indexFormatVersion: json['indexFormatVersion'] as int,
      parserVersion: json['parserVersion'] as String,
      normalizationVersion: json['normalizationVersion'] as String,
      sourceFileName: json['sourceFileName'] as String,
      sourceSize: json['sourceSize'] as int,
      sourceContentHash: json['sourceContentHash'] as String,
      encoding: TextEncoding.values.byName(json['encoding'] as String),
      normalizedCharacterLength: json['normalizedCharacterLength'] as int,
      volumeCount: json['volumeCount'] as int,
      chapterCount: json['chapterCount'] as int,
      tocEntries: (json['tocEntries'] as List)
          .map((e) => TocEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'indexFormatVersion': indexFormatVersion,
    'parserVersion': parserVersion,
    'normalizationVersion': normalizationVersion,
    'sourceFileName': sourceFileName,
    'sourceSize': sourceSize,
    'sourceContentHash': sourceContentHash,
    'encoding': encoding.name,
    'normalizedCharacterLength': normalizedCharacterLength,
    'volumeCount': volumeCount,
    'chapterCount': chapterCount,
    'tocEntries': tocEntries.map((e) => e.toJson()).toList(),
    'generatedAt': generatedAt.toIso8601String(),
  };

  String encode() => jsonEncode(toJson());

  static TxtIndex decode(String s) =>
      TxtIndex.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// 索引缓存格式版本（缓存结构演进时递增）。
  final int indexFormatVersion;

  /// 扫描器/解析器版本（章节规则变化时递增）。
  final String parserVersion;

  /// 规范化版本（规范化规则变化时递增）。
  final String normalizationVersion;

  final String sourceFileName;
  final int sourceSize;

  /// 源文件内容 SHA-256（hex）。
  final String sourceContentHash;

  final TextEncoding encoding;

  /// 规范化后的字符长度（UTF-16 码元数）。
  final int normalizedCharacterLength;

  /// 卷数量（不计入章节总数）。
  final int volumeCount;

  /// 章节数量（不含卷）。
  final int chapterCount;

  final List<TocEntry> tocEntries;

  final DateTime generatedAt;
}
