import 'dart:convert';
import 'dart:io';

import 'package:xaocen_reader/sources/remote/legacy_capability_gap_clustering.dart';
import 'package:xaocen_reader/sources/remote/xaocen_source_pack.dart';

Future<void> main([List<String>? args]) async {
  final arguments = args ?? const <String>[];
  final packPath = File(
    arguments.isNotEmpty
        ? arguments[0]
        : 'docs/M5_9D_12_1_LEGACY_SOURCE_PACK.json',
  );
  final jsonPath = File(
    arguments.length > 1
        ? arguments[1]
        : 'docs/M5_9D_12_2_LEGACY_CAPABILITY_GAP_CLUSTERING.json',
  );
  final markdownPath = File(
    arguments.length > 2
        ? arguments[2]
        : 'docs/M5_9D_12_2_LEGACY_CAPABILITY_GAP_CLUSTERING.md',
  );

  final pack = XaocenWebBookSourcePack.fromJsonString(
    await packPath.readAsString(),
  );
  final report = const LegacyCapabilityGapAnalyzer().analyze(pack);
  await jsonPath.parent.create(recursive: true);
  await jsonPath.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report.toJson()),
  );
  await markdownPath.parent.create(recursive: true);
  await markdownPath.writeAsString(_markdown(report, packPath));

  stdout.writeln('NEEDS_CAPABILITY=${report.sourceCount}');
  for (final entry in report.categoryCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))) {
    stdout.writeln('${entry.key.code}=${entry.value}');
  }
  stdout.writeln('JSON=${jsonPath.absolute.path}');
  stdout.writeln('REPORT=${markdownPath.absolute.path}');
}

String _markdown(
  LegacyCapabilityGapClusterReport report,
  File packPath,
) {
  final buffer = StringBuffer()
    ..writeln('# M5.9d-12.2 — Legacy Capability Gap Clustering')
    ..writeln()
    ..writeln('输入 Pack：`${packPath.path}`')
    ..writeln()
    ..writeln('本报告只分析 Source Pack 中的 `NEEDS_CAPABILITY` 条目；不联网、不执行规则、不修改生产引擎。')
    ..writeln()
    ..writeln('## 1. 能力缺口统计')
    ..writeln()
    ..writeln('| 缺口 | 覆盖书源 | 覆盖率 |')
    ..writeln('|---|---:|---:|');
  for (final entry in report.categoryCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))) {
    final percentage = (entry.value * 100 / report.sourceCount).toStringAsFixed(1);
    buffer.writeln('| `${entry.key.code}` | ${entry.value} | $percentage% |');
  }
  buffer
    ..writeln()
    ..writeln('同一书源可以命中多个缺口，因此各行不能相加。')
    ..writeln()
    ..writeln('Header/Cookie/Auth 细分使用原始字段证据；扫描器仅因 `enabledCookieJar=false` 产生的误报不计入字段缺口（本批 scanner-only 信号：${report.scannerOnlyAuthSignals}）。')
    ..writeln()
    ..writeln('## 2. Top 10 高频组合')
    ..writeln()
    ..writeln('| 排名 | 组合 | 数量 |')
    ..writeln('|---:|---|---:|');
  var rank = 1;
  for (final entry in report.combinationCounts.entries) {
    buffer.writeln('| $rank | `${entry.key}` | ${entry.value} |');
    rank++;
  }
  buffer
    ..writeln()
    ..writeln('## 3. 单项能力新增转换估算')
    ..writeln()
    ..writeln('| 能力 | 命中数（上限） | 仅此单项缺口（保守新增） |')
    ..writeln('|---|---:|---:|');
  for (final estimate in report.estimates) {
    buffer.writeln(
      '| `${estimate.gap.code}` | ${estimate.coverage} | ${estimate.singleGapCandidates} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('“保守新增”只统计缺口集合恰好只有该项的书源；“上限”不扣除其它组合缺口，不能直接相加。')
    ..writeln()
    ..writeln('## 4. 优先级建议')
    ..writeln()
    ..writeln('- **低风险优先**：建立受限的 `@tag.*` → CSS 后代 selector 映射白名单，并为 `@ownText`/`##` 做纯静态、可审计的 transform 试验。')
    ..writeln('- **中风险独立 runtime**：动态 URL/template、嵌套目录/二次请求、XPath、JSONPath；每项都要独立安全边界和 fixture，不能混入当前 CSS runtime。')
    ..writeln('- **高风险暂缓**：JS/WebView、登录态自动化、复杂 Cookie/认证、图片/音频源；本阶段不实现。')
    ..writeln()
    ..writeln('## 5. 推荐下一阶段')
    ..writeln()
    ..writeln('1. 只实现受限 `@tag.*` selector 映射，并以离线 fixture 验证；预计立即可新增转换约 ${_estimate(report, ' @tag.*')} 条（按保守单项口径）。')
    ..writeln('2. 若第一项通过，再单独评估纯静态 `##`/`||` 内容变换；不要同时引入动态请求或认证。')
    ..writeln()
    ..writeln('当前结论：**CAPABILITY GAP ANALYSIS = PASS；生产能力扩展 = NOT STARTED**。');
  return buffer.toString();
}

int _estimate(LegacyCapabilityGapClusterReport report, String code) {
  for (final estimate in report.estimates) {
    if (estimate.gap.code == code.trim()) return estimate.singleGapCandidates;
  }
  return 0;
}
