import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data_root.dart';
import '../../sources/remote/xaocen_web_book_source_definition.dart';

/// A locally registered WebBook definition and its user-controlled status.
///
/// The definition remains the single source/rule truth; [enabled] is only
/// registry state and is intentionally not exported as part of a source JSON.
final class WebBookSourceRegistryEntry {
  const WebBookSourceRegistryEntry({
    required this.definition,
    required this.enabled,
  });

  final XaocenWebBookSourceDefinition definition;
  final bool enabled;

  String get sourceId => definition.sourceId;

  WebBookSourceRegistryEntry copyWith({bool? enabled}) =>
      WebBookSourceRegistryEntry(
        definition: definition,
        enabled: enabled ?? this.enabled,
      );
}

/// Profile/DataRoot-scoped persistence for XAOCEN WebBook source definitions.
///
/// This is deliberately a small atomically-written JSON registry rather than
/// a Drift table. It stores source definitions and enabled state only; it does
/// not perform network requests, expose a UI, or import credentials.
final class WebBookSourceRegistry {
  WebBookSourceRegistry(this.root);

  static const int formatVersion = 1;
  static const String fileName = 'webbook_sources.json';

  final DataRoot root;

  File get storageFile => File(p.join(root.settingsDirectory.path, fileName));

  Future<List<WebBookSourceRegistryEntry>> list() async {
    final entries = await _read();
    entries.sort((a, b) => a.sourceId.compareTo(b.sourceId));
    return List.unmodifiable(entries);
  }

  Future<WebBookSourceRegistryEntry?> find(String sourceId) async {
    final normalized = _requireSourceId(sourceId);
    for (final entry in await _read()) {
      if (entry.sourceId == normalized) return entry;
    }
    return null;
  }

  /// Imports one XAOCEN JSON definition and upserts it by stable source id.
  ///
  /// Re-importing a source updates its definition but preserves the existing
  /// enabled/disabled choice. Malformed or unsupported JSON is rejected before
  /// anything is written.
  Future<WebBookSourceRegistryEntry> importJson(String json) async {
    final definition = _decode(json);
    return importDefinition(definition);
  }

  Future<WebBookSourceRegistryEntry> importDefinition(
    XaocenWebBookSourceDefinition definition,
  ) async {
    final entries = await _read();
    final index = entries.indexWhere(
      (entry) => entry.sourceId == definition.sourceId,
    );
    final value = WebBookSourceRegistryEntry(
      definition: definition,
      enabled: index < 0 ? true : entries[index].enabled,
    );
    if (index < 0) {
      entries.add(value);
    } else {
      entries[index] = value;
    }
    await _write(entries);
    return value;
  }

  Future<WebBookSourceRegistryEntry> setEnabled(
    String sourceId,
    bool enabled,
  ) async {
    final normalized = _requireSourceId(sourceId);
    final entries = await _read();
    final index = entries.indexWhere((entry) => entry.sourceId == normalized);
    if (index < 0) {
      throw const DataRootException('webbook source not found');
    }
    final value = entries[index].copyWith(enabled: enabled);
    entries[index] = value;
    await _write(entries);
    return value;
  }

  Future<bool> remove(String sourceId) async {
    final normalized = _requireSourceId(sourceId);
    final entries = await _read();
    final before = entries.length;
    entries.removeWhere((entry) => entry.sourceId == normalized);
    if (entries.length == before) return false;
    await _write(entries);
    return true;
  }

  /// Exports only the validated source definition. Registry enabled state is
  /// local policy and is intentionally not embedded in portable source JSON.
  Future<String> exportJson(String sourceId) async {
    final entry = await find(sourceId);
    if (entry == null) {
      throw const DataRootException('webbook source not found');
    }
    return entry.definition.toJsonString();
  }

  XaocenWebBookSourceDefinition _decode(String json) {
    try {
      return XaocenWebBookSourceDefinition.fromJsonString(json);
    } catch (error) {
      throw DataRootException('invalid XAOCEN WebBook source JSON: $error');
    }
  }

  Future<List<WebBookSourceRegistryEntry>> _read() async {
    if (!await storageFile.exists()) return <WebBookSourceRegistryEntry>[];
    try {
      final decoded = jsonDecode(await storageFile.readAsString());
      if (decoded is! Map || decoded['entries'] is! List) {
        throw const FormatException('invalid webbook source registry');
      }
      if (decoded['formatVersion'] != formatVersion) {
        throw FormatException(
          'unsupported webbook registry format: ${decoded['formatVersion']}',
        );
      }
      final storedProfileId = decoded['profileId'];
      final storedRootId = decoded['rootId'];
      if (storedProfileId is String && storedProfileId != root.profileId) {
        throw const FormatException(
          'webbook registry belongs to another profile',
        );
      }
      if (storedRootId is String && storedRootId != root.rootId) {
        throw const FormatException(
          'webbook registry belongs to another data root',
        );
      }
      final result = <WebBookSourceRegistryEntry>[];
      final identities = <String>{};
      for (final value in decoded['entries'] as List) {
        if (value is! Map || value['definition'] is! Map) {
          throw const FormatException('invalid webbook source entry');
        }
        final definitionMap = (value['definition'] as Map).map<String, Object?>(
          (key, value) => MapEntry(key.toString(), value),
        );
        final definition = XaocenWebBookSourceDefinition.fromJson(
          definitionMap,
        );
        final enabled = value['enabled'];
        if (enabled is! bool) {
          throw const FormatException('webbook source enabled must be bool');
        }
        if (!identities.add(definition.sourceId)) {
          throw const FormatException('duplicate webbook source');
        }
        result.add(
          WebBookSourceRegistryEntry(definition: definition, enabled: enabled),
        );
      }
      return result;
    } catch (error) {
      throw DataRootException('cannot read WebBook source registry: $error');
    }
  }

  Future<void> _write(List<WebBookSourceRegistryEntry> entries) async {
    await storageFile.parent.create(recursive: true);
    final sorted = [...entries]
      ..sort((a, b) => a.sourceId.compareTo(b.sourceId));
    final payload = <String, Object?>{
      'formatVersion': formatVersion,
      'profileId': root.profileId,
      'rootId': root.rootId,
      'entries': [
        for (final entry in sorted)
          <String, Object?>{
            'enabled': entry.enabled,
            'definition': entry.definition.toJson(),
          },
      ],
    };
    final temporary = File('${storageFile.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await temporary.rename(storageFile.path);
  }

  static String _requireSourceId(String value) {
    final normalized = value.trim();
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(normalized)) {
      throw const DataRootException('invalid webbook source id');
    }
    return normalized;
  }
}
