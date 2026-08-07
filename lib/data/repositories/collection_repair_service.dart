/// CollectionRepairService —— 从 managed source.txt 重建损坏的派生文件。
///
/// 触发条件：alreadyImported 检测发现 health check 不健康但 source.txt 有效。
/// 流程：标记 repairing → 从 managed source.txt 重新执行 M1 管线 →
/// 写 repair 临时目录 → 校验 → 原子替换派生文件 → Drift 事务更新 →
/// 再次 health check → 标记 completed。
///
/// 红线：
/// - 不修改/不删除用户外部 TXT；
/// - 失败时保留有效 source.txt、不覆盖原有文件；
/// - 失败后允许重试或删除书库记录。
// ignore_for_file: prefer_initializing_formals
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../domain/library/normalized_artifact.dart';
import '../../domain/local_txt/txt_index.dart';
import '../database/app_database.dart';
import 'encoding_index_provider.dart';
import 'library_file_manager.dart';
import 'managed_collection_health.dart';
import '../../sources/local_txt/txt_import_request.dart';
import '../../sources/local_txt/txt_import_service.dart';

/// 修复结果。
class RepairResult {
  const RepairResult({
    required this.collectionId,
    required this.success,
    required this.normalizedHash,
    required this.health,
    required this.error,
  });

  final String collectionId;
  final bool success;
  final String? normalizedHash;
  final ManagedCollectionHealth? health;
  final String? error;

  bool get repaired => success && normalizedHash != null;
}

/// 修复服务。
class CollectionRepairService {
  CollectionRepairService({
    required AppDatabase database,
    required LibraryFileManager fileManager,
    required EncodingIndexProvider encodingIndexProvider,
  }) : _db = database,
       _files = fileManager,
       _encodingIndexProvider = encodingIndexProvider;

  final AppDatabase _db;
  final LibraryFileManager _files;
  final EncodingIndexProvider _encodingIndexProvider;

  /// 从 managed source.txt 重建派生文件（normalized.txt / index.json / manifest.json）。
  ///
  /// [collectionId] 形如 `local-txt:<contentHash>`。
  /// 返回成功修复后的 normalizedHash；失败返回错误（不覆盖原文件）。
  Future<RepairResult> repair(String collectionId) async {
    final hash = collectionId.replaceFirst('local-txt:', '');
    final contentDir = _files.contentDir(hash);
    final sourceFile = File(p.join(contentDir.path, 'source.txt'));

    // 0. 前置：source.txt 必须存在且 hash 正确（目录名 = contentHash）
    if (!await sourceFile.exists()) {
      return RepairResult(
        collectionId: collectionId,
        success: false,
        normalizedHash: null,
        health: null,
        error: 'source.txt 缺失，无法修复',
      );
    }
    final sourceBytes = await sourceFile.readAsBytes();
    final sourceHash = sha256.convert(sourceBytes).toString();
    if (sourceHash != hash) {
      return RepairResult(
        collectionId: collectionId,
        success: false,
        normalizedHash: null,
        health: null,
        error: 'source.txt hash 与内容身份不一致，无法安全修复',
      );
    }

    // 1. 标记 repairing（不删旧记录）
    try {
      await _markRepairState(collectionId, 'repairing');
    } catch (_) {}

    // 2. 备份原 manifest（失败回滚用）
    final origManifestFile = File(p.join(contentDir.path, 'manifest.json'));
    final origManifestBackup = File(
      p.join(contentDir.path, 'manifest.json.repair-bak'),
    );
    if (await origManifestFile.exists()) {
      await origManifestFile.copy(origManifestBackup.path);
    }
    final origNormFile = File(p.join(contentDir.path, 'normalized.txt'));
    final origNormBackup = File(p.join(contentDir.path, 'normalized.txt.bak'));
    if (await origNormFile.exists()) {
      await origNormFile.copy(origNormBackup.path);
    }

    // 3. 从 managed source.txt 重新执行 M1 管线（repair 临时目录）
    final repairJobId =
        'repair-${hash.substring(0, 12)}-${DateTime.now().microsecondsSinceEpoch}';
    final repairDir = await _files.createImportingJob(repairJobId);
    try {
      String? normalizedText;
      final indexData = await _encodingIndexProvider.load();
      final service = TxtImportService(
        encodingTableLoader: () async => indexData,
        onNormalizedText: (text) => normalizedText = text,
      );
      final result = await service.import(
        TxtImportRequest(
          file: sourceFile,
          cacheDirectory: Directory(p.join(repairDir.path, '.m1cache')),
          allowLargeFileConfirmation: true,
        ),
      );
      if (normalizedText == null) {
        throw const FormatException('规范化文本未生成');
      }

      // 4. 写入 repair 临时目录（正确写入顺序，hash 来自落盘字节）
      // 4.0 写 index.json（含完整 displayTitle / parserVersion 2.0.0），
      //     否则 _replaceDerivedFiles 无新 index 可复制，旧短标题残留。
      final newIndexFile = File(p.join(repairDir.path, 'index.json'));
      await newIndexFile.writeAsString(result.index.encode(), flush: true);
      final normText = normalizedText!;
      final tmpFile = File(p.join(repairDir.path, 'normalized.tmp'));
      await tmpFile.writeAsBytes(utf8.encode(normText), flush: true);
      final bytes = await tmpFile.readAsBytes();
      final normalizedHash = sha256.convert(bytes).toString();
      final decoded = utf8.decode(bytes);
      if (decoded.length != result.index.normalizedCharacterLength) {
        throw const FormatException('规范化长度与索引不一致');
      }
      final newNormFile = File(p.join(repairDir.path, 'normalized.txt'));
      await tmpFile.rename(newNormFile.path);
      final artifact = NormalizedArtifact(
        filePath: newNormFile.path,
        utf8ByteLength: bytes.length,
        utf16CharacterLength: decoded.length,
        sha256: normalizedHash,
        normalizationVersion: result.index.normalizationVersion,
      );
      await _writeManifest(
        repairDir,
        index: result.index,
        contentHash: hash,
        sourceHash: sourceHash,
        artifact: artifact,
      );
      // 校验
      final verify = sha256.convert(await newNormFile.readAsBytes()).toString();
      if (verify != normalizedHash) {
        throw const FormatException('repair 产物校验失败');
      }

      // 5. 原子替换旧派生文件（保留 source.txt 不动）
      await _replaceDerivedFiles(contentDir, repairDir, newNormFile);

      // 6. Drift 事务更新（content_documents.content_hash → normalizedHash；
      //    toc_entries / content_items 标题 → 完整 displayTitle，M3.2 §七）
      await _db.transaction(() async {
        final docs = await (_db.select(
          _db.contentDocuments,
        )..where((t) => t.storagePath.contains(hash))).get();
        for (final d in docs) {
          await (_db.update(
            _db.contentDocuments,
          )..where((t) => t.id.equals(d.id))).write(
            ContentDocumentsCompanion(
              contentHash: Value(normalizedHash),
              normalizationVersion: Value(result.index.normalizationVersion),
            ),
          );
        }
        // 同步完整标题到 toc_entries 与 content_items（保留 id/offset 不变）
        final newEntries = result.index.tocEntries;
        final newByOffset = {
          for (final e in newEntries) e.startCharacterOffset: e,
        };
        // 校验 offset 未漂移：旧 toc 的 offset 集合 == 新 toc 的 offset 集合
        final oldToc = await (_db.select(
          _db.tocEntries,
        )..where((t) => t.collectionId.equals(collectionId))).get();
        final oldOffsets = oldToc.map((t) => t.startCharacterOffset).toSet();
        final newOffsets = newByOffset.keys.toSet();
        if (!oldOffsets.containsAll(newOffsets) ||
            !newOffsets.containsAll(oldOffsets)) {
          throw const FormatException(
            'repair: toc offset 漂移（新旧 offset 不一致），禁止静默重建',
          );
        }
        for (final r in oldToc) {
          final e = newByOffset[r.startCharacterOffset];
          if (e == null) continue;
          await (_db.update(
            _db.tocEntries,
          )..where((t) => t.id.equals(r.id))).write(
            TocEntriesCompanion(
              title: Value(e.displayTitle),
              level: Value(e.level),
              orderIndex: Value(e.order),
            ),
          );
        }
        // content_items 标题同步（按 startCharacterOffset 匹配）
        final items = await (_db.select(
          _db.contentItems,
        )..where((t) => t.collectionId.equals(collectionId))).get();
        for (final it in items) {
          final e = newByOffset[it.startCharacterOffset];
          if (e == null) continue;
          await (_db.update(_db.contentItems)..where((t) => t.id.equals(it.id)))
              .write(ContentItemsCompanion(title: Value(e.displayTitle)));
        }
        await _markRepairState(collectionId, 'completed', repairError: null);
      });
      // 7. 再次完整 health check
      final health = await ManagedCollectionHealthCheck(
        database: _db,
        fileManager: _files,
      ).check(collectionId);

      // 清理备份
      try {
        if (await origManifestBackup.exists()) {
          await origManifestBackup.delete();
        }
        if (await origNormBackup.exists()) {
          await origNormBackup.delete();
        }
      } catch (_) {}

      return RepairResult(
        collectionId: collectionId,
        success: health.ok,
        normalizedHash: normalizedHash,
        health: health,
        error: health.ok ? null : health.problems.join('; '),
      );
    } catch (e) {
      // 8. 失败：回滚备份，保留原文件
      try {
        if (await origManifestBackup.exists() &&
            await origManifestFile.exists()) {
          await origManifestFile.delete();
          await origManifestBackup.rename(origManifestFile.path);
        }
        if (await origNormBackup.exists()) {
          if (await origNormFile.exists()) {
            await origNormFile.delete();
          }
          await origNormBackup.rename(origNormFile.path);
        }
      } catch (_) {}
      try {
        await _markRepairState(collectionId, 'failed', repairError: '$e');
      } catch (_) {}
      return RepairResult(
        collectionId: collectionId,
        success: false,
        normalizedHash: null,
        health: null,
        error: '修复失败: $e',
      );
    } finally {
      // 清理 repair 临时目录
      try {
        if (await repairDir.exists()) {
          await repairDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  Future<void> _markRepairState(
    String collectionId,
    String state, {
    String? repairError,
  }) async {
    final now = DateTime.now();
    await _db
        .into(_db.importRecords)
        .insert(
          ImportRecordsCompanion.insert(
            id: 'repair:$collectionId:${now.microsecondsSinceEpoch}',
            sourceHash: collectionId.replaceFirst('local-txt:', ''),
            state: state,
            startedAt: now,
            completedAt: Value(
              state == 'completed' || state == 'failed' ? now : null,
            ),
            errorCode: Value(repairError == null ? null : 'repair_failed'),
            errorMessage: Value(repairError),
          ),
        );
  }

  Future<void> _writeManifest(
    Directory dir, {
    required TxtIndex index,
    required String contentHash,
    required String sourceHash,
    required NormalizedArtifact artifact,
  }) async {
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
    await File(p.join(dir.path, 'manifest.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
  }

  /// 原子替换派生文件（source.txt 不动；失败不覆盖原文件）。
  Future<void> _replaceDerivedFiles(
    Directory contentDir,
    Directory repairDir,
    File newNormFile,
  ) async {
    // 先写 index.json
    final newIndex = File(p.join(repairDir.path, 'index.json'));
    final dstIndex = File(p.join(contentDir.path, 'index.json'));
    if (await newIndex.exists()) {
      final tmp = File(p.join(contentDir.path, 'index.json.new'));
      await newIndex.copy(tmp.path);
      if (await dstIndex.exists()) {
        await dstIndex.delete();
      }
      await tmp.rename(dstIndex.path);
    }

    // normalized.txt 原子替换
    final dstNorm = File(p.join(contentDir.path, 'normalized.txt'));
    final tmpNorm = File(p.join(contentDir.path, 'normalized.txt.new'));
    await newNormFile.copy(tmpNorm.path);
    if (await dstNorm.exists()) {
      await dstNorm.delete();
    }
    await tmpNorm.rename(dstNorm.path);

    // manifest.json 原子替换
    final newManifest = File(p.join(repairDir.path, 'manifest.json'));
    final dstManifest = File(p.join(contentDir.path, 'manifest.json'));
    final tmpManifest = File(p.join(contentDir.path, 'manifest.json.new'));
    await newManifest.copy(tmpManifest.path);
    if (await dstManifest.exists()) {
      await dstManifest.delete();
    }
    await tmpManifest.rename(dstManifest.path);
  }
}
