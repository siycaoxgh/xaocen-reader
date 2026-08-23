import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/sources/remote/legacy_source_capability_scanner.dart';

Map<String, Object?> _staticRecord({
  String name = '静态测试源',
  String url = 'https://example.test',
}) => <String, Object?>{
  'bookSourceName': name,
  'bookSourceUrl': url,
  'bookSourceType': 0,
  'searchUrl': '/search?q={{key}}',
  'ruleSearch': <String, Object?>{
    'bookList': '.book',
    'name': '.title@text',
    'bookUrl': 'a@href',
  },
  'ruleBookInfo': <String, Object?>{'name': 'h1@text'},
  'ruleToc': <String, Object?>{
    'chapterList': '.chapter',
    'chapterName': '@text',
    'chapterUrl': '@href',
  },
  'ruleContent': <String, Object?>{'content': '#content@html'},
};

void main() {
  const scanner = LegacySourceCapabilityScanner();

  test('static CSS text source is an automatic conversion candidate', () {
    final result = scanner.scanRecord(_staticRecord());

    expect(result.isLegadoLike, isTrue);
    expect(result.capabilities, contains(LegacySourceCapability.staticText));
    expect(result.capabilities, isNot(contains(LegacySourceCapability.js)));
    expect(
      result.disposition,
      LegacySourceDisposition.automaticallyConvertible,
    );
    expect(result.ruleFields, contains('ruleContent.content'));
  });

  test('XPath, JSON API and login are surfaced for manual review', () {
    final xpath = scanner.scanRecord(<String, Object?>{
      ..._staticRecord(name: 'XPath 源', url: 'https://xpath.test'),
      'ruleSearch': <String, Object?>{
        'bookList': "//ul[@class='list']/li",
        'name': "//h2/text()",
      },
    });
    expect(xpath.capabilities, contains(LegacySourceCapability.xpath));
    expect(xpath.disposition, LegacySourceDisposition.manualReview);

    final api = scanner.scanRecord(<String, Object?>{
      ..._staticRecord(name: 'JSON 源', url: 'https://api.test'),
      'searchUrl': '/api/search, { method: post }',
      'ruleSearch': <String, Object?>{
        'bookList': r'$.data[*]',
        'name': r'$.name',
      },
    });
    expect(api.capabilities, contains(LegacySourceCapability.jsonApi));
    expect(api.disposition, LegacySourceDisposition.manualReview);

    final login = scanner.scanRecord(<String, Object?>{
      ..._staticRecord(name: '登录源', url: 'https://login.test'),
      'loginUrl': '/login',
      'enabledCookieJar': true,
    });
    expect(login.capabilities, contains(LegacySourceCapability.login));
    expect(login.disposition, LegacySourceDisposition.manualReview);
  });

  test('JS, WebView, image and audio are unsupported without execution', () {
    final js = scanner.scanRecord(<String, Object?>{
      ..._staticRecord(name: '脚本源', url: 'https://js.test'),
      'ruleContent': <String, Object?>{'content': '@js:java.url()'},
    });
    expect(js.capabilities, contains(LegacySourceCapability.js));
    expect(js.disposition, LegacySourceDisposition.unsupported);

    final webView = scanner.scanRecord(<String, Object?>{
      ..._staticRecord(name: 'WebView 源', url: 'https://webview.test'),
      'useWebView': true,
    });
    expect(webView.capabilities, contains(LegacySourceCapability.webview));
    expect(webView.disposition, LegacySourceDisposition.unsupported);

    final image = scanner.scanRecord(<String, Object?>{
      ..._staticRecord(name: '图片源', url: 'https://image.test'),
      'bookSourceType': 2,
      'imageStyle': 'gallery',
    });
    expect(image.capabilities, contains(LegacySourceCapability.image));
    expect(image.disposition, LegacySourceDisposition.unsupported);

    final audio = scanner.scanRecord(<String, Object?>{
      ..._staticRecord(name: '有声源', url: 'https://audio.test'),
      'bookSourceType': 1,
    });
    expect(audio.capabilities, contains(LegacySourceCapability.audio));
    expect(audio.disposition, LegacySourceDisposition.unsupported);
  });

  test('malformed JSON is invalid and never triggers a request', () {
    final result = scanner.scanJson('{not-json', sourceFile: 'bad.json');

    expect(result.capabilities, contains(LegacySourceCapability.invalid));
    expect(result.disposition, LegacySourceDisposition.unsupported);
    expect(result.reasons.single, contains('JSON 解析失败'));
  });

  test(
    'directory scan deduplicates subset exports without network access',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'xaocen-legacy-scan-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = _staticRecord(name: '重复源', url: 'https://duplicate.test');
      final second = _staticRecord(name: '唯一源', url: 'https://unique.test');
      await File(
        '${directory.path}/a.json',
      ).writeAsString(jsonEncode(<Object?>[first, second]));
      await File(
        '${directory.path}/b.json',
      ).writeAsString(jsonEncode(<Object?>[first]));
      await File('${directory.path}/bad.json').writeAsString('{bad');

      final report = await scanner.scanDirectory(directory);

      expect(report.filesScanned, 3);
      expect(report.recordsRead, 3);
      expect(report.uniqueRecords, 3); // two sources + one invalid file result
      expect(report.duplicateRecords, 1);
      expect(report.capabilityCounts['STATIC_TEXT'], 2);
      expect(report.capabilityCounts['INVALID'], 1);
      expect(report.dispositionCounts['UNSUPPORTED'], 1);
    },
  );
}
