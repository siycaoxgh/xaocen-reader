import 'legacy_source_capability_scanner.dart';
import 'legacy_static_transform.dart';
import 'legacy_static_text_converter.dart';
import 'xaocen_source_pack.dart';
import 'xaocen_web_book_source_definition.dart';

/// Result for one record when it is evaluated for inclusion in a Source Pack.
final class LegacySourcePackConversionResult {
  const LegacySourcePackConversionResult({
    required this.sourceId,
    required this.sourceName,
    required this.sourceFile,
    required this.compatibility,
    required this.scan,
    required this.legacyFields,
    required this.reasons,
    this.definition,
  });

  final String sourceId;
  final String? sourceName;
  final String sourceFile;
  final LegacyCompatibilityLevel compatibility;
  final LegacySourceScanResult scan;
  final Map<String, Object?> legacyFields;
  final List<String> reasons;
  final XaocenWebBookSourceDefinition? definition;

  XaocenSourcePackEntry toPackEntry() => XaocenSourcePackEntry(
    sourceId: sourceId,
    legacySourceId: scan.sourceId,
    sourceName: sourceName,
    compatibility: compatibility,
    sourceFile: sourceFile,
    legacyFields: legacyFields,
    reasons: reasons,
    definition: definition,
  );

  Map<String, Object?> toJson() => toPackEntry().toJson();
}

/// Converts a batch of legacy records into a non-importing XAOCEN Source Pack.
///
/// The existing strict [LegacyStaticTextConverter] remains available for the
/// original all-or-nothing conversion API. This converter adds a deliberate
/// compatibility layer: optional Legacy fields are retained in [legacyFields]
/// while the supported search/detail/TOC/content core is allowed to produce a
/// runnable partial draft.
final class LegacySourcePackConverter {
  const LegacySourcePackConverter({
    this.scanner = const LegacySourceCapabilityScanner(),
    this.converter = const LegacyStaticTextConverter(),
  });

  final LegacySourceCapabilityScanner scanner;
  final LegacyStaticTextConverter converter;

  LegacySourcePackConversionResult convertRecord(
    Map<String, Object?> record, {
    String sourceFile = '<memory>',
  }) {
    final scan = scanner.scanRecord(record, sourceFile: sourceFile);
    final legacyFields = <String, Object?>{};
    final sanitized = _sanitize(record, legacyFields);

    if (_isUnsupported(scan)) {
      return LegacySourcePackConversionResult(
        sourceId: _stableId(scan.sourceId),
        sourceName: scan.sourceName,
        sourceFile: sourceFile,
        compatibility: LegacyCompatibilityLevel.unsupported,
        scan: scan,
        legacyFields: legacyFields,
        reasons: _mergeReasons(scan.reasons, <String>[
          '当前来源依赖 XAOCEN 尚未执行的能力，未生成可运行 source',
        ]),
      );
    }

    final converted = converter.convertRecord(
      sanitized.record,
      sourceFile: sourceFile,
      requireAutomatic: false,
    );
    if (converted.definition != null) {
      final definition = _reidentify(converted.definition!, scan.sourceId);
      final hasPartialData =
          legacyFields.isNotEmpty ||
          scan.disposition != LegacySourceDisposition.automaticallyConvertible;
      return LegacySourcePackConversionResult(
        sourceId: definition.sourceId,
        sourceName: scan.sourceName,
        sourceFile: sourceFile,
        compatibility: hasPartialData
            ? LegacyCompatibilityLevel.runnablePartial
            : LegacyCompatibilityLevel.full,
        scan: scan,
        legacyFields: legacyFields,
        reasons: hasPartialData
            ? _mergeReasons(scan.reasons, <String>[
                '核心搜索/详情/目录/正文可运行；未映射 Legacy 字段已保留供后续迁移',
              ])
            : const <String>[],
        definition: definition,
      );
    }

    final fallbackReasons = _mergeReasons(converted.reasons, scan.reasons);
    final compatibility = _isNeedsCapability(scan, fallbackReasons)
        ? LegacyCompatibilityLevel.needsCapability
        : LegacyCompatibilityLevel.unsupported;
    return LegacySourcePackConversionResult(
      sourceId: _stableId(scan.sourceId),
      sourceName: scan.sourceName,
      sourceFile: sourceFile,
      compatibility: compatibility,
      scan: scan,
      legacyFields: legacyFields,
      reasons: fallbackReasons.isEmpty
          ? const <String>['核心规则无法映射到当前 XAOCEN CSS contract']
          : fallbackReasons,
    );
  }

  XaocenWebBookSourcePack buildPack(
    Iterable<Map<String, Object?>> records, {
    String sourceFile = '<memory>',
    String packId = 'legacy-static-text-pack-v1',
    String name = 'Legacy Static Text Source Pack',
  }) {
    final entries = <XaocenSourcePackEntry>[];
    final seen = <String>{};
    for (final record in records) {
      final result = convertRecord(record, sourceFile: sourceFile);
      if (seen.add(result.sourceId)) entries.add(result.toPackEntry());
    }
    return XaocenWebBookSourcePack(
      packId: packId,
      name: name,
      generatedAt: DateTime.now().toUtc(),
      sources: List.unmodifiable(entries),
    );
  }

  static bool _isUnsupported(LegacySourceScanResult scan) {
    if (scan.disposition == LegacySourceDisposition.unsupported) return true;
    return scan.capabilities.any(
      (capability) => switch (capability) {
        LegacySourceCapability.js => true,
        LegacySourceCapability.webview => true,
        LegacySourceCapability.image => true,
        LegacySourceCapability.audio => true,
        LegacySourceCapability.invalid => true,
        _ => false,
      },
    );
  }

  static bool _isNeedsCapability(
    LegacySourceScanResult scan,
    List<String> reasons,
  ) {
    if (scan.capabilities.contains(LegacySourceCapability.xpath) ||
        scan.capabilities.contains(LegacySourceCapability.jsonApi) ||
        scan.capabilities.contains(LegacySourceCapability.login)) {
      return true;
    }
    return reasons.any(
      (reason) =>
          reason.contains('selector') ||
          reason.contains('searchUrl') ||
          reason.contains('正文') ||
          reason.contains('核心规则'),
    );
  }

  static List<String> _mergeReasons(
    Iterable<String> first,
    Iterable<String> second,
  ) {
    final result = <String>[];
    for (final reason in <String>[...first, ...second]) {
      if (reason.trim().isNotEmpty && !result.contains(reason)) {
        result.add(reason);
      }
    }
    return result;
  }

  static XaocenWebBookSourceDefinition _reidentify(
    XaocenWebBookSourceDefinition definition,
    String legacySourceId,
  ) {
    final json = Map<String, Object?>.from(definition.toJson());
    json['sourceId'] = _stableId(legacySourceId);
    return XaocenWebBookSourceDefinition.fromJson(json);
  }

  static String _stableId(String value) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return 'legacy-${hash.toRadixString(16)}';
  }

  static _SanitizedLegacyRecord _sanitize(
    Map<String, Object?> original,
    Map<String, Object?> legacyFields,
  ) {
    final result = Map<String, Object?>.from(original);
    const knownRoot = <String>{
      'bookSourceName',
      'bookSourceUrl',
      'bookSourceType',
      'searchUrl',
      'ruleSearch',
      'ruleBookInfo',
      'ruleToc',
      'ruleContent',
    };
    for (final entry in original.entries) {
      if (!knownRoot.contains(entry.key)) {
        legacyFields[entry.key] = entry.value;
      }
    }

    _sanitizeRuleMap(
      result,
      original,
      'ruleSearch',
      const <String>{'bookList', 'name', 'author', 'bookUrl'},
      const <String>{'bookList', 'name', 'bookUrl'},
      legacyFields,
    );
    _sanitizeRuleMap(
      result,
      original,
      'ruleBookInfo',
      const <String>{'name', 'author', 'intro'},
      const <String>{'name'},
      legacyFields,
    );
    _sanitizeRuleMap(
      result,
      original,
      'ruleToc',
      const <String>{'chapterList', 'chapterName', 'chapterUrl'},
      const <String>{'chapterList', 'chapterName', 'chapterUrl'},
      legacyFields,
    );
    _sanitizeRuleMap(
      result,
      original,
      'ruleContent',
      const <String>{'content', 'nextContentUrl'},
      const <String>{'content'},
      legacyFields,
    );

    final header = original['header'];
    if (_hasValue(header)) {
      result.remove('header');
      legacyFields['header'] = header;
    }
    final explore = original['exploreUrl'];
    if (_hasValue(explore)) {
      result.remove('exploreUrl');
      legacyFields['exploreUrl'] = explore;
    }
    return _SanitizedLegacyRecord(result);
  }

  static void _sanitizeRuleMap(
    Map<String, Object?> result,
    Map<String, Object?> original,
    String ruleName,
    Set<String> allowed,
    Set<String> required,
    Map<String, Object?> legacyFields,
  ) {
    final raw = original[ruleName];
    if (raw is! Map) return;
    final sanitized = <String, Object?>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final path = '$ruleName.$key';
      if (!allowed.contains(key)) {
        if (_hasValue(entry.value)) legacyFields[path] = entry.value;
        continue;
      }
      if (!required.contains(key) && !_isStaticField(entry.value)) {
        if (_hasValue(entry.value)) legacyFields[path] = entry.value;
        continue;
      }
      sanitized[key] = entry.value;
    }
    result[ruleName] = sanitized;
  }

  static bool _isStaticField(Object? value) {
    if (value is! String || value.trim().isEmpty) return false;
    final raw = value.trim();
    if (raw.contains('{{') ||
        RegExp(
          r'(?:@get\s*:|@put\s*:|@js\s*:|<js>|javascript\s*:)',
          caseSensitive: false,
        ).hasMatch(raw)) {
      return false;
    }
    try {
      LegacyStaticTransform.parse(raw);
      return true;
    } on LegacyStaticTransformException {
      return false;
    }
  }

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }
}

final class _SanitizedLegacyRecord {
  const _SanitizedLegacyRecord(this.record);

  final Map<String, Object?> record;
}
