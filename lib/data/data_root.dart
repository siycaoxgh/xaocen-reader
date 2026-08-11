import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The storage scope used by one XAOCEN application instance.
enum DataRootMode { standard, portable }

/// Owns all writable paths used by the application.
///
/// The root is deliberately separate from the executable directory in
/// standard mode. Portable mode is opt-in and places data below the supplied
/// executable directory's `data/` child. Existing book storage paths keep
/// their `library/...` contract; [booksDirectory] is the physical directory
/// that resolves those paths.
final class DataRoot {
  DataRoot._({
    required this.rootDirectory,
    required this.mode,
    required this.legacySupportDirectory,
  });

  static const int formatVersion = 1;
  static const String metadataFileName = '.xaocen_data_root.json';
  static const String lockFileName = '.xaocen_data_root.lock';
  static final Map<String, DataRootLease> _processLeases = {};

  final Directory rootDirectory;
  final DataRootMode mode;
  final Directory? legacySupportDirectory;

  Directory get databaseDirectory =>
      Directory(p.join(rootDirectory.path, 'database'));
  File get databaseFile =>
      File(p.join(databaseDirectory.path, 'xaocen_v4_local.sqlite'));

  /// Physical books directory. The database continues to refer to files as
  /// `library/...` so old records remain valid after migration.
  Directory get booksDirectory =>
      Directory(p.join(rootDirectory.path, 'books'));
  Directory get normalizedIndexDirectory =>
      Directory(p.join(booksDirectory.path, 'local_txt'));
  Directory get readerBackgroundsDirectory =>
      Directory(p.join(booksDirectory.path, 'reader_backgrounds'));
  Directory get settingsDirectory =>
      Directory(p.join(rootDirectory.path, 'settings'));
  Directory get fontsDirectory =>
      Directory(p.join(rootDirectory.path, 'fonts'));
  Directory get backupMetadataDirectory =>
      Directory(p.join(rootDirectory.path, 'backups'));
  Directory get temporaryDirectory =>
      Directory(p.join(rootDirectory.path, 'tmp'));
  File get metadataFile => File(p.join(rootDirectory.path, metadataFileName));
  File get lockFile => File(p.join(rootDirectory.path, lockFileName));

  String? _rootId;
  String get rootId =>
      _rootId ?? (throw StateError('DataRoot has not been initialized'));

  static Future<DataRoot> standard({Directory? supportDirectory}) async {
    final support = supportDirectory ?? await getApplicationSupportDirectory();
    final root = DataRoot._(
      rootDirectory: Directory(p.join(support.path, 'xaocen_reader')),
      mode: DataRootMode.standard,
      legacySupportDirectory: support,
    );
    await root.initialize();
    return root;
  }

  /// Creates a portable root. Callers must explicitly opt into this method.
  static Future<DataRoot> portable({
    required Directory executableDirectory,
  }) async {
    final root = DataRoot._(
      rootDirectory: Directory(p.join(executableDirectory.path, 'data')),
      mode: DataRootMode.portable,
      legacySupportDirectory: null,
    );
    await root.initialize();
    return root;
  }

  /// A deterministic, filesystem-only constructor useful for tests and
  /// import/export tooling. It still writes the same root metadata.
  static Future<DataRoot> forDirectory(
    Directory directory, {
    DataRootMode mode = DataRootMode.portable,
  }) async {
    final root = DataRoot._(
      rootDirectory: directory,
      mode: mode,
      legacySupportDirectory: null,
    );
    await root.initialize();
    return root;
  }

  Future<void> initialize() async {
    await _migrateLegacyIfNeeded();
    await rootDirectory.create(recursive: true);
    await Future.wait([
      databaseDirectory.create(recursive: true),
      booksDirectory.create(recursive: true),
      settingsDirectory.create(recursive: true),
      fontsDirectory.create(recursive: true),
      backupMetadataDirectory.create(recursive: true),
      temporaryDirectory.create(recursive: true),
    ]);

    if (await metadataFile.exists()) {
      try {
        final json = jsonDecode(await metadataFile.readAsString());
        if (json is! Map ||
            json['rootId'] is! String ||
            (json['rootId'] as String).isEmpty) {
          throw const DataRootException('invalid data root metadata');
        }
        _rootId = json['rootId'] as String;
      } catch (error) {
        throw DataRootException('cannot read data root metadata: $error');
      }
    } else {
      _rootId = _newRootId();
      await _writeMetadata(migratedFromLegacy: false);
    }
  }

  Future<DataRootLease> acquireLease() async {
    await initialize();
    final key = rootDirectory.absolute.path.toLowerCase();
    if (_processLeases.containsKey(key)) {
      throw const DataRootException(
        'data root is already open in this process',
      );
    }
    final file = await lockFile.open(mode: FileMode.write);
    try {
      await file.lock(FileLock.exclusive);
    } catch (error) {
      await file.close();
      throw DataRootException('data root is already in use: $error');
    }
    final lease = DataRootLease._(root: this, file: file, key: key);
    _processLeases[key] = lease;
    return lease;
  }

  bool get hasProcessLease =>
      _processLeases.containsKey(rootDirectory.absolute.path.toLowerCase());

  Future<void> _writeMetadata({required bool migratedFromLegacy}) async {
    final payload = <String, Object?>{
      'formatVersion': formatVersion,
      'rootId': rootId,
      'mode': mode.name,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'migratedFromLegacy': migratedFromLegacy,
    };
    final temporary = File('${metadataFile.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    await temporary.rename(metadataFile.path);
  }

  Future<void> _migrateLegacyIfNeeded() async {
    final legacy = legacySupportDirectory;
    if (legacy == null || legacy.absolute.path == rootDirectory.absolute.path) {
      return;
    }
    if (await metadataFile.exists()) return;

    final legacyDb = File(p.join(legacy.path, 'xaocen_v4_local.sqlite'));
    final legacyBooks = Directory(p.join(legacy.path, 'library'));
    final hasLegacy = await legacyDb.exists() || await legacyBooks.exists();
    if (!hasLegacy) return;

    await rootDirectory.create(recursive: true);
    final dbDir = databaseDirectory;
    await dbDir.create(recursive: true);
    if (await legacyDb.exists() && !await databaseFile.exists()) {
      await legacyDb.copy(databaseFile.path);
      for (final suffix in const ['-wal', '-shm']) {
        final sidecar = File('${legacyDb.path}$suffix');
        if (await sidecar.exists()) {
          await sidecar.copy('${databaseFile.path}$suffix');
        }
      }
    }
    if (await legacyBooks.exists() && !await booksDirectory.exists()) {
      await _copyDirectory(legacyBooks, booksDirectory);
    }
    _rootId = _newRootId();
    await _writeMetadata(migratedFromLegacy: true);
  }

  static String _newRootId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entry in source.list(followLinks: false)) {
      final name = p.basename(entry.path);
      final destination = p.join(target.path, name);
      if (entry is Directory) {
        await _copyDirectory(entry, Directory(destination));
      } else if (entry is File) {
        await entry.copy(destination);
      }
    }
  }
}

final class DataRootLease {
  DataRootLease._({required this.root, required this.file, required this.key});

  final DataRoot root;
  final RandomAccessFile file;
  final String key;
  bool _released = false;

  Future<void> release() async {
    if (_released) return;
    _released = true;
    try {
      await file.unlock();
    } finally {
      await file.close();
      DataRoot._processLeases.remove(key);
    }
  }
}

class DataRootException implements Exception {
  const DataRootException(this.message);
  final String message;

  @override
  String toString() => 'DataRootException: $message';
}
