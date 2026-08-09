import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/encoding_index_provider.dart';
import '../data/repositories/library_file_manager.dart';
import '../data/repositories/local_library_repository.dart';
import '../data/repositories/reading_progress_repository.dart';
import '../data/repositories/reader_bookmark_repository.dart';
import '../data/repositories/reader_preferences_repository.dart';
import '../data/repositories/reading_history_repository.dart';
import '../data/repositories/reading_session_repository.dart';
import '../domain/library/library_entities.dart';
import '../domain/library/library_import_models.dart';
import '../domain/reader/reading_history.dart';
import '../domain/local_txt/pipeline_progress.dart';
import '../reader/normalized_document_loader.dart';
import '../sources/local_txt/txt_cancellation.dart';

/// 数据库 Provider（懒加载）。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.forTesting();
  ref.onDispose(db.close);
  return db;
});

/// 文件管理 Provider（使用系统 support 目录下 library 根）。
final fileManagerProvider = Provider<LibraryFileManager>((ref) {
  // 正式路径由 AppDatabase.open 的目录推导；测试用内存库时覆盖。
  throw UnimplementedError('fileManagerProvider must be overridden');
});

/// GB18030 索引 Provider（Flutter AssetBundle 懒加载 + 进程内缓存）。
final encodingIndexProvider = Provider<EncodingIndexProvider>((ref) {
  return FlutterAssetEncodingIndexProvider();
});

/// 书库仓库 Provider。
final libraryRepositoryProvider = Provider<LocalLibraryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final files = ref.watch(fileManagerProvider);
  final enc = ref.watch(encodingIndexProvider);
  return LocalLibraryRepository(
    database: db,
    fileManager: files,
    encodingIndexProvider: enc,
  );
});

/// 书架集合列表（自动刷新）。
final collectionsProvider = FutureProvider<List<LibraryCollection>>((
  ref,
) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.listCollections();
});

/// 文档加载器 Provider（Reader 使用）。
final documentLoaderProvider = Provider<NormalizedDocumentLoader>((ref) {
  final files = ref.watch(fileManagerProvider);
  return NormalizedDocumentLoader(fileManager: files);
});

/// 阅读进度仓库 Provider。
final readingProgressRepositoryProvider = Provider<ReadingProgressRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return ReadingProgressRepository(db: db);
});

final readerBookmarkRepositoryProvider = Provider<ReaderBookmarkRepository>((
  ref,
) {
  return ReaderBookmarkRepository(db: ref.watch(databaseProvider));
});

final readerPreferencesRepositoryProvider =
    Provider<ReaderPreferencesRepository>((ref) {
      return ReaderPreferencesRepository(db: ref.watch(databaseProvider));
    });

final readingHistoryRepositoryProvider = Provider<ReadingHistoryRepository>((
  ref,
) {
  return ReadingHistoryRepository(db: ref.watch(databaseProvider));
});

final recentReadingProvider = FutureProvider<List<ReadingHistoryEntry>>((ref) {
  return ref
      .watch(readingHistoryRepositoryProvider)
      .loadRecentInLibrary(limit: 2);
});

final readingSessionRepositoryProvider = Provider<ReadingSessionRepository>((
  ref,
) {
  return ReadingSessionRepository(db: ref.watch(databaseProvider));
});

/// 导入进度状态。
class ImportProgressState {
  const ImportProgressState({
    this.running = false,
    this.progress,
    this.error,
    this.done = false,
    this.alreadyImported = false,
  });

  final bool running;
  final PipelineProgress? progress;
  final String? error;
  final bool done;
  final bool alreadyImported;

  ImportProgressState copyWith({
    bool? running,
    PipelineProgress? progress,
    String? error,
    bool? done,
    bool? alreadyImported,
  }) {
    return ImportProgressState(
      running: running ?? this.running,
      progress: progress ?? this.progress,
      error: error,
      done: done ?? this.done,
      alreadyImported: alreadyImported ?? this.alreadyImported,
    );
  }
}

final importProgressProvider =
    StateNotifierProvider<ImportProgressNotifier, ImportProgressState>(
      (ref) => ImportProgressNotifier(ref),
    );

class ImportProgressNotifier extends StateNotifier<ImportProgressState> {
  ImportProgressNotifier(this._ref) : super(const ImportProgressState());

  final Ref _ref;

  TxtImportCancellationToken? _token;
  File? _pendingFile;

  void cancel() {
    _token?.cancel();
  }

  /// 设置错误（UI 内部使用）。
  void setError(String message) {
    state = ImportProgressState(error: message);
  }

  /// 强制进入运行状态（widget 测试使用，不触发真实导入）。
  void forceRunning() {
    _token = TxtImportCancellationToken();
    state = ImportProgressState(
      running: true,
      progress: PipelineProgress(
        phase: PipelinePhase.decoding,
        processedBytes: 0,
        totalBytes: 100,
      ),
    );
  }

  /// 测试辅助：token 是否已取消。
  bool get debugTokenCancelled => _token?.isCancelled ?? false;

  /// 大文件确认后重试。
  void retryWithConfirmation() {
    final file = _pendingFile;
    if (file == null) return;
    start(ImportTxtRequest(externalFile: file, confirmLargeFile: true));
  }

  Future<void> start(ImportTxtRequest request) async {
    final repo = _ref.read(libraryRepositoryProvider);
    _token = TxtImportCancellationToken();
    _pendingFile = request.externalFile;
    state = const ImportProgressState(running: true);
    try {
      final result = await repo.importTxt(
        request,
        onProgress: (p) {
          state = state.copyWith(progress: p);
        },
        token: _token,
      );
      state = ImportProgressState(
        done: true,
        alreadyImported: result.alreadyImported,
      );
      _pendingFile = null;
      // 触发书架刷新
      _ref.invalidate(collectionsProvider);
    } on ImportCancelledException {
      state = const ImportProgressState(error: '导入已取消');
      _pendingFile = null;
    } on LargeFileConfirmationRequired {
      state = const ImportProgressState(
        error: 'large_file_confirmation_required',
      );
    } on LargeFileUnsupported catch (e) {
      state = ImportProgressState(error: '文件超过 50MB，不支持导入（${e.size} 字节）');
      _pendingFile = null;
    } on LibraryException catch (e) {
      state = ImportProgressState(error: e.message);
      _pendingFile = null;
    } catch (e) {
      state = ImportProgressState(error: '导入失败: $e');
      _pendingFile = null;
    }
  }
}
