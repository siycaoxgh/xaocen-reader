import 'dart:convert';
import 'dart:io';

/// Capabilities observed in a legacy Legado/阅读 source definition.
///
/// This scanner is deliberately read-only.  It never interprets a rule,
/// executes JavaScript, opens a WebView, or performs a network request.
enum LegacySourceCapability {
  staticText,
  jsonApi,
  xpath,
  js,
  webview,
  login,
  image,
  audio,
  invalid,
}

extension LegacySourceCapabilityCode on LegacySourceCapability {
  String get code => switch (this) {
    LegacySourceCapability.staticText => 'STATIC_TEXT',
    LegacySourceCapability.jsonApi => 'JSON_API',
    LegacySourceCapability.xpath => 'XPATH',
    LegacySourceCapability.js => 'JS',
    LegacySourceCapability.webview => 'WEBVIEW',
    LegacySourceCapability.login => 'LOGIN',
    LegacySourceCapability.image => 'IMAGE',
    LegacySourceCapability.audio => 'AUDIO',
    LegacySourceCapability.invalid => 'INVALID',
  };
}

/// What the future static-text converter may do with a source.
enum LegacySourceDisposition {
  automaticallyConvertible,
  manualReview,
  unsupported,
}

extension LegacySourceDispositionCode on LegacySourceDisposition {
  String get code => switch (this) {
    LegacySourceDisposition.automaticallyConvertible =>
      'AUTOMATICALLY_CONVERTIBLE',
    LegacySourceDisposition.manualReview => 'MANUAL_REVIEW',
    LegacySourceDisposition.unsupported => 'UNSUPPORTED',
  };
}

/// A deterministic, explainable result for one legacy source record.
final class LegacySourceScanResult {
  const LegacySourceScanResult({
    required this.sourceId,
    required this.sourceName,
    required this.sourceFile,
    required this.isLegadoLike,
    required this.capabilities,
    required this.disposition,
    required this.presentFields,
    required this.ruleFields,
    required this.reasons,
    this.formatVersion,
  });

  final String sourceId;
  final String? sourceName;
  final String sourceFile;
  final bool isLegadoLike;
  final String? formatVersion;
  final Set<LegacySourceCapability> capabilities;
  final LegacySourceDisposition disposition;
  final List<String> presentFields;
  final List<String> ruleFields;
  final List<String> reasons;

  Map<String, Object?> toJson() => <String, Object?>{
    'sourceId': sourceId,
    'sourceName': sourceName,
    'sourceFile': sourceFile,
    'legadoLike': isLegadoLike,
    'formatVersion': formatVersion,
    'capabilities': capabilities.map((item) => item.code).toList(),
    'disposition': disposition.code,
    'presentFields': presentFields,
    'ruleFields': ruleFields,
    'reasons': reasons,
  };
}

/// Aggregated results for a directory scan.
final class LegacySourceScanReport {
  const LegacySourceScanReport({
    required this.filesScanned,
    required this.recordsRead,
    required this.uniqueRecords,
    required this.duplicateRecords,
    required this.results,
  });

  final int filesScanned;
  final int recordsRead;
  final int uniqueRecords;
  final int duplicateRecords;
  final List<LegacySourceScanResult> results;

  Map<String, int> get capabilityCounts {
    final counts = <String, int>{};
    for (final result in results) {
      for (final capability in result.capabilities) {
        counts.update(capability.code, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get dispositionCounts {
    final counts = <String, int>{};
    for (final result in results) {
      counts.update(
        result.disposition.code,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return Map.unmodifiable(counts);
  }

  Map<String, Object?> toJson({bool includeResults = true}) =>
      <String, Object?>{
        'filesScanned': filesScanned,
        'recordsRead': recordsRead,
        'uniqueRecords': uniqueRecords,
        'duplicateRecords': duplicateRecords,
        'capabilityCounts': capabilityCounts,
        'dispositionCounts': dispositionCounts,
        if (includeResults)
          'results': results.map((item) => item.toJson()).toList(),
      };
}

/// Read-only capability detector for Legado/阅读 JSON exports.
///
/// The scanner intentionally reports capability evidence instead of trying to
/// convert it.  This keeps legacy data outside the production source registry
/// until a later, separately reviewed converter is available.
final class LegacySourceCapabilityScanner {
  const LegacySourceCapabilityScanner();

  LegacySourceScanResult scanRecord(
    Map<String, Object?> record, {
    String sourceFile = '<memory>',
    int? recordIndex,
  }) {
    final values = <String, String>{};
    _collectValues(record, '', values);
    final presentFields = record.keys.map((key) => key.toString()).toList()
      ..sort();
    final ruleFields = values.keys.where((key) => _isRulePath(key)).toList()
      ..sort();

    final name = _text(record['bookSourceName']);
    final url = _text(record['bookSourceUrl']);
    final sourceId = _sourceId(record, sourceFile, recordIndex);
    final capabilities = <LegacySourceCapability>{};
    final reasons = <String>[];
    final coreRules = const <String>[
      'ruleSearch',
      'ruleBookInfo',
      'ruleToc',
      'ruleContent',
    ];
    final hasAnyRule = coreRules.any((key) => _hasValue(record[key]));
    final legadoLike =
        url != null &&
        name != null &&
        (hasAnyRule || record.containsKey('bookSourceType'));

    if (url == null || name == null || !legadoLike) {
      capabilities.add(LegacySourceCapability.invalid);
      reasons.add('缺少 bookSourceName/bookSourceUrl 或不是可识别的 Legado 记录');
    }

    final allText = values.values.join('\n');
    final ruleText = values.entries
        .where((entry) => _isRulePath(entry.key))
        .map((entry) => entry.value)
        .join('\n');
    final type = _text(record['bookSourceType']);

    final hasJs =
        _hasExplicitValue(record, const <String>[
          'jsLib',
          'webJs',
          'loginCheckJs',
          'coverDecodeJs',
        ]) ||
        RegExp(
          r'(?:@js\s*:|<js>|javascript\s*:|\beval\s*\(|formatJs|java\.)',
          caseSensitive: false,
        ).hasMatch(allText);
    if (hasJs) {
      capabilities.add(LegacySourceCapability.js);
      reasons.add('检测到 JavaScript/脚本动作，扫描器不会执行脚本');
    }

    final hasWebView =
        _hasExplicitValue(record, const <String>[
          'webView',
          'webview',
          'useWebView',
          'loadWithWebView',
        ]) ||
        RegExp(r'web[- ]?view', caseSensitive: false).hasMatch(allText);
    if (hasWebView) {
      capabilities.add(LegacySourceCapability.webview);
      reasons.add('依赖 WebView/动态页面，当前静态运行时不支持');
    }

    final hasXPath = RegExp(
      r'(?:^|\s)(?://[a-z*][\w:-]*(?:\[|/)|text\s*\(\)|/@[\w:-]+|\[@[\w:-]+)',
      caseSensitive: false,
    ).hasMatch(ruleText);
    if (hasXPath) {
      capabilities.add(LegacySourceCapability.xpath);
      reasons.add('检测到 XPath 选择器，XAOCEN 规则当前使用 CSS selector');
    }

    final hasJsonApi = RegExp(
      r'(?:jsonpath|application/json|\$\s*(?:\.|\[)|(?:^|[\s,{])(?:method|requestmethod|type)\s*[:=]\s*post\b|[/_.-]api(?:[/_.-]|$))',
      caseSensitive: false,
    ).hasMatch(allText);
    if (hasJsonApi) {
      capabilities.add(LegacySourceCapability.jsonApi);
      reasons.add('检测到 JSONPath/JSON API 或 POST 请求，需要独立 API 规则能力');
    }

    final login =
        _hasExplicitValue(record, const <String>[
          'loginUrl',
          'loginUi',
          'loginCheckJs',
          'cookie',
          'authorization',
        ]) ||
        record['enabledCookieJar'] == true ||
        RegExp(
          r'(?:authorization|bearer\s+|cookie\s*[:=]|token\s*[:=])',
          caseSensitive: false,
        ).hasMatch(allText);
    if (login) {
      capabilities.add(LegacySourceCapability.login);
      reasons.add('包含登录、Cookie 或认证状态，不能自动导入凭据');
    }

    final contentText = _stringify(record['ruleContent']);
    final image =
        type == '2' ||
        _hasExplicitValue(record, const <String>['imageStyle', 'imageRule']) ||
        RegExp(
          r'(?:imageStyle|gallery|img\s*[@:]?src|图片章节)',
          caseSensitive: false,
        ).hasMatch(contentText);
    if (image) {
      capabilities.add(LegacySourceCapability.image);
      reasons.add('检测到图片章节/图集能力，不当作纯文本 WebBook 转换');
    }

    final audio =
        type == '1' ||
        RegExp(
          r'(?:audio|music|listen|tts|\.(?:mp3|m4a|aac|flac)(?:[?&]|$))',
          caseSensitive: false,
        ).hasMatch(allText);
    if (audio) {
      capabilities.add(LegacySourceCapability.audio);
      reasons.add('检测到音频/有声内容，不属于文本 ReaderContent');
    }

    final hasStaticContent =
        _hasValue(record['ruleContent']) &&
        !RegExp(
          r'(?:@js\s*:|<js>|javascript\s*:|webview)',
          caseSensitive: false,
        ).hasMatch(_stringify(record['ruleContent']));
    if (hasStaticContent && type != '1' && type != '2') {
      capabilities.add(LegacySourceCapability.staticText);
    }

    if (!capabilities.contains(LegacySourceCapability.invalid) &&
        capabilities.isEmpty) {
      reasons.add('未发现可识别的正文规则能力');
    }

    final disposition = _disposition(
      capabilities,
      record: record,
      hasStaticContent: hasStaticContent,
      reasons: reasons,
    );
    return LegacySourceScanResult(
      sourceId: sourceId,
      sourceName: name,
      sourceFile: sourceFile,
      isLegadoLike: legadoLike,
      formatVersion: _firstText(record, const <String>[
        'version',
        'ruleVersion',
        'sourceVersion',
      ]),
      capabilities: Set.unmodifiable(capabilities),
      disposition: disposition,
      presentFields: List.unmodifiable(presentFields),
      ruleFields: List.unmodifiable(ruleFields),
      reasons: List.unmodifiable(reasons),
    );
  }

  LegacySourceScanResult scanJson(
    String json, {
    String sourceFile = '<memory>',
  }) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) {
        return scanRecord(
          Map<String, Object?>.fromEntries(
            decoded.entries.map(
              (entry) => MapEntry(entry.key.toString(), entry.value),
            ),
          ),
          sourceFile: sourceFile,
        );
      }
      return _invalidResult(sourceFile, '根 JSON 不是对象记录');
    } on FormatException catch (error) {
      return _invalidResult(sourceFile, 'JSON 解析失败：${error.message}');
    }
  }

  Future<LegacySourceScanReport> scanDirectory(Directory directory) async {
    final files = await directory
        .list(followLinks: false)
        .where(
          (entity) =>
              entity is File && entity.path.toLowerCase().endsWith('.json'),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));

    final results = <LegacySourceScanResult>[];
    final seen = <String>{};
    var recordsRead = 0;
    var duplicateRecords = 0;
    for (final file in files) {
      dynamic decoded;
      try {
        decoded = jsonDecode(await file.readAsString());
      } on Object catch (error) {
        final invalid = _invalidResult(file.path, 'JSON 解析失败：$error');
        if (seen.add(invalid.sourceId)) results.add(invalid);
        continue;
      }
      if (decoded is! List) {
        final invalid = _invalidResult(file.path, '根 JSON 不是数组');
        if (seen.add(invalid.sourceId)) results.add(invalid);
        continue;
      }
      for (var index = 0; index < decoded.length; index++) {
        recordsRead++;
        final value = decoded[index];
        if (value is! Map) {
          final invalid = _invalidResult('${file.path}#$index', '数组元素不是对象');
          if (seen.add(invalid.sourceId)) results.add(invalid);
          continue;
        }
        final record = Map<String, Object?>.fromEntries(
          value.entries.map(
            (entry) => MapEntry(entry.key.toString(), entry.value),
          ),
        );
        final result = scanRecord(
          record,
          sourceFile: file.path,
          recordIndex: index,
        );
        if (!seen.add(result.sourceId)) {
          duplicateRecords++;
          continue;
        }
        results.add(result);
      }
    }
    return LegacySourceScanReport(
      filesScanned: files.length,
      recordsRead: recordsRead,
      uniqueRecords: results.length,
      duplicateRecords: duplicateRecords,
      results: List.unmodifiable(results),
    );
  }

  LegacySourceDisposition _disposition(
    Set<LegacySourceCapability> capabilities, {
    required Map<String, Object?> record,
    required bool hasStaticContent,
    required List<String> reasons,
  }) {
    const unsupported = <LegacySourceCapability>{
      LegacySourceCapability.invalid,
      LegacySourceCapability.js,
      LegacySourceCapability.webview,
      LegacySourceCapability.audio,
      LegacySourceCapability.image,
    };
    if (capabilities.any(unsupported.contains)) {
      return LegacySourceDisposition.unsupported;
    }
    final hasManualCapability =
        capabilities.contains(LegacySourceCapability.jsonApi) ||
        capabilities.contains(LegacySourceCapability.xpath) ||
        capabilities.contains(LegacySourceCapability.login);
    final completeRules = const <String>[
      'ruleSearch',
      'ruleBookInfo',
      'ruleToc',
      'ruleContent',
    ].every((key) => _hasValue(record[key]));
    final search = _stringify(record['searchUrl']);
    final staticGet =
        search.isEmpty ||
        (!RegExp(
              r'\b(?:post|put|patch)\b',
              caseSensitive: false,
            ).hasMatch(search) &&
            !search.contains('@js:'));
    if (hasStaticContent &&
        !hasManualCapability &&
        completeRules &&
        staticGet) {
      return LegacySourceDisposition.automaticallyConvertible;
    }
    if (!hasStaticContent) {
      reasons.add('缺少可确认的静态正文规则');
    }
    if (!completeRules) {
      reasons.add('搜索、详情、目录、正文规则不完整');
    }
    if (!staticGet) {
      reasons.add('搜索请求包含非 GET/动态动作');
    }
    return LegacySourceDisposition.manualReview;
  }

  LegacySourceScanResult _invalidResult(String sourceFile, String reason) =>
      LegacySourceScanResult(
        sourceId: 'invalid:$sourceFile',
        sourceName: null,
        sourceFile: sourceFile,
        isLegadoLike: false,
        capabilities: const <LegacySourceCapability>{
          LegacySourceCapability.invalid,
        },
        disposition: LegacySourceDisposition.unsupported,
        presentFields: const <String>[],
        ruleFields: const <String>[],
        reasons: <String>[reason],
      );

  static String _sourceId(
    Map<String, Object?> record,
    String sourceFile,
    int? recordIndex,
  ) {
    final url = _text(record['bookSourceUrl']);
    final name = _text(record['bookSourceName']);
    if (url != null && name != null) {
      // The same URL/name may legitimately occur with different rules.  Use
      // a stable content fingerprint so subset exports deduplicate exact
      // copies without collapsing distinct source definitions.
      return 'legado:${url.trim()}|$name|${_fingerprint(record)}';
    }
    return 'invalid:$sourceFile#${recordIndex ?? 0}';
  }

  static String _fingerprint(Object? value) {
    final canonical = _canonicalJson(value);
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in canonical.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }

  static String _canonicalJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      final parts = <String>[];
      for (final key in keys) {
        parts.add('${jsonEncode(key)}:${_canonicalJson(value[key])}');
      }
      return '{${parts.join(',')}}';
    }
    if (value is Iterable) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }

  static String? _firstText(Map<String, Object?> record, List<String> keys) {
    for (final key in keys) {
      final value = _text(record[key]);
      if (value != null) return value;
    }
    return null;
  }

  static bool _hasExplicitValue(
    Map<String, Object?> record,
    List<String> keys,
  ) => keys.any((key) => _hasValue(record[key]));

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }

  static String? _text(Object? value) {
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }
    if (value is num || value is bool) return value.toString();
    return null;
  }

  static String _stringify(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    try {
      return jsonEncode(value);
    } on Object {
      return value.toString();
    }
  }

  static bool _isRulePath(String path) {
    if (path.isEmpty) return false;
    final root = path.split('.').first.toLowerCase();
    return root.startsWith('rule') ||
        root == 'searchurl' ||
        root == 'exploreurl';
  }

  static void _collectValues(
    Object? value,
    String path,
    Map<String, String> output,
  ) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        _collectValues(entry.value, path.isEmpty ? key : '$path.$key', output);
      }
      return;
    }
    if (value is Iterable) {
      var index = 0;
      for (final item in value) {
        _collectValues(item, '$path[$index]', output);
        index++;
      }
      return;
    }
    if (value == null) return;
    output[path] = _stringify(value);
  }
}
