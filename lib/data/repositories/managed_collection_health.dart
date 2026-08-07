/// ManagedCollectionHealth —— 托管 collection 健康检查。
///
/// 检查内容：source.txt 存在与 hash、normalized.txt 存在与 hash（对照
/// manifest.normalizedHash）、UTF-16 长度（对照 manifest/index）、
/// Drift 记录与 manifest 一致性（normalizedHash）、版本兼容。
/// 只读，不修改任何文件或数据库。
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import 'library_file_manager.dart';

/// 健康检查结果。
class ManagedCollectionHealth {
  const ManagedCollectionHealth({
    required this.collectionId,
    required this.ok,
    required this.sourceOk,
    required this.normalizedOk,
    required this.dbConsistent,
    required this.versionCompatible,
    required this.problems,
    required this.manifestNormalizedHash,
    required this.actualNormalizedHash,
    required this.sourceHash,
    required this.actualSourceHash,
  });

  final String collectionId;

  /// 整体健康（source + normalized + db + version 全过）。
  final bool ok;

  /// source.txt 存在且 hash 正确。
  final bool sourceOk;

  /// normalized.txt 存在且 hash（对照 manifest）正确、长度正确。
  final bool normalizedOk;

  /// Drift content_documents.content_hash 与 manifest.normalizedHash 一致。
  final bool dbConsistent;

  /// manifest/index 版本与当前解析器兼容。
  final bool versionCompatible;

  /// 问题描述列表（空 = 健康）。
  final List<String> problems;

  /// manifest 记录的 normalizedHash。
  final String? manifestNormalizedHash;

  /// normalized.txt 实际字节 hash。
  final String? actualNormalizedHash;

  /// manifest 记录的 sourceHash。
  final String? sourceHash;

  /// source.txt 实际字节 hash。
  final String? actualSourceHash;
}

/// 集合健康检查服务（只读）。
class ManagedCollectionHealthCheck {
  ManagedCollectionHealthCheck({
    required AppDatabase database,
    required LibraryFileManager fileManager,
  }) : _db = database,
       _files = fileManager;

  final AppDatabase _db;
  final LibraryFileManager _files;

  /// 检查 collection 健康。
  ///
  /// [collectionId] 形如 `local-txt:<contentHash>`。
  Future<ManagedCollectionHealth> check(String collectionId) async {
    final problems = <String>[];
    final hash = collectionId.replaceFirst('local-txt:', '');

    // ---- source.txt ----
    final sourceDir = _files.contentDir(hash);
    final sourceFile = File(p.join(sourceDir.path, 'source.txt'));
    String? actualSourceHash;
    bool sourceOk = false;
    if (!await sourceFile.exists()) {
      problems.add('source.txt 缺失');
    } else {
      actualSourceHash = sha256
          .convert(await sourceFile.readAsBytes())
          .toString();
      // 目录名即 contentHash（稳定内容身份）
      sourceOk = actualSourceHash == hash;
      if (!sourceOk) {
        problems.add('source.txt hash 与目录名不一致');
      }
    }

    // ---- manifest ----
    final manifestFile = File(p.join(sourceDir.path, 'manifest.json'));
    Map<String, dynamic>? manifest;
    if (await manifestFile.exists()) {
      try {
        manifest =
            jsonDecode(await manifestFile.readAsString())
                as Map<String, dynamic>;
      } catch (_) {
        problems.add('manifest.json 无法解析');
      }
    } else {
      problems.add('manifest.json 缺失');
    }
    final manifestNormalizedHash = manifest?['normalizedHash'] as String?;
    final manifestSourceHash = manifest?['sourceHash'] as String?;
    final manifestNormLen = manifest?['normalizedCharacterLength'];

    // index.json（parserVersion 权威判断，M3.2 §六）
    Map<String, dynamic>? index;
    final indexFile = File(p.join(sourceDir.path, 'index.json'));
    if (await indexFile.exists()) {
      try {
        index =
            jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }

    // ---- normalized.txt ----
    final normFile = File(p.join(sourceDir.path, 'normalized.txt'));
    String? actualNormalizedHash;
    bool normalizedOk = false;
    if (!await normFile.exists()) {
      problems.add('normalized.txt 缺失');
    } else {
      final bytes = await normFile.readAsBytes();
      actualNormalizedHash = sha256.convert(bytes).toString();
      var normOk = true;
      if (manifestNormalizedHash == null) {
        problems.add('manifest 缺 normalizedHash');
        normOk = false;
      } else if (actualNormalizedHash != manifestNormalizedHash) {
        problems.add('normalized.txt hash 与 manifest 不一致');
        normOk = false;
      }
      // UTF-16 长度
      if (manifestNormLen != null) {
        final utf16Len = utf8.decode(bytes).length;
        final expect = manifestNormLen is int
            ? manifestNormLen
            : int.tryParse(manifestNormLen.toString());
        if (expect != null && utf16Len != expect) {
          problems.add('normalized.txt UTF-16 长度与 manifest 不一致');
          normOk = false;
        }
      }
      normalizedOk = normOk;
    }

    // ---- Drift 一致性 ----
    bool dbConsistent = false;
    if (manifestNormalizedHash != null) {
      final docs = await (_db.select(
        _db.contentDocuments,
      )..where((t) => t.storagePath.contains(hash))).get();
      if (docs.isEmpty) {
        problems.add('Drift 无该 collection 的 document 记录');
      } else {
        final docHashes = docs.map((d) => d.contentHash).toSet();
        if (docHashes.length == 1 &&
            docHashes.first == manifestNormalizedHash) {
          dbConsistent = true;
        } else {
          problems.add(
            'Drift content_documents.content_hash 与 manifest.normalizedHash 不一致',
          );
        }
      }
    }

    // ---- 版本兼容 ----
    bool versionCompatible = true;
    final normVersion = manifest?['normalizationVersion']?.toString();
    final parserVersion = manifest?['parserVersion']?.toString();
    if (normVersion != null && normVersion != '1.0.0') {
      problems.add('normalizationVersion 不兼容: $normVersion');
      versionCompatible = false;
    }
    // M3.2：parserVersion 2.0.0 = 完整标题合同。旧版本（1.0.0）
    // 的标题是短标题（仅「第X章」），需要重新生成索引。
    if (parserVersion != null &&
        parserVersion != '1.0.0' &&
        parserVersion != '2.0.0') {
      problems.add('parserVersion 不兼容: $parserVersion');
      versionCompatible = false;
    }
    // 标题完整性（§六 情况B/C）：旧 parserVersion（<2.0.0）的扫描器
    // 只存「第X章」正则片段，没有完整标题 → 需要重新索引。
    // 判断依据是 index.json/manifest 的 parserVersion（权威），
    // 不能靠猜测单个标题是否"太短"——真实文件中「第五十一章」这类
    // 纯编号标题是合法的完整标题。
    final needReindex = _isOldParser(manifest, index);
    if (needReindex) {
      problems.add('toc 标题不完整（旧 parserVersion 数据），需要重新索引');
    }
    if (manifest?['manifestVersion'] is int &&
        (manifest!['manifestVersion'] as int) != 1) {
      problems.add('manifestVersion 不兼容');
      versionCompatible = false;
    }

    return ManagedCollectionHealth(
      collectionId: collectionId,
      ok:
          sourceOk &&
          normalizedOk &&
          dbConsistent &&
          versionCompatible &&
          !needReindex,
      sourceOk: sourceOk,
      normalizedOk: normalizedOk,
      dbConsistent: dbConsistent,
      versionCompatible: versionCompatible,
      problems: problems,
      manifestNormalizedHash: manifestNormalizedHash,
      actualNormalizedHash: actualNormalizedHash,
      sourceHash: manifestSourceHash,
      actualSourceHash: actualSourceHash,
    );
  }

  /// 判断索引是否为旧 parserVersion（<2.0.0，无完整标题）数据（M3.2 §六）。
  ///
  /// 旧扫描器（parser 1.0.0）产出的 toc 标题只有「第X章/卷」正则片段。
  /// 判断依据：index.json 的 parserVersion（权威）；缺失时回退 manifest。
  /// 注意：真实文件中「第五十一章」这类纯编号标题是合法的完整标题，
  /// 不能靠猜测单个标题是否"太短"判断。
  bool _isOldParser(
    Map<String, dynamic>? manifest,
    Map<String, dynamic>? index,
  ) {
    final idxParser = index?['parserVersion']?.toString();
    if (idxParser != null && idxParser != '1.0.0' && idxParser != '2.0.0') {
      return true; // 未来未知版本，保守要求重索引
    }
    if (idxParser != null) return idxParser == '1.0.0';
    // index.json 缺失：回退 manifest
    final maniParser = manifest?['parserVersion']?.toString();
    if (maniParser != null) return maniParser == '1.0.0';
    return false;
  }
}
