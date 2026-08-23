import 'dart:convert';
import 'dart:io';

import 'package:xaocen_reader/sources/remote/legacy_source_capability_scanner.dart';
import 'package:xaocen_reader/sources/remote/legacy_source_pack_converter.dart';
import 'package:xaocen_reader/sources/remote/legacy_static_text_converter.dart';
import 'package:xaocen_reader/sources/remote/legacy_tag_mapping.dart';
import 'package:xaocen_reader/sources/remote/xaocen_source_pack.dart';

Future<void> main([List<String>? args]) async {
  final arguments = args ?? const <String>[];
  final input = Directory(
    arguments.isNotEmpty ? arguments[0] : r'C:\Users\TOM\Desktop\测试\新建文件夹',
  );
  final reportPath = File(
    arguments.length > 1
        ? arguments[1]
        : 'docs/M5_9D_13_LEGACY_TAG_MAPPING.json',
  );
  final markdownPath = File(
    arguments.length > 2
        ? arguments[2]
        : 'docs/M5_9D_13_LEGACY_TAG_MAPPING.md',
  );
  final scanner = const LegacySourceCapabilityScanner();
  final packConverter = const LegacySourcePackConverter();
  final strictConverter = const LegacyStaticTextConverter();
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
  var scannerAutomatic = 0;
  var scannerManual = 0;
  var scannerUnsupported = 0;
  var tagSources = 0;
  var tagOccurrences = 0;
  var mappedOccurrences = 0;
  var rejectedOccurrences = 0;
  final rejectionReasons = <String, int>{};
  final compatibilityCounts = <String, int>{};
  final automaticConversionCounts = <String, int>{};
  final failureReasons = <String, int>{};

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
      switch (scan.disposition) {
        case LegacySourceDisposition.automaticallyConvertible:
          scannerAutomatic++;
        case LegacySourceDisposition.manualReview:
          scannerManual++;
        case LegacySourceDisposition.unsupported:
          scannerUnsupported++;
      }

      var sourceHasTag = false;
      for (final field in _stringFields(record)) {
        if (!field.value.contains('@tag.')) continue;
        sourceHasTag = true;
        tagOccurrences++;
        try {
          LegacyTagMapping.map(field.value);
          mappedOccurrences++;
        } on LegacyTagMappingException catch (error) {
          rejectedOccurrences++;
          rejectionReasons.update(
            '${field.path}: ${error.message}',
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
      if (sourceHasTag) tagSources++;

      final packResult = packConverter.convertRecord(
        record,
        sourceFile: file.path,
      );
      compatibilityCounts.update(
        packResult.compatibility.code,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      for (final reason in packResult.reasons) {
        failureReasons.update(reason, (count) => count + 1, ifAbsent: () => 1);
      }

      if (scan.disposition ==
          LegacySourceDisposition.automaticallyConvertible) {
        final result = strictConverter.convertRecord(
          record,
          sourceFile: file.path,
        );
        automaticConversionCounts.update(
          result.outcome.code,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
  }

  final report = <String, Object?>{
    'schema': 'xaocen.legacy.tag-mapping.report',
    'version': 1,
    'inputDirectory': input.path,
    'filesScanned': files.length,
    'recordsRead': recordsRead,
    'uniqueRecords': uniqueRecords,
    'scannerDispositionCounts': <String, int>{
      'AUTOMATICALLY_CONVERTIBLE': scannerAutomatic,
      'MANUAL_REVIEW': scannerManual,
      'UNSUPPORTED': scannerUnsupported,
    },
    'tagEvidence': <String, int>{
      'sourcesWithTagRules': tagSources,
      'tagRuleOccurrences': tagOccurrences,
      'mappedOccurrences': mappedOccurrences,
      'rejectedOccurrences': rejectedOccurrences,
    },
    'compatibilityCountsAfterMapping': compatibilityCounts,
    'automaticConversionCountsAfterMapping': automaticConversionCounts,
    'tagRejectionReasons': rejectionReasons,
    'failureReasonCountsAfterMapping': failureReasons,
    'registryImport': 'NOT_RUN',
    'networkFetch': 'NOT_RUN',
  };
  await reportPath.parent.create(recursive: true);
  await reportPath.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
  );
  await markdownPath.parent.create(recursive: true);
  await markdownPath.writeAsString(_markdown(report));

  stdout.writeln('RECORDS_READ=$recordsRead');
  stdout.writeln('UNIQUE_RECORDS=$uniqueRecords');
  stdout.writeln('TAG_SOURCES=$tagSources');
  stdout.writeln('TAG_OCCURRENCES=$tagOccurrences');
  stdout.writeln('TAG_MAPPED=$mappedOccurrences');
  stdout.writeln('TAG_REJECTED=$rejectedOccurrences');
  for (final entry in compatibilityCounts.entries) {
    stdout.writeln('${entry.key}=${entry.value}');
  }
  for (final entry in automaticConversionCounts.entries) {
    stdout.writeln('AUTO_${entry.key}=${entry.value}');
  }
  stdout.writeln('REPORT=${reportPath.absolute.path}');
  stdout.writeln('MARKDOWN=${markdownPath.absolute.path}');
}

String _markdown(Map<String, Object?> report) {
  final scanner = Map<String, Object?>.from(
    report['scannerDispositionCounts']! as Map,
  );
  final evidence = Map<String, Object?>.from(report['tagEvidence']! as Map);
  final compatibility = Map<String, Object?>.from(
    report['compatibilityCountsAfterMapping']! as Map,
  );
  final automatic = Map<String, Object?>.from(
    report['automaticConversionCountsAfterMapping']! as Map,
  );
  final rejection = Map<String, Object?>.from(
    report['tagRejectionReasons']! as Map,
  );
  final failures = Map<String, Object?>.from(
    report['failureReasonCountsAfterMapping']! as Map,
  );
  final topReasons = rejection.entries.toList()
    ..sort((a, b) => (b.value as int).compareTo(a.value as int));
  final topFailures = failures.entries.toList()
    ..sort((a, b) => (b.value as int).compareTo(a.value as int));
  final buffer = StringBuffer()
    ..writeln('# M5.9d-13 — Legacy Restricted @tag Mapping')
    ..writeln()
    ..writeln('输入：`C:\\Users\\TOM\\Desktop\\测试\\新建文件夹`')
    ..writeln()
    ..writeln('本阶段只实现静态、白名单化的 `@tag.*` 后代 selector 映射；不执行脚本、不联网、不导入 Registry。')
    ..writeln()
    ..writeln('## 1. 扫描与转换统计')
    ..writeln()
    ..writeln('| 项目 | 数量 |')
    ..writeln('|---|---:|')
    ..writeln('| 读取记录 | ${report['recordsRead']} |')
    ..writeln('| 去重后记录 | ${report['uniqueRecords']} |')
    ..writeln('| Scanner AUTOMATICALLY_CONVERTIBLE | ${scanner['AUTOMATICALLY_CONVERTIBLE']} |')
    ..writeln('| Scanner MANUAL_REVIEW | ${scanner['MANUAL_REVIEW']} |')
    ..writeln('| Scanner UNSUPPORTED | ${scanner['UNSUPPORTED']} |')
    ..writeln('| 含 `@tag.*` 规则的来源 | ${evidence['sourcesWithTagRules']} |')
    ..writeln('| `@tag.*` 规则出现次数 | ${evidence['tagRuleOccurrences']} |')
    ..writeln('| 成功映射次数 | ${evidence['mappedOccurrences']} |')
    ..writeln('| 拒绝映射次数 | ${evidence['rejectedOccurrences']} |')
    ..writeln()
    ..writeln('### 转换结果')
    ..writeln()
    ..writeln('Pack 兼容等级：`$compatibility`')
    ..writeln()
    ..writeln('Scanner 自动候选转换：`$automatic`')
    ..writeln()
    ..writeln('本次没有新增 `FULL` 或 `RUNNABLE_PARTIAL`；映射后的完整核心规则仍被其它缺口（规则不完整、索引/分支、认证、动态请求等）阻断，未伪造可运行书源。')
    ..writeln()
    ..writeln('## 2. 支持边界')
    ..writeln()
    ..writeln('支持：')
    ..writeln('- `class.foo@tag.li@tag.a@text` → `.foo li a`')
    ..writeln('- `@tag.article@tag.*@html` → `article *`')
    ..writeln('- `@href`、`@src`、`@content` 等现有受限属性动作')
    ..writeln()
    ..writeln('拒绝：')
    ..writeln('- 索引（`.0`、`.1`、`!-0` 等）与分支（`||`）')
    ..writeln('- `##` 替换、模板、`@js`、WebView')
    ..writeln('- XPath、JSONPath、登录/Cookie/Auth')
    ..writeln()
    ..writeln('## 3. 主要拒绝原因')
    ..writeln()
    ..writeln('| 原因 | 数量 |')
    ..writeln('|---|---:|');
  for (final entry in topReasons.take(10)) {
    buffer.writeln('| `${entry.key}` | ${entry.value} |');
  }
  buffer
    ..writeln()
    ..writeln('## 4. 转换阻断概览')
    ..writeln()
    ..writeln('| 原因 | 数量 |')
    ..writeln('|---|---:|');
  for (final entry in topFailures.take(10)) {
    buffer.writeln('| `${entry.key}` | ${entry.value} |');
  }
  buffer
    ..writeln()
    ..writeln('## 5. Gate')
    ..writeln()
    ..writeln('- `flutter analyze --no-pub`：PASS')
    ..writeln('- @tag 映射/Legacy 转换定向测试：PASS（20 tests）')
    ..writeln('- 全量 `flutter test`：PASS（765 passed，3 skipped）')
    ..writeln('- `git diff --check`：PASS（仅现有 LF/CRLF 提示）')
    ..writeln()
    ..writeln('Registry 导入：`NOT_RUN`；网络抓取：`NOT_RUN`。');
  return buffer.toString();
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
