import 'dart:convert';

import 'legacy_source_capability_scanner.dart';
import 'legacy_static_transform.dart';
import 'web_book_rule_engine.dart';
import 'xaocen_web_book_source_definition.dart';

/// Outcome of converting one legacy record.  A skipped record was never
/// eligible according to the read-only capability scanner; a manual result is
/// an eligible candidate whose rule semantics cannot be mapped without loss.
enum LegacyStaticTextConversionOutcome { converted, manualReview, skipped }

extension LegacyStaticTextConversionOutcomeCode
    on LegacyStaticTextConversionOutcome {
  String get code => switch (this) {
    LegacyStaticTextConversionOutcome.converted => 'CONVERTED',
    LegacyStaticTextConversionOutcome.manualReview => 'MANUAL_REVIEW',
    LegacyStaticTextConversionOutcome.skipped => 'SKIPPED',
  };
}

final class LegacyStaticTextConversionResult {
  const LegacyStaticTextConversionResult({
    required this.outcome,
    required this.sourceId,
    required this.sourceName,
    required this.scanDisposition,
    required this.reasons,
    this.definition,
  });

  final LegacyStaticTextConversionOutcome outcome;
  final String sourceId;
  final String? sourceName;
  final LegacySourceDisposition scanDisposition;
  final XaocenWebBookSourceDefinition? definition;
  final List<String> reasons;

  Map<String, Object?> toJson() => <String, Object?>{
    'outcome': outcome.code,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'scanDisposition': scanDisposition.code,
    'reasons': reasons,
    if (definition != null) 'draft': definition!.toJson(),
  };
}

/// Conservative adapter from one Legado/阅读 static-text record to a
/// XAOCEN-owned `xaocen.webBook` draft.
///
/// This class intentionally does not register or persist a source.  It only
/// emits a validated draft when all mapped semantics are representable by the
/// existing CSS rule contract.
final class LegacyStaticTextConverter {
  const LegacyStaticTextConverter({
    this.scanner = const LegacySourceCapabilityScanner(),
  });

  final LegacySourceCapabilityScanner scanner;

  LegacyStaticTextConversionResult convertRecord(
    Map<String, Object?> record, {
    String sourceFile = '<memory>',
    bool requireAutomatic = true,
  }) {
    final scan = scanner.scanRecord(record, sourceFile: sourceFile);
    if (requireAutomatic &&
        scan.disposition != LegacySourceDisposition.automaticallyConvertible) {
      return LegacyStaticTextConversionResult(
        outcome: LegacyStaticTextConversionOutcome.skipped,
        sourceId: scan.sourceId,
        sourceName: scan.sourceName,
        scanDisposition: scan.disposition,
        reasons: <String>[
          '扫描器标记为 ${scan.disposition.code}，本转换器只处理 AUTOMATICALLY_CONVERTIBLE',
          ...scan.reasons,
        ],
      );
    }

    try {
      final definition = _convertEligible(record, scan);
      return LegacyStaticTextConversionResult(
        outcome: LegacyStaticTextConversionOutcome.converted,
        sourceId: scan.sourceId,
        sourceName: scan.sourceName,
        scanDisposition: scan.disposition,
        reasons: const <String>[],
        definition: definition,
      );
    } on _ConversionException catch (error) {
      return LegacyStaticTextConversionResult(
        outcome: LegacyStaticTextConversionOutcome.manualReview,
        sourceId: scan.sourceId,
        sourceName: scan.sourceName,
        scanDisposition: scan.disposition,
        reasons: <String>[error.message],
      );
    } on Object catch (error) {
      return LegacyStaticTextConversionResult(
        outcome: LegacyStaticTextConversionOutcome.manualReview,
        sourceId: scan.sourceId,
        sourceName: scan.sourceName,
        scanDisposition: scan.disposition,
        reasons: <String>['生成 XAOCEN 草稿失败：$error'],
      );
    }
  }

  XaocenWebBookSourceDefinition _convertEligible(
    Map<String, Object?> record,
    LegacySourceScanResult scan,
  ) {
    final endpoint = _parseEndpoint(record);
    final search = _asMap(record['ruleSearch'], 'ruleSearch');
    final detail = _asMap(record['ruleBookInfo'], 'ruleBookInfo');
    final toc = _asMap(record['ruleToc'], 'ruleToc');
    final content = _asMap(record['ruleContent'], 'ruleContent');

    _checkOnlyMapped(search, const <String>{
      'bookList',
      'name',
      'author',
      'bookUrl',
    }, 'ruleSearch');
    _checkOnlyMapped(detail, const <String>{
      'name',
      'author',
      'intro',
    }, 'ruleBookInfo');
    _checkOnlyMapped(toc, const <String>{
      'chapterList',
      'chapterName',
      'chapterUrl',
    }, 'ruleToc');
    _checkOnlyMapped(content, const <String>{
      'content',
      'nextContentUrl',
    }, 'ruleContent');

    final rootHeader = _text(record['header']);
    if (rootHeader != null) {
      throw _ConversionException(
        'Legacy header 未纳入当前 XAOCEN draft contract，需人工确认',
      );
    }
    if (_hasValue(record['exploreUrl'])) {
      throw _ConversionException('Legacy exploreUrl/发现规则没有对应 XAOCEN 字段，需人工确认');
    }

    final searchItemSelector = _selector(
      search['bookList'],
      'ruleSearch.bookList',
    );
    final searchTitle = _field(search['name'], 'ruleSearch.name').toSelector();
    final searchAuthor = _optionalField(
      search['author'],
      'ruleSearch.author',
    )?.toSelector();
    final bookLink = _field(search['bookUrl'], 'ruleSearch.bookUrl');
    if (bookLink.attribute != 'href' || bookLink.fallbackSelectors.isNotEmpty) {
      throw _ConversionException('ruleSearch.bookUrl 必须明确使用 @href，当前规则无法无损映射');
    }

    final detailTitle = _field(
      detail['name'],
      'ruleBookInfo.name',
    ).toSelector();
    final detailAuthor = _optionalField(
      detail['author'],
      'ruleBookInfo.author',
    )?.toSelector();
    final detailDescription = _optionalField(
      detail['intro'],
      'ruleBookInfo.intro',
    )?.toSelector();

    final tocEntrySelector = _selector(
      toc['chapterList'],
      'ruleToc.chapterList',
    );
    final tocTitle = _field(
      toc['chapterName'],
      'ruleToc.chapterName',
    ).toSelector();
    final chapterLink = _field(toc['chapterUrl'], 'ruleToc.chapterUrl');
    if (chapterLink.attribute != 'href' ||
        chapterLink.selector != null ||
        chapterLink.fallbackSelectors.isNotEmpty ||
        chapterLink.removePrefix != null) {
      throw _ConversionException(
        'ruleToc.chapterUrl 必须是当前目录节点的 @href，嵌套链接需人工确认',
      );
    }

    final body = _field(content['content'], 'ruleContent.content');
    if (body.selector == null ||
        body.fallbackSelectors.isNotEmpty ||
        body.attribute != null ||
        body.removePrefix != null) {
      throw _ConversionException('ruleContent.content 必须是 CSS 正文节点（不支持属性值正文）');
    }

    String? nextPageSelector;
    final next = _optionalField(
      content['nextContentUrl'],
      'ruleContent.nextContentUrl',
    );
    if (next != null) {
      if (next.attribute != 'href' ||
          next.selector == null ||
          next.fallbackSelectors.isNotEmpty ||
          next.removePrefix != null) {
        throw _ConversionException(
          'ruleContent.nextContentUrl 不是可验证的 CSS @href 链接',
        );
      }
      nextPageSelector = next.selector;
    }

    final searchEndpoint = _parseSearchEndpoint(endpoint, record['searchUrl']);
    final searchQueryParameter = _searchQueryParameter(record['searchUrl']);
    final name = _requiredText(record['bookSourceName'], 'bookSourceName');
    if (name.length > 200) {
      throw _ConversionException('bookSourceName 超过 XAOCEN 名称长度限制');
    }
    final sourceId = 'legacy-${_hash('${endpoint.toString()}|$name')}';
    final ruleSetId = '$sourceId-v1';
    final rules = WebBookCssRuleSet(
      id: ruleSetId,
      searchItemSelector: searchItemSelector,
      searchTitle: searchTitle,
      searchAuthor: searchAuthor,
      searchLinkSelector: bookLink.selector,
      detailSelector: 'body',
      detailTitle: detailTitle,
      detailAuthor: detailAuthor,
      detailDescription: detailDescription,
      tocEntrySelector: tocEntrySelector,
      tocTitle: tocTitle,
      chapterBodySelector: body.selector!,
      chapterNextPageSelector: nextPageSelector,
    );
    try {
      return XaocenWebBookSourceDefinition(
        sourceId: sourceId,
        name: name,
        endpoint: endpoint,
        searchEndpoint: searchEndpoint,
        searchQueryParameter: searchQueryParameter,
        bookKey: 'legacy:${endpoint.host}',
        ruleVersion: 1,
        rules: rules,
      );
    } on FormatException catch (error) {
      throw _ConversionException('XAOCEN CSS/URI 校验失败：${error.message}');
    }
  }

  static Map<String, Object?> _asMap(Object? value, String path) {
    if (value is! Map) {
      throw _ConversionException('$path 必须是对象');
    }
    return value.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  static void _checkOnlyMapped(
    Map<String, Object?> map,
    Set<String> allowed,
    String path,
  ) {
    for (final entry in map.entries) {
      if (!allowed.contains(entry.key) && _hasValue(entry.value)) {
        throw _ConversionException('$path.${entry.key} 没有 XAOCEN 等价字段，无法无损转换');
      }
    }
  }

  static String _selector(Object? value, String path) {
    final field = _field(value, path);
    if (field.selector == null ||
        field.fallbackSelectors.isNotEmpty ||
        field.attribute != null ||
        field.removePrefix != null) {
      throw _ConversionException('$path 必须是纯 CSS selector');
    }
    return field.selector!;
  }

  static _LegacyField _field(Object? value, String path) {
    final raw = _requiredText(value, path);
    if (raw.contains('{{') ||
        RegExp(
          r'(?:@get\s*:|@put\s*:|@js\s*:|<js>|javascript\s*:)',
          caseSensitive: false,
        ).hasMatch(raw)) {
      throw _ConversionException('$path 包含动态动作/模板/脚本语法，需人工确认');
    }
    try {
      final mapped = LegacyStaticTransform.parse(raw);
      return _LegacyField(
        selector: mapped.selector,
        fallbackSelectors: mapped.fallbackSelectors,
        attribute: mapped.attribute,
        removePrefix: mapped.removePrefix,
      );
    } on LegacyStaticTransformException catch (error) {
      throw _ConversionException('$path ${error.message}');
    }
  }

  static _LegacyField? _optionalField(Object? value, String path) {
    if (!_hasValue(value)) return null;
    return _field(value, path);
  }

  static Uri _parseEndpoint(Map<String, Object?> record) {
    final raw = _requiredText(record['bookSourceUrl'], 'bookSourceUrl');
    final endpoint = Uri.tryParse(raw);
    if (endpoint == null ||
        (endpoint.scheme != 'http' && endpoint.scheme != 'https') ||
        endpoint.host.isEmpty ||
        endpoint.fragment.isNotEmpty) {
      throw _ConversionException('bookSourceUrl 不是安全的 HTTP(S) endpoint');
    }
    return endpoint;
  }

  static Uri? _parseSearchEndpoint(Uri endpoint, Object? value) {
    if (!_hasValue(value)) return null;
    final raw = _requiredText(value, 'searchUrl');
    if (raw.contains(',')) {
      throw _ConversionException('searchUrl 包含 Legacy 请求对象/POST 描述');
    }
    if (raw.contains('{{') && !raw.contains('{{key}}')) {
      throw _ConversionException('searchUrl 使用动态模板，无法安全转换');
    }
    if (raw.contains('{{key}}') &&
        !RegExp(r'[A-Za-z][A-Za-z0-9_-]{0,63}=\{\{key\}\}').hasMatch(raw)) {
      throw _ConversionException('searchUrl 的 {{key}} 不在可识别查询参数中');
    }
    final template = raw.replaceAll('{{key}}', 'xaocen-search');
    final resolved = endpoint.resolve(template);
    if (resolved.host != endpoint.host || resolved.scheme != endpoint.scheme) {
      throw _ConversionException('searchUrl 跨域，XAOCEN source 不允许自动转换');
    }
    final parameter = _searchQueryParameter(value);
    final query = <String, String>{...resolved.queryParameters};
    query.remove(parameter);
    return Uri(
      scheme: resolved.scheme,
      userInfo: resolved.userInfo,
      host: resolved.host,
      port: resolved.hasPort ? resolved.port : null,
      path: resolved.path,
      queryParameters: query.isEmpty ? null : query,
      fragment: resolved.fragment.isEmpty ? null : resolved.fragment,
    );
  }

  static String _searchQueryParameter(Object? value) {
    if (!_hasValue(value)) return 'q';
    final raw = _stringify(value);
    final match = RegExp(
      r'([A-Za-z][A-Za-z0-9_-]{0,63})=\{\{key\}\}',
    ).firstMatch(raw);
    return match?.group(1) ?? 'q';
  }

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }

  static String _requiredText(Object? value, String path) {
    final text = _text(value);
    if (text == null) throw _ConversionException('$path 必须是非空字符串');
    return text;
  }

  static String? _text(Object? value) {
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  static String _stringify(Object? value) {
    if (value is String) return value;
    try {
      return jsonEncode(value);
    } on Object {
      return value.toString();
    }
  }

  static String _hash(String value) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }
}

final class _LegacyField {
  const _LegacyField({
    required this.selector,
    this.fallbackSelectors = const <String>[],
    this.attribute,
    this.removePrefix,
  });

  final String? selector;
  final List<String> fallbackSelectors;
  final String? attribute;
  final String? removePrefix;

  WebBookFieldSelector toSelector() => selector == null
      ? (attribute == null
            ? const WebBookFieldSelector.text()
            : WebBookFieldSelector.fromAttribute(attribute!))
      : WebBookFieldSelector(
          selector: selector,
          fallbackSelectors: fallbackSelectors,
          attribute: attribute,
          removePrefix: removePrefix,
        );
}

final class _ConversionException implements Exception {
  const _ConversionException(this.message);

  final String message;

  @override
  String toString() => message;
}
