import 'dart:convert';
import 'dart:io';

import 'package:xaocen_reader/sources/remote/legacy_source_capability_scanner.dart';
import 'package:xaocen_reader/sources/remote/legacy_source_pack_converter.dart';
import 'package:xaocen_reader/sources/remote/xaocen_source_pack.dart';

Future<void> main([List<String>? args]) async {
  final arguments = args ?? const <String>[];
  final input = Directory(
    arguments.isNotEmpty ? arguments[0] : r'C:\Users\TOM\Desktop\测试\新建文件夹',
  );
  final packPath = File(
    arguments.length > 1
        ? arguments[1]
        : 'docs/M5_9D_12_1_LEGACY_SOURCE_PACK.json',
  );
  final reportPath = File(
    arguments.length > 2
        ? arguments[2]
        : 'docs/M5_9D_12_1_LEGACY_SOURCE_PACK_REPORT.json',
  );
  final scanner = const LegacySourceCapabilityScanner();
  final converter = const LegacySourcePackConverter();
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
  final results = <LegacySourcePackConversionResult>[];
  var recordsRead = 0;
  for (final file in files) {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) continue;
    for (final value in decoded) {
      recordsRead++;
      if (value is! Map) continue;
      final record = Map<String, Object?>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );
      final scan = scanner.scanRecord(record, sourceFile: file.path);
      if (!seen.add(scan.sourceId)) continue;
      results.add(converter.convertRecord(record, sourceFile: file.path));
    }
  }

  final entries = results.map((result) => result.toPackEntry()).toList();
  final pack = XaocenWebBookSourcePack(
    packId: 'legacy-static-text-pack-v1',
    name: 'Legacy Static Text Source Pack',
    generatedAt: DateTime.now().toUtc(),
    sources: List.unmodifiable(entries),
  );
  final levelCounts = <String, int>{};
  final reasonCounts = <String, int>{};
  for (final result in results) {
    levelCounts.update(
      result.compatibility.code,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    for (final reason in result.reasons) {
      reasonCounts.update(reason, (value) => value + 1, ifAbsent: () => 1);
    }
  }

  await packPath.parent.create(recursive: true);
  await packPath.writeAsString(pack.toJsonString());
  await reportPath.parent.create(recursive: true);
  final report = <String, Object?>{
    'schema': 'xaocen.webBook.source-pack.report',
    'version': 1,
    'inputDirectory': input.path,
    'filesScanned': files.length,
    'recordsRead': recordsRead,
    'uniqueRecords': results.length,
    'compatibilityCounts': levelCounts,
    'reasonCounts': reasonCounts,
    'registryImport': 'NOT_RUN',
    'networkFetch': 'NOT_RUN',
    'packOutput': packPath.absolute.path,
  };
  await reportPath.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
  );

  stdout.writeln('RECORDS_READ=$recordsRead');
  stdout.writeln('UNIQUE_RECORDS=${results.length}');
  for (final level in LegacyCompatibilityLevel.values) {
    stdout.writeln('${level.code}=${levelCounts[level.code] ?? 0}');
  }
  stdout.writeln('PACK=${packPath.absolute.path}');
  stdout.writeln('REPORT=${reportPath.absolute.path}');
}
