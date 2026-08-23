import 'xaocen_source_pack.dart';

/// Capability gaps observed in the legacy sources that are not currently
/// runnable. This is analysis data only; it does not execute any rule.
enum LegacyCapabilityGap {
  tagAction,
  xpath,
  jsonPath,
  regexReplace,
  dynamicUrlTemplate,
  nestedToc,
  headerCookieAuth,
  jsWebView,
  other,
}

extension LegacyCapabilityGapCode on LegacyCapabilityGap {
  String get code => switch (this) {
    LegacyCapabilityGap.tagAction => '@tag.*',
    LegacyCapabilityGap.xpath => 'XPATH',
    LegacyCapabilityGap.jsonPath => 'JSONPATH',
    LegacyCapabilityGap.regexReplace => 'REGEX_REPLACE',
    LegacyCapabilityGap.dynamicUrlTemplate => 'DYNAMIC_URL_TEMPLATE',
    LegacyCapabilityGap.nestedToc => 'NESTED_TOC_OR_SECOND_REQUEST',
    LegacyCapabilityGap.headerCookieAuth => 'HEADER_COOKIE_AUTH',
    LegacyCapabilityGap.jsWebView => 'JS_WEBVIEW',
    LegacyCapabilityGap.other => 'OTHER',
  };
}

final class LegacyCapabilityGapEstimate {
  const LegacyCapabilityGapEstimate({
    required this.gap,
    required this.coverage,
    required this.singleGapCandidates,
  });

  final LegacyCapabilityGap gap;
  final int coverage;
  final int singleGapCandidates;

  Map<String, Object?> toJson() => <String, Object?>{
    'gap': gap.code,
    'coverage': coverage,
    // Conservative estimate: only records with this one known gap are counted.
    'estimatedNewConversions': singleGapCandidates,
    'upperBoundIfOtherGapsAreAlsoResolved': coverage,
  };
}

final class LegacyCapabilityGapClusterReport {
  const LegacyCapabilityGapClusterReport({
    required this.sourceCount,
    required this.categoryCounts,
    required this.combinationCounts,
    required this.estimates,
    required this.scannerOnlyAuthSignals,
  });

  final int sourceCount;
  final Map<LegacyCapabilityGap, int> categoryCounts;
  final Map<String, int> combinationCounts;
  final List<LegacyCapabilityGapEstimate> estimates;
  final int scannerOnlyAuthSignals;

  Map<String, Object?> toJson() => <String, Object?>{
    'sourceCount': sourceCount,
    'categoryCounts': <String, int>{
      for (final entry in categoryCounts.entries) entry.key.code: entry.value,
    },
    'topCombinations': combinationCounts.entries
        .map(
          (entry) => <String, Object?>{
            'combination': entry.key,
            'count': entry.value,
          },
        )
        .toList(growable: false),
    'estimates': estimates.map((item) => item.toJson()).toList(growable: false),
    'scannerOnlyAuthSignals': scannerOnlyAuthSignals,
  };
}

/// Read-only clustering of a previously generated Source Pack.
final class LegacyCapabilityGapAnalyzer {
  const LegacyCapabilityGapAnalyzer();

  LegacyCapabilityGapClusterReport analyze(XaocenWebBookSourcePack pack) {
    // Keep zero-count categories in the report so the capability matrix is
    // explicit (notably JS/WebView is already UNSUPPORTED in this pack).
    final categoryCounts = <LegacyCapabilityGap, int>{
      for (final gap in LegacyCapabilityGap.values) gap: 0,
    };
    final combinations = <String, int>{};
    var sourceCount = 0;
    var scannerOnlyAuthSignals = 0;
    final categorySets = <Set<LegacyCapabilityGap>>[];

    for (final entry in pack.sources) {
      if (entry.compatibility != LegacyCompatibilityLevel.needsCapability) {
        continue;
      }
      sourceCount++;
      final categories = _categories(entry);
      categorySets.add(categories);
      for (final category in categories) {
        categoryCounts.update(
          category,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      final key = (categories.toList()..sort((a, b) => a.code.compareTo(b.code)))
          .map((category) => category.code)
          .join(' + ');
      combinations.update(key, (value) => value + 1, ifAbsent: () => 1);
      if (_hasScannerOnlyAuthSignal(entry) &&
          !_hasFieldAuthSignal(entry)) {
        scannerOnlyAuthSignals++;
      }
    }

    final sortedCombinations = combinations.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final topCombinations = <String, int>{
      for (final entry in sortedCombinations.take(10)) entry.key: entry.value,
    };
    final estimates = <LegacyCapabilityGapEstimate>[];
    for (final gap in LegacyCapabilityGap.values
        .where((gap) => gap != LegacyCapabilityGap.other)) {
      estimates.add(
        LegacyCapabilityGapEstimate(
          gap: gap,
          coverage: categorySets.where((set) => set.contains(gap)).length,
          singleGapCandidates: categorySets
              .where((set) => set.length == 1 && set.contains(gap))
              .length,
        ),
      );
    }
    estimates.sort((a, b) => b.coverage.compareTo(a.coverage));
    return LegacyCapabilityGapClusterReport(
      sourceCount: sourceCount,
      categoryCounts: Map.unmodifiable(categoryCounts),
      combinationCounts: Map.unmodifiable(topCombinations),
      estimates: List.unmodifiable(estimates),
      scannerOnlyAuthSignals: scannerOnlyAuthSignals,
    );
  }

  static Set<LegacyCapabilityGap> _categories(XaocenSourcePackEntry entry) {
    final fields = entry.legacyFields;
    final text = <String>[
      for (final field in fields.entries) '${field.key}=${field.value}',
      ...entry.reasons,
    ].join('\n');
    final categories = <LegacyCapabilityGap>{};
    if (_matches(text, r'@tag\.|@(?:li|td|dl|a|children)\b')) {
      categories.add(LegacyCapabilityGap.tagAction);
    }
    if (_matches(text, r'XPath|//[A-Za-z*]|/@[A-Za-z]|text\s*\(|\[@')) {
      categories.add(LegacyCapabilityGap.xpath);
    }
    if (_matches(text, r'JSONPath|JSON API|jsonpath|application/json|\$\s*[.\[]')) {
      categories.add(LegacyCapabilityGap.jsonPath);
    }
    if (_matches(text, r'replaceRegex|##|\|\||@ownText')) {
      categories.add(LegacyCapabilityGap.regexReplace);
    }
    if (_matches(text, r'动态|\{\{[^}]+\}\}|non GET|@js|<js>|javascript:')) {
      categories.add(LegacyCapabilityGap.dynamicUrlTemplate);
    }
    if (_matches(text, r'嵌套链接|二次请求') ||
        fields.keys.any(
          (key) => _matches(key, r'(?:tocUrl|nextTocUrl|nextContentUrl|nextPage)') &&
              _hasValue(fields[key]),
        )) {
      categories.add(LegacyCapabilityGap.nestedToc);
    }
    if (_hasFieldAuthSignal(entry)) {
      categories.add(LegacyCapabilityGap.headerCookieAuth);
    }
    if (_matches(text, r'JavaScript|脚本|WebView|webview')) {
      categories.add(LegacyCapabilityGap.jsWebView);
    }
    if (categories.isEmpty) categories.add(LegacyCapabilityGap.other);
    return categories;
  }

  static bool _hasFieldAuthSignal(XaocenSourcePackEntry entry) {
    for (final field in entry.legacyFields.entries) {
      final key = field.key.toLowerCase();
      final value = field.value?.toString().trim() ?? '';
      if (value.isEmpty) continue;
      if (key == 'enabledcookiejar') {
        if (value.toLowerCase() == 'true') return true;
        continue;
      }
      if (key == 'header' ||
          key == 'cookie' ||
          key == 'loginurl' ||
          key == 'loginui' ||
          key == 'logincheckjs' ||
          key == 'authorization' ||
          key == 'token' ||
          key.contains('authorization') ||
          key.contains('auth')) {
        return true;
      }
      if (_matches(value, r'authorization|bearer\s+|cookie\s*[:=]|token\s*[:=]')) {
        return true;
      }
    }
    return false;
  }

  static bool _hasScannerOnlyAuthSignal(XaocenSourcePackEntry entry) =>
      entry.reasons.any((reason) => _matches(reason, r'Cookie|认证|登录'));

  static bool _matches(String value, String pattern) =>
      RegExp(pattern, caseSensitive: false).hasMatch(value);

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }
}
