import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

import '../../domain/remote/remote_source.dart';
import 'web_book_rule_engine.dart';
import 'web_book_runtime.dart';

/// The versioned, XAOCEN-owned JSON description of one static WebBook source.
///
/// This is deliberately a data/validation boundary. It describes CSS
/// selectors only; it does not register a source, fetch a page, execute
/// JavaScript or persist credentials. A later registry can decide where a
/// validated definition is allowed to come from.
@immutable
final class XaocenWebBookSourceDefinition {
  XaocenWebBookSourceDefinition({
    required this.sourceId,
    required this.name,
    required this.endpoint,
    required this.searchEndpoint,
    this.searchQueryParameter = 'q',
    required this.bookKey,
    required this.ruleVersion,
    required WebBookCssRuleSet rules,
  }) : rules = rules,
       ruleSetId = '${sourceId.trim()}-v$ruleVersion' {
    _validateSourceId(sourceId);
    _validateName(name);
    _validateBookKey(bookKey);
    _validateQueryParameter(searchQueryParameter, 'searchQueryParameter');
    _validateHttpUri(endpoint, 'endpoint');
    if (searchEndpoint != null) {
      _validateHttpUri(searchEndpoint!, 'searchEndpoint');
      final source = WebBookSource(
        id: RemoteSourceId(sourceId),
        endpoint: endpoint,
        searchEndpoint: searchEndpoint,
        bookKey: bookKey,
        ruleSetId: ruleSetId,
      );
      if (!source.accepts(searchEndpoint!)) {
        throw const FormatException('searchEndpoint 必须属于 endpoint 的同一来源域名');
      }
    }
    if (ruleVersion <= 0) {
      throw FormatException('ruleVersion 必须为正整数: $ruleVersion');
    }
    _validateRuleSet(rules);
  }

  static const schema = 'xaocen.webBook';
  static const schemaVersion = 1;

  final String sourceId;
  final String name;
  final Uri endpoint;
  final Uri? searchEndpoint;
  final String searchQueryParameter;
  final String bookKey;
  final int ruleVersion;
  final String ruleSetId;
  final WebBookCssRuleSet rules;

  /// Converts this definition to the existing transport-free source model.
  WebBookSource toSource() => WebBookSource(
    id: RemoteSourceId(sourceId),
    endpoint: endpoint,
    searchEndpoint: searchEndpoint,
    searchQueryParameter: searchQueryParameter,
    bookKey: bookKey,
    ruleSetId: ruleSetId,
  );

  /// Converts this definition to the existing runtime rule container.
  WebBookExtractionRules toExtractionRules() => WebBookExtractionRules(
    id: ruleSetId,
    version: ruleVersion,
    cssRuleSet: rules,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': schema,
    'version': schemaVersion,
    'sourceId': sourceId,
    'name': name,
    'endpoint': endpoint.toString(),
    'searchEndpoint': searchEndpoint?.toString(),
    'searchRequest': <String, Object?>{'queryParameter': searchQueryParameter},
    'bookKey': bookKey,
    'ruleVersion': ruleVersion,
    'rules': _encodeRules(rules),
  };

  String toJsonString() => jsonEncode(toJson());

  static XaocenWebBookSourceDefinition fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('XAOCEN WebBook JSON 根节点必须是对象');
    }
    return fromJson(
      decoded.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }

  static XaocenWebBookSourceDefinition fromJson(Map<String, Object?> json) {
    _checkKeys(json, const <String>{
      'schema',
      'version',
      'sourceId',
      'name',
      'endpoint',
      'searchEndpoint',
      'searchRequest',
      'bookKey',
      'ruleVersion',
      'rules',
    }, 'source');
    if (json['schema'] != schema) {
      throw FormatException('不支持的 XAOCEN schema: ${json['schema']}');
    }
    final version = _requiredInt(json, 'version');
    if (version != schemaVersion) {
      throw FormatException('不支持的 XAOCEN schema version: $version');
    }

    final sourceId = _requiredString(json, 'sourceId');
    final name = _requiredString(json, 'name');
    final endpoint = _parseHttpUri(
      _requiredString(json, 'endpoint'),
      'endpoint',
    );
    final searchValue = json['searchEndpoint'];
    final searchEndpoint = searchValue == null
        ? null
        : _parseHttpUri(
            _stringValue(searchValue, 'searchEndpoint'),
            'searchEndpoint',
          );
    final searchRequestValue = json['searchRequest'];
    var searchQueryParameter = 'q';
    if (searchRequestValue != null) {
      if (searchRequestValue is! Map) {
        throw const FormatException('searchRequest 必须是对象或 null');
      }
      final searchRequest = searchRequestValue.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      );
      _checkKeys(searchRequest, const <String>{
        'queryParameter',
      }, 'searchRequest');
      searchQueryParameter = _requiredString(searchRequest, 'queryParameter');
    }
    final bookKey = _requiredString(json, 'bookKey');
    final ruleVersion = _requiredInt(json, 'ruleVersion');
    final rules = _decodeRules(
      _requiredMap(json, 'rules'),
      ruleSetId: '$sourceId-v$ruleVersion',
    );

    return XaocenWebBookSourceDefinition(
      sourceId: sourceId,
      name: name,
      endpoint: endpoint,
      searchEndpoint: searchEndpoint,
      searchQueryParameter: searchQueryParameter,
      bookKey: bookKey,
      ruleVersion: ruleVersion,
      rules: rules,
    );
  }

  static bool canDecode(Object? value) {
    try {
      if (value is String) {
        fromJsonString(value);
      } else if (value is Map) {
        fromJson(
          value.map<String, Object?>(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
      } else {
        return false;
      }
      return true;
    } on Object {
      return false;
    }
  }

  static Map<String, Object?> _encodeRules(WebBookCssRuleSet rules) =>
      <String, Object?>{
        'search': <String, Object?>{
          'itemSelector': rules.searchItemSelector,
          'title': _encodeField(rules.searchTitle),
          'author': _encodeOptionalField(rules.searchAuthor),
          'linkSelector': rules.searchLinkSelector,
          'keyAttribute': rules.searchBookKeyAttribute,
        },
        'detail': <String, Object?>{
          'selector': rules.detailSelector,
          'title': _encodeField(rules.detailTitle),
          'author': _encodeOptionalField(rules.detailAuthor),
          'description': _encodeOptionalField(rules.detailDescription),
          'keyAttribute': rules.detailBookKeyAttribute,
        },
        'toc': <String, Object?>{
          'entrySelector': rules.tocEntrySelector,
          'title': _encodeField(rules.tocTitle),
          'keyAttribute': rules.chapterKeyAttribute,
          'hrefAttribute': rules.hrefAttribute,
        },
        'chapter': <String, Object?>{
          'bodySelector': rules.chapterBodySelector,
          'nextPageSelector': rules.chapterNextPageSelector,
        },
      };

  static WebBookCssRuleSet _decodeRules(
    Map<String, Object?> json, {
    required String ruleSetId,
  }) {
    _checkKeys(json, const <String>{
      'search',
      'detail',
      'toc',
      'chapter',
    }, 'rules');
    final search = _requiredMap(json, 'search');
    final detail = _requiredMap(json, 'detail');
    final toc = _requiredMap(json, 'toc');
    final chapter = _requiredMap(json, 'chapter');
    _checkKeys(search, const <String>{
      'itemSelector',
      'title',
      'author',
      'linkSelector',
      'keyAttribute',
    }, 'rules.search');
    _checkKeys(detail, const <String>{
      'selector',
      'title',
      'author',
      'description',
      'keyAttribute',
    }, 'rules.detail');
    _checkKeys(toc, const <String>{
      'entrySelector',
      'title',
      'keyAttribute',
      'hrefAttribute',
    }, 'rules.toc');
    _checkKeys(chapter, const <String>{
      'bodySelector',
      'nextPageSelector',
    }, 'rules.chapter');

    final searchItemSelector = _requiredString(search, 'itemSelector');
    final detailSelector = _requiredString(detail, 'selector');
    final tocEntrySelector = _requiredString(toc, 'entrySelector');
    final chapterBodySelector = _requiredString(chapter, 'bodySelector');
    _validateSelector(searchItemSelector, 'rules.search.itemSelector');
    _validateSelector(detailSelector, 'rules.detail.selector');
    _validateSelector(tocEntrySelector, 'rules.toc.entrySelector');
    _validateSelector(chapterBodySelector, 'rules.chapter.bodySelector');
    final nextPageSelector = _optionalString(chapter, 'nextPageSelector');
    if (nextPageSelector != null) {
      _validateSelector(nextPageSelector, 'rules.chapter.nextPageSelector');
    }

    final linkSelector = _optionalString(search, 'linkSelector');
    if (linkSelector != null) {
      _validateSelector(linkSelector, 'rules.search.linkSelector');
    }
    final searchTitle = _requiredField(search, 'title', 'rules.search.title');
    final detailTitle = _requiredField(detail, 'title', 'rules.detail.title');
    final tocTitle =
        _optionalField(toc, 'title', 'rules.toc.title') ??
        const WebBookFieldSelector.text();
    return WebBookCssRuleSet(
      id: ruleSetId,
      searchItemSelector: searchItemSelector,
      searchTitle: searchTitle,
      searchAuthor: _optionalField(search, 'author', 'rules.search.author'),
      searchLinkSelector: linkSelector,
      searchBookKeyAttribute: _optionalAttribute(
        search,
        'keyAttribute',
        'rules.search.keyAttribute',
      ),
      detailSelector: detailSelector,
      detailTitle: detailTitle,
      detailAuthor: _optionalField(detail, 'author', 'rules.detail.author'),
      detailDescription: _optionalField(
        detail,
        'description',
        'rules.detail.description',
      ),
      detailBookKeyAttribute: _optionalAttribute(
        detail,
        'keyAttribute',
        'rules.detail.keyAttribute',
      ),
      tocEntrySelector: tocEntrySelector,
      tocTitle: tocTitle,
      chapterKeyAttribute: _optionalAttribute(
        toc,
        'keyAttribute',
        'rules.toc.keyAttribute',
      ),
      hrefAttribute:
          _optionalAttribute(toc, 'hrefAttribute', 'rules.toc.hrefAttribute') ??
          'href',
      chapterBodySelector: chapterBodySelector,
      chapterNextPageSelector: nextPageSelector,
    );
  }

  static Map<String, Object?> _encodeField(WebBookFieldSelector field) =>
      <String, Object?>{
        if (field.selector != null) 'selector': field.selector,
        if (field.fallbackSelectors.isNotEmpty)
          'fallbackSelectors': field.fallbackSelectors,
        if (field.attribute != null) 'attribute': field.attribute,
        if (field.removePrefix != null) 'removePrefix': field.removePrefix,
      };

  static Object? _encodeOptionalField(WebBookFieldSelector? field) =>
      field == null ? null : _encodeField(field);

  static WebBookFieldSelector _requiredField(
    Map<String, Object?> parent,
    String key,
    String path,
  ) {
    final value = parent[key];
    if (value is! Map) throw FormatException('$path 必须是对象');
    return _decodeField(
      value.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      ),
      path,
    );
  }

  static WebBookFieldSelector? _optionalField(
    Map<String, Object?> parent,
    String key,
    String path,
  ) {
    final value = parent[key];
    if (value == null) return null;
    if (value is! Map) throw FormatException('$path 必须是对象或 null');
    return _decodeField(
      value.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      ),
      path,
    );
  }

  static WebBookFieldSelector _decodeField(
    Map<String, Object?> json,
    String path,
  ) {
    _checkKeys(json, const <String>{
      'selector',
      'fallbackSelectors',
      'attribute',
      'removePrefix',
    }, path);
    final selector = _optionalString(json, 'selector');
    final fallbackValue = json['fallbackSelectors'];
    final fallbackSelectors = <String>[];
    if (fallbackValue != null) {
      if (fallbackValue is! List ||
          fallbackValue.any((item) => item is! String)) {
        throw FormatException('$path.fallbackSelectors 必须是字符串数组');
      }
      for (final item in fallbackValue.cast<String>()) {
        final value = item.trim();
        if (value.isEmpty) {
          throw FormatException('$path.fallbackSelectors 不能包含空 selector');
        }
        _validateSelector(value, '$path.fallbackSelectors');
        if (value != selector && !fallbackSelectors.contains(value)) {
          fallbackSelectors.add(value);
        }
      }
    }
    final attribute = _optionalString(json, 'attribute');
    final removePrefix = _optionalString(json, 'removePrefix');
    if (selector != null) _validateSelector(selector, '$path.selector');
    if (selector == null && fallbackSelectors.isNotEmpty) {
      throw FormatException('$path.fallbackSelectors 需要主 selector');
    }
    if (attribute != null) _validateAttribute(attribute, '$path.attribute');
    return WebBookFieldSelector(
      selector: selector,
      fallbackSelectors: fallbackSelectors,
      attribute: attribute,
      removePrefix: removePrefix,
    );
  }

  static String? _optionalAttribute(
    Map<String, Object?> json,
    String key,
    String path,
  ) {
    final value = _optionalString(json, key);
    if (value != null) _validateAttribute(value, path);
    return value;
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key 必须是非空字符串');
    }
    return value.trim();
  }

  static String? _optionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('$key 必须是字符串或 null');
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _stringValue(Object? value, String key) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key 必须是非空字符串');
    }
    return value.trim();
  }

  static int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) throw FormatException('$key 必须是整数');
    return value;
  }

  static Map<String, Object?> _requiredMap(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is! Map) throw FormatException('$key 必须是对象');
    return value.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  static Uri _parseHttpUri(String value, String path) {
    final uri = Uri.tryParse(value);
    if (uri == null) throw FormatException('$path 不是合法 URI');
    _validateHttpUri(uri, path);
    return uri;
  }

  static void _validateHttpUri(Uri uri, String path) {
    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      throw FormatException('$path 只允许带主机的 http/https URI');
    }
  }

  static void _validateSourceId(String value) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(value.trim())) {
      throw FormatException('sourceId 只能包含字母、数字、点、下划线和连字符');
    }
  }

  static void _validateName(String value) {
    if (value.trim().isEmpty || value.length > 200) {
      throw const FormatException('name 必须为 1-200 个字符');
    }
  }

  static void _validateBookKey(String value) {
    if (value.trim().isEmpty ||
        value.length > 512 ||
        value.contains('\u0000')) {
      throw const FormatException('bookKey 必须为稳定的非空标识');
    }
  }

  static void _validateQueryParameter(String value, String path) {
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9_-]{0,63}$').hasMatch(value.trim())) {
      throw FormatException('$path 不是合法查询参数名');
    }
  }

  static void _validateAttribute(String value, String path) {
    if (!RegExp(r'^[A-Za-z_:][A-Za-z0-9_.:-]*$').hasMatch(value)) {
      throw FormatException('$path 不是合法 HTML 属性名');
    }
  }

  static void _validateSelector(String value, String path) {
    if (value.contains('//') || value.toLowerCase().contains('javascript:')) {
      throw FormatException('$path 只允许 CSS selector，不允许 XPath/JavaScript');
    }
    try {
      html_parser.parse('<div></div>').querySelector(value);
    } on Object catch (error) {
      throw FormatException('$path 不是合法 CSS selector: $error');
    }
  }

  static void _validateRuleSet(WebBookCssRuleSet rules) {
    _validateSelector(rules.searchItemSelector, 'rules.search.itemSelector');
    _validateSelector(rules.detailSelector, 'rules.detail.selector');
    _validateSelector(rules.tocEntrySelector, 'rules.toc.entrySelector');
    _validateSelector(rules.chapterBodySelector, 'rules.chapter.bodySelector');
    if (rules.searchLinkSelector != null) {
      _validateSelector(rules.searchLinkSelector!, 'rules.search.linkSelector');
    }
    if (rules.chapterNextPageSelector != null) {
      _validateSelector(
        rules.chapterNextPageSelector!,
        'rules.chapter.nextPageSelector',
      );
    }
    _validateField(rules.searchTitle, 'rules.search.title');
    _validateField(rules.searchAuthor, 'rules.search.author');
    _validateField(rules.detailTitle, 'rules.detail.title');
    _validateField(rules.detailAuthor, 'rules.detail.author');
    _validateField(rules.detailDescription, 'rules.detail.description');
    _validateField(rules.tocTitle, 'rules.toc.title');
  }

  static void _validateField(WebBookFieldSelector? field, String path) {
    if (field == null) return;
    if (field.selector == null && field.fallbackSelectors.isNotEmpty) {
      throw FormatException('$path 需要主 selector 才能使用 fallbackSelectors');
    }
    for (final selector in field.fallbackSelectors) {
      _validateSelector(selector, '$path.fallbackSelectors');
    }
  }

  static void _checkKeys(
    Map<String, Object?> json,
    Set<String> allowed,
    String path,
  ) {
    for (final key in json.keys) {
      if (!allowed.contains(key)) throw FormatException('$path 包含未知字段: $key');
    }
  }
}

/// Convenience codec for the XAOCEN-owned definition. It intentionally
/// returns a definition rather than a bare [RemoteSource], so its display
/// name and CSS rule mapping cannot be lost at the import boundary.
final class XaocenWebBookSourceDefinitionCodec {
  const XaocenWebBookSourceDefinitionCodec();

  XaocenWebBookSourceDefinition decode(Map<String, Object?> json) =>
      XaocenWebBookSourceDefinition.fromJson(json);

  Map<String, Object?> encode(XaocenWebBookSourceDefinition definition) =>
      definition.toJson();

  bool canDecode(Object? value) =>
      XaocenWebBookSourceDefinition.canDecode(value);
}
