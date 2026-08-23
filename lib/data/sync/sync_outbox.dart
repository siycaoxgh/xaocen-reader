import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../data_root.dart';

/// A local, append-only change envelope reserved for a future sync adapter.
///
/// The outbox stores metadata operations only. It does not replace the local
/// database, does not contain normalized TXT bodies, and never performs
/// network I/O by itself.
final class SyncOutboxEntry {
  const SyncOutboxEntry({
    required this.id,
    required this.profileId,
    required this.rootId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.completedAt,
  });

  final String id;
  final String profileId;
  final String rootId;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  Map<String, Object?> toJson() => {
    'formatVersion': 1,
    'id': id,
    'profileId': profileId,
    'rootId': rootId,
    'entityType': entityType,
    'entityId': entityId,
    'operation': operation,
    'payload': payload,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'retryCount': retryCount,
    if (completedAt != null)
      'completedAt': completedAt!.toUtc().toIso8601String(),
  };

  static SyncOutboxEntry fromJson(Object? value) {
    if (value is! Map ||
        value['id'] is! String ||
        value['profileId'] is! String ||
        value['rootId'] is! String ||
        value['entityType'] is! String ||
        value['entityId'] is! String ||
        value['operation'] is! String ||
        value['payload'] is! Map ||
        value['createdAt'] is! String) {
      throw const DataRootException('invalid sync outbox entry');
    }
    final createdAt = DateTime.tryParse(value['createdAt'] as String);
    if (createdAt == null) {
      throw const DataRootException('invalid sync outbox timestamp');
    }
    final completedValue = value['completedAt'];
    final completedAt = completedValue == null
        ? null
        : DateTime.tryParse(completedValue as String);
    if (completedValue != null && completedAt == null) {
      throw const DataRootException('invalid sync outbox completion time');
    }
    final payload = <String, Object?>{};
    for (final entry in (value['payload'] as Map).entries) {
      if (entry.key is! String) {
        throw const DataRootException('invalid sync outbox payload key');
      }
      payload[entry.key as String] = entry.value;
    }
    return SyncOutboxEntry(
      id: value['id'] as String,
      profileId: value['profileId'] as String,
      rootId: value['rootId'] as String,
      entityType: value['entityType'] as String,
      entityId: value['entityId'] as String,
      operation: value['operation'] as String,
      payload: Map.unmodifiable(payload),
      createdAt: createdAt,
      retryCount: value['retryCount'] is int ? value['retryCount'] as int : 0,
      completedAt: completedAt,
    );
  }

  SyncOutboxEntry copyWith({int? retryCount, DateTime? completedAt}) {
    return SyncOutboxEntry(
      id: id,
      profileId: profileId,
      rootId: rootId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

final class SyncOutbox {
  SyncOutbox({required this.root});

  final DataRoot root;
  static final Random _random = Random();

  Directory get pendingDirectory =>
      Directory(p.join(root.syncOutboxDirectory.path, 'pending'));
  Directory get completedDirectory =>
      Directory(p.join(root.syncOutboxDirectory.path, 'completed'));

  Future<SyncOutboxEntry> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    _requireText(entityType, 'entityType');
    _requireText(entityId, 'entityId');
    _requireText(operation, 'operation');
    // Validate JSON compatibility before touching disk.
    jsonEncode(payload);
    await pendingDirectory.create(recursive: true);
    final now = DateTime.now().toUtc();
    String id;
    File file;
    do {
      id = '${now.microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
      file = File(p.join(pendingDirectory.path, '$id.json'));
    } while (await file.exists());
    final entry = SyncOutboxEntry(
      id: id,
      profileId: root.profileId,
      rootId: root.rootId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: Map.unmodifiable(Map<String, Object?>.from(payload)),
      createdAt: now,
    );
    await _writeAtomically(file, entry.toJson());
    return entry;
  }

  Future<List<SyncOutboxEntry>> pending() => _readDirectory(pendingDirectory);

  Future<List<SyncOutboxEntry>> completed() =>
      _readDirectory(completedDirectory);

  Future<void> markCompleted(String id) async {
    final source = _entryFile(pendingDirectory, id);
    if (!await source.exists()) {
      throw const DataRootException('sync outbox entry not found');
    }
    final entry = SyncOutboxEntry.fromJson(
      jsonDecode(await source.readAsString()),
    );
    await completedDirectory.create(recursive: true);
    final completed = entry.copyWith(completedAt: DateTime.now().toUtc());
    final destination = _entryFile(completedDirectory, id);
    await _writeAtomically(destination, completed.toJson());
    await source.delete();
  }

  Future<void> recordFailure(String id) async {
    final source = _entryFile(pendingDirectory, id);
    if (!await source.exists()) {
      throw const DataRootException('sync outbox entry not found');
    }
    final entry = SyncOutboxEntry.fromJson(
      jsonDecode(await source.readAsString()),
    );
    await _writeAtomically(
      source,
      entry.copyWith(retryCount: entry.retryCount + 1).toJson(),
    );
  }

  Future<void> remove(String id) async {
    for (final directory in [pendingDirectory, completedDirectory]) {
      final file = _entryFile(directory, id);
      if (await file.exists()) await file.delete();
    }
  }

  Future<List<SyncOutboxEntry>> _readDirectory(Directory directory) async {
    if (!await directory.exists()) return const <SyncOutboxEntry>[];
    final entries = <SyncOutboxEntry>[];
    await for (final item in directory.list(followLinks: false)) {
      if (item is! File || !item.path.endsWith('.json')) continue;
      try {
        entries.add(
          SyncOutboxEntry.fromJson(jsonDecode(await item.readAsString())),
        );
      } catch (error) {
        throw DataRootException('cannot read sync outbox entry: $error');
      }
    }
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(entries);
  }

  File _entryFile(Directory directory, String id) {
    if (!_isSafeId(id)) throw const DataRootException('unsafe sync outbox id');
    return File(p.join(directory.path, '$id.json'));
  }

  Future<void> _writeAtomically(File file, Map<String, Object?> value) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(value),
      flush: true,
    );
    await temporary.rename(file.path);
  }

  static void _requireText(String value, String name) {
    if (value.trim().isEmpty) {
      throw DataRootException('$name must not be empty');
    }
  }

  static bool _isSafeId(String value) =>
      value.isNotEmpty && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);
}
