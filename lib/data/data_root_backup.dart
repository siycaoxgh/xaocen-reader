import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'data_root.dart';

/// A portable manifest for backup, export, import and future sync.
final class DataRootManifest {
  const DataRootManifest({
    required this.formatVersion,
    required this.sourceRootId,
    required this.createdAt,
    required this.files,
  });

  final int formatVersion;
  final String sourceRootId;
  final DateTime createdAt;
  final List<DataRootManifestEntry> files;

  Map<String, Object?> toJson() => {
    'formatVersion': formatVersion,
    'sourceRootId': sourceRootId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'files': files.map((file) => file.toJson()).toList(growable: false),
  };

  static DataRootManifest fromJson(Object? value) {
    if (value is! Map ||
        value['formatVersion'] is! int ||
        value['sourceRootId'] is! String ||
        value['files'] is! List) {
      throw const DataRootException('invalid backup manifest');
    }
    final created = DateTime.tryParse(value['createdAt'] as String? ?? '');
    if (created == null) {
      throw const DataRootException('invalid backup timestamp');
    }
    final entries = <DataRootManifestEntry>[];
    for (final item in value['files'] as List) {
      entries.add(DataRootManifestEntry.fromJson(item));
    }
    return DataRootManifest(
      formatVersion: value['formatVersion'] as int,
      sourceRootId: value['sourceRootId'] as String,
      createdAt: created,
      files: List.unmodifiable(entries),
    );
  }
}

final class DataRootManifestEntry {
  const DataRootManifestEntry({
    required this.path,
    required this.size,
    required this.sha256,
  });

  final String path;
  final int size;
  final String sha256;

  Map<String, Object?> toJson() => {
    'path': path,
    'size': size,
    'sha256': sha256,
  };

  static DataRootManifestEntry fromJson(Object? value) {
    if (value is! Map ||
        value['path'] is! String ||
        value['size'] is! int ||
        value['sha256'] is! String) {
      throw const DataRootException('invalid backup file entry');
    }
    final path = value['path'] as String;
    if (!DataRootBackupService._isSafeRelativePath(path)) {
      throw const DataRootException('unsafe backup path');
    }
    return DataRootManifestEntry(
      path: path,
      size: value['size'] as int,
      sha256: value['sha256'] as String,
    );
  }
}

/// Directory based backups avoid a mandatory archive dependency while still
/// providing a complete, hash-verifiable export format. The `payload/` tree
/// is directly portable and can be zipped by a caller when desired.
final class DataRootBackupService {
  const DataRootBackupService();

  static const String payloadDirectoryName = 'payload';
  static const String manifestFileName = 'manifest.json';

  Future<DataRootManifest> exportBundle({
    required DataRoot root,
    required Directory destination,
  }) async {
    if (root.hasProcessLease) {
      throw const DataRootException(
        'close the database before exporting a complete backup',
      );
    }
    if (await destination.exists()) {
      final entries = await destination.list().toList();
      if (entries.isNotEmpty) {
        throw const DataRootException('backup destination is not empty');
      }
    } else {
      await destination.create(recursive: true);
    }
    final payload = Directory(p.join(destination.path, payloadDirectoryName));
    await payload.create(recursive: true);
    await _copyRootFiles(root.rootDirectory, payload, root.rootDirectory);
    final files = await _hashFiles(payload, payload);
    final manifest = DataRootManifest(
      formatVersion: 1,
      sourceRootId: root.rootId,
      createdAt: DateTime.now().toUtc(),
      files: files,
    );
    await File(p.join(destination.path, manifestFileName)).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    return manifest;
  }

  Future<DataRootManifest> createBackup({
    required DataRoot root,
    required Directory destination,
  }) => exportBundle(root: root, destination: destination);

  Future<DataRootManifest> verifyBundle({required Directory bundle}) async {
    final manifestFile = File(p.join(bundle.path, manifestFileName));
    final payload = Directory(p.join(bundle.path, payloadDirectoryName));
    if (!await manifestFile.exists() || !await payload.exists()) {
      throw const DataRootException('backup manifest or payload missing');
    }
    final manifest = DataRootManifest.fromJson(
      jsonDecode(await manifestFile.readAsString()),
    );
    for (final entry in manifest.files) {
      final file = _safeJoin(payload, entry.path);
      if (!await file.exists()) {
        throw DataRootException('backup file missing: ${entry.path}');
      }
      final stat = await file.stat();
      if (stat.size != entry.size || await _sha256(file) != entry.sha256) {
        throw DataRootException('backup hash mismatch: ${entry.path}');
      }
    }
    return manifest;
  }

  /// Restores through a staged sibling directory and a directory rename. The
  /// existing root is retained as a rollback directory until the new root has
  /// been moved into place, then removed only after the swap succeeds.
  Future<DataRootManifest> restoreBundle({
    required DataRoot root,
    required Directory bundle,
  }) async {
    if (root.hasProcessLease) {
      throw const DataRootException(
        'close the database before restoring a complete backup',
      );
    }
    final manifest = await verifyBundle(bundle: bundle);
    final parent = root.rootDirectory.parent;
    final token = DateTime.now().microsecondsSinceEpoch.toString();
    final staging = Directory(p.join(parent.path, '.xaocen-restore-$token'));
    final previous = Directory(
      p.join(parent.path, '.xaocen-before-restore-$token'),
    );
    await staging.create(recursive: true);
    try {
      await _copyDirectory(
        Directory(p.join(bundle.path, payloadDirectoryName)),
        staging,
      );
      if (await root.rootDirectory.exists()) {
        await root.rootDirectory.rename(previous.path);
      }
      await staging.rename(root.rootDirectory.path);
      if (await previous.exists()) await previous.delete(recursive: true);
      return manifest;
    } catch (error) {
      if (await staging.exists()) await staging.delete(recursive: true);
      if (!await root.rootDirectory.exists() && await previous.exists()) {
        await previous.rename(root.rootDirectory.path);
      }
      throw DataRootException('restore failed: $error');
    }
  }

  Future<void> _copyRootFiles(
    Directory source,
    Directory target,
    Directory root,
  ) async {
    await for (final entry in source.list(followLinks: false)) {
      final name = p.basename(entry.path);
      if (name == DataRoot.lockFileName || name == 'tmp' || name == 'backups') {
        continue;
      }
      if (entry is Directory) {
        await _copyRootFiles(entry, Directory(p.join(target.path, name)), root);
      } else if (entry is File) {
        final destination = File(p.join(target.path, name));
        await destination.parent.create(recursive: true);
        await entry.copy(destination.path);
      }
    }
  }

  Future<List<DataRootManifestEntry>> _hashFiles(
    Directory directory,
    Directory base,
  ) async {
    final result = <DataRootManifestEntry>[];
    await for (final entry in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entry is! File) continue;
      final relative = p
          .relative(entry.path, from: base.path)
          .replaceAll('\\', '/');
      final stat = await entry.stat();
      result.add(
        DataRootManifestEntry(
          path: relative,
          size: stat.size,
          sha256: await _sha256(entry),
        ),
      );
    }
    result.sort((a, b) => a.path.compareTo(b.path));
    return result;
  }

  Future<String> _sha256(File file) async =>
      sha256.convert(await file.readAsBytes()).toString();

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entry in source.list(followLinks: false)) {
      final destination = p.join(target.path, p.basename(entry.path));
      if (entry is Directory) {
        await _copyDirectory(entry, Directory(destination));
      } else if (entry is File) {
        await entry.copy(destination);
      }
    }
  }

  File _safeJoin(Directory root, String relative) {
    if (!_isSafeRelativePath(relative)) {
      throw const DataRootException('unsafe backup path');
    }
    return File(p.joinAll([root.path, ...relative.split('/')]));
  }

  static bool _isSafeRelativePath(String value) =>
      value.isNotEmpty &&
      !p.isAbsolute(value) &&
      !value.split('/').contains('..') &&
      !value.contains('\\');
}
