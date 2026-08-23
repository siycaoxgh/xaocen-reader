import 'dart:convert';
import 'dart:io';

import 'package:xaocen_reader/sources/remote/legacy_source_capability_scanner.dart';

Future<void> main(List<String> args) async {
  final input = Directory(
    args.isNotEmpty ? args[0] : r'C:\Users\TOM\Desktop\测试\新建文件夹',
  );
  final reportPath = File(
    args.length > 1
        ? args[1]
        : 'docs/M5_9D_11_LEGACY_SOURCE_CAPABILITY_SCAN.json',
  );
  final scanner = const LegacySourceCapabilityScanner();
  final report = await scanner.scanDirectory(input);
  final representatives = <String, LegacySourceScanResult>{};
  for (final capability in LegacySourceCapability.values) {
    for (final result in report.results) {
      if (result.capabilities.contains(capability)) {
        representatives[capability.code] = result;
        break;
      }
    }
  }
  final dispositionRepresentatives = <String, LegacySourceScanResult>{};
  for (final disposition in LegacySourceDisposition.values) {
    for (final result in report.results) {
      if (result.disposition == disposition) {
        dispositionRepresentatives[disposition.code] = result;
        break;
      }
    }
  }

  final output = <String, Object?>{
    'inputDirectory': input.path,
    'expectedRecordCount': 3587,
    'filesScanned': report.filesScanned,
    'recordsRead': report.recordsRead,
    'uniqueRecords': report.uniqueRecords,
    'duplicateRecords': report.duplicateRecords,
    'capabilityCounts': report.capabilityCounts,
    'dispositionCounts': report.dispositionCounts,
    'bulkNetworkFetch': 'NOT_RUN',
    'representatives': representatives.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'dispositionRepresentatives': dispositionRepresentatives.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };
  await reportPath.parent.create(recursive: true);
  await reportPath.writeAsString(
    const JsonEncoder.withIndent('  ').convert(output),
  );

  stdout.writeln('FILES_SCANNED=${report.filesScanned}');
  stdout.writeln('RECORDS_READ=${report.recordsRead}');
  stdout.writeln('UNIQUE_RECORDS=${report.uniqueRecords}');
  stdout.writeln('DUPLICATE_RECORDS=${report.duplicateRecords}');
  stdout.writeln('CAPABILITIES=${jsonEncode(report.capabilityCounts)}');
  stdout.writeln('DISPOSITIONS=${jsonEncode(report.dispositionCounts)}');
  stdout.writeln('REPORT=${reportPath.absolute.path}');
}
