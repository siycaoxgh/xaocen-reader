import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/sources/remote/legacy_capability_gap_clustering.dart';
import 'package:xaocen_reader/sources/remote/xaocen_source_pack.dart';

XaocenSourcePackEntry _needs({
  required String sourceId,
  required Map<String, Object?> fields,
  required List<String> reasons,
}) => XaocenSourcePackEntry(
  sourceId: sourceId,
  legacySourceId: 'legado:$sourceId',
  sourceName: sourceId,
  compatibility: LegacyCompatibilityLevel.needsCapability,
  sourceFile: 'fixture.json',
  legacyFields: fields,
  reasons: reasons,
);

void main() {
  test('clusters overlapping gaps and keeps optional runnable entries out', () {
    final pack = XaocenWebBookSourcePack(
      packId: 'cluster-test',
      name: 'cluster test',
      sources: <XaocenSourcePackEntry>[
        _needs(
          sourceId: 'one',
          fields: <String, Object?>{
            'ruleSearch.bookList': '.list@tag.li',
            'enabledCookieJar': false,
          },
          reasons: const <String>['检测到 XPath 选择器'],
        ),
        _needs(
          sourceId: 'two',
          fields: <String, Object?>{'ruleContent.replaceRegex': '##广告'},
          reasons: const <String>[],
        ),
        _needs(
          sourceId: 'three',
          fields: <String, Object?>{'header': 'User-Agent: fixture'},
          reasons: const <String>[],
        ),
        const XaocenSourcePackEntry(
          sourceId: 'partial',
          legacySourceId: 'legado:partial',
          sourceName: 'partial',
          compatibility: LegacyCompatibilityLevel.runnablePartial,
          sourceFile: 'fixture.json',
          legacyFields: <String, Object?>{'ruleSearch.coverUrl': 'img@src'},
          reasons: <String>[],
        ),
      ],
    );

    final report = const LegacyCapabilityGapAnalyzer().analyze(pack);

    expect(report.sourceCount, 3);
    expect(report.categoryCounts[LegacyCapabilityGap.tagAction], 1);
    expect(report.categoryCounts[LegacyCapabilityGap.xpath], 1);
    expect(report.categoryCounts[LegacyCapabilityGap.regexReplace], 1);
    expect(report.categoryCounts[LegacyCapabilityGap.headerCookieAuth], 1);
    expect(report.scannerOnlyAuthSignals, 0);
    expect(report.estimates, isNotEmpty);
  });

  test('enabledCookieJar false is not treated as auth evidence', () {
    final pack = XaocenWebBookSourcePack(
      packId: 'false-cookie-test',
      name: 'false cookie test',
      sources: <XaocenSourcePackEntry>[
        _needs(
          sourceId: 'one',
          fields: <String, Object?>{'enabledCookieJar': false},
          reasons: const <String>[],
        ),
      ],
    );

    final report = const LegacyCapabilityGapAnalyzer().analyze(pack);
    expect(report.categoryCounts[LegacyCapabilityGap.headerCookieAuth], 0);
    expect(report.categoryCounts[LegacyCapabilityGap.other], 1);
  });
}
