import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/reader/content_transform.dart';
import 'package:xaocen_reader/domain/reader/reader_content.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';

void main() {
  test(
    'article stages preserve list to body identity and transform boundary',
    () async {
      final adapter = _ArticleFixtureAdapter();
      final page = await adapter.list(
        WebArticleListRequest(uri: Uri.parse('https://example.test/articles')),
      );
      final item = page.items.single;
      final document = await adapter.open(item);

      expect(page.items.single.identity, 'article-1');
      expect(document.item.identity, item.identity);
      expect(document.ruleSet.id, 'article-rules');
      expect(document.body.canonical.contentId, 'article-1');

      final derived = document.body.derive(const IdentityContentTransform());
      expect(derived.text, '正文');
      expect(derived.canPersistCanonicalLocator, isTrue);
      expect(adapter.remoteKind, RemoteSourceKind.webArticle);
    },
  );

  test('book stages preserve source TOC order and chapter identity', () async {
    final adapter = _BookFixtureAdapter();
    final results = await adapter.search(
      const WebBookSearchRequest(query: '示例书'),
    );
    final detail = await adapter.openDetail(results.single);
    final toc = await adapter.loadTableOfContents(detail);
    final chapter = await adapter.openChapter(detail, toc.entries.last);

    expect(toc.entries.map((entry) => entry.orderIndex), [9, 2]);
    expect(chapter.entry.chapterKey, 'chapter-b');
    expect(chapter.body.canonical.contentId, 'book-1:chapter-b');
    expect(adapter.remoteKind, RemoteSourceKind.webBook);
  });

  test('both adapters project through existing ReaderContent contract', () {
    final collection = LibraryCollection(
      id: 'collection-1',
      sourceId: 'remote:article-1',
      title: '示例文章',
      subtitle: null,
      itemCount: 1,
      normalizedCharacterLength: 2,
      detectedEncoding: TextEncoding.utf8,
      sourceSize: 6,
      importedAt: DateTime.utc(2026, 1, 1),
    );
    final content = _ArticleFixtureAdapter().adapt(
      collection: collection,
      documents: const <LibraryDocument>[],
      navigation: const <LibraryTocEntry>[],
    );

    expect(content.identity.contentId, collection.id);
    expect(content.identity.sourceKind, ReaderContentSourceKinds.online);
    expect(content.metadata.title, '示例文章');
  });

  test(
    'article source can declare a list endpoint without changing rule identity',
    () {
      final source = WebArticleSource(
        id: RemoteSourceId('article:fixture'),
        endpoint: Uri.parse('https://example.test'),
        listUri: Uri.parse('https://example.test/articles'),
        articleUri: Uri.parse('https://example.test/articles/1'),
        ruleSetId: 'article-rules',
      );

      expect(source.accepts(source.endpoint), isTrue);
      expect(source.accepts(source.listUri!), isTrue);
      expect(source.accepts(source.articleUri), isTrue);
      expect(source.accepts(Uri.parse('https://example.test/other')), isFalse);
    },
  );
}

final class _ArticleFixtureAdapter implements WebArticleSourceAdapter {
  _ArticleFixtureAdapter()
    : source = WebArticleSource(
        id: RemoteSourceId('article:fixture'),
        endpoint: Uri.parse('https://example.test'),
        listUri: Uri.parse('https://example.test/articles'),
        articleUri: Uri.parse('https://example.test/articles/1'),
        ruleSetId: 'article-rules',
      );

  @override
  final WebArticleSource source;

  @override
  RemoteSourceKind get remoteKind => RemoteSourceKind.webArticle;

  @override
  String get sourceKind => ReaderContentSourceKinds.online;

  @override
  bool canAdapt(LibraryCollection collection) =>
      collection.sourceId == 'remote:article-1';

  @override
  bool canAdaptRemote(RemoteSource source) => source.kind == remoteKind;

  @override
  Future<WebArticleListPage> list(WebArticleListRequest request) async {
    return WebArticleListPage(
      items: <WebArticleListItem>[
        WebArticleListItem(
          identity: 'article-1',
          title: '示例文章',
          uri: source.articleUri,
        ),
      ],
      sourceRevision: 'fixture-v1',
    );
  }

  @override
  Future<WebArticleDocument> open(WebArticleListItem item) async {
    return WebArticleDocument(
      item: item,
      body: const WebSourceBody(
        canonical: CanonicalContent(
          contentId: 'article-1',
          sourceRevision: 'fixture-v1',
          text: '正文',
        ),
      ),
      ruleSet: const WebRuleSetRef(id: 'article-rules'),
    );
  }

  @override
  ReaderContent adapt({
    required LibraryCollection collection,
    required List<LibraryDocument> documents,
    required List<LibraryTocEntry> navigation,
  }) {
    return ReaderContent(
      identity: ReaderContentIdentity(
        contentId: collection.id,
        sourceId: collection.sourceId,
        sourceKind: sourceKind,
      ),
      metadata: ReaderContentMetadata.fromCollection(collection),
      documents: documents,
      navigation: navigation,
      normalizedCharacterLength: collection.normalizedCharacterLength,
    );
  }
}

final class _BookFixtureAdapter implements WebBookSourceAdapter {
  _BookFixtureAdapter()
    : source = WebBookSource(
        id: RemoteSourceId('book:fixture'),
        endpoint: Uri.parse('https://example.test'),
        bookKey: 'book-1',
        ruleSetId: 'book-rules',
      );

  @override
  final WebBookSource source;

  @override
  RemoteSourceKind get remoteKind => RemoteSourceKind.webBook;

  @override
  String get sourceKind => ReaderContentSourceKinds.online;

  @override
  bool canAdapt(LibraryCollection collection) =>
      collection.sourceId == 'remote:book-1';

  @override
  bool canAdaptRemote(RemoteSource source) => source.kind == remoteKind;

  @override
  Future<List<WebBookSearchResult>> search(WebBookSearchRequest request) async {
    return <WebBookSearchResult>[
      WebBookSearchResult(
        bookKey: 'book-1',
        title: '示例书',
        detailUri: Uri.parse('https://example.test/books/1'),
      ),
    ];
  }

  @override
  Future<WebBookDetail> openDetail(WebBookSearchResult result) async {
    return WebBookDetail(
      bookKey: result.bookKey,
      title: result.title,
      detailUri: result.detailUri,
      ruleSet: const WebRuleSetRef(id: 'book-rules'),
    );
  }

  @override
  Future<WebBookTableOfContents> loadTableOfContents(
    WebBookDetail detail,
  ) async {
    return WebBookTableOfContents(
      bookKey: detail.bookKey,
      entries: <WebBookTocEntry>[
        WebBookTocEntry(
          chapterKey: 'chapter-a',
          title: '第二章',
          orderIndex: 9,
          chapterUri: Uri.parse('https://example.test/books/1/2'),
        ),
        WebBookTocEntry(
          chapterKey: 'chapter-b',
          title: '第一章',
          orderIndex: 2,
          chapterUri: Uri.parse('https://example.test/books/1/1'),
        ),
      ],
    );
  }

  @override
  Future<WebBookChapter> openChapter(
    WebBookDetail detail,
    WebBookTocEntry entry,
  ) async {
    return WebBookChapter(
      bookKey: detail.bookKey,
      entry: entry,
      body: WebSourceBody(
        canonical: CanonicalContent(
          contentId: '${detail.bookKey}:${entry.chapterKey}',
          sourceRevision: 'fixture-v1',
          text: entry.title,
        ),
      ),
      ruleSet: detail.ruleSet ?? const WebRuleSetRef(id: 'book-rules'),
    );
  }

  @override
  ReaderContent adapt({
    required LibraryCollection collection,
    required List<LibraryDocument> documents,
    required List<LibraryTocEntry> navigation,
  }) {
    return ReaderContent(
      identity: ReaderContentIdentity(
        contentId: collection.id,
        sourceId: collection.sourceId,
        sourceKind: sourceKind,
      ),
      metadata: ReaderContentMetadata.fromCollection(collection),
      documents: documents,
      navigation: navigation,
      normalizedCharacterLength: collection.normalizedCharacterLength,
    );
  }
}
