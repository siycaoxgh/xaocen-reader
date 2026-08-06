// XAOCEN Reader v4 - GB18030 binary index generator.
//
// Usage:
//   dart run tool/generate_gb18030_index.dart \
//     --input <whatwg index-gb18030.txt> \
//     --out <project>/assets/encoding/gb18030_index.bin
//
// The 4-byte anchor table is embedded in gb18030_anchors_data.dart
// (standard data, 209 entries, verified against Python gb18030 codec).
//
// Output:
//   assets/encoding/gb18030_index.bin      (binary, see format below)
//   assets/encoding/gb18030_index.meta.json (source version / counts / SHA-256)
//
// Binary format v1 (little-endian):
//   offset  size  field
//   0       4     magic "GBIX"
//   4       1     formatVersion (1)
//   5       1     flags (0)
//   6       4     entryCount (u32 LE = 23940)
//   10      n     entries: entryCount x [pointer u16 LE, codepoint u16 LE]
//   10+n    4     anchorCount (u32 LE = 209)
//   14+n    m     anchors: anchorCount x [pointer u32 LE, codepoint u32 LE]
//
// Running the generator twice on the same input produces identical bytes
// (entries are written in ascending pointer order; anchors in fixed order).
// ignore_for_file: avoid_print
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'gb18030_anchors_data.dart';

const int kFormatVersion = 1;
const int kExpectedEntryCount = 23940;
const int kExpectedAnchorCount = 209;
const String kWhatwgSourceVersion =
    'WHATWG encoding standard index-gb18030.txt (2024-09-18 snapshot)';

void main(List<String> args) {
  String? inputPath;
  String? outDir;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--input' && i + 1 < args.length) {
      inputPath = args[i + 1];
      i++;
    } else if (args[i] == '--out' && i + 1 < args.length) {
      outDir = args[i + 1];
      i++;
    } else if (args[i] == '--help' || args[i] == '-h') {
      print('''
Usage: dart run tool/generate_gb18030_index.dart --input <index-gb18030.txt> --out <outdir>

Reads the WHATWG index-gb18030.txt source and writes:
  <outdir>/gb18030_index.bin
  <outdir>/gb18030_index.meta.json
''');
      return;
    }
  }
  if (inputPath == null || outDir == null) {
    stderr.writeln('ERROR: --input and --out are required');
    exitCode = 64;
    return;
  }

  try {
    final result = generate(
      inputFile: File(inputPath),
      outDirectory: Directory(outDir),
    );
    stdout.writeln('OK: ${result.binFile.path}');
    stdout.writeln(
      '    entries=${result.entryCount} anchors=${result.anchorCount} sha256=${result.sha256}',
    );
    stdout.writeln('    meta written to ${result.metaFile.path}');
  } catch (e) {
    stderr.writeln('ERROR: $e');
    exitCode = 1;
  }
}

class GenerateResult {
  const GenerateResult({
    required this.binFile,
    required this.metaFile,
    required this.entryCount,
    required this.anchorCount,
    required this.sha256,
  });

  final File binFile;
  final File metaFile;
  final int entryCount;
  final int anchorCount;
  final String sha256;
}

GenerateResult generate({
  required File inputFile,
  required Directory outDirectory,
}) {
  if (!inputFile.existsSync()) {
    throw Exception('input file not found: ${inputFile.path}');
  }

  // 1. Parse WHATWG index: pointer -> codepoint (ascending pointer order).
  final entries = <int, int>{};
  final lines = inputFile.readAsLinesSync();
  for (final line in lines) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length < 2) continue;
    final pointer = int.parse(parts[0]);
    final cp = int.parse(parts[1].replaceFirst('0x', ''), radix: 16);
    entries[pointer] = cp;
  }
  if (entries.length != kExpectedEntryCount) {
    throw Exception(
      'unexpected entry count ${entries.length} (expected $kExpectedEntryCount)',
    );
  }

  // 2. Anchors: embedded standard table.
  if (gb18030Anchors.length != kExpectedAnchorCount) {
    throw Exception(
      'unexpected anchor count ${gb18030Anchors.length} (expected $kExpectedAnchorCount)',
    );
  }

  // 3. Serialize binary (little-endian).
  final bd = ByteData(10 + entries.length * 4 + 4 + gb18030Anchors.length * 8);
  var offset = 0;
  // magic
  bd.setUint8(offset++, 0x47);
  bd.setUint8(offset++, 0x42);
  bd.setUint8(offset++, 0x49);
  bd.setUint8(offset++, 0x58);
  bd.setUint8(offset++, kFormatVersion);
  bd.setUint8(offset++, 0); // flags
  bd.setUint32(offset, entries.length, Endian.little);
  offset += 4;
  // entries: ascending pointer order (pointer == index)
  for (var p = 0; p < entries.length; p++) {
    final cp = entries[p];
    if (cp == null) {
      throw Exception('missing entry at pointer $p (index must be contiguous)');
    }
    bd.setUint16(offset, p, Endian.little);
    bd.setUint16(offset + 2, cp, Endian.little);
    offset += 4;
  }
  bd.setUint32(offset, gb18030Anchors.length, Endian.little);
  offset += 4;
  for (final anchor in gb18030Anchors) {
    bd.setUint32(offset, anchor[0], Endian.little);
    bd.setUint32(offset + 4, anchor[1], Endian.little);
    offset += 8;
  }
  final bytes = bd.buffer.asUint8List();
  final sha = sha256.convert(bytes).toString();

  // 4. Write outputs.
  if (!outDirectory.existsSync()) {
    outDirectory.createSync(recursive: true);
  }
  final binFile = File(
    '${outDirectory.path}${Platform.pathSeparator}gb18030_index.bin',
  );
  binFile.writeAsBytesSync(bytes, flush: true);

  final meta = {
    'formatVersion': kFormatVersion,
    'source': kWhatwgSourceVersion,
    'entryCount': entries.length,
    'anchorCount': gb18030Anchors.length,
    'sha256': sha,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
  };
  final metaFile = File(
    '${outDirectory.path}${Platform.pathSeparator}gb18030_index.meta.json',
  );
  metaFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(meta),
    flush: true,
  );

  return GenerateResult(
    binFile: binFile,
    metaFile: metaFile,
    entryCount: entries.length,
    anchorCount: gb18030Anchors.length,
    sha256: sha,
  );
}
