import 'dart:io';

/// 应用管理文件布局：
///
/// ```
/// <applicationSupport>/library/
/// ├── importing/<jobId>/        # 临时导入目录（两阶段提交中转）
/// │   ├── source.txt
/// │   ├── normalized.txt
/// │   ├── index.json
/// │   └── manifest.json
/// └── local_txt/<contentHash>/  # 正式目录（原子移动后）
///     ├── source.txt
///     ├── normalized.txt
///     ├── index.json
///     └── manifest.json
/// ```
class LibraryFileManager {
  LibraryFileManager({required this.libraryRoot});

  /// 应用管理 library 根目录（由 path_provider 提供，不硬编码）。
  final Directory libraryRoot;

  Directory get importingDir =>
      Directory('${libraryRoot.path}${Platform.pathSeparator}importing');
  Directory get localTxtDir =>
      Directory('${libraryRoot.path}${Platform.pathSeparator}local_txt');

  Directory importingJobDir(String jobId) =>
      Directory('${importingDir.path}${Platform.pathSeparator}$jobId');

  Directory contentDir(String contentHash) =>
      Directory('${localTxtDir.path}${Platform.pathSeparator}$contentHash');

  /// 解析 DB 中存储的相对路径（如 `library/local_txt/<hash>/normalized.txt`）
  /// 为绝对 File。
  ///
  /// storagePath 以 `library/` 开头（相对 applicationSupport），
  /// 而本 manager 的 [libraryRoot] 即 `<support>/library`，
  /// 因此要去掉 `library/` 前缀避免重复。
  File resolveStoragePath(String storagePath) {
    var rel = storagePath;
    const libraryPrefix = 'library/';
    if (rel.startsWith(libraryPrefix)) {
      rel = rel.substring(libraryPrefix.length);
    } else if (rel.startsWith('library\\')) {
      rel = rel.substring('library\\'.length);
    }
    if (rel.contains('..')) {
      throw LibraryFileException('unsafe storagePath: $storagePath');
    }
    return File('${libraryRoot.path}${Platform.pathSeparator}$rel');
  }

  /// 创建临时导入目录。
  Future<Directory> createImportingJob(String jobId) async {
    await importingDir.create(recursive: true);
    final dir = importingJobDir(jobId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    return dir;
  }

  /// 原子移动：临时目录 → 正式 contentHash 目录。
  /// 目标已存在时（重复导入竞态）删除目标后移动。
  Future<void> commitToContentDir(String jobId, String contentHash) async {
    final src = importingJobDir(jobId);
    if (!await src.exists()) {
      throw LibraryFileException('import job dir missing: $jobId');
    }
    final dst = contentDir(contentHash);
    if (await dst.exists()) {
      await dst.delete(recursive: true);
    }
    await localTxtDir.create(recursive: true);
    try {
      await src.rename(dst.path);
    } catch (_) {
      // 跨设备回退：复制后删除
      await _copyRecursive(src, dst);
      await src.delete(recursive: true);
    }
  }

  /// 清理未完成导入 job（启动时调用；只清 importing 下，不清正式目录）。
  Future<void> cleanupStaleImportingJobs() async {
    if (!await importingDir.exists()) return;
    await for (final e in importingDir.list()) {
      if (e is Directory) {
        try {
          await e.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  /// 删除正式 contentHash 目录（删除前安全校验）。
  Future<void> deleteContentDir(String contentHash) async {
    if (contentHash.isEmpty) {
      throw const LibraryFileException('refusing empty directory name');
    }
    if (contentHash.contains('..')) {
      throw const LibraryFileException('path traversal rejected');
    }
    final target = contentDir(contentHash);
    _assertSafeDelete(target);
    if (await target.exists()) {
      await target.delete(recursive: true);
    }
  }

  /// 删除前安全校验（任务书 §十二）：
  /// - 目标位于 library 根下；
  /// - 目录名与 contentHash 一致（32 位 hex）；
  /// - 不允许 .. 逃逸；
  /// - 不允许空路径；
  /// - 不允许删除 library 根本身。
  void _assertSafeDelete(Directory target) {
    final libraryPath = libraryRoot.resolveSymbolicLinksSync();
    final targetPath = target.resolveSymbolicLinksSync();
    if (!targetPath.startsWith(libraryPath + Platform.pathSeparator)) {
      throw LibraryFileException('unsafe delete path: $targetPath');
    }
    // Windows 下 Directory.uri.pathSegments 末尾有尾随空段，需过滤
    final segments = target.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .toList();
    final name = segments.isEmpty ? '' : segments.last;
    if (name.isEmpty) {
      throw const LibraryFileException('refusing empty directory name');
    }
    if (name == 'library' || name == 'importing' || name == 'local_txt') {
      throw LibraryFileException(
        'refusing to delete library root child: $name',
      );
    }
    if (name.contains('..')) {
      throw const LibraryFileException('path traversal rejected');
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(name)) {
      // contentHash 是 64 位 hex；也允许测试用的短 hash（>=8 hex）
      if (!RegExp(r'^[0-9a-f]{8,64}$').hasMatch(name)) {
        throw LibraryFileException('unexpected directory name: $name');
      }
    }
  }

  Future<void> _copyRecursive(Directory src, Directory dst) async {
    await dst.create(recursive: true);
    await for (final e in src.list()) {
      if (e is File) {
        final target = File(
          '${dst.path}${Platform.pathSeparator}${e.uri.pathSegments.last}',
        );
        await e.copy(target.path);
      } else if (e is Directory) {
        await _copyRecursive(
          e,
          Directory(
            '${dst.path}${Platform.pathSeparator}'
            '${e.uri.pathSegments.last}',
          ),
        );
      }
    }
  }
}

class LibraryFileException implements Exception {
  const LibraryFileException(this.message);
  final String message;

  @override
  String toString() => 'LibraryFileException: $message';
}
