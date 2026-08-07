import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../domain/library/library_entities.dart';
import '../../domain/library/library_import_models.dart';
import '../../domain/library/normalized_artifact.dart';
import '../../domain/local_txt/large_file_policy.dart';
import '../../domain/local_txt/pipeline_progress.dart';
import '../../domain/local_txt/text_encoding.dart';
import '../../domain/local_txt/txt_index.dart';
import '../database/app_database.dart';
import 'collection_repair_service.dart';
import 'encoding_index_provider.dart';
import 'library_file_manager.dart';
import 'managed_collection_health.dart';
import '../../sources/local_txt/txt_import_request.dart';
import '../../sources/local_txt/txt_import_service.dart';

/// 本地书库仓库 —— UI 唯一数据入口（UI 不直接访问 Drift）。
///
/// M1 TXT 管线通过依赖注入使用，不在此重实现扫描器。
/// 导入采用两阶段提交：prepared → filesCommitted → databaseCommitted → completed。
class LocalLibraryRepository {
  LocalLibraryRepository({
    required AppDatabase database,
    required LibraryFileManager fileManager,
    required this.encodingIndexProvider,
  }) : _db = database,
       _files = fileManager;

  final AppDatabase _db;
  final LibraryFileManager _files;
  final EncodingIndexProvider encodingIndexProvider;

  /// 数据库访问（repair 等外部服务需要）。
  AppDatabase get database => _db;

  /// 文件管理（repair 等外部服务需要）。
  LibraryFileManager get fileManager => _files;
  // ---- 稳定 ID 生成（确定性，非 UUID，不使用当前时间）----

  static String sourceIdFor(String hash) => 'local-txt-source:$hash';
  static String collectionIdFor(String hash) => 'local-txt:$hash';
  static String wholeItemIdFor(String hash) => 'local-txt:$hash:whole';
  static String chapterItemIdFor(String hash, int offset) =>
      'local-txt:$hash:chapter:$offset';
  static String documentIdFor(String hash, int offset) =>
      'local-txt:$hash:document:$offset';

  // ---- 导入 ----

  /// 导入 TXT 到书库。
  ///
  /// 流程：校验 → 大小策略 → 去重检查 → 两阶段提交
  /// （prepared → filesCommitted → databaseCommitted → completed）。
  Future<ImportTxtResult> importTxt(
    ImportTxtRequest request, {
    ImportProgressCallback? onProgress,
    ImportCancellationToken? token,
  }) async {
    final file = request.externalFile;
    final stopwatch = Stopwatch()..start();
    void emit(
      PipelinePhase phase, {
      String message = '',
      int? processed,
      int? total,
    }) {
      onProgress?.call(
        PipelineProgress(
          phase: phase,
          processedBytes: processed ?? 0,
          totalBytes: total ?? 0,
          elapsed: stopwatch.elapsed,
          message: message,
        ),
      );
    }

    _throwIfCancelled(token);
    emit(PipelinePhase.validatingFile, message: '校验文件');

    // 1. 存在性与大小
    if (!await file.exists()) {
      throw const LibraryException('file_not_found', '文件不存在');
    }
    final stat = await file.stat();
    if (stat.type == FileSystemEntityType.directory) {
      throw const LibraryException('not_a_file', '路径是目录');
    }
    final size = stat.size;
    if (size == 0) {
      throw const LibraryException('empty_file', '文件为空');
    }

    // 2. 大小策略
    final fileClass = LargeFilePolicy.classify(size);
    if (fileClass == LargeFileClass.unsupported) {
      throw LargeFileUnsupported(size);
    }
    if (fileClass == LargeFileClass.requiresConfirmation &&
        !request.confirmLargeFile) {
      throw LargeFileConfirmationRequired(size);
    }
    _throwIfCancelled(token);

    // 3. 内容身份（hash）
    emit(PipelinePhase.readingBytes, message: '读取文件', total: size);
    final bytes = await file.readAsBytes();
    final contentHash = sha256.convert(bytes).toString();
    _throwIfCancelled(token);

    // 4. 重复导入检测（§九：不能只凭 sourceHash 直接返回 alreadyImported）
    final existing = await findByContentHash(contentHash);
    if (existing != null) {
      // 执行 managed health check
      final health = await ManagedCollectionHealthCheck(
        database: _db,
        fileManager: _files,
      ).check(existing.id);
      if (health.ok) {
        // 健康：alreadyImported
        return ImportTxtResult(
          collection: existing,
          alreadyImported: true,
          outcome: ImportOutcome.alreadyImported,
        );
      }
      if (health.sourceOk) {
        // 不健康但 source.txt 有效：自动修复
        final repair = await CollectionRepairService(
          database: _db,
          fileManager: _files,
          encodingIndexProvider: encodingIndexProvider,
        ).repair(existing.id);
        if (repair.repaired) {
          return ImportTxtResult(
            collection: existing,
            alreadyImported: true,
            outcome: ImportOutcome.repairedExisting,
          );
        }
        throw LibraryException(
          'repair_failed',
          '已有书库记录需要修复但修复失败: ${repair.error}',
        );
      }
      // source.txt 也无效：corruptedManagedCopy，允许用户明确重新导入
      return ImportTxtResult(
        collection: existing,
        alreadyImported: true,
        outcome: ImportOutcome.corruptedManagedCopy,
      );
    }

    // 5. 两阶段提交
    final jobId =
        'job-${contentHash.substring(0, 12)}-${DateTime.now().microsecondsSinceEpoch}';
    var phase = 'prepared';
    try {
      final jobDir = await _files.createImportingJob(jobId);

      // 阶段 A：文件阶段
      phase = 'copying';
      emit(PipelinePhase.decoding, message: '复制原始文件');
      // source.txt 字节级副本
      final sourceFile = File(p.join(jobDir.path, 'source.txt'));
      await sourceFile.writeAsBytes(bytes, flush: true);
      // 验证 hash
      final sourceHash = sha256
          .convert(await sourceFile.readAsBytes())
          .toString();
      if (sourceHash != contentHash) {
        throw const LibraryException('hash_mismatch', '源文件副本 hash 不一致');
      }
      _throwIfCancelled(token);

      // 阶段 B：M1 索引管线
      phase = 'indexing';
      emit(PipelinePhase.detectingEncoding, message: '检测编码');
      final importServiceResult = await _runM1Pipeline(
        request.externalFile,
        jobDir,
        onProgress: onProgress,
        token: token,
        size: size,
      );
      _throwIfCancelled(token);

      // 阶段 C：文件提交（normalized.txt / index.json / manifest.json）
      phase = 'writingFiles';
      emit(PipelinePhase.writingCache, message: '写入派生文件');
      final artifact = await _writeDerivedFiles(
        jobDir: jobDir,
        index: importServiceResult.index,
        contentHash: contentHash,
        sourceHash: sourceHash,
        normalizedText: importServiceResult.normalizedText,
      );
      _throwIfCancelled(token);

      // 阶段 D：数据库提交（事务）
      phase = 'writingDatabase';
      emit(PipelinePhase.scanningToc, message: '写入书库');
      final collection = await _writeDatabase(
        jobDir: jobDir,
        index: importServiceResult.index,
        contentHash: contentHash,
        sourceHash: sourceHash,
        normalizedHash: artifact.sha256,
        originalFileName: file.uri.pathSegments.last,
        size: size,
      );
      _throwIfCancelled(token);

      // 阶段 E：原子移动（filesCommitted → completed）
      phase = 'filesCommitted';
      await _files.commitToContentDir(jobId, contentHash);
      // 最终校验：移动后重新读取 normalized.txt 验证 hash 一致
      final committed = _files.contentDir(contentHash);
      final committedNorm = File(p.join(committed.path, 'normalized.txt'));
      if (!await committedNorm.exists()) {
        throw const LibraryException(
          'normalized_missing_after_commit',
          '提交后 normalized.txt 不存在',
        );
      }
      final finalHash = sha256
          .convert(await committedNorm.readAsBytes())
          .toString();
      if (finalHash != artifact.sha256) {
        throw const LibraryException(
          'normalized_verify_failed',
          '提交后 normalized.txt hash 不一致',
        );
      }
      phase = 'completed';
      emit(PipelinePhase.completed, message: '导入完成');
      return ImportTxtResult(collection: collection, alreadyImported: false);
    } catch (e) {
      // 清理：临时目录 + 未完成数据库记录（若已写入）
      try {
        final jobDir = _files.importingJobDir(jobId);
        if (await jobDir.exists()) await jobDir.delete(recursive: true);
      } catch (_) {}
      try {
        if (phase == 'writingDatabase' || phase == 'filesCommitted') {
          final collection = await findByContentHash(contentHash);
          if (collection != null) {
            await removeCollection(collection.id, deleteManagedFiles: false);
          }
        }
      } catch (_) {}
      if (e is ImportCancelledException) rethrow;
      if (e is LibraryException) rethrow;
      throw LibraryException('import_failed', '导入失败: $e');
    }
  }

  /// 调用 M1 管线（缓存目录用 jobDir 内的 .m1cache 子目录，不入正式库）。
  /// 规范化文本经 [TxtImportService.onNormalizedText] 回调获取。
  Future<_M1PipelineResult> _runM1Pipeline(
    File externalFile,
    Directory jobDir, {
    ImportProgressCallback? onProgress,
    ImportCancellationToken? token,
    required int size,
  }) async {
    // M1 管线需要 GB18030 索引（由 provider 懒加载）
    final indexData = await encodingIndexProvider.load();
    String? normalizedText;
    final service = TxtImportService(
      encodingTableLoader: () async => indexData,
      onNormalizedText: (text) => normalizedText = text,
    );
    final result = await service.import(
      TxtImportRequest(
        file: externalFile,
        cacheDirectory: Directory(p.join(jobDir.path, '.m1cache')),
        allowLargeFileConfirmation: true,
        progressSink: (progress) {
          onProgress?.call(progress);
        },
      ),
      token: token,
    );
    if (normalizedText == null) {
      throw const LibraryException('normalized_missing', '规范化文本未生成');
    }
    return _M1PipelineResult(
      index: result.index,
      normalizedText: normalizedText!,
    );
  }

  /// 写入派生文件（唯一 hash 合同：hash 来自落盘字节）。
  ///
  /// 正确顺序（任务书 §六）：
  /// 1. 生成规范化文本（内存）；
  /// 2. 写 normalized.tmp（flush）；
  /// 3. 从落盘字节重新读取计算 SHA-256；
  /// 4. 重新解码验证 UTF-16 字符长度；
  /// 5. 原子 rename 为 normalized.txt；
  /// 6. 同一 NormalizedArtifact 写入 manifest；
  /// 7. 最终重读 normalized.txt 完整校验。
  Future<NormalizedArtifact> _writeDerivedFiles({
    required Directory jobDir,
    required TxtIndex index,
    required String contentHash,
    required String sourceHash,
    required String normalizedText,
  }) async {
    // 长度预校验（内存文本 vs 索引）
    if (normalizedText.length != index.normalizedCharacterLength) {
      throw const LibraryException('normalized_length_mismatch', '规范化长度与索引不一致');
    }

    // 1-2. 写 tmp（flush）
    final tmpFile = File(p.join(jobDir.path, 'normalized.tmp'));
    await tmpFile.writeAsBytes(utf8.encode(normalizedText), flush: true);

    // 3. 从落盘字节计算 hash（不信任内存 encode 结果）
    final bytes = await tmpFile.readAsBytes();
    final normalizedHash = sha256.convert(bytes).toString();

    // 4. 重新解码验证 UTF-16 长度
    final decoded = utf8.decode(bytes);
    if (decoded.length != index.normalizedCharacterLength) {
      throw const LibraryException(
        'normalized_length_mismatch',
        '落盘规范化长度与索引不一致',
      );
    }

    // 5. 原子 rename
    final normalizedFile = File(p.join(jobDir.path, 'normalized.txt'));
    await tmpFile.rename(normalizedFile.path);

    final artifact = NormalizedArtifact(
      filePath: normalizedFile.path,
      utf8ByteLength: bytes.length,
      utf16CharacterLength: decoded.length,
      sha256: normalizedHash,
      normalizationVersion: index.normalizationVersion,
    );

    // index.json（M1 TxtIndex 格式）
    final indexFile = File(p.join(jobDir.path, 'index.json'));
    await indexFile.writeAsString(index.encode(), flush: true);

    // 6. manifest.json —— 使用同一 artifact
    final manifest = <String, dynamic>{
      'manifestVersion': 1,
      'contentHash': contentHash,
      'originalFileName': index.sourceFileName,
      'sourceSize': index.sourceSize,
      'sourceHash': sourceHash,
      'normalizedHash': artifact.sha256,
      'normalizedUtf8ByteLength': artifact.utf8ByteLength,
      'detectedEncoding': index.encoding.name,
      'normalizedCharacterLength': artifact.utf16CharacterLength,
      'parserVersion': index.parserVersion,
      'normalizationVersion': artifact.normalizationVersion,
      'indexFormatVersion': index.indexFormatVersion,
      'importedAt': DateTime.now().toUtc().toIso8601String(),
    };
    final manifestFile = File(p.join(jobDir.path, 'manifest.json'));
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );

    // 7. 最终完整校验（重读 normalized.txt）
    final verifyBytes = await normalizedFile.readAsBytes();
    final verifyHash = sha256.convert(verifyBytes).toString();
    if (verifyHash != artifact.sha256) {
      throw const LibraryException(
        'normalized_verify_failed',
        '落盘 normalized.txt 校验失败',
      );
    }

    return artifact;
  }

  Future<LibraryCollection> _writeDatabase({
    required Directory jobDir,
    required TxtIndex index,
    required String contentHash,
    required String sourceHash,
    required String normalizedHash,
    required String originalFileName,
    required int size,
  }) async {
    final now = DateTime.now();
    final sourceId = sourceIdFor(contentHash);
    final collectionId = collectionIdFor(contentHash);
    final title = originalFileName.endsWith('.txt')
        ? originalFileName.substring(0, originalFileName.length - 4)
        : originalFileName;
    final sourcePath = p.join(
      'library',
      'local_txt',
      contentHash,
      'source.txt',
    );
    final normalizedPath = p.join(
      'library',
      'local_txt',
      contentHash,
      'normalized.txt',
    );

    final itemCount = index.chapterCount > 0 ? index.chapterCount : 1;
    final collection = LibraryCollection(
      id: collectionId,
      sourceId: sourceId,
      title: title,
      subtitle: null,
      itemCount: itemCount,
      normalizedCharacterLength: index.normalizedCharacterLength,
      detectedEncoding: index.encoding,
      sourceSize: size,
      importedAt: now,
    );

    await _db.transaction(() async {
      // source
      await _db
          .into(_db.contentSources)
          .insert(
            ContentSourcesCompanion.insert(
              id: sourceId,
              type: 'localTxt',
              displayName: originalFileName,
              contentHash: contentHash,
              managedSourcePath: sourcePath,
              sourceSize: size,
              detectedEncoding: index.encoding.name,
              createdAt: now,
              updatedAt: now,
            ),
          );
      // collection
      await _db
          .into(_db.contentCollections)
          .insert(
            ContentCollectionsCompanion.insert(
              id: collectionId,
              sourceId: sourceId,
              title: title,
              itemCount: itemCount,
              normalizedCharacterLength: index.normalizedCharacterLength,
              importedAt: now,
              updatedAt: now,
            ),
          );

      // items + documents
      final chapters = index.tocEntries.where((e) => e.isChapter).toList();
      if (chapters.isEmpty) {
        // whole item
        final itemId = wholeItemIdFor(contentHash);
        await _db
            .into(_db.contentItems)
            .insert(
              ContentItemsCompanion.insert(
                id: itemId,
                collectionId: collectionId,
                kind: 'whole',
                title: '全文',
                orderIndex: 1,
                startCharacterOffset: 0,
                endCharacterOffset: index.normalizedCharacterLength,
                createdAt: now,
              ),
            );
        await _db
            .into(_db.contentDocuments)
            .insert(
              ContentDocumentsCompanion.insert(
                id: documentIdFor(contentHash, 0),
                itemId: itemId,
                storagePath: normalizedPath,
                mediaType: 'text/plain; charset=utf-8',
                startCharacterOffset: 0,
                endCharacterOffset: index.normalizedCharacterLength,
                contentHash: normalizedHash,
                normalizationVersion: index.normalizationVersion,
              ),
            );
      } else {
        for (var i = 0; i < chapters.length; i++) {
          final c = chapters[i];
          final itemId = chapterItemIdFor(contentHash, c.startCharacterOffset);
          await _db
              .into(_db.contentItems)
              .insert(
                ContentItemsCompanion.insert(
                  id: itemId,
                  collectionId: collectionId,
                  kind: 'chapter',
                  title: c.title,
                  orderIndex: c.order,
                  startCharacterOffset: c.startCharacterOffset,
                  endCharacterOffset: c.endCharacterOffset,
                  createdAt: now,
                ),
              );
          await _db
              .into(_db.contentDocuments)
              .insert(
                ContentDocumentsCompanion.insert(
                  id: documentIdFor(contentHash, c.startCharacterOffset),
                  itemId: itemId,
                  storagePath: normalizedPath,
                  mediaType: 'text/plain; charset=utf-8',
                  startCharacterOffset: c.startCharacterOffset,
                  endCharacterOffset: c.endCharacterOffset,
                  contentHash: normalizedHash,
                  normalizationVersion: index.normalizationVersion,
                ),
              );
        }
      }

      // toc entries（卷 + 章）
      for (final e in index.tocEntries) {
        final String? itemId = e.isChapter
            ? chapterItemIdFor(contentHash, e.startCharacterOffset)
            : null;
        await _db
            .into(_db.tocEntries)
            .insert(
              TocEntriesCompanion.insert(
                id: '$collectionId:${e.id}',
                collectionId: collectionId,
                itemId: Value(itemId),
                parentId: Value(
                  e.parentId == null ? null : '$collectionId:${e.parentId}',
                ),
                kind: e.isVolume ? 'volume' : 'chapter',
                level: e.level,
                title: e.title,
                orderIndex: e.order,
                startCharacterOffset: e.startCharacterOffset,
                endCharacterOffset: e.endCharacterOffset,
              ),
            );
      }

      // import record
      await _db
          .into(_db.importRecords)
          .insert(
            ImportRecordsCompanion.insert(
              id: 'import:$sourceHash:${now.microsecondsSinceEpoch}',
              sourceHash: sourceHash,
              state: 'completed',
              startedAt: now,
              completedAt: Value(now),
            ),
          );
    });

    return collection;
  }

  // ---- 查询 ----

  Future<List<LibraryCollection>> listCollections() async {
    final rows = await (_db.select(
      _db.contentCollections,
    )..orderBy([(t) => OrderingTerm.desc(t.importedAt)])).get();
    final sources = await _db.select(_db.contentSources).get();
    final sourceById = {for (final s in sources) s.id: s};
    return rows.map((r) {
      final src = sourceById[r.sourceId];
      return LibraryCollection(
        id: r.id,
        sourceId: r.sourceId,
        title: r.title,
        subtitle: r.subtitle,
        itemCount: r.itemCount,
        normalizedCharacterLength: r.normalizedCharacterLength,
        detectedEncoding: TextEncoding.values.byName(
          src?.detectedEncoding ?? 'unknown',
        ),
        sourceSize: src?.sourceSize ?? 0,
        importedAt: r.importedAt,
      );
    }).toList();
  }

  Future<LibraryCollection?> getCollection(String id) async {
    final row = await (_db.select(
      _db.contentCollections,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final src = await (_db.select(
      _db.contentSources,
    )..where((t) => t.id.equals(row.sourceId))).getSingleOrNull();
    return LibraryCollection(
      id: row.id,
      sourceId: row.sourceId,
      title: row.title,
      subtitle: row.subtitle,
      itemCount: row.itemCount,
      normalizedCharacterLength: row.normalizedCharacterLength,
      detectedEncoding: TextEncoding.values.byName(
        src?.detectedEncoding ?? 'unknown',
      ),
      sourceSize: src?.sourceSize ?? 0,
      importedAt: row.importedAt,
    );
  }

  Future<List<LibraryItem>> getItems(String collectionId) async {
    final rows =
        await (_db.select(_db.contentItems)
              ..where((t) => t.collectionId.equals(collectionId))
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
            .get();
    return rows
        .map(
          (r) => LibraryItem(
            id: r.id,
            collectionId: r.collectionId,
            kind: r.kind,
            title: r.title,
            orderIndex: r.orderIndex,
            startCharacterOffset: r.startCharacterOffset,
            endCharacterOffset: r.endCharacterOffset,
          ),
        )
        .toList();
  }

  Future<List<LibraryTocEntry>> getToc(String collectionId) async {
    final rows =
        await (_db.select(_db.tocEntries)
              ..where((t) => t.collectionId.equals(collectionId))
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
            .get();
    return rows
        .map(
          (r) => LibraryTocEntry(
            id: r.id,
            collectionId: r.collectionId,
            itemId: r.itemId,
            parentId: r.parentId,
            kind: r.kind,
            level: r.level,
            title: r.title,
            orderIndex: r.orderIndex,
            startCharacterOffset: r.startCharacterOffset,
            endCharacterOffset: r.endCharacterOffset,
          ),
        )
        .toList();
  }

  Future<List<LibraryDocument>> getDocuments(String collectionId) async {
    final items = await (_db.select(
      _db.contentItems,
    )..where((t) => t.collectionId.equals(collectionId))).get();
    final itemIds = items.map((e) => e.id).toList();
    if (itemIds.isEmpty) return const [];
    final rows = await (_db.select(
      _db.contentDocuments,
    )..where((t) => t.itemId.isIn(itemIds))).get();
    return rows
        .map(
          (r) => LibraryDocument(
            id: r.id,
            itemId: r.itemId,
            storagePath: r.storagePath,
            mediaType: r.mediaType,
            startCharacterOffset: r.startCharacterOffset,
            endCharacterOffset: r.endCharacterOffset,
            contentHash: r.contentHash,
            normalizationVersion: r.normalizationVersion,
          ),
        )
        .toList();
  }

  /// 按内容 hash 查找（重复导入检测）。
  Future<LibraryCollection?> findByContentHash(String hash) async {
    final src = await (_db.select(
      _db.contentSources,
    )..where((t) => t.contentHash.equals(hash))).getSingleOrNull();
    if (src == null) return null;
    final row = await (_db.select(
      _db.contentCollections,
    )..where((t) => t.sourceId.equals(src.id))).getSingleOrNull();
    if (row == null) return null;
    return LibraryCollection(
      id: row.id,
      sourceId: row.sourceId,
      title: row.title,
      subtitle: row.subtitle,
      itemCount: row.itemCount,
      normalizedCharacterLength: row.normalizedCharacterLength,
      detectedEncoding: TextEncoding.values.byName(src.detectedEncoding),
      sourceSize: src.sourceSize,
      importedAt: row.importedAt,
    );
  }

  /// 删除 collection：级联删除 items/documents/toc + 清理应用管理文件目录。
  /// 不删除用户外部原 TXT。
  Future<void> removeCollection(
    String collectionId, {
    bool deleteManagedFiles = true,
  }) async {
    final collection = await getCollection(collectionId);
    if (collection == null) {
      throw const LibraryException('not_found', '书库记录不存在');
    }
    final hash = collection.id.replaceFirst('local-txt:', '');

    await _db.transaction(() async {
      // 级联删除（外键依赖顺序：documents → toc → items → collection → source）
      final itemIds = await (_db.select(
        _db.contentItems,
      )..where((t) => t.collectionId.equals(collectionId))).get();
      for (final item in itemIds) {
        await (_db.delete(
          _db.contentDocuments,
        )..where((t) => t.itemId.equals(item.id))).go();
      }
      // toc_entries.itemId 引用 content_items，必须先删 toc
      await (_db.delete(
        _db.tocEntries,
      )..where((t) => t.collectionId.equals(collectionId))).go();
      await (_db.delete(
        _db.contentItems,
      )..where((t) => t.collectionId.equals(collectionId))).go();
      await (_db.delete(
        _db.contentCollections,
      )..where((t) => t.id.equals(collectionId))).go();
      await (_db.delete(
        _db.contentSources,
      )..where((t) => t.id.equals(collection.sourceId))).go();
    });

    if (deleteManagedFiles) {
      await _files.deleteContentDir(hash);
    }
  }

  // ---- 辅助 ----

  void _throwIfCancelled(ImportCancellationToken? token) {
    if (token != null && token.isCancelled) {
      throw const ImportCancelledException();
    }
  }
}

/// M1 管线结果（仓库内部使用）。
class _M1PipelineResult {
  const _M1PipelineResult({required this.index, required this.normalizedText});

  final TxtIndex index;
  final String normalizedText;
}
