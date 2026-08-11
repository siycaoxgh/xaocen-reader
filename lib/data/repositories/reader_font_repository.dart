import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/data_root.dart';
import '../../domain/reader/reader_font.dart';
import '../database/app_database.dart';

/// Owns imported font bytes and their typed database metadata.
final class ReaderFontRepository {
  ReaderFontRepository({required this.db, required this.dataRoot});

  final AppDatabase db;
  final DataRoot dataRoot;

  Future<List<ReaderFontAsset>> list() async {
    final rows = await (db.select(
      db.readerFontAssetRows,
    )..orderBy([(t) => OrderingTerm.asc(t.familyNameSnapshot)])).get();
    return rows.map(_decode).toList(growable: false);
  }

  Future<ReaderFontAsset?> get(String fontId) async {
    final row = await (db.select(
      db.readerFontAssetRows,
    )..where((t) => t.fontId.equals(fontId))).getSingleOrNull();
    return row == null ? null : _decode(row);
  }

  Future<ReaderFontAsset> importFile(File source) async {
    if (!await source.exists()) {
      throw const ReaderFontException('font source missing');
    }
    final extension = p.extension(source.path).toLowerCase();
    final format = switch (extension) {
      '.ttf' => ReaderFontFormat.ttf,
      '.otf' => ReaderFontFormat.otf,
      '.ttc' => throw const ReaderFontException(
        'TTC font collections are not supported on this build',
      ),
      _ => throw const ReaderFontException(
        'only TTF and OTF fonts are supported',
      ),
    };
    final bytes = await source.readAsBytes();
    _validateSfnt(bytes, format);
    final hash = sha256.convert(bytes).toString();
    final existing = await (db.select(
      db.readerFontAssetRows,
    )..where((t) => t.contentHash.equals(hash))).getSingleOrNull();
    if (existing != null) return _decode(existing);

    final fontId = hash;
    final relativePath = 'fonts/$fontId.${format.name}';
    final target = _resolve(relativePath);
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.importing');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
    final now = DateTime.now();
    await db
        .into(db.readerFontAssetRows)
        .insert(
          ReaderFontAssetRowsCompanion.insert(
            fontId: fontId,
            contentHash: hash,
            relativePath: relativePath,
            format: format.name,
            familyNameSnapshot: _fontDisplayName(
              bytes,
              fallback: p.basenameWithoutExtension(source.path),
            ),
            fileSize: bytes.length,
            createdAt: now,
            lastUsedAt: now,
          ),
        );
    return (await get(fontId))!;
  }

  Future<ReaderFontAsset?> markAvailability(String fontId) async {
    final asset = await get(fontId);
    if (asset == null) return null;
    final file = _resolve(asset.relativePath);
    final available =
        await file.exists() && await _sha256File(file) == asset.contentHash;
    final next = available
        ? ReaderFontAvailability.available
        : ReaderFontAvailability.missing;
    if (next.name != asset.availability.name) {
      await (db.update(db.readerFontAssetRows)
            ..where((t) => t.fontId.equals(fontId)))
          .write(ReaderFontAssetRowsCompanion(availability: Value(next.name)));
    }
    return (await get(fontId))!;
  }

  Future<void> touch(String fontId) async {
    await (db.update(db.readerFontAssetRows)
          ..where((t) => t.fontId.equals(fontId)))
        .write(ReaderFontAssetRowsCompanion(lastUsedAt: Value(DateTime.now())));
  }

  /// Clears every per-book reference before removing the shared file. A book
  /// therefore resolves to systemDefault instead of retaining a dead ID.
  Future<void> delete(String fontId) async {
    await (db.update(db.readerPreferencesRows)
          ..where((t) => t.fontId.equals(fontId)))
        .write(const ReaderPreferencesRowsCompanion(fontId: Value(null)));
    final asset = await get(fontId);
    if (asset != null) {
      final file = _resolve(asset.relativePath);
      if (await file.exists()) await file.delete();
      await (db.delete(
        db.readerFontAssetRows,
      )..where((t) => t.fontId.equals(fontId))).go();
    }
  }

  File _resolve(String relativePath) {
    final normalized = p.posix.normalize(relativePath.replaceAll('\\', '/'));
    if (!normalized.startsWith('fonts/') || normalized.contains('..')) {
      throw const ReaderFontException('unsafe managed font path');
    }
    return File(
      p.joinAll([dataRoot.rootDirectory.path, ...normalized.split('/')]),
    );
  }

  /// Resolves a managed asset for the runtime FontLoader without exposing an
  /// absolute path to domain or persistence callers.
  File resolve(ReaderFontAsset asset) => _resolve(asset.relativePath);

  Future<List<int>> readBytes(ReaderFontAsset asset) async {
    final file = _resolve(asset.relativePath);
    final bytes = await file.readAsBytes();
    if (sha256.convert(bytes).toString() != asset.contentHash) {
      throw const ReaderFontException('managed font checksum mismatch');
    }
    return bytes;
  }

  ReaderFontAsset _decode(ReaderFontAssetRow row) => ReaderFontAsset(
    fontId: row.fontId,
    contentHash: row.contentHash,
    relativePath: row.relativePath,
    format: ReaderFontFormat.values.firstWhere(
      (value) => value.name == row.format,
      orElse: () => ReaderFontFormat.ttf,
    ),
    familyNameSnapshot: row.familyNameSnapshot,
    styleNameSnapshot: row.styleNameSnapshot,
    faceIndex: row.faceIndex,
    fileSize: row.fileSize,
    createdAt: row.createdAt,
    lastUsedAt: row.lastUsedAt,
    availability: ReaderFontAvailability.values.firstWhere(
      (value) => value.name == row.availability,
      orElse: () => ReaderFontAvailability.invalid,
    ),
  );

  static void _validateSfnt(List<int> bytes, ReaderFontFormat format) {
    if (bytes.length < 4) {
      throw const ReaderFontException('font file is too small');
    }
    final tag = String.fromCharCodes(bytes.take(4));
    final valid =
        tag == 'OTTO' ||
        tag == 'true' ||
        tag == 'typ1' ||
        (bytes[0] == 0 && bytes[1] == 1 && bytes[2] == 0 && bytes[3] == 0);
    if (!valid) {
      throw ReaderFontException(
        'invalid ${format.name.toUpperCase()} font container',
      );
    }
  }

  /// Reads the OpenType family name without introducing a parser dependency.
  /// Prefer a Chinese localized name when one is present; otherwise use the
  /// first English/Unicode family name and finally the source file name.
  static String _fontDisplayName(List<int> bytes, {required String fallback}) {
    try {
      if (bytes.length < 12) return fallback;
      final tableCount = _u16(bytes, 4);
      for (var index = 0; index < tableCount; index++) {
        final record = 12 + index * 16;
        if (record + 16 > bytes.length) break;
        final tag = String.fromCharCodes(bytes.sublist(record, record + 4));
        if (tag != 'name') continue;
        final offset = _u32(bytes, record + 8);
        final length = _u32(bytes, record + 12);
        if (offset < 0 || length < 6 || offset + length > bytes.length) {
          return fallback;
        }
        final count = _u16(bytes, offset + 2);
        final strings = offset + _u16(bytes, offset + 4);
        String? english;
        String? chinese;
        for (var item = 0; item < count; item++) {
          final recordOffset = offset + 6 + item * 12;
          if (recordOffset + 12 > bytes.length) break;
          final platform = _u16(bytes, recordOffset);
          final language = _u16(bytes, recordOffset + 4);
          final nameId = _u16(bytes, recordOffset + 6);
          if (nameId != 1) continue;
          final itemLength = _u16(bytes, recordOffset + 8);
          final itemOffset = _u16(bytes, recordOffset + 10);
          final start = strings + itemOffset;
          if (start < 0 || start + itemLength > bytes.length) continue;
          final value = _decodeName(
            bytes.sublist(start, start + itemLength),
            unicode: platform == 0 || platform == 3,
          );
          if (value == null || value.trim().isEmpty) continue;
          if (_isChineseLanguage(language) || _hasCjk(value)) {
            chinese ??= value.trim();
          } else {
            english ??= value.trim();
          }
        }
        return chinese ?? english ?? fallback;
      }
    } catch (_) {
      // A malformed optional name table must not reject an otherwise valid
      // font container.
    }
    return fallback;
  }

  static int _u16(List<int> bytes, int offset) =>
      (bytes[offset] << 8) | bytes[offset + 1];

  static int _u32(List<int> bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  static String? _decodeName(List<int> bytes, {required bool unicode}) {
    if (unicode) {
      if (bytes.length.isOdd) return null;
      final codeUnits = <int>[];
      for (var i = 0; i < bytes.length; i += 2) {
        codeUnits.add((bytes[i] << 8) | bytes[i + 1]);
      }
      return String.fromCharCodes(codeUnits);
    }
    return String.fromCharCodes(bytes);
  }

  static bool _isChineseLanguage(int language) =>
      language == 0x0404 ||
      language == 0x0804 ||
      language == 0x0c04 ||
      language == 0x1004 ||
      language == 0x1404;

  static bool _hasCjk(String value) =>
      RegExp(r'[\u3400-\u9fff]').hasMatch(value);

  static Future<String> _sha256File(File file) async =>
      sha256.convert(await file.readAsBytes()).toString();
}

final class ReaderFontException implements Exception {
  const ReaderFontException(this.message);
  final String message;

  @override
  String toString() => 'ReaderFontException: $message';
}
