import 'dart:convert';

import 'xaocen_web_book_source_definition.dart';

/// Compatibility result for one legacy source inside a versioned source pack.
enum LegacyCompatibilityLevel {
  full,
  runnablePartial,
  needsCapability,
  unsupported,
}

extension LegacyCompatibilityLevelCode on LegacyCompatibilityLevel {
  String get code => switch (this) {
    LegacyCompatibilityLevel.full => 'FULL',
    LegacyCompatibilityLevel.runnablePartial => 'RUNNABLE_PARTIAL',
    LegacyCompatibilityLevel.needsCapability => 'NEEDS_CAPABILITY',
    LegacyCompatibilityLevel.unsupported => 'UNSUPPORTED',
  };

  static LegacyCompatibilityLevel parse(String value) => switch (value) {
    'FULL' => LegacyCompatibilityLevel.full,
    'RUNNABLE_PARTIAL' => LegacyCompatibilityLevel.runnablePartial,
    'NEEDS_CAPABILITY' => LegacyCompatibilityLevel.needsCapability,
    'UNSUPPORTED' => LegacyCompatibilityLevel.unsupported,
    _ => throw FormatException('未知 Legacy 兼容等级: $value'),
  };
}

/// One source entry in an [XaocenWebBookSourcePack].
///
/// The optional [definition] is present only when XAOCEN can execute the
/// currently supported core rules. [legacyFields] deliberately preserves the
/// unmapped legacy values and their source metadata for a later migration
/// pass; this class never imports an entry into the runtime registry.
final class XaocenSourcePackEntry {
  const XaocenSourcePackEntry({
    required this.sourceId,
    required this.legacySourceId,
    required this.sourceName,
    required this.compatibility,
    required this.sourceFile,
    required this.legacyFields,
    required this.reasons,
    this.definition,
  });

  final String sourceId;
  final String legacySourceId;
  final String? sourceName;
  final LegacyCompatibilityLevel compatibility;
  final String sourceFile;
  final Map<String, Object?> legacyFields;
  final List<String> reasons;
  final XaocenWebBookSourceDefinition? definition;

  Map<String, Object?> toJson() => <String, Object?>{
    'sourceId': sourceId,
    'legacySourceId': legacySourceId,
    'sourceName': sourceName,
    'compatibility': compatibility.code,
    'sourceFile': sourceFile,
    if (definition != null) 'source': definition!.toJson(),
    'legacy': <String, Object?>{
      'sourceId': legacySourceId,
      'sourceFile': sourceFile,
      'fields': legacyFields,
    },
    'reasons': reasons,
  };

  static XaocenSourcePackEntry fromJson(Map<String, Object?> json) {
    final sourceId = _requiredString(json, 'sourceId');
    final sourceName = _optionalString(json, 'sourceName');
    final sourceFile = _requiredString(json, 'sourceFile');
    final compatibility = LegacyCompatibilityLevelCode.parse(
      _requiredString(json, 'compatibility'),
    );
    final rawSource = json['source'];
    XaocenWebBookSourceDefinition? definition;
    if (rawSource != null) {
      if (rawSource is! Map) {
        throw const FormatException('sources[].source 必须是对象或 null');
      }
      definition = XaocenWebBookSourceDefinition.fromJson(
        rawSource.map<String, Object?>(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      if (definition.sourceId != sourceId) {
        throw const FormatException('sources[].sourceId 与 source.sourceId 不一致');
      }
    }
    final legacy = _optionalMap(json, 'legacy') ?? const <String, Object?>{};
    final legacySourceId = _requiredString(legacy, 'sourceId');
    final topLevelLegacySourceId = _optionalString(json, 'legacySourceId');
    if (topLevelLegacySourceId != null &&
        topLevelLegacySourceId != legacySourceId) {
      throw const FormatException(
        'legacySourceId 与 legacy.sourceId 不一致',
      );
    }
    final legacyFields = _optionalMap(legacy, 'fields') ?? const <String, Object?>{};
    final reasons = _stringList(json['reasons'], 'reasons');
    if (compatibility == LegacyCompatibilityLevel.full && definition == null) {
      throw const FormatException('FULL source 必须包含可执行 source');
    }
    if (compatibility == LegacyCompatibilityLevel.runnablePartial &&
        definition == null) {
      throw const FormatException('RUNNABLE_PARTIAL source 必须包含可执行 source');
    }
    return XaocenSourcePackEntry(
      sourceId: sourceId,
      legacySourceId: legacySourceId,
      sourceName: sourceName,
      compatibility: compatibility,
      sourceFile: sourceFile,
      legacyFields: legacyFields,
      reasons: reasons,
      definition: definition,
    );
  }
}

/// Versioned container for multiple XAOCEN WebBook source drafts.
///
/// A pack is a transport/document boundary only. Decoding it does not persist
/// or enable any source in the application Registry.
final class XaocenWebBookSourcePack {
  const XaocenWebBookSourcePack({
    required this.packId,
    required this.name,
    required this.sources,
    this.generatedAt,
  });

  static const schema = 'xaocen.webBook.source-pack';
  static const schemaVersion = 1;

  final String packId;
  final String name;
  final DateTime? generatedAt;
  final List<XaocenSourcePackEntry> sources;

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': schema,
    'version': schemaVersion,
    'packId': packId,
    'name': name,
    if (generatedAt != null) 'generatedAt': generatedAt!.toUtc().toIso8601String(),
    'sources': sources.map((source) => source.toJson()).toList(growable: false),
  };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  static XaocenWebBookSourcePack fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Source Pack 根节点必须是对象');
    }
    return fromJson(
      decoded.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }

  static XaocenWebBookSourcePack fromJson(Map<String, Object?> json) {
    if (json['schema'] != schema) {
      throw FormatException('Source Pack schema 必须为 $schema');
    }
    if (json['version'] != schemaVersion) {
      throw FormatException('不支持的 Source Pack version: ${json['version']}');
    }
    final rawSources = json['sources'];
    if (rawSources is! List) {
      throw const FormatException('Source Pack sources 必须是数组');
    }
    final sources = <XaocenSourcePackEntry>[];
    final ids = <String>{};
    for (final raw in rawSources) {
      if (raw is! Map) {
        throw const FormatException('Source Pack sources[] 必须是对象');
      }
      final entry = XaocenSourcePackEntry.fromJson(
        raw.map<String, Object?>(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      if (!ids.add(entry.sourceId)) {
        throw FormatException('Source Pack sourceId 重复: ${entry.sourceId}');
      }
      sources.add(entry);
    }
    final generatedAtValue = _optionalString(json, 'generatedAt');
    DateTime? generatedAt;
    if (generatedAtValue != null) {
      generatedAt = DateTime.tryParse(generatedAtValue);
      if (generatedAt == null) {
        throw const FormatException('generatedAt 不是合法时间');
      }
    }
    return XaocenWebBookSourcePack(
      packId: _requiredString(json, 'packId'),
      name: _requiredString(json, 'name'),
      generatedAt: generatedAt,
      sources: List.unmodifiable(sources),
    );
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key 必须是非空字符串');
  }
  return value.trim();
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key 必须是字符串或 null');
  final text = value.trim();
  return text.isEmpty ? null : text;
}

Map<String, Object?>? _optionalMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! Map) throw FormatException('$key 必须是对象或 null');
  return value.map<String, Object?>(
    (key, value) => MapEntry(key.toString(), value),
  );
}

List<String> _stringList(Object? value, String path) {
  if (value == null) return const <String>[];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$path 必须是字符串数组');
  }
  return List.unmodifiable(value.cast<String>());
}
