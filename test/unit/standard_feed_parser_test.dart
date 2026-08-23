import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/sources/remote/standard_feed_parser.dart';

void main() {
  const rss = '''
<rss version="2.0"><channel>
  <title>示例订阅</title><description>摘要</description>
  <item><title>第一篇</title><guid>entry-1</guid><pubDate>2026-08-01T10:00:00Z</pubDate><description>正文一</description><link>https://example.test/1</link></item>
  <item><title>第二篇</title><link>https://example.test/2</link><description>正文二</description></item>
</channel></rss>
''';
  const atom = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom 示例</title><author><name>作者</name></author>
  <entry><id>tag:example.test,2026:1</id><title>Atom 第一篇</title>
    <updated>2026-08-02T10:00:00Z</updated><link rel="alternate" href="https://example.test/a"/>
    <summary>Atom 正文</summary>
  </entry>
</feed>
''';

  StandardFeedSource source(String id, String format) => StandardFeedSource(
    id: RemoteSourceId(id),
    endpoint: Uri.parse('https://example.test/$id'),
    format: format,
  );

  test('RSS 2.0 keeps item order and extracts core fields', () {
    final result = const StandardFeedParser().parse(
      xml: rss,
      source: source('rss-main', 'rss'),
    );

    expect(result.format, StandardFeedFormat.rss);
    expect(result.title, '示例订阅');
    expect(result.items.map((item) => item.title), ['第一篇', '第二篇']);
    expect(result.items.first.body, '正文一');
    expect(result.items.first.link, Uri.parse('https://example.test/1'));
    expect(result.items.first.publishedAt, isNotNull);
  });

  test('Atom extracts author, updated time and alternate link', () {
    final result = const StandardFeedParser().parse(
      xml: atom,
      source: source('atom-main', 'atom'),
    );

    expect(result.format, StandardFeedFormat.atom);
    expect(result.author, '作者');
    expect(result.items.single.author, '作者');
    expect(result.items.single.link, Uri.parse('https://example.test/a'));
    expect(result.items.single.summary, 'Atom 正文');
  });

  test('identities stay stable when the source order is unchanged', () {
    final parser = const StandardFeedParser();
    final first = parser.parse(xml: rss, source: source('rss-main', 'rss'));
    final second = parser.parse(xml: rss, source: source('rss-main', 'rss'));

    expect(first.stableSourceIdentity, second.stableSourceIdentity);
    expect(
      first.items.map((item) => item.identity).toList(),
      second.items.map((item) => item.identity).toList(),
    );
  });

  test('normalizes HTML content, entities, paragraphs, links and images', () {
    const htmlRss = '''
<rss version="2.0"><channel><title>HTML</title>
  <item><title>HTML 条目</title><guid>html-1</guid>
    <description><![CDATA[<p>摘要 &amp; 实体</p>]]></description>
    <content:encoded xmlns:content="http://purl.org/rss/1.0/modules/content/"><![CDATA[
      <p>第一段&nbsp;正文<br>换行</p>
      <p><strong>第二段</strong> <a href="https://example.test/full">阅读全文</a></p>
      <img src="https://example.test/image.jpg" alt="封面图">
    ]]></content:encoded>
    <link>https://example.test/html</link>
  </item></channel></rss>
''';
    final result = const StandardFeedParser().parse(
      xml: htmlRss,
      source: source('html', 'rss'),
    );
    final body = result.items.single.body;

    expect(body, contains('第一段 正文'));
    expect(body, contains('换行'));
    expect(body, contains('第二段'));
    expect(body, contains('阅读全文 (https://example.test/full)'));
    expect(body, contains('[图片：封面图]'));
    expect(result.items.single.imageLinks, [
      Uri.parse('https://example.test/image.jpg'),
    ]);
    expect(body, isNot(contains('<p>')));
    expect(body, isNot(contains('<img')));
    expect(result.items.single.summary, '摘要 & 实体');
  });

  test('RSS plain content element is preferred over a short description', () {
    const contentRss = '''
<rss version="2.0"><channel><title>Plain content</title>
  <item><title>长文</title>
    <description>只有一句摘要</description>
    <content><![CDATA[<p>完整正文第一段。</p><p>完整正文第二段。</p>]]></content>
  </item></channel></rss>
''';
    final result = const StandardFeedParser().parse(
      xml: contentRss,
      source: source('plain-content', 'rss'),
    );

    expect(result.items.single.body, '完整正文第一段。\n完整正文第二段。');
  });

  test('Atom joins split CDATA without exposing XML delimiters', () {
    const splitCdata = '''
<feed xmlns="http://www.w3.org/2005/Atom"><title>CDATA</title>
  <entry><id>split-1</id><title>分段正文</title>
    <content type="html"><![CDATA[<p>第一段</p>]]><![CDATA[<p>第二段</p>]]></content>
  </entry>
</feed>
''';
    final result = const StandardFeedParser().parse(
      xml: splitCdata,
      source: source('split-cdata', 'atom'),
    );

    expect(result.items.single.body, '第一段\n第二段');
    expect(result.items.single.body, isNot(contains(']]>')));
  });

  test('falls back to summary and marks link-only entries without body', () {
    const linkOnly = '''
<rss version="2.0"><channel><title>Fallback</title>
  <item><title>有摘要</title><guid>fallback-1</guid>
    <description>这是可读摘要</description>
    <content:encoded xmlns:content="http://purl.org/rss/1.0/modules/content/"><![CDATA[<a href="https://example.test/full">阅读全文</a>]]></content:encoded>
  </item>
  <item><title>无正文</title><guid>fallback-2</guid>
    <link>https://example.test/only-link</link>
  </item></channel></rss>
''';
    final result = const StandardFeedParser().parse(
      xml: linkOnly,
      source: source('fallback', 'rss'),
    );

    expect(result.items[0].body, '这是可读摘要');
    expect(result.items[1].body, '订阅源未提供正文');
  });

  test('feed projects into the existing ReaderContent contract', () {
    final result = const StandardFeedParser().parse(
      xml: rss,
      source: source('rss-main', 'rss'),
    );
    final projection = const StandardFeedParser().toReaderContent(result);

    expect(projection.content.identity.sourceKind, 'rss');
    expect(projection.content.documents, hasLength(2));
    expect(projection.content.navigation, hasLength(2));
    expect(projection.content.navigation.first.startCharacterOffset, 0);
    expect(projection.documentTextById, hasLength(2));
    expect(projection.content.normalizedCharacterLength, greaterThan(0));
  });

  test('malformed or unsupported roots fail at the source boundary', () {
    final parser = const StandardFeedParser();
    expect(
      () => parser.parse(
        xml: '<html><body>not a feed</body></html>',
        source: source('bad', 'rss'),
      ),
      throwsA(isA<StandardFeedParseException>()),
    );
    expect(
      () => parser.parse(xml: '<rss>', source: source('bad', 'rss')),
      throwsA(isA<StandardFeedParseException>()),
    );
  });
}
