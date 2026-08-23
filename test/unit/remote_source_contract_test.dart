import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';

void main() {
  test(
    'remote source kinds keep feed, article and book semantics separate',
    () {
      final feed = StandardFeedSource(
        id: RemoteSourceId('feed:example'),
        endpoint: Uri.parse('https://example.com/feed.xml'),
        format: 'atom',
      );
      final article = WebArticleSource(
        id: RemoteSourceId('article:example:1'),
        endpoint: Uri.parse('https://example.com'),
        articleUri: Uri.parse('https://example.com/posts/1'),
        ruleSetId: 'article-v1',
      );
      final book = WebBookSource(
        id: RemoteSourceId('book:example:book-1'),
        endpoint: Uri.parse('https://example.com'),
        bookKey: 'book-1',
        ruleSetId: 'book-v1',
      );

      expect(feed.kind, RemoteSourceKind.standardFeed);
      expect(article.kind, RemoteSourceKind.webArticle);
      expect(book.kind, RemoteSourceKind.webBook);
      expect(RemoteSourceKind.values.map((kind) => kind.wireName), [
        'standardFeed',
        'webArticle',
        'webBook',
      ]);
      expect(article.accepts(article.articleUri), isTrue);
      expect(
        article.accepts(Uri.parse('https://example.com/posts/2')),
        isFalse,
      );
      expect(book.accepts(Uri.parse('https://example.com/chapter/2')), isTrue);
    },
  );

  test('shared request plan separates safe headers from auth and cookies', () {
    final source = StandardFeedSource(
      id: RemoteSourceId('feed:secure'),
      endpoint: Uri.parse('https://example.com'),
      format: 'rss',
      requestCapabilities: const RemoteRequestCapabilities(
        allowedHeaders: {'accept', 'user-agent'},
        authSchemes: {RemoteAuthScheme.bearer},
        cookieMode: RemoteCookieMode.session,
      ),
    );
    final plan = source.planRequest(
      uri: Uri.parse('https://example.com/feed.xml'),
      headers: RemoteHeaders({'Accept': 'application/rss+xml'}),
      credential: const RemoteCredentialRef(
        id: 'credential:feed',
        scheme: RemoteAuthScheme.bearer,
      ),
      cookieJar: const RemoteCookieJarRef(id: 'cookie:feed'),
    );

    expect(plan.method, 'GET');
    expect(plan.headers.values, {'accept': 'application/rss+xml'});
    expect(plan.credential?.id, 'credential:feed');
    expect(plan.cookieJar?.id, 'cookie:feed');
    expect(plan.capabilities.allowsCookies, isTrue);
  });

  test(
    'request boundary rejects secrets, undeclared capabilities and unsafe URI',
    () {
      expect(
        () => RemoteHeaders({'Authorization': 'Bearer secret'}),
        throwsArgumentError,
      );

      final source = StandardFeedSource(
        id: RemoteSourceId('feed:limited'),
        endpoint: Uri.parse('https://example.com'),
        format: 'rss',
      );
      expect(
        () => source.planRequest(
          uri: Uri.parse('https://example.com/feed.xml'),
          headers: RemoteHeaders({'accept': 'application/rss+xml'}),
        ),
        throwsArgumentError,
      );
      expect(
        () => source.planRequest(
          uri: Uri.parse('https://example.com/feed.xml'),
          credential: const RemoteCredentialRef(
            id: 'credential:1',
            scheme: RemoteAuthScheme.bearer,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => source.planRequest(uri: Uri.parse('file:///tmp/feed.xml')),
        throwsArgumentError,
      );
      expect(
        () => source.planRequest(
          uri: Uri.parse('https://other.example.org/feed.xml'),
        ),
        throwsArgumentError,
      );
    },
  );

  test('Legado JSON is an explicit future codec extension point', () {
    expect(RemoteSourceConfigFormats.legadoJson, 'legado-json');
  });
}
