import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The storage scope used by one XAOCEN application instance.
enum DataRootMode { standard, portable }

/// Owns all writable paths used by the application.
///
/// Standard mode uses a stable product key and never derives its path from
/// the EXE's display name. Portable mode is explicit and uses `user_data/`
/// beside the executable; Flutter's sibling `data/` directory is reserved
/// for runtime assets. Existing book storage paths keep their `library/...`
/// contract; [booksDirectory] is the physical directory that resolves them.
final class DataRoot {
  DataRoot._({
    required this.rootDirectory,
    required this.mode,
    required this.legacySupportDirectory,
    required this.profileId,
    this.legacyCandidates = const <Directory>[],
  });

  static const int formatVersion = 1;
  static const String metadataFileName = '.xaocen_data_root.json';
  static const String lockFileName = '.xaocen_data_root.lock';
  static const String stableCompanyDirectory = 'XAOCEN';
  static const String stableProductDirectory = 'Reader';
  static const String profilesDirectoryName = 'profiles';
  static const String defaultProfileId = 'default';
  static const String portableUserDataDirectoryName = 'user_data';
  static const String portableMarkerFileName = 'portable.marker';
  static const String portableArgument = '--portable';
  static const String profileArgumentPrefix = '--profile=';
  static const String profileEnvironmentVariable = 'XAOCEN_PROFILE';
  static const String activeProfileFileName = 'active_profile.json';
  static final Map<String, DataRootLease> _processLeases = {};

  final Directory rootDirectory;
  final DataRootMode mode;
  final Directory? legacySupportDirectory;
  final String profileId;
  final List<Directory> legacyCandidates;
  String? _migrationSource;

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

  /// Profile-scoped RSS image cache. Images are fetched only when an article
  /// is opened and are never written beside the user's source feed.
  Directory get remoteFeedImagesDirectory =>
      Directory(p.join(booksDirectory.path, 'remote_feeds', 'images'));
  Directory get settingsDirectory =>
      Directory(p.join(rootDirectory.path, 'settings'));
  Directory get fontsDirectory =>
      Directory(p.join(rootDirectory.path, 'fonts'));
  Directory get backupMetadataDirectory =>
      Directory(p.join(rootDirectory.path, 'backups'));
  Directory get temporaryDirectory =>
      Directory(p.join(rootDirectory.path, 'tmp'));
  Directory get syncDirectory => Directory(p.join(rootDirectory.path, 'sync'));
  Directory get syncOutboxDirectory =>
      Directory(p.join(syncDirectory.path, 'outbox'));
  Directory get profileScopeDirectory => rootDirectory.parent.parent;
  Directory get profilesDirectory => rootDirectory.parent;
  File get activeProfileFile =>
      File(p.join(profileScopeDirectory.path, activeProfileFileName));
  File get metadataFile => File(p.join(rootDirectory.path, metadataFileName));
  File get lockFile => File(p.join(rootDirectory.path, lockFileName));

  String? _rootId;
  String get rootId =>
      _rootId ?? (throw StateError('DataRoot has not been initialized'));

  /// Opens the fixed standard root. The Windows path is based on LOCALAPPDATA,
  /// rather than EXE ProductName metadata, so branding changes cannot move
  /// the database again. A caller-supplied [supportDirectory] is treated as
  /// the base directory for deterministic tests and migration tooling.
  static Future<DataRoot> standard({
    Directory? supportDirectory,
    String profileId = defaultProfileId,
  }) async {
    final support = supportDirectory ?? await _standardBaseDirectory();
    final normalizedProfileId = _normalizeProfileId(profileId);
    final rootDirectory = Directory(
      p.join(
        support.path,
        stableCompanyDirectory,
        stableProductDirectory,
        profilesDirectoryName,
        normalizedProfileId,
      ),
    );
    final root = DataRoot._(
      rootDirectory: rootDirectory,
      mode: DataRootMode.standard,
      legacySupportDirectory: support,
      profileId: normalizedProfileId,
      legacyCandidates: _standardLegacyCandidates(
        supportBases: [
          support,
          if (supportDirectory == null && Platform.isWindows)
            ..._windowsRoamingBases(),
        ],
        target: rootDirectory,
        includeDirectSupport: supportDirectory != null,
      ),
    );
    await root.initialize();
    return root;
  }

  /// Resolves the active storage mode. Portable mode is never inferred merely
  /// from the executable location; it requires an explicit argument, marker,
  /// or test injection.
  static Future<DataRoot> resolve({
    List<String> arguments = const <String>[],
    Directory? executableDirectory,
    String? profileId,
  }) async {
    final executable =
        executableDirectory ??
        Directory(p.dirname(Platform.resolvedExecutable));
    final marker = File(p.join(executable.path, portableMarkerFileName));
    final requested =
        arguments.contains(portableArgument) ||
        Platform.environment['XAOCEN_PORTABLE'] == '1';
    final mode = requested || await marker.exists()
        ? DataRootMode.portable
        : DataRootMode.standard;
    final scope = mode == DataRootMode.portable
        ? Directory(p.join(executable.path, portableUserDataDirectoryName))
        : await _standardScopeDirectory();
    final resolvedProfile = _normalizeProfileId(
      profileId ??
          _profileIdFromArguments(arguments) ??
          Platform.environment[profileEnvironmentVariable] ??
          await _readActiveProfileId(scope) ??
          defaultProfileId,
    );
    if (mode == DataRootMode.portable) {
      return portable(
        executableDirectory: executable,
        profileId: resolvedProfile,
      );
    }
    return standard(profileId: resolvedProfile);
  }

  /// Persists the profile selected for the next application start. The
  /// running database is intentionally not replaced in place.
  static Future<void> setActiveProfile({
    required String profileId,
    DataRootMode mode = DataRootMode.standard,
    Directory? executableDirectory,
  }) async {
    final normalized = _normalizeProfileId(profileId);
    final scope = mode == DataRootMode.portable
        ? Directory(
            p.join(
              (executableDirectory ??
                      Directory(p.dirname(Platform.resolvedExecutable)))
                  .path,
              portableUserDataDirectoryName,
            ),
          )
        : await _standardScopeDirectory();
    await scope.create(recursive: true);
    final file = File(p.join(scope.path, activeProfileFileName));
    final temporary = File('${file.path}.tmp');
    final payload = <String, Object?>{
      'formatVersion': 1,
      'profileId': normalized,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    await temporary.rename(file.path);
  }

  /// Lists initialized profiles in this storage scope without opening their
  /// databases. The default profile is returned first when present.
  Future<List<String>> listProfileIds() async {
    if (!await profilesDirectory.exists()) return const <String>[];
    final ids = <String>[];
    await for (final entry in profilesDirectory.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final id = p.basename(entry.path);
      if (_normalizeProfileId(id) != id) continue;
      if (await File(p.join(entry.path, metadataFileName)).exists()) {
        ids.add(id);
      }
    }
    ids.sort((a, b) {
      if (a == defaultProfileId) return -1;
      if (b == defaultProfileId) return 1;
      return a.compareTo(b);
    });
    return List.unmodifiable(ids);
  }

  /// Creates a portable root. Callers must explicitly opt into this method.
  /// The user data directory is intentionally separate from Flutter's
  /// executable-local `data/` runtime bundle.
  static Future<DataRoot> portable({
    required Directory executableDirectory,
    String profileId = defaultProfileId,
  }) async {
    final normalizedProfileId = _normalizeProfileId(profileId);
    final root = DataRoot._(
      rootDirectory: Directory(
        p.join(
          executableDirectory.path,
          portableUserDataDirectoryName,
          profilesDirectoryName,
          normalizedProfileId,
        ),
      ),
      mode: DataRootMode.portable,
      legacySupportDirectory: null,
      profileId: normalizedProfileId,
    );
    await root.initialize();
    return root;
  }

  /// A deterministic, filesystem-only constructor useful for tests and
  /// import/export tooling. It still writes the same root metadata.
  static Future<DataRoot> forDirectory(
    Directory directory, {
    DataRootMode mode = DataRootMode.portable,
    String profileId = defaultProfileId,
  }) async {
    final root = DataRoot._(
      rootDirectory: directory,
      mode: mode,
      legacySupportDirectory: null,
      profileId: _normalizeProfileId(profileId),
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
      syncOutboxDirectory.create(recursive: true),
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
      _rootId ??= _newRootId();
      await _writeMetadata(migratedFromLegacy: _migrationSource != null);
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
      'profileId': profileId,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'migratedFromLegacy': migratedFromLegacy,
      if (_migrationSource != null) 'migrationSource': _migrationSource,
    };
    final temporary = File('${metadataFile.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    await temporary.rename(metadataFile.path);
  }

  Future<void> _migrateLegacyIfNeeded() async {
    if (await metadataFile.exists() || await databaseFile.exists()) return;

    Directory? source;
    for (final candidate in legacyCandidates) {
      if (candidate.absolute.path == rootDirectory.absolute.path) continue;
      if (await _looksLikeDataRoot(candidate)) {
        source = candidate;
        break;
      }
    }
    if (source == null) return;

    // Copy into a sibling staging directory first. Existing user data is never
    // deleted or overwritten by automatic migration.
    final staging = Directory(
      '${rootDirectory.path}.migration-${DateTime.now().microsecondsSinceEpoch}',
    );
    await _copyLegacyDataRoot(source, staging);
    await rootDirectory.create(recursive: true);
    await _copyDirectory(staging, rootDirectory);
    await staging.delete(recursive: true);

    _migrationSource = source.path;
    final migratedMetadata = File(p.join(rootDirectory.path, metadataFileName));
    final sourceMetadata = File(p.join(source.path, metadataFileName));
    if (await sourceMetadata.exists()) {
      try {
        final json = jsonDecode(await sourceMetadata.readAsString());
        if (json is Map && json['rootId'] is String) {
          _rootId = json['rootId'] as String;
        }
      } catch (_) {
        // A corrupt legacy metadata file must not block the database copy.
      }
    }
    _rootId ??= _newRootId();
    if (await migratedMetadata.exists()) {
      await migratedMetadata.delete();
    }
    await _writeMetadata(migratedFromLegacy: true);
  }

  static Future<Directory> _standardBaseDirectory() async {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        return Directory(localAppData);
      }
    }
    return getApplicationSupportDirectory();
  }

  static Future<Directory> _standardScopeDirectory() async {
    final base = await _standardBaseDirectory();
    return Directory(
      p.join(base.path, stableCompanyDirectory, stableProductDirectory),
    );
  }

  static String? _profileIdFromArguments(List<String> arguments) {
    for (final argument in arguments) {
      if (argument.startsWith(profileArgumentPrefix)) {
        return argument.substring(profileArgumentPrefix.length);
      }
    }
    return null;
  }

  static Future<String?> _readActiveProfileId(Directory scope) async {
    final file = File(p.join(scope.path, activeProfileFileName));
    if (!await file.exists()) return null;
    try {
      final value = jsonDecode(await file.readAsString());
      if (value is! Map || value['profileId'] is! String) return null;
      final profile = _normalizeProfileId(value['profileId'] as String);
      return profile == (value['profileId'] as String) ? profile : null;
    } catch (_) {
      return null;
    }
  }

  static List<Directory> _standardLegacyCandidates({
    required List<Directory> supportBases,
    required Directory target,
    required bool includeDirectSupport,
  }) {
    final candidates = <Directory>[];
    for (final support in supportBases) {
      final base = support.path;
      candidates.addAll([
        // M5.6 DataRoot under the pre-brand Windows version resource.
        Directory(p.join(base, 'com.xaocen', 'xaocen_reader', 'xaocen_reader')),
        // Older M2/M3 support root layout.
        Directory(p.join(base, 'com.xaocen', 'xaocen_reader')),
        // The immediately previous branded ProductName-derived root.
        Directory(p.join(base, 'XAOCEN', 'XAOCEN Reader', 'xaocen_reader')),
        if (includeDirectSupport)
          // Test/tooling compatibility: a legacy root supplied directly.
          support,
      ]);
    }
    final seen = <String>{target.absolute.path.toLowerCase()};
    return candidates.where((candidate) {
      final key = candidate.absolute.path.toLowerCase();
      return seen.add(key);
    }).toList();
  }

  static List<Directory> _windowsRoamingBases() {
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.isEmpty) return const <Directory>[];
    final base = Directory(appData);
    final local = Platform.environment['LOCALAPPDATA'];
    if (local != null &&
        p.normalize(local).toLowerCase() ==
            p.normalize(appData).toLowerCase()) {
      return const <Directory>[];
    }
    return [base];
  }

  static String _normalizeProfileId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return defaultProfileId;
    final safe = trimmed
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (safe.isEmpty || safe == '.' || safe == '..') {
      return defaultProfileId;
    }
    return safe.length > 64 ? safe.substring(0, 64) : safe;
  }

  static Future<bool> _looksLikeDataRoot(Directory candidate) async {
    if (!await candidate.exists()) return false;
    final currentDb = File(
      p.join(candidate.path, 'database', 'xaocen_v4_local.sqlite'),
    );
    final legacyDb = File(p.join(candidate.path, 'xaocen_v4_local.sqlite'));
    final books = Directory(p.join(candidate.path, 'books'));
    final legacyBooks = Directory(p.join(candidate.path, 'library'));
    return await currentDb.exists() ||
        await legacyDb.exists() ||
        await books.exists() ||
        await legacyBooks.exists();
  }

  /// Copies the supported legacy layouts into the current root contract.
  /// Older builds used a root-level database and `library/`, while M5.6 used
  /// `database/` and `books/`. The mapping is intentionally explicit so a
  /// broad support directory is never copied recursively into itself.
  static Future<void> _copyLegacyDataRoot(
    Directory source,
    Directory target,
  ) async {
    await target.create(recursive: true);

    final currentDatabase = Directory(p.join(source.path, 'database'));
    final legacyDatabase = File(p.join(source.path, 'xaocen_v4_local.sqlite'));
    if (await currentDatabase.exists()) {
      await _copyDirectory(
        currentDatabase,
        Directory(p.join(target.path, 'database')),
      );
    } else if (await legacyDatabase.exists()) {
      final targetDatabase = Directory(p.join(target.path, 'database'));
      await targetDatabase.create(recursive: true);
      await legacyDatabase.copy(
        p.join(targetDatabase.path, 'xaocen_v4_local.sqlite'),
      );
      for (final suffix in const ['-wal', '-shm']) {
        final sidecar = File('${legacyDatabase.path}$suffix');
        if (await sidecar.exists()) {
          await sidecar.copy(
            p.join(targetDatabase.path, 'xaocen_v4_local.sqlite$suffix'),
          );
        }
      }
    }

    final currentBooks = Directory(p.join(source.path, 'books'));
    final legacyLibrary = Directory(p.join(source.path, 'library'));
    final sourceBooks = await currentBooks.exists()
        ? currentBooks
        : legacyLibrary;
    if (await sourceBooks.exists()) {
      await _copyDirectory(
        sourceBooks,
        Directory(p.join(target.path, 'books')),
      );
    }

    for (final name in const ['fonts', 'settings', 'backups']) {
      final directory = Directory(p.join(source.path, name));
      if (await directory.exists()) {
        await _copyDirectory(directory, Directory(p.join(target.path, name)));
      }
    }

    final sourceMetadata = File(p.join(source.path, metadataFileName));
    if (await sourceMetadata.exists()) {
      await sourceMetadata.copy(p.join(target.path, metadataFileName));
    }
  }

  static String _newRootId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory target, {
    Set<String> excludedNames = const <String>{},
  }) async {
    await target.create(recursive: true);
    await for (final entry in source.list(followLinks: false)) {
      final name = p.basename(entry.path);
      if (excludedNames.contains(name)) continue;
      final destination = p.join(target.path, name);
      if (entry is Directory) {
        await _copyDirectory(
          entry,
          Directory(destination),
          excludedNames: excludedNames,
        );
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
