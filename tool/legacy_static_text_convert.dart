import 'dart:convert';
import 'dart:io';

import 'package:xaocen_reader/sources/remote/legacy_static_text_converter.dart';
import 'package:xaocen_reader/sources/remote/legacy_source_capability_scanner.dart';

Future<void> main([List<String>? args]) async {
  final arguments = args ?? const <String>[];
  final input = Directory(
    arguments.isNotEmpty ? arguments[0] : r'C:\Users\TOM\Desktop\测试\新建文件夹',
  );
  final outputPath = File(
    arguments.length > 1
        ? arguments[1]
        : 'docs/M5_9D_12_LEGACY_STATIC_TEXT_DRAFTS.json',
  );
  final reportPath = File(
    arguments.length > 2
        ? arguments[2]
        : 'docs/M5_9D_12_LEGACY_STATIC_TEXT_CONVERSION.json',
  );
  final converter = const LegacyStaticTextConverter();
  final files = await input
      .list(followLinks: false)
      .where(
        (entity) =>
            entity is File && entity.path.toLowerCase().endsWith('.json'),
      )
      .cast<File>()
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));

  final seen = <String>{};
  final drafts = <Map<String, Object?>>[];
  final results = <LegacyStaticTextConversionResult>[];
  var recordsRead = 0;
  for (final file in files) {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) continue;
    for (var index = 0; index < decoded.length; index++) {
      recordsRead++;
      final value = decoded[index];
      if (value is! Map) continue;
      final record = Map<String, Object?>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );
      final result = converter.convertRecord(record, sourceFile: file.path);
      if (!seen.add(result.sourceId)) continue;
      results.add(result);
      if (result.definition != null) {
        drafts.add(result.definition!.toJson());
      }
    }
  }

  final failureReasons = <String, int>{};
  for (final result in results.where(
    (item) => item.outcome == LegacyStaticTextConversionOutcome.manualReview,
  )) {
    for (final reason in result.reasons) {
      failureReasons.update(reason, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final representatives = <String, Map<String, Object?>>{};
  for (final outcome in LegacyStaticTextConversionOutcome.values) {
    for (final result in results) {
      if (result.outcome == outcome) {
        representatives[outcome.code] = result.toJson();
        break;
      }
    }
  }
  final converted = results
      .where(
        (item) => item.outcome == LegacyStaticTextConversionOutcome.converted,
      )
      .length;
  final downgraded = results
      .where(
        (item) =>
            item.outcome == LegacyStaticTextConversionOutcome.manualReview,
      )
      .length;
  final skipped = results
      .where(
        (item) => item.outcome == LegacyStaticTextConversionOutcome.skipped,
      )
      .length;
  final eligible = results
      .where((item) => item.scanDisposition.code == 'AUTOMATICALLY_CONVERTIBLE')
      .length;

  await outputPath.parent.create(recursive: true);
  await outputPath.writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schema': 'xaocen.webBook.draft-set',
      'version': 1,
      'source': 'LegacyStaticTextConverter',
      'drafts': drafts,
    }),
  );
  await reportPath.parent.create(recursive: true);
  await reportPath.writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'inputDirectory': input.path,
      'filesScanned': files.length,
      'recordsRead': recordsRead,
      'uniqueRecords': results.length,
      'scannerEligible': eligible,
      'converted': converted,
      'downgradedToManualReview': downgraded,
      'skippedNotEligible': skipped,
      'registryImport': 'NOT_RUN',
      'networkFetch': 'NOT_RUN',
      'failureReasonCounts': failureReasons,
      'representatives': representatives,
    }),
  );

  stdout.writeln('RECORDS_READ=$recordsRead');
  stdout.writeln('UNIQUE_RECORDS=${results.length}');
  stdout.writeln('SCANNER_ELIGIBLE=$eligible');
  stdout.writeln('CONVERTED=$converted');
  stdout.writeln('DOWNGRADED_TO_MANUAL_REVIEW=$downgraded');
  stdout.writeln('SKIPPED_NOT_ELIGIBLE=$skipped');
  stdout.writeln('DRAFTS=${outputPath.absolute.path}');
  stdout.writeln('REPORT=${reportPath.absolute.path}');
}
