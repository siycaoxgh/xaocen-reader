import 'dart:io';

import 'package:path/path.dart' as p;

import 'library_file_manager.dart';

/// Owns imported Reader background images inside application-managed storage.
///
/// ReaderPreferences persists only the returned relative path. The source file
/// is copied before that reference is committed, so moving or deleting the
/// original never breaks an already imported background.
final class ReaderAppearanceAssetRepository {
  ReaderAppearanceAssetRepository({required this.fileManager});

  static const String managedPrefix = 'library/reader_backgrounds/';

  final LibraryFileManager fileManager;

  Future<String> importBackground({
    required String collectionId,
    required File source,
  }) async {
    if (!await source.exists()) {
      throw const ReaderAppearanceAssetException('background source missing');
    }
    final extension = p.extension(source.path).toLowerCase();
    if (!const {'.jpg', '.jpeg', '.png', '.webp', '.gif'}.contains(extension)) {
      throw const ReaderAppearanceAssetException('unsupported image format');
    }

    final collectionFolder = _safeCollectionFolder(collectionId);
    final relative =
        '$managedPrefix$collectionFolder/'
        'background_${DateTime.now().microsecondsSinceEpoch}$extension';
    final target = resolve(relative);
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.importing');
    try {
      await source.copy(temporary.path);
      await temporary.rename(target.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
    return relative;
  }

  File resolve(String relativePath) {
    final normalized = p.posix.normalize(relativePath.replaceAll('\\', '/'));
    if (!normalized.startsWith(managedPrefix) || normalized.contains('..')) {
      throw ReaderAppearanceAssetException(
        'unsafe managed background path: $relativePath',
      );
    }
    return fileManager.resolveStoragePath(normalized);
  }

  Future<void> deleteIfManaged(String? relativePath) async {
    if (relativePath == null) return;
    final target = resolve(relativePath);
    if (await target.exists()) await target.delete();
  }

  String _safeCollectionFolder(String collectionId) {
    final safe = collectionId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    if (safe.isEmpty) {
      throw const ReaderAppearanceAssetException('invalid collection id');
    }
    return safe;
  }
}

final class ReaderAppearanceAssetException implements Exception {
  const ReaderAppearanceAssetException(this.message);
  final String message;

  @override
  String toString() => 'ReaderAppearanceAssetException: $message';
}
