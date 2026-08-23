import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'library_file_manager.dart';

/// Stores user-selected covers under app-managed library storage.
final class LocalBookCoverRepository {
  LocalBookCoverRepository({
    required AppDatabase database,
    required LibraryFileManager fileManager,
  }) : _db = database,
       _files = fileManager;

  static const prefix = 'library/covers/';
  final AppDatabase _db;
  final LibraryFileManager _files;

  Future<String> importCover({
    required String collectionId,
    required File source,
  }) async {
    if (!await source.exists()) throw const LocalBookCoverException('封面文件不存在');
    final extension = p.extension(source.path).toLowerCase();
    if (!const {'.jpg', '.jpeg', '.png', '.webp'}.contains(extension)) {
      throw const LocalBookCoverException('仅支持 JPG、PNG、WebP 封面');
    }
    final folder = _safeId(collectionId);
    final relative = '$prefix$folder/cover$extension';
    final target = _files.resolveStoragePath(relative);
    final existing = await (_db.select(
      _db.contentCollections,
    )..where((t) => t.id.equals(collectionId))).getSingleOrNull();
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.importing');
    await source.copy(temporary.path);
    if (await target.exists()) await target.delete();
    await temporary.rename(target.path);
    final oldPath = existing?.coverPath;
    if (oldPath != null && oldPath != relative && oldPath.startsWith(prefix)) {
      final oldFile = _files.resolveStoragePath(oldPath);
      if (await oldFile.exists()) await oldFile.delete();
    }
    await (_db.update(
      _db.contentCollections,
    )..where((t) => t.id.equals(collectionId))).write(
      ContentCollectionsCompanion(
        coverPath: Value(relative),
        coverSource: const Value('manual'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return relative;
  }

  Future<void> removeCover(String collectionId, String? relativePath) async {
    final existing = await (_db.select(
      _db.contentCollections,
    )..where((t) => t.id.equals(collectionId))).getSingleOrNull();
    if (relativePath != null && relativePath.startsWith(prefix)) {
      final file = _files.resolveStoragePath(relativePath);
      if (await file.exists()) await file.delete();
    }
    final source = existing == null
        ? null
        : await (_db.select(
            _db.contentSources,
          )..where((t) => t.id.equals(existing.sourceId))).getSingleOrNull();
    final automaticPath = await _resolveAutomaticEpubCover(
      source?.managedSourcePath,
    );
    await (_db.update(
      _db.contentCollections,
    )..where((t) => t.id.equals(collectionId))).write(
      ContentCollectionsCompanion(
        coverPath: Value(automaticPath),
        coverSource: Value(
          automaticPath == null ? 'placeholder' : 'autoDetected',
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  File? resolve(String? relativePath) {
    if (relativePath == null || !_isManagedCoverPath(relativePath)) {
      return null;
    }
    final file = _files.resolveStoragePath(relativePath);
    return file.existsSync() ? file : null;
  }

  Future<String?> _resolveAutomaticEpubCover(String? sourcePath) async {
    if (sourcePath == null || sourcePath.trim().isEmpty) return null;
    final normalized = sourcePath.replaceAll('\\', '/');
    final epubDirectory = p.posix.dirname(normalized);
    if (!epubDirectory.startsWith('library/epub/')) return null;
    for (final extension in const <String>[
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.gif',
    ]) {
      final relative = '$epubDirectory/cover$extension';
      if (await _files.resolveStoragePath(relative).exists()) return relative;
    }
    return null;
  }

  bool _isManagedCoverPath(String relativePath) {
    return relativePath.startsWith(prefix) ||
        relativePath.startsWith('library/epub/');
  }

  String _safeId(String id) {
    final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    if (safe.isEmpty) throw const LocalBookCoverException('无效书籍身份');
    return safe;
  }
}

final class LocalBookCoverException implements Exception {
  const LocalBookCoverException(this.message);
  final String message;
  @override
  String toString() => 'LocalBookCoverException: $message';
}
