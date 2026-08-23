import 'dart:convert';
import 'dart:io';

import 'package:xaocen_reader/sources/remote/legacy_source_capability_scanner.dart';
import 'package:xaocen_reader/sources/remote/legacy_source_pack_converter.dart';
import 'package:xaocen_reader/sources/remote/legacy_static_text_converter.dart';
import 'package:xaocen_reader/sources/remote/legacy_static_transform.dart';
import 'package:xaocen_reader/sources/remote/xaocen_source_pack.dart';

Future<void> main([List<String>? args]) async {
  final input = Directory(
    args != null && args.isNotEmpty
        ? args[0]
        : r'C:\Users\TOM\Desktop\测试\新建文件夹',
  );
  final jsonPath = File(
    args != null && args.length > 1
        ? args[1]
        : 'docs/M5_9D_14_LEGACY_STATIC_TRANSFORM.json',
  );
  final markdownPath = File(
    args != null && args.length > 2
        ? args[2]
        : 'docs/M5_9D_14_LEGACY_STATIC_TRANSFORM.md',
  );
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
  var recordsRead = 0;
  var uniqueRecords = 0;
  var transformSources = 0;
  var transformOccurrences = 0;
  var prefixMapped = 0;
  var fallbackMapped = 0;
  var rejected = 0;
  final rejectionReasons = <String, int>{};
  final outcomes = <String, int>{};
  final compatibility = <String, int>{};
  final scannerCounts = <String, int>{};
  const scanner = LegacySourceCapabilityScanner();
  const converter = LegacyStaticTextConverter();
  const packConverter = LegacySourcePackConverter();

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
      uniqueRecords++;
      scannerCounts.update(
        scan.disposition.code,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      var hasTransform = false;
      for (final field in _stringFields(record)) {
        if (!field.value.contains('##') && !field.value.contains('||')) {
          continue;
        }
        hasTransform = true;
        transformOccurrences++;
        try {
          final mapped = LegacyStaticTransform.parse(field.value);
          if (mapped.removePrefix != null) prefixMapped++;
          if (mapped.fallbackSelectors.isNotEmpty) fallbackMapped++;
        } on LegacyStaticTransformException catch (error) {
          rejected++;
          rejectionReasons.update(
            '${field.path}: ${error.message}',
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
      if (hasTransform) transformSources++;

      final result = converter.convertRecord(record, sourceFile: file.path);
      outcomes.update(
        result.outcome.code,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final pack = packConverter.convertRecord(record, sourceFile: file.path);
      compatibility.update(
        pack.compatibility.code,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  final report = <String, Object?>{
    'schema': 'xaocen.legacy.static-transform.report',
    'version': 1,
    'inputDirectory': input.path,
    'filesScanned': files.length,
    'recordsRead': recordsRead,
    'uniqueRecords': uniqueRecords,
    'scannerDispositionCounts': scannerCounts,
    'transformEvidence': <String, int>{
      'sourcesWithStaticTransforms': transformSources,
      'transformOccurrences': transformOccurrences,
      'literalPrefixMappings': prefixMapped,
      'fallbackMappings': fallbackMapped,
      'rejectedTransforms': rejected,
    },
    'conversionOutcomes': outcomes,
    'packCompatibility': compatibility,
    'rejectionReasons': rejectionReasons,
    'networkFetch': 'NOT_RUN',
    'registryImport': 'NOT_RUN',
  };
  await jsonPath.parent.create(recursive: true);
  await jsonPath.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
  );
  await markdownPath.parent.create(recursive: true);
  await markdownPath.writeAsString(_markdown(report));
  stdout.writeln('UNIQUE_RECORDS=$uniqueRecords');
  stdout.writeln('TRANSFORM_OCCURRENCES=$transformOccurrences');
  stdout.writeln('PREFIX_MAPPED=$prefixMapped');
  stdout.writeln('FALLBACK_MAPPED=$fallbackMapped');
  stdout.writeln('TRANSFORM_REJECTED=$rejected');
  stdout.writeln('REPORT=${jsonPath.absolute.path}');
  stdout.writeln('MARKDOWN=${markdownPath.absolute.path}');
}

String _markdown(Map<String, Object?> report) {
  final evidence = Map<String, Object?>.from(
    report['transformEvidence']! as Map,
  );
  final outcomes = Map<String, Object?>.from(
    report['conversionOutcomes']! as Map,
  );
  final compatibility = Map<String, Object?>.from(
    report['packCompatibility']! as Map,
  );
  final scanner = Map<String, Object?>.from(
    report['scannerDispositionCounts']! as Map,
  );
  final rejection = Map<String, Object?>.from(
    report['rejectionReasons']! as Map,
  );
  final topRejection = rejection.entries.toList()
    ..sort((a, b) => (b.value as int).compareTo(a.value as int));
  final out = StringBuffer()
    ..writeln('# M5.9d-14 — Legacy Static `##` / `||` Transform')
    ..writeln()
    ..writeln('输入：`C:\\Users\\TOM\\Desktop\\测试\\新建文件夹`')
    ..writeln()
    ..writeln('本阶段只允许字面前缀移除和同动作 CSS fallback；不执行正则、脚本、模板、网络请求或 Registry 导入。')
    ..writeln()
    ..writeln('## 统计')
    ..writeln()
    ..writeln('| 项目 | 数量 |')
    ..writeln('|---|---:|')
    ..writeln('| 读取记录 | ${report['recordsRead']} |')
    ..writeln('| 去重后记录 | ${report['uniqueRecords']} |')
    ..writeln('| Scanner 自动候选 | ${scanner['AUTOMATICALLY_CONVERTIBLE'] ?? 0} |')
    ..writeln('| 含 `##`/`||` 来源 | ${evidence['sourcesWithStaticTransforms']} |')
    ..writeln('| 变换规则出现次数 | ${evidence['transformOccurrences']} |')
    ..writeln('| 字面前缀映射 | ${evidence['literalPrefixMappings']} |')
    ..writeln('| fallback 映射 | ${evidence['fallbackMappings']} |')
    ..writeln('| 拒绝（正则/动态/不一致） | ${evidence['rejectedTransforms']} |')
    ..writeln()
    ..writeln('Scanner 分布：`$scanner`')
    ..writeln()
    ..writeln('严格转换结果：`$outcomes`')
    ..writeln()
    ..writeln('Pack 兼容结果：`$compatibility`')
    ..writeln()
    ..writeln('## 支持边界')
    ..writeln()
    ..writeln('- `selector@text##字面前缀` → `removePrefix`（只在结果以该前缀开头时移除）')
    ..writeln('- `selectorA@text||selectorB@text` → 有序 fallback selector')
    ..writeln(
      '- 顶层 `bookList`/目录节点、正文节点的 `||`/`##` 不强行转换，因为现有契约只有单一节点 selector',
    )
    ..writeln('- 正则替换、多段 `##`、索引、脚本、模板、XPath/JSONPath、登录/Cookie/Auth 保留为人工复核')
    ..writeln()
    ..writeln('## 代表拒绝原因');
  for (final entry in topRejection.take(10)) {
    out.writeln('- `${entry.key}`：${entry.value}');
  }
  out
    ..writeln()
    ..writeln('## Gate')
    ..writeln()
    ..writeln('- `flutter analyze --no-pub`：待执行')
    ..writeln('- 静态变换/Legacy 定向测试：待执行')
    ..writeln('- 全量 `flutter test`：待执行')
    ..writeln('- `git diff --check`：待执行')
    ..writeln()
    ..writeln('Registry 导入：`NOT_RUN`；网络抓取：`NOT_RUN`。');
  return out.toString();
}

Iterable<_StringField> _stringFields(Object? value, [String path = '']) sync* {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString();
      yield* _stringFields(entry.value, path.isEmpty ? key : '$path.$key');
    }
    return;
  }
  if (value is Iterable) {
    var index = 0;
    for (final item in value) {
      yield* _stringFields(item, '$path[$index]');
      index++;
    }
    return;
  }
  if (value is String) yield _StringField(path, value.trim());
}

final class _StringField {
  const _StringField(this.path, this.value);

  final String path;
  final String value;
}
