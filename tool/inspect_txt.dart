// XAOCEN Reader v4 - read-only TXT pipeline diagnostic tool.
//
// Usage:
//   dart run tool/inspect_txt.dart --file "<path>" --cache "<cache-dir>"
//
// Outputs (never the full body text):
//   file size, hash, encoding, normalized chars, volume count, chapter count,
//   specified chapter titles + offsets, cacheHit, per-phase timings.
//
// This tool is for development diagnostics only, not a production entry.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xaocen_reader/sources/local_txt/gb18030_index_loader.dart';
import 'package:xaocen_reader/sources/local_txt/txt_content_identity.dart';
import 'package:xaocen_reader/sources/local_txt/txt_import_request.dart';
import 'package:xaocen_reader/sources/local_txt/txt_import_result.dart';
import 'package:xaocen_reader/sources/local_txt/txt_import_service.dart';

Future<void> main(List<String> args) async {
  String? filePath;
  String? cachePath;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--file' && i + 1 < args.length) {
      filePath = args[i + 1];
      i++;
    } else if (args[i] == '--cache' && i + 1 < args.length) {
      cachePath = args[i + 1];
      i++;
    }
  }
  if (filePath == null || cachePath == null) {
    stderr.writeln(
      'Usage: dart run tool/inspect_txt.dart --file <path> --cache <dir>',
    );
    exitCode = 64;
    return;
  }

  final file = File(filePath);
  if (!await file.exists()) {
    stderr.writeln('ERROR: file not found: $filePath');
    exitCode = 2;
    return;
  }

  final cacheDir = Directory(cachePath);

  final service = TxtImportService(
    encodingTableLoader: () async {
      // Load from the committed binary asset (dev-time path).
      final binFile = File(
        p.join(
          Directory.current.path,
          'assets',
          'encoding',
          'gb18030_index.bin',
        ),
      );
      final bytes = await binFile.readAsBytes();
      return const Gb18030IndexLoader().parse(bytes);
    },
  );

  stdout.writeln('== XAOCEN TXT pipeline inspect ==');
  stdout.writeln('file : $filePath');
  stdout.writeln('cache: $cachePath');
  stdout.writeln('');

  // Phase 1: identity (read-only).
  final identity = await TxtContentIdentity.fromFile(file);
  stdout.writeln('size        : ${identity.size} bytes');
  stdout.writeln('sha256      : ${identity.contentHash}');
  stdout.writeln('large class : ${classifyLabel(identity.size)}');
  stdout.writeln('');

  final request = TxtImportRequest(
    file: file,
    cacheDirectory: cacheDir,
    allowLargeFileConfirmation: true,
  );

  try {
    final sw = Stopwatch()..start();
    final result = await service.import(request);
    sw.stop();
    _printResult('first run ', result, sw.elapsedMilliseconds);

    final sw2 = Stopwatch()..start();
    final result2 = await service.import(request);
    sw2.stop();
    _printResult('second run', result2, sw2.elapsedMilliseconds);
  } on TxtImportException catch (e) {
    stderr.writeln('ERROR: $e');
    exitCode = 3;
  } on TxtImportRequiresConfirmation catch (e) {
    stderr.writeln('NEEDS CONFIRMATION: $e');
    exitCode = 0;
  }
}

String classifyLabel(int size) {
  if (size <= 20 * 1024 * 1024) return 'normal (<=20MB)';
  if (size <= 50 * 1024 * 1024) return 'requires confirmation (20-50MB)';
  return 'unsupported (>50MB)';
}

void _printResult(String label, TxtImportResult r, int wallMs) {
  final i = r.index;
  stdout.writeln('[$label]');
  stdout.writeln('  cacheHit         : ${r.cacheHit}');
  stdout.writeln('  encoding         : ${i.encoding.label}');
  stdout.writeln('  normalized chars : ${i.normalizedCharacterLength}');
  stdout.writeln('  volumeCount      : ${i.volumeCount}');
  stdout.writeln('  chapterCount     : ${i.chapterCount}');
  stdout.writeln('  wall ms          : $wallMs');
  stdout.writeln(
    '  timings (ms)     : read=${r.stats.fileReadMs} '
    'decode=${r.stats.decodeMs} normalize=${r.stats.normalizeMs} '
    'scan=${r.stats.scanMs} dedupe=${r.stats.dedupeMs} '
    'cacheWrite=${r.stats.cacheWriteMs} cacheRead=${r.stats.cacheReadMs} '
    'total=${r.stats.totalMs}',
  );
  final chapters = i.tocEntries.where((e) => e.isChapter).toList();
  stdout.writeln('  chapters: ${chapters.length}');
  if (chapters.length <= 20) {
    for (final c in chapters) {
      stdout.writeln(
        '    #${c.order} off=${c.startCharacterOffset} '
        'end=${c.endCharacterOffset} "${c.title}"',
      );
    }
  } else {
    const wanted = [1, 19, 42, 112, 195, 258, 300, 400, 473];
    for (final w in wanted) {
      if (w <= chapters.length) {
        final c = chapters[w - 1];
        stdout.writeln(
          '    #$w off=${c.startCharacterOffset} '
          'end=${c.endCharacterOffset} "${c.title}"',
        );
      }
    }
    final last = chapters.last;
    stdout.writeln(
      '    ... last #${last.order} off=${last.startCharacterOffset} '
      'end=${last.endCharacterOffset} "${last.title}"',
    );
  }
  stdout.writeln('');
}
