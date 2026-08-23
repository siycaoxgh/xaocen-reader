import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../domain/library/library_entities.dart';
import '../../domain/library/metadata_source_priority.dart';
import '../../domain/library/library_import_models.dart';
import '../../domain/library/local_txt_metadata.dart';
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
import '../../sources/epub/epub_parser.dart';
import '../../sources/epub/epub_models.dart';
import '../../sources/epub/epub_reader_content_adapter.dart';
import '../../domain/reader/reader_rendering.dart';
import '../../domain/remote/web_source_contracts.dart';

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
  static String epubSourceIdFor(String hash) => 'epub-source:$hash';
  static String epubCollectionIdFor(String hash) => 'epub:$hash';
  static String epubItemIdFor(String hash, int index) =>
      'epub:$hash:item:$index';
  static String epubDocumentIdFor(String hash, int index) =>
      'epub:$hash:document:$index';
  static String webBookCollectionIdFor(String sourceId, String bookKey) =>
      'web-book:$sourceId:$bookKey';
  static String webBookSourceIdFor(String sourceId, String bookKey) =>
      'web-book-source:$sourceId:$bookKey';
  static String webBookStorageKeyFor(String collectionId) =>
      sha256.convert(utf8.encode(collectionId)).toString();

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

  /// 导入 EPUB 到现有 library/content 数据模型。
  ///
  /// EPUB 的 spine 文本会被展平到应用管理的 normalized.txt，章节/导航
  /// 仍保留为 content_items/toc_entries，Reader 因而继续使用同一
  /// NormalizedDocumentLoader、UTF-16 Locator 与 progress repository。
  /// 不新增 schema，也不修改外部 EPUB 文件。
  Future<ImportEpubResult> importEpub(ImportEpubRequest request) async {
    final file = request.externalFile;
    if (!await file.exists()) {
      throw const LibraryException('file_not_found', '文件不存在');
    }
    final stat = await file.stat();
    if (stat.type == FileSystemEntityType.directory || stat.size == 0) {
      throw const LibraryException('invalid_epub', 'EPUB 文件无效');
    }

    final bytes = await file.readAsBytes();
    final contentHash = sha256.convert(bytes).toString();
    final existing = await findByContentHash(contentHash);
    if (existing != null) {
      if (!existing.sourceId.startsWith('epub-source:')) {
        throw const LibraryException(
          'duplicate_content_identity',
          '内容身份与已有书籍冲突',
        );
      }
      if (await _epubManagedFilesHealthy(existing)) {
        return ImportEpubResult(
          collection: existing,
          alreadyImported: true,
          outcome: ImportOutcome.alreadyImported,
        );
      }
      return ImportEpubResult(
        collection: existing,
        alreadyImported: true,
        outcome: ImportOutcome.corruptedManagedCopy,
      );
    }

    final EpubBook book;
    try {
      book = const EpubParser().parseBytes(bytes);
    } on EpubParseException catch (e) {
      throw LibraryException('invalid_epub', e.message);
    }
    final sourceName = file.uri.pathSegments.isEmpty
        ? '未命名.epub'
        : file.uri.pathSegments.last;
    final sourceId = epubSourceIdFor(contentHash);
    final collectionId = epubCollectionIdFor(contentHash);
    final content = const EpubReaderContentAdapter().adaptBook(
      book: book,
      contentId: collectionId,
      sourceId: sourceId,
    );
    if (content.documents.isEmpty) {
      throw const LibraryException('invalid_epub', 'EPUB 没有可读正文');
    }

    final normalizedText = _joinEpubSpine(book);
    final normalizedBytes = utf8.encode(normalizedText);
    final normalizedHash = sha256.convert(normalizedBytes).toString();
    final parsedRendering = const EpubReaderContentAdapter().renderingForBook(
      book,
    );
    final imageAssetsByHref = <String, EpubAsset>{
      for (final asset in book.assets) asset.href: asset,
    };
    final persistedImages = <ReaderImagePlacement>[];
    String? persistedCoverPath;
    var persistedCoverSource = CoverSourcePriority.placeholder;
    final now = DateTime.now();
    final jobId =
        'epub-${contentHash.substring(0, 12)}-${now.microsecondsSinceEpoch}';
    final jobDir = await _files.createImportingJob(jobId);
    try {
      await File(
        p.join(jobDir.path, 'source.epub'),
      ).writeAsBytes(bytes, flush: true);
      await File(
        p.join(jobDir.path, 'normalized.txt'),
      ).writeAsBytes(normalizedBytes, flush: true);
      for (var index = 0; index < parsedRendering.images.length; index++) {
        final image = parsedRendering.images[index];
        final asset = imageAssetsByHref[image.storagePath];
        if (asset == null || asset.bytes.isEmpty) continue;
        final extension = _epubImageExtension(asset.mediaType, asset.href);
        // Persist storage paths with POSIX separators so a library imported
        // on Windows remains portable to Android/Linux.  Filesystem access
        // still uses the host-native join below.
        final relative = p.posix.join('images', '${index + 1}$extension');
        final imageFile = File(p.join(jobDir.path, relative));
        await imageFile.parent.create(recursive: true);
        await imageFile.writeAsBytes(asset.bytes, flush: true);
        persistedImages.add(
          ReaderImagePlacement(
            characterOffset: image.characterOffset,
            storagePath: 'library/epub/$contentHash/$relative',
            altText: image.altText,
            width: image.width,
            height: image.height,
          ),
        );
      }
      final coverHref = book.metadata.coverHref;
      final coverAsset = coverHref == null
          ? null
          : imageAssetsByHref[coverHref];
      if (coverAsset != null && coverAsset.bytes.isNotEmpty) {
        final extension = _epubImageExtension(
          coverAsset.mediaType,
          coverAsset.href,
        );
        final coverRelative = 'cover$extension';
        final coverFile = File(p.join(jobDir.path, coverRelative));
        await coverFile.writeAsBytes(coverAsset.bytes, flush: true);
        persistedCoverPath = 'library/epub/$contentHash/$coverRelative';
        persistedCoverSource = CoverSourcePriority.autoDetected;
      }
      final rendering = ReaderRenderingMetadata(
        styleRuns: parsedRendering.styleRuns,
        images: persistedImages,
      );
      final manifest = <String, dynamic>{
        'manifestVersion': 1,
        'contentHash': contentHash,
        'sourceHash': contentHash,
        'normalizedHash': normalizedHash,
        'normalizedCharacterLength': normalizedText.length,
        'normalizedUtf8ByteLength': normalizedBytes.length,
        'normalizationVersion': 'epub-text-v1',
        'originalFileName': sourceName,
        'sourceSize': stat.size,
        'mediaType': 'application/epub+zip',
        'parserVersion': 'epub-parser-v1',
        'cover': persistedCoverPath == null
            ? null
            : <String, String>{
                'href': book.metadata.coverHref!,
                'storagePath': persistedCoverPath,
                'source': persistedCoverSource,
              },
        'rendering': rendering.toJson(),
        'importedAt': now.toUtc().toIso8601String(),
      };
      await File(p.join(jobDir.path, 'manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest),
        flush: true,
      );

      final sourcePath = 'library/epub/$contentHash/source.epub';
      final normalizedPath = 'library/epub/$contentHash/normalized.txt';
      final metadata = content.metadata;
      final collection = LibraryCollection(
        id: collectionId,
        sourceId: sourceId,
        title: metadata.title.trim().isEmpty ? sourceName : metadata.title,
        subtitle: null,
        itemCount: content.navigation.isNotEmpty
            ? content.navigation.length
            : content.documents.length,
        normalizedCharacterLength: normalizedText.length,
        detectedEncoding: TextEncoding.utf8,
        sourceSize: stat.size,
        importedAt: now,
        author: metadata.author,
        description: metadata.description,
        metadataSource: metadata.titleSource == MetadataSourcePriority.fileName
            ? MetadataSourcePriority.fileName
            : MetadataSourcePriority.autoDetected,
        titleSource: metadata.titleSource,
        authorSource: metadata.authorSource,
        fileName: sourceName,
        sourcePath: sourcePath,
        coverPath: persistedCoverPath,
        coverSource: persistedCoverSource,
      );

      await _db.transaction(() async {
        await _db
            .into(_db.contentSources)
            .insert(
              ContentSourcesCompanion.insert(
                id: sourceId,
                type: 'epub',
                displayName: sourceName,
                contentHash: contentHash,
                managedSourcePath: sourcePath,
                sourceSize: stat.size,
                detectedEncoding: TextEncoding.utf8.name,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _db
            .into(_db.contentCollections)
            .insert(
              ContentCollectionsCompanion.insert(
                id: collectionId,
                sourceId: sourceId,
                title: collection.title,
                author: Value(collection.author),
                description: Value(collection.description),
                metadataSource: Value(collection.metadataSource),
                titleSource: Value(collection.titleSource),
                authorSource: Value(collection.authorSource),
                coverPath: Value(collection.coverPath),
                coverSource: Value(collection.coverSource),
                itemCount: collection.itemCount,
                normalizedCharacterLength: collection.normalizedCharacterLength,
                importedAt: now,
                updatedAt: now,
              ),
            );
        for (var index = 0; index < content.documents.length; index++) {
          final document = content.documents[index];
          final spine = book.spine[index];
          final itemTitle = spine.title.trim().isEmpty
              ? '第${index + 1}节'
              : spine.title;
          await _db
              .into(_db.contentItems)
              .insert(
                ContentItemsCompanion.insert(
                  id: document.itemId,
                  collectionId: collectionId,
                  kind: 'chapter',
                  title: itemTitle,
                  orderIndex: index + 1,
                  startCharacterOffset: document.startCharacterOffset,
                  endCharacterOffset: document.endCharacterOffset,
                  createdAt: now,
                ),
              );
          await _db
              .into(_db.contentDocuments)
              .insert(
                ContentDocumentsCompanion.insert(
                  id: document.id,
                  itemId: document.itemId,
                  storagePath: normalizedPath,
                  mediaType: document.mediaType,
                  startCharacterOffset: document.startCharacterOffset,
                  endCharacterOffset: document.endCharacterOffset,
                  contentHash: normalizedHash,
                  normalizationVersion: document.normalizationVersion,
                ),
              );
        }
        for (final entry in content.navigation) {
          await _db
              .into(_db.tocEntries)
              .insert(
                TocEntriesCompanion.insert(
                  id: entry.id,
                  collectionId: collectionId,
                  itemId: Value(entry.itemId),
                  parentId: Value(entry.parentId),
                  kind: entry.kind,
                  level: entry.level,
                  title: entry.title,
                  orderIndex: entry.orderIndex,
                  startCharacterOffset: entry.startCharacterOffset,
                  endCharacterOffset: entry.endCharacterOffset,
                ),
              );
        }
        await _db
            .into(_db.importRecords)
            .insert(
              ImportRecordsCompanion.insert(
                id: 'import:$contentHash:${now.microsecondsSinceEpoch}',
                sourceHash: contentHash,
                state: 'completed',
                startedAt: now,
                completedAt: Value(now),
              ),
            );
      });

      await _files.commitToEpubContentDir(jobId, contentHash);
      final normalizedFile = _files.resolveStoragePath(normalizedPath);
      final finalBytes = await normalizedFile.readAsBytes();
      if (sha256.convert(finalBytes).toString() != normalizedHash) {
        throw const LibraryException('normalized_verify_failed', 'EPUB 正文校验失败');
      }
      return ImportEpubResult(collection: collection, alreadyImported: false);
    } catch (e) {
      try {
        if (await jobDir.exists()) await jobDir.delete(recursive: true);
      } catch (_) {}
      try {
        if (await findByContentHash(contentHash) != null) {
          await removeCollection(collectionId, deleteManagedFiles: false);
        }
      } catch (_) {}
      if (e is LibraryException) rethrow;
      throw LibraryException('import_failed', 'EPUB 导入失败: $e');
    }
  }

  /// Persists a WebBook snapshot through the existing library tables.
  ///
  /// WebBook does not get a second database model: the runtime projection is
  /// flattened into one UTF-8 normalized document plus the same item/TOC
  /// ranges used by TXT and EPUB. The source identity includes both the
  /// registered source and book key, so adding the same book twice is a
  /// stable no-op while different books from one source remain distinct.
  Future<ImportWebBookResult> importWebBook(
    ImportWebBookRequest request,
  ) async {
    final source = request.source;
    final detail = request.detail;
    final projection = request.projection;
    final content = projection.content;
    if (content.documents.isEmpty || content.navigation.isEmpty) {
      throw const LibraryException('invalid_webbook', '书源没有可读章节');
    }
    if (content.identity.sourceId != source.id.value ||
        content.identity.contentId !=
            webBookCollectionIdFor(source.id.value, detail.bookKey)) {
      throw const LibraryException('invalid_webbook', '书源内容身份不一致');
    }

    final collectionId = content.identity.contentId;
    final persistedSourceId = webBookSourceIdFor(
      source.id.value,
      detail.bookKey,
    );
    final existing = await getCollection(collectionId);
    if (existing != null) {
      return ImportWebBookResult(collection: existing, alreadyImported: true);
    }

    final catalogEntries = request.catalogEntries == null
        ? content.navigation
              .where((entry) => entry.itemId != null)
              .map(
                (entry) => WebBookTocEntry(
                  chapterKey: _webBookChapterKeyFromItemId(entry.itemId!),
                  title: entry.title,
                  orderIndex: entry.orderIndex,
                  chapterUri: detail.detailUri,
                ),
              )
              .toList(growable: false)
        : List<WebBookTocEntry>.unmodifiable(request.catalogEntries!);
    if (catalogEntries.isEmpty) {
      throw const LibraryException('invalid_webbook', '书源目录为空');
    }
    final catalogKeys = <String>{};
    for (final entry in catalogEntries) {
      if (!catalogKeys.add(entry.chapterKey)) {
        throw const LibraryException('invalid_webbook', '书源目录包含重复章节');
      }
    }
    final cachedNavigation = content.navigation
        .where((entry) => entry.itemId != null)
        .toList(growable: false);
    for (final entry in cachedNavigation) {
      final key = _webBookChapterKeyFromItemId(entry.itemId!);
      if (!catalogKeys.contains(key)) {
        throw const LibraryException('invalid_webbook', '缓存章节不属于当前目录');
      }
    }
    final cachedByKey = <String, LibraryTocEntry>{
      for (final entry in cachedNavigation)
        _webBookChapterKeyFromItemId(entry.itemId!): entry,
    };

    final textParts = <String>[];
    for (final document in content.documents) {
      final text = projection.documentTextById[document.id];
      if (text == null) {
        throw const LibraryException('invalid_webbook', '章节正文缺失');
      }
      textParts.add(text);
    }
    final normalizedText = textParts.join('\n\n');
    if (normalizedText.isEmpty ||
        normalizedText.length != content.normalizedCharacterLength) {
      throw const LibraryException('invalid_webbook', '章节正文长度不一致');
    }

    final normalizedBytes = utf8.encode(normalizedText);
    final normalizedHash = sha256.convert(normalizedBytes).toString();
    final identityHash = sha256
        .convert(utf8.encode(persistedSourceId))
        .toString();
    final storageKey = webBookStorageKeyFor(collectionId);
    final normalizedPath = 'library/web_book/$storageKey/normalized.txt';
    final now = DateTime.now().toUtc();
    final jobId =
        'web-book-${storageKey.substring(0, 12)}-${now.microsecondsSinceEpoch}';
    final jobDir = await _files.createImportingJob(jobId);
    final title = detail.title.trim().isEmpty ? '未命名书籍' : detail.title.trim();
    final collection = LibraryCollection(
      id: collectionId,
      sourceId: persistedSourceId,
      title: title,
      subtitle: null,
      itemCount: catalogEntries.length,
      normalizedCharacterLength: normalizedText.length,
      detectedEncoding: TextEncoding.utf8,
      sourceSize: normalizedBytes.length,
      importedAt: now,
      author: detail.author,
      description: detail.description,
      metadataSource: 'autoDetected',
      titleSource: 'autoDetected',
      authorSource: detail.author == null ? 'unknown' : 'autoDetected',
      fileName: title,
      sourcePath: normalizedPath,
    );
    try {
      await File(
        p.join(jobDir.path, 'normalized.txt'),
      ).writeAsBytes(normalizedBytes, flush: true);
      await File(p.join(jobDir.path, 'manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'manifestVersion': 1,
          'sourceKind': 'webBook',
          'sourceId': source.id.value,
          'bookKey': detail.bookKey,
          'detailUri': detail.detailUri.toString(),
          'normalizedHash': normalizedHash,
          'normalizedCharacterLength': normalizedText.length,
          'normalizedUtf8ByteLength': normalizedBytes.length,
          'normalizationVersion': 'web-book-html-v1',
          'parserVersion': 'web-book-rule-engine-v1',
          'originalFileName': title,
          'sourceName': request.sourceName,
          'sourceEndpoint': source.endpoint.toString(),
          'cacheMode': catalogEntries.length == cachedByKey.length
              ? 'fullSnapshot'
              : 'chapterCache',
          'cachedChapterKeys': cachedByKey.keys.toList(growable: false),
          'totalChapterCount': catalogEntries.length,
          'toc': [
            for (final entry in catalogEntries)
              <String, Object?>{
                'chapterKey': entry.chapterKey,
                'title': entry.title,
                'orderIndex': entry.orderIndex,
                'chapterUri': entry.chapterUri.toString(),
              },
          ],
          'importedAt': now.toIso8601String(),
        }),
        flush: true,
      );

      final tocTitleByItemId = <String, String>{
        for (final entry in content.navigation)
          if (entry.itemId != null) entry.itemId!: entry.title,
      };
      await _db.transaction(() async {
        await _db
            .into(_db.contentSources)
            .insert(
              ContentSourcesCompanion.insert(
                id: persistedSourceId,
                type: 'webBook',
                displayName: title,
                contentHash: identityHash,
                managedSourcePath: normalizedPath,
                sourceSize: normalizedBytes.length,
                detectedEncoding: TextEncoding.utf8.name,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _db
            .into(_db.contentCollections)
            .insert(
              ContentCollectionsCompanion.insert(
                id: collectionId,
                sourceId: persistedSourceId,
                title: title,
                author: Value(detail.author),
                description: Value(detail.description),
                metadataSource: const Value('autoDetected'),
                titleSource: const Value('autoDetected'),
                authorSource: Value(
                  detail.author == null ? 'unknown' : 'autoDetected',
                ),
                itemCount: catalogEntries.length,
                normalizedCharacterLength: normalizedText.length,
                importedAt: now,
                updatedAt: now,
              ),
            );
        for (var index = 0; index < content.documents.length; index++) {
          final document = content.documents[index];
          await _db
              .into(_db.contentItems)
              .insert(
                ContentItemsCompanion.insert(
                  id: document.itemId,
                  collectionId: collectionId,
                  kind: 'chapter',
                  title: tocTitleByItemId[document.itemId] ?? '第${index + 1}章',
                  orderIndex: index,
                  startCharacterOffset: document.startCharacterOffset,
                  endCharacterOffset: document.endCharacterOffset,
                  createdAt: now,
                ),
              );
          await _db
              .into(_db.contentDocuments)
              .insert(
                ContentDocumentsCompanion.insert(
                  id: document.id,
                  itemId: document.itemId,
                  storagePath: normalizedPath,
                  mediaType: 'text/plain; charset=utf-8',
                  startCharacterOffset: document.startCharacterOffset,
                  endCharacterOffset: document.endCharacterOffset,
                  contentHash: normalizedHash,
                  normalizationVersion: 'web-book-html-v1',
                ),
              );
        }
        for (final entry in catalogEntries) {
          final cached = cachedByKey[entry.chapterKey];
          await _db
              .into(_db.tocEntries)
              .insert(
                TocEntriesCompanion.insert(
                  id: '$collectionId:toc:${entry.chapterKey}',
                  collectionId: collectionId,
                  itemId: Value(cached?.itemId),
                  parentId: const Value(null),
                  kind: 'chapter',
                  level: 0,
                  title: entry.title,
                  orderIndex: entry.orderIndex,
                  startCharacterOffset: cached?.startCharacterOffset ?? 0,
                  endCharacterOffset: cached?.endCharacterOffset ?? 0,
                ),
              );
        }
        await _db
            .into(_db.importRecords)
            .insert(
              ImportRecordsCompanion.insert(
                id: 'import:$identityHash:${now.microsecondsSinceEpoch}',
                sourceHash: identityHash,
                state: 'completed',
                startedAt: now,
                completedAt: Value(now),
              ),
            );
      });
      await _files.commitToWebBookContentDir(jobId, storageKey);
      final finalFile = _files.resolveStoragePath(normalizedPath);
      final finalBytes = await finalFile.readAsBytes();
      if (sha256.convert(finalBytes).toString() != normalizedHash) {
        throw const LibraryException(
          'normalized_verify_failed',
          'WebBook 正文校验失败',
        );
      }
      return ImportWebBookResult(
        collection: collection,
        alreadyImported: false,
      );
    } catch (error) {
      try {
        if (await jobDir.exists()) await jobDir.delete(recursive: true);
      } catch (_) {}
      try {
        if (await getCollection(collectionId) != null) {
          await removeCollection(collectionId, deleteManagedFiles: false);
        }
      } catch (_) {}
      if (error is LibraryException) rethrow;
      throw LibraryException('import_webbook_failed', 'WebBook 加入书架失败: $error');
    }
  }

  /// Compares a persisted WebBook snapshot with a freshly fetched source TOC.
  ///
  /// Existing chapter ranges are deliberately treated as immutable.  The
  /// current product contract therefore accepts append-only source changes;
  /// removal or insertion before a persisted chapter returns `failed` rather
  /// than rewriting the normalized text and invalidating UTF-16 offsets.
  Future<WebBookUpdatePlan> planWebBookUpdate({
    required String collectionId,
    required WebBookTableOfContents toc,
  }) async {
    final collection = await getCollection(collectionId);
    if (collection == null) {
      throw const LibraryException('not_found', '书库记录不存在');
    }
    if (!collection.sourceId.startsWith('web-book-source:')) {
      throw const LibraryException('not_webbook', '该书不是在线书源书籍');
    }

    final items = await getItems(collectionId);
    final persistedKeys = <String>[];
    final itemPrefix = '$collectionId:item:';
    for (final item in items) {
      if (!item.id.startsWith(itemPrefix)) {
        return WebBookUpdatePlan(
          collection: collection,
          status: WebBookUpdateStatus.failed,
          newEntries: const [],
          message: '已有章节 identity 无法识别，未执行更新',
        );
      }
      final key = item.id.substring(itemPrefix.length);
      if (key.isEmpty || persistedKeys.contains(key)) {
        return WebBookUpdatePlan(
          collection: collection,
          status: WebBookUpdateStatus.failed,
          newEntries: const [],
          message: '已有章节 identity 重复，未执行更新',
        );
      }
      persistedKeys.add(key);
    }

    final sourceEntries = toc.entries;
    final sourceKeys = <String>{};
    for (final entry in sourceEntries) {
      if (!sourceKeys.add(entry.chapterKey)) {
        return WebBookUpdatePlan(
          collection: collection,
          status: WebBookUpdateStatus.failed,
          newEntries: const [],
          message: '来源目录包含重复章节，未执行更新',
        );
      }
    }
    var previousIndex = -1;
    for (final key in persistedKeys) {
      final index = sourceEntries.indexWhere(
        (entry) => entry.chapterKey == key,
      );
      if (index < 0 || index <= previousIndex) {
        return WebBookUpdatePlan(
          collection: collection,
          status: WebBookUpdateStatus.failed,
          newEntries: const [],
          message: '来源目录删除或移动了已有章节，未执行更新',
        );
      }
      previousIndex = index;
    }
    final newEntries = sourceEntries
        .where((entry) => !persistedKeys.contains(entry.chapterKey))
        .toList(growable: false);
    if (newEntries.isEmpty) {
      return WebBookUpdatePlan(
        collection: collection,
        status: WebBookUpdateStatus.noChanges,
        newEntries: const [],
        message: '当前已是最新章节',
      );
    }
    // New chapters must be after every persisted chapter.  This keeps all
    // existing offsets stable without silently changing source order.
    if (newEntries.any(
      (entry) => sourceEntries.indexOf(entry) <= previousIndex,
    )) {
      return WebBookUpdatePlan(
        collection: collection,
        status: WebBookUpdateStatus.failed,
        newEntries: const [],
        message: '来源新增章节位于已有章节之前，未执行更新',
      );
    }
    return WebBookUpdatePlan(
      collection: collection,
      status: WebBookUpdateStatus.updated,
      newEntries: newEntries,
      message: '发现 ${newEntries.length} 个新章节',
    );
  }

  /// Appends the chapters from a validated [WebBookUpdatePlan].
  ///
  /// The file and existing document rows keep their original prefix and
  /// offsets.  Only the new suffix is written and indexed, so progress,
  /// bookmarks and ReaderPreferences remain valid without a schema change.
  Future<WebBookUpdateResult> updateWebBook({
    required WebBookUpdatePlan plan,
    required List<WebBookChapter> chapters,
    required WebBookTableOfContents toc,
  }) async {
    if (plan.status == WebBookUpdateStatus.noChanges) {
      return WebBookUpdateResult(
        collection: plan.collection,
        status: WebBookUpdateStatus.noChanges,
        addedChapterCount: 0,
        message: plan.message ?? '当前已是最新章节',
      );
    }
    if (plan.status == WebBookUpdateStatus.failed) {
      return WebBookUpdateResult(
        collection: plan.collection,
        status: WebBookUpdateStatus.failed,
        addedChapterCount: 0,
        message: plan.message ?? '无法安全更新书籍',
      );
    }
    if (chapters.length != plan.newEntries.length) {
      throw const LibraryException('invalid_webbook_update', '新章节数量不一致');
    }
    final expectedKeys = plan.newEntries.map((entry) => entry.chapterKey);
    final actualKeys = chapters.map((chapter) => chapter.entry.chapterKey);
    if (!_sameStrings(expectedKeys, actualKeys)) {
      throw const LibraryException(
        'invalid_webbook_update',
        '新章节顺序或 identity 不一致',
      );
    }
    final collection = plan.collection;
    final sourcePath = collection.sourcePath;
    if (sourcePath == null || !sourcePath.endsWith('/normalized.txt')) {
      throw const LibraryException('source_missing', '找不到在线书籍正文快照');
    }
    final normalizedFile = _files.resolveStoragePath(sourcePath);
    if (!await normalizedFile.exists()) {
      throw const LibraryException('source_missing', '找不到在线书籍正文快照');
    }
    final oldBytes = await normalizedFile.readAsBytes();
    final oldText = utf8.decode(oldBytes);
    if (oldText.length != collection.normalizedCharacterLength) {
      throw const LibraryException('invalid_webbook_update', '现有正文快照长度不一致');
    }

    final text = StringBuffer(oldText);
    final newRanges = <({WebBookChapter chapter, int start, int end})>[];
    for (final chapter in chapters) {
      final body = chapter.body.canonical.text;
      if (body.trim().isEmpty) {
        throw const LibraryException('invalid_webbook_update', '新章节正文为空');
      }
      if (text.isNotEmpty) text.write('\n\n');
      final start = text.length;
      text.write(body);
      newRanges.add((chapter: chapter, start: start, end: text.length));
    }
    final normalizedText = text.toString();
    final normalizedBytes = utf8.encode(normalizedText);
    final normalizedHash = sha256.convert(normalizedBytes).toString();
    final now = DateTime.now().toUtc();
    final existingItemIds =
        (await (_db.select(
              _db.contentItems,
            )..where((item) => item.collectionId.equals(collection.id))).get())
            .map((item) => item.id)
            .toList(growable: false);
    try {
      await normalizedFile.writeAsBytes(normalizedBytes, flush: true);
      await _db.transaction(() async {
        await (_db.update(
          _db.contentDocuments,
        )..where((document) => document.itemId.isIn(existingItemIds))).write(
          ContentDocumentsCompanion(contentHash: Value(normalizedHash)),
        );

        for (var index = 0; index < newRanges.length; index++) {
          final range = newRanges[index];
          final entry = range.chapter.entry;
          final itemId = '${collection.id}:item:${entry.chapterKey}';
          final documentId =
              '${collection.id}:document:${collection.itemCount + index}';
          await _db
              .into(_db.contentItems)
              .insert(
                ContentItemsCompanion.insert(
                  id: itemId,
                  collectionId: collection.id,
                  kind: 'chapter',
                  title: entry.title,
                  orderIndex: entry.orderIndex,
                  startCharacterOffset: range.start,
                  endCharacterOffset: range.end,
                  createdAt: now,
                ),
              );
          await _db
              .into(_db.contentDocuments)
              .insert(
                ContentDocumentsCompanion.insert(
                  id: documentId,
                  itemId: itemId,
                  storagePath: sourcePath,
                  mediaType: 'text/plain; charset=utf-8',
                  startCharacterOffset: range.start,
                  endCharacterOffset: range.end,
                  contentHash: normalizedHash,
                  normalizationVersion: 'web-book-html-v1',
                ),
              );
          await _db
              .into(_db.tocEntries)
              .insert(
                TocEntriesCompanion.insert(
                  id: '${collection.id}:toc:${entry.chapterKey}',
                  collectionId: collection.id,
                  itemId: Value(itemId),
                  parentId: const Value(null),
                  kind: 'chapter',
                  level: 0,
                  title: entry.title,
                  orderIndex: entry.orderIndex,
                  startCharacterOffset: range.start,
                  endCharacterOffset: range.end,
                ),
              );
        }
        await (_db.update(
          _db.contentCollections,
        )..where((item) => item.id.equals(collection.id))).write(
          ContentCollectionsCompanion(
            itemCount: Value(collection.itemCount + newRanges.length),
            normalizedCharacterLength: Value(normalizedText.length),
            updatedAt: Value(now),
          ),
        );
        await (_db.update(
          _db.contentSources,
        )..where((source) => source.id.equals(collection.sourceId))).write(
          ContentSourcesCompanion(
            sourceSize: Value(normalizedBytes.length),
            updatedAt: Value(now),
          ),
        );
        await _db
            .into(_db.importRecords)
            .insert(
              ImportRecordsCompanion.insert(
                id: 'webbook-update:${collection.id}:${now.microsecondsSinceEpoch}',
                sourceHash: sha256
                    .convert(utf8.encode(collection.sourceId))
                    .toString(),
                state: 'completed',
                startedAt: now,
                completedAt: Value(now),
              ),
            );
      });
      try {
        await _updateWebBookManifest(
          normalizedFile: normalizedFile,
          normalizedHash: normalizedHash,
          normalizedTextLength: normalizedText.length,
          normalizedByteLength: normalizedBytes.length,
          chapterCount: collection.itemCount + newRanges.length,
          sourceRevision: toc.sourceRevision,
          updatedAt: now,
        );
      } catch (_) {
        // The normalized file and database are the Reader truth. A manifest
        // is diagnostic metadata; a write failure must not roll back a valid
        // append after the transaction has committed.
      }
    } catch (error) {
      try {
        await normalizedFile.writeAsBytes(oldBytes, flush: true);
      } catch (_) {}
      if (error is LibraryException) rethrow;
      throw LibraryException('webbook_update_failed', '在线书籍更新失败: $error');
    }
    final updated = await getCollection(collection.id);
    if (updated == null) {
      throw const LibraryException('webbook_update_failed', '更新后书籍记录不存在');
    }
    return WebBookUpdateResult(
      collection: updated,
      status: WebBookUpdateStatus.updated,
      addedChapterCount: newRanges.length,
      message: '已新增 ${newRanges.length} 个章节',
    );
  }

  /// Appends a contiguous, source-ordered prefix of chapters fetched on
  /// demand. Unlike the refresh path, this method never assumes that the
  /// collection item count equals the number of cached rows (the catalog may
  /// already contain the full remote chapter count). Existing normalized text
  /// is kept byte-for-byte as a prefix, so all existing UTF-16 offsets remain
  /// valid.
  Future<WebBookUpdateResult> appendWebBookChapterCache({
    required String collectionId,
    required List<WebBookChapter> chapters,
    required WebBookTableOfContents toc,
  }) async {
    if (chapters.isEmpty) {
      final collection = await getCollection(collectionId);
      if (collection == null) {
        throw const LibraryException('not_found', '书库记录不存在');
      }
      return WebBookUpdateResult(
        collection: collection,
        status: WebBookUpdateStatus.noChanges,
        addedChapterCount: 0,
        message: '章节已在本地缓存',
      );
    }
    final collection = await getCollection(collectionId);
    if (collection == null) {
      throw const LibraryException('not_found', '书库记录不存在');
    }
    if (!collection.sourceId.startsWith('web-book-source:')) {
      throw const LibraryException('not_webbook', '该书不是在线书源书籍');
    }
    final sourcePath = collection.sourcePath;
    if (sourcePath == null || !sourcePath.endsWith('/normalized.txt')) {
      throw const LibraryException('source_missing', '找不到在线书籍正文快照');
    }
    final normalizedFile = _files.resolveStoragePath(sourcePath);
    if (!await normalizedFile.exists()) {
      throw const LibraryException('source_missing', '找不到在线书籍正文快照');
    }

    final persistedItems = await getItems(collectionId);
    final persistedKeys = <String>[];
    final itemPrefix = '$collectionId:item:';
    for (final item in persistedItems) {
      if (!item.id.startsWith(itemPrefix)) {
        throw const LibraryException(
          'invalid_webbook_cache',
          '已有缓存章节 identity 无法识别',
        );
      }
      persistedKeys.add(item.id.substring(itemPrefix.length));
    }
    final sourceEntries = toc.entries;
    if (persistedKeys.length > sourceEntries.length) {
      throw const LibraryException('invalid_webbook_cache', '缓存章节数量超过来源目录');
    }
    for (var index = 0; index < persistedKeys.length; index++) {
      if (persistedKeys[index] != sourceEntries[index].chapterKey) {
        throw const LibraryException(
          'invalid_webbook_cache',
          '来源目录顺序发生变化，未改写现有正文快照',
        );
      }
    }
    final expected = sourceEntries
        .skip(persistedKeys.length)
        .take(chapters.length)
        .toList(growable: false);
    if (expected.length != chapters.length ||
        !_sameStrings(
          expected.map((entry) => entry.chapterKey),
          chapters.map((chapter) => chapter.entry.chapterKey),
        )) {
      throw const LibraryException(
        'invalid_webbook_cache',
        '按需章节必须按来源目录顺序连续写入',
      );
    }

    final oldBytes = await normalizedFile.readAsBytes();
    final oldText = utf8.decode(oldBytes);
    if (oldText.length != collection.normalizedCharacterLength) {
      throw const LibraryException('invalid_webbook_cache', '现有正文快照长度不一致');
    }
    final text = StringBuffer(oldText);
    final newRanges = <({WebBookChapter chapter, int start, int end})>[];
    for (final chapter in chapters) {
      final body = chapter.body.canonical.text.trim();
      if (body.isEmpty) {
        throw const LibraryException('invalid_webbook_cache', '章节正文为空，未写入缓存');
      }
      if (text.isNotEmpty) text.write('\n\n');
      final start = text.length;
      text.write(body);
      newRanges.add((chapter: chapter, start: start, end: text.length));
    }
    final normalizedText = text.toString();
    final normalizedBytes = utf8.encode(normalizedText);
    final normalizedHash = sha256.convert(normalizedBytes).toString();
    final now = DateTime.now().toUtc();
    final existingItemIds = persistedItems
        .map((item) => item.id)
        .toList(growable: false);
    try {
      await normalizedFile.writeAsBytes(normalizedBytes, flush: true);
      await _db.transaction(() async {
        if (existingItemIds.isNotEmpty) {
          await (_db.update(
            _db.contentDocuments,
          )..where((document) => document.itemId.isIn(existingItemIds))).write(
            ContentDocumentsCompanion(contentHash: Value(normalizedHash)),
          );
        }
        for (final range in newRanges) {
          final entry = range.chapter.entry;
          final itemId = '$collectionId:item:${entry.chapterKey}';
          final documentId = '$collectionId:document:${entry.orderIndex}';
          await _db
              .into(_db.contentItems)
              .insert(
                ContentItemsCompanion.insert(
                  id: itemId,
                  collectionId: collectionId,
                  kind: 'chapter',
                  title: entry.title,
                  orderIndex: entry.orderIndex,
                  startCharacterOffset: range.start,
                  endCharacterOffset: range.end,
                  createdAt: now,
                ),
              );
          await _db
              .into(_db.contentDocuments)
              .insert(
                ContentDocumentsCompanion.insert(
                  id: documentId,
                  itemId: itemId,
                  storagePath: sourcePath,
                  mediaType: 'text/plain; charset=utf-8',
                  startCharacterOffset: range.start,
                  endCharacterOffset: range.end,
                  contentHash: normalizedHash,
                  normalizationVersion: 'web-book-html-v1',
                ),
              );
          await (_db.update(_db.tocEntries)..where(
                (tocEntry) =>
                    tocEntry.id.equals('$collectionId:toc:${entry.chapterKey}'),
              ))
              .write(
                TocEntriesCompanion(
                  itemId: Value(itemId),
                  startCharacterOffset: Value(range.start),
                  endCharacterOffset: Value(range.end),
                ),
              );
        }
        await (_db.update(
          _db.contentCollections,
        )..where((item) => item.id.equals(collectionId))).write(
          ContentCollectionsCompanion(
            // itemCount is the full source catalog count and must not be
            // inflated every time a cached suffix is appended.
            itemCount: Value(collection.itemCount),
            normalizedCharacterLength: Value(normalizedText.length),
            updatedAt: Value(now),
          ),
        );
        await (_db.update(
          _db.contentSources,
        )..where((source) => source.id.equals(collection.sourceId))).write(
          ContentSourcesCompanion(
            sourceSize: Value(normalizedBytes.length),
            updatedAt: Value(now),
          ),
        );
        await _db
            .into(_db.importRecords)
            .insert(
              ImportRecordsCompanion.insert(
                id: 'webbook-cache:$collectionId:${now.microsecondsSinceEpoch}',
                sourceHash: sha256
                    .convert(utf8.encode(collection.sourceId))
                    .toString(),
                state: 'completed',
                startedAt: now,
                completedAt: Value(now),
              ),
            );
      });
      await _updateWebBookManifest(
        normalizedFile: normalizedFile,
        normalizedHash: normalizedHash,
        normalizedTextLength: normalizedText.length,
        normalizedByteLength: normalizedBytes.length,
        chapterCount: collection.itemCount,
        sourceRevision: toc.sourceRevision,
        updatedAt: now,
        cachedChapterKeys: [
          ...persistedKeys,
          ...chapters.map((chapter) => chapter.entry.chapterKey),
        ],
        totalChapterCount: sourceEntries.length,
      );
    } catch (error) {
      try {
        await normalizedFile.writeAsBytes(oldBytes, flush: true);
      } catch (_) {}
      if (error is LibraryException) rethrow;
      throw LibraryException('webbook_cache_failed', '章节缓存写入失败: $error');
    }
    final updated = await getCollection(collectionId);
    if (updated == null) {
      throw const LibraryException('webbook_cache_failed', '缓存后书籍记录不存在');
    }
    return WebBookUpdateResult(
      collection: updated,
      status: WebBookUpdateStatus.updated,
      addedChapterCount: chapters.length,
      message: '已缓存 ${chapters.length} 个章节',
    );
  }

  /// Reads the persisted source/book identity without adding a WebBook table.
  Future<WebBookSnapshotMetadata> getWebBookSnapshotMetadata(
    String collectionId,
  ) async {
    final collection = await getCollection(collectionId);
    if (collection == null) {
      throw const LibraryException('not_found', '书库记录不存在');
    }
    final sourcePath = collection.sourcePath;
    if (sourcePath == null || !sourcePath.endsWith('/normalized.txt')) {
      throw const LibraryException('source_missing', '找不到在线书籍快照信息');
    }
    final normalizedFile = _files.resolveStoragePath(sourcePath);
    final manifest = File(
      p.join(p.dirname(normalizedFile.path), 'manifest.json'),
    );
    if (!await manifest.exists()) {
      throw const LibraryException('source_missing', '在线书籍缺少书源更新信息');
    }
    final decoded = jsonDecode(await manifest.readAsString());
    if (decoded is! Map ||
        decoded['sourceId'] is! String ||
        decoded['bookKey'] is! String ||
        decoded['detailUri'] is! String) {
      throw const LibraryException('source_missing', '在线书籍书源更新信息不完整');
    }
    final detailUri = Uri.tryParse(decoded['detailUri'] as String);
    if (detailUri == null || detailUri.scheme.isEmpty) {
      throw const LibraryException('source_missing', '在线书籍详情地址无效');
    }
    return WebBookSnapshotMetadata(
      sourceId: decoded['sourceId'] as String,
      bookKey: decoded['bookKey'] as String,
      detailUri: detailUri,
      sourceName: decoded['sourceName'] is String
          ? decoded['sourceName'] as String
          : null,
      sourceEndpoint: decoded['sourceEndpoint'] is String
          ? Uri.tryParse(decoded['sourceEndpoint'] as String)
          : null,
      cacheMode: decoded['cacheMode'] is String
          ? decoded['cacheMode'] as String
          : 'fullSnapshot',
      cachedChapterKeys: decoded['cachedChapterKeys'] is List
          ? [
              for (final key in decoded['cachedChapterKeys'] as List)
                if (key is String) key,
            ]
          : const <String>[],
      totalChapterCount: decoded['totalChapterCount'] is int
          ? decoded['totalChapterCount'] as int
          : null,
      catalog: _manifestCatalog(decoded['toc']),
    );
  }

  List<WebBookTocEntry> _manifestCatalog(Object? value) {
    if (value is! List) return const <WebBookTocEntry>[];
    final result = <WebBookTocEntry>[];
    for (final item in value) {
      if (item is! Map) continue;
      final key = item['chapterKey'];
      final title = item['title'];
      final orderIndex = item['orderIndex'];
      final uri = item['chapterUri'];
      if (key is! String ||
          title is! String ||
          orderIndex is! int ||
          uri is! String) {
        continue;
      }
      final chapterUri = Uri.tryParse(uri);
      if (chapterUri == null || chapterUri.scheme.isEmpty) continue;
      result.add(
        WebBookTocEntry(
          chapterKey: key,
          title: title,
          orderIndex: orderIndex,
          chapterUri: chapterUri,
        ),
      );
    }
    result.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return List.unmodifiable(result);
  }

  Future<void> _updateWebBookManifest({
    required File normalizedFile,
    required String normalizedHash,
    required int normalizedTextLength,
    required int normalizedByteLength,
    required int chapterCount,
    required String? sourceRevision,
    required DateTime updatedAt,
    List<String>? cachedChapterKeys,
    int? totalChapterCount,
  }) async {
    final manifest = File(
      p.join(p.dirname(normalizedFile.path), 'manifest.json'),
    );
    if (!await manifest.exists()) return;
    final decoded = jsonDecode(await manifest.readAsString());
    final value = decoded is Map
        ? <String, Object?>{
            for (final entry in decoded.entries) '${entry.key}': entry.value,
          }
        : <String, Object?>{};
    value['normalizedHash'] = normalizedHash;
    value['normalizedCharacterLength'] = normalizedTextLength;
    value['normalizedUtf8ByteLength'] = normalizedByteLength;
    value['chapterCount'] = chapterCount;
    if (sourceRevision != null) value['sourceRevision'] = sourceRevision;
    if (cachedChapterKeys != null) {
      value['cachedChapterKeys'] = cachedChapterKeys;
    }
    if (totalChapterCount != null) {
      value['totalChapterCount'] = totalChapterCount;
    }
    value['updatedAt'] = updatedAt.toIso8601String();
    await manifest.writeAsString(
      const JsonEncoder.withIndent('  ').convert(value),
      flush: true,
    );
  }

  bool _sameStrings(Iterable<String> left, Iterable<String> right) {
    final a = left.toList();
    final b = right.toList();
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  String _joinEpubSpine(EpubBook book) {
    final buffer = StringBuffer();
    for (var index = 0; index < book.spine.length; index++) {
      if (index > 0) buffer.write('\n\n');
      buffer.write(book.spine[index].text);
    }
    return buffer.toString();
  }

  String _epubImageExtension(String mediaType, String href) {
    switch (mediaType.toLowerCase()) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      default:
        final extension = p.extension(href).toLowerCase();
        return extension.length <= 5 ? extension : '.bin';
    }
  }

  Future<bool> _epubManagedFilesHealthy(LibraryCollection collection) async {
    final sourcePath = collection.sourcePath;
    if (sourcePath == null || !sourcePath.endsWith('/source.epub')) {
      return false;
    }
    final normalizedPath = sourcePath.replaceFirst(
      RegExp(r'source\.epub$'),
      'normalized.txt',
    );
    final source = _files.resolveStoragePath(sourcePath);
    final normalized = _files.resolveStoragePath(normalizedPath);
    final manifest = _files.resolveStoragePath(
      normalizedPath.replaceFirst(RegExp(r'normalized\.txt$'), 'manifest.json'),
    );
    return await source.exists() &&
        await normalized.exists() &&
        await manifest.exists();
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
    // normalized.txt is UTF-8 regardless of the source encoding, while the
    // original file name remains the safe fallback title source.
    final normalizedForMetadata = File(p.join(jobDir.path, 'normalized.txt'));
    final metadata = LocalTxtMetadataInferer.fromText(
      await normalizedForMetadata.readAsString(),
      originalFileName,
    );
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
      title: metadata.title,
      subtitle: null,
      itemCount: itemCount,
      normalizedCharacterLength: index.normalizedCharacterLength,
      detectedEncoding: index.encoding,
      sourceSize: size,
      importedAt: now,
      author: metadata.author,
      description: metadata.description,
      metadataSource: metadata.metadataSource,
      titleSource: metadata.titleSource,
      authorSource: metadata.authorSource,
      fileName: originalFileName,
      sourcePath: sourcePath,
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
              title: metadata.title,
              author: Value(metadata.author),
              description: Value(metadata.description),
              metadataSource: Value(metadata.metadataSource),
              titleSource: Value(metadata.titleSource),
              authorSource: Value(metadata.authorSource),
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
                  title: c.displayTitle,
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
                title: e.displayTitle,
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
        author: r.author,
        description: r.description,
        metadataSource: r.metadataSource,
        titleSource: r.titleSource,
        authorSource: r.authorSource,
        fileName: src?.displayName,
        sourcePath: src?.managedSourcePath,
        coverPath: r.coverPath,
        coverSource: r.coverSource,
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
      author: row.author,
      description: row.description,
      metadataSource: row.metadataSource,
      titleSource: row.titleSource,
      authorSource: row.authorSource,
      fileName: src?.displayName,
      sourcePath: src?.managedSourcePath,
      coverPath: row.coverPath,
      coverSource: row.coverSource,
    );
  }

  /// Persist user-edited metadata without touching the source file, collection
  /// identity, normalized content, or any reader state.
  Future<LibraryCollection> updateManualMetadata(
    String collectionId, {
    required String title,
    required String? author,
    required String? description,
    required bool titleChanged,
    required bool authorChanged,
    required bool descriptionChanged,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const LibraryException('invalid_metadata', '书名不能为空');
    }
    final current = await getCollection(collectionId);
    if (current == null) {
      throw const LibraryException('not_found', '书库记录不存在');
    }
    final trimmedAuthor = author?.trim();
    final trimmedDescription = description?.trim();
    final hasManualOverride =
        titleChanged || authorChanged || descriptionChanged;
    if (!hasManualOverride) return current;

    await (_db.update(
      _db.contentCollections,
    )..where((t) => t.id.equals(collectionId))).write(
      ContentCollectionsCompanion(
        title: titleChanged ? Value(trimmedTitle) : const Value.absent(),
        author: authorChanged
            ? Value(
                trimmedAuthor == null || trimmedAuthor.isEmpty
                    ? null
                    : trimmedAuthor,
              )
            : const Value.absent(),
        description: descriptionChanged
            ? Value(
                trimmedDescription == null || trimmedDescription.isEmpty
                    ? null
                    : trimmedDescription,
              )
            : const Value.absent(),
        metadataSource: const Value('manual'),
        titleSource: titleChanged
            ? const Value('manual')
            : const Value.absent(),
        authorSource: authorChanged
            ? const Value('manual')
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    final updated = await getCollection(collectionId);
    if (updated == null) {
      throw const LibraryException('update_failed', '书籍信息保存失败');
    }
    return updated;
  }

  /// Re-read only the managed source prefix and restore inferred metadata.
  /// This never re-imports the book and therefore preserves its identity and
  /// reader progress.
  Future<LibraryCollection> restoreAutomaticMetadata(
    String collectionId,
  ) async {
    final current = await getCollection(collectionId);
    if (current == null) {
      throw const LibraryException('not_found', '书库记录不存在');
    }
    final sourcePath = current.sourcePath;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      throw const LibraryException('source_missing', '找不到原始 TXT 来源');
    }
    final normalizedPath = sourcePath.replaceFirst(
      RegExp(r'source\.txt$'),
      'normalized.txt',
    );
    final normalizedFile = _files.resolveStoragePath(normalizedPath);
    if (!await normalizedFile.exists()) {
      throw const LibraryException('source_missing', '找不到原始 TXT 来源');
    }
    final metadata = LocalTxtMetadataInferer.fromText(
      await normalizedFile.readAsString(),
      current.fileName ?? '未命名书籍.txt',
    );
    await (_db.update(
      _db.contentCollections,
    )..where((t) => t.id.equals(collectionId))).write(
      ContentCollectionsCompanion(
        title: Value(metadata.title),
        author: Value(metadata.author),
        description: Value(metadata.description),
        metadataSource: Value(metadata.metadataSource),
        titleSource: Value(metadata.titleSource),
        authorSource: Value(metadata.authorSource),
        updatedAt: Value(DateTime.now()),
      ),
    );
    final restored = await getCollection(collectionId);
    if (restored == null) {
      throw const LibraryException('update_failed', '自动识别信息恢复失败');
    }
    return restored;
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
      author: row.author,
      description: row.description,
      metadataSource: row.metadataSource,
      titleSource: row.titleSource,
      authorSource: row.authorSource,
      fileName: src.displayName,
      sourcePath: src.managedSourcePath,
      coverPath: row.coverPath,
      coverSource: row.coverSource,
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
    final isEpub = collection.sourceId.startsWith('epub-source:');
    final isWebBook = collection.sourceId.startsWith('web-book-source:');
    final hash = isEpub
        ? collection.id.replaceFirst('epub:', '')
        : isWebBook
        ? webBookStorageKeyFor(collection.id)
        : collection.id.replaceFirst('local-txt:', '');

    await _db.transaction(() async {
      // 级联删除（外键依赖顺序：documents → toc → items → collection → source）
      // 显式删除 reading_progress（DB FK 已加 CASCADE，双保险；修复删书残留进度）。
      await (_db.delete(
        _db.readingProgress,
      )..where((t) => t.collectionId.equals(collectionId))).go();
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
      if (isEpub) {
        await _files.deleteEpubContentDir(hash);
      } else if (isWebBook) {
        await _files.deleteWebBookContentDir(hash);
      } else {
        await _files.deleteContentDir(hash);
      }
    }
  }

  // ---- 辅助 ----

  String _webBookChapterKeyFromItemId(String itemId) {
    const marker = ':item:';
    final index = itemId.lastIndexOf(marker);
    return index < 0 ? itemId : itemId.substring(index + marker.length);
  }

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
