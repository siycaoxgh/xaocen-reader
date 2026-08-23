import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xaocen_reader/domain/library/library_entities.dart';
import 'package:xaocen_reader/domain/local_txt/text_encoding.dart';
import 'package:xaocen_reader/domain/reader/content_transform.dart';
import 'package:xaocen_reader/domain/reader/reader_content.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';

void main() {
  test(
    'offline article fixture follows list → article → body → ReaderContent',
    () async {
      final adapter = _FixtureArticleAdapter();
      final page = await adapter.list(
        WebArticleListRequest(uri: adapter.source.listUri!),
      );
      final first = page.items.first;
      final document = await adapter.open(first);
      final derived = document.body.derive(const IdentityContentTransform());
      final content = adapter.adapt(
        collection: _collection(
          id: 'fixture-article-001',
          sourceId: 'fixture:web-article:article-001',
          title: document.item.title,
          length: document.body.canonical.utf16Length,
        ),
        documents: <LibraryDocument>[
          LibraryDocument(
            id: 'fixture-document-001',
            itemId: first.identity,
            storagePath: 'fixture/article-001.txt',
            mediaType: 'text/plain',
            startCharacterOffset: 0,
            endCharacterOffset: derived.text.length,
            contentHash: document.body.canonical.sourceRevision,
            normalizationVersion: 'fixture-v1',
          ),
        ],
        navigation: const <LibraryTocEntry>[],
      );

      expect(page.items.map((item) => item.identity), [
        'article-001',
        'article-002',
      ]);
      expect(document.item.identity, first.identity);
      expect(document.author, 'Fixture Author');
      expect(derived.text, contains('Important canonical article text.'));
      expect(derived.canPersistCanonicalLocator, isTrue);
      expect(content.identity.sourceKind, ReaderContentSourceKinds.online);
      expect(content.identity.sourceId, 'fixture:web-article:article-001');
      expect(content.metadata.title, 'Fixture Article One');
      expect(content.primaryDocument?.startCharacterOffset, 0);

      final repeated = await adapter.list(
        WebArticleListRequest(uri: adapter.source.listUri!),
      );
      expect(
        repeated.items.map((item) => item.identity),
        page.items.map((item) => item.identity),
      );
    },
  );

  test(
    'offline book fixture follows search → detail → TOC → chapter → ReaderContent',
    () async {
      final adapter = _FixtureBookAdapter();
      final results = await adapter.search(
        const WebBookSearchRequest(query: 'Fixture Book'),
      );
      final detail = await adapter.openDetail(results.single);
      final toc = await adapter.loadTableOfContents(detail);
      final firstChapter = await adapter.openChapter(detail, toc.entries.first);
      final secondChapter = await adapter.openChapter(detail, toc.entries.last);
      final content = adapter.adapt(
        collection: _collection(
          id: 'fixture-book-001',
          sourceId: 'fixture:web-book:book-001',
          title: detail.title,
          length:
              firstChapter.body.canonical.utf16Length +
              secondChapter.body.canonical.utf16Length,
        ),
        documents: <LibraryDocument>[
          LibraryDocument(
            id: 'fixture-chapter-002',
            itemId: 'chapter-002',
            storagePath: 'fixture/book-001/chapter-002.txt',
            mediaType: 'text/plain',
            startCharacterOffset: 0,
            endCharacterOffset: firstChapter.body.canonical.utf16Length,
            contentHash: firstChapter.body.canonical.sourceRevision,
            normalizationVersion: 'fixture-v1',
          ),
          LibraryDocument(
            id: 'fixture-chapter-001',
            itemId: 'chapter-001',
            storagePath: 'fixture/book-001/chapter-001.txt',
            mediaType: 'text/plain',
            startCharacterOffset: firstChapter.body.canonical.utf16Length,
            endCharacterOffset:
                firstChapter.body.canonical.utf16Length +
                secondChapter.body.canonical.utf16Length,
            contentHash: secondChapter.body.canonical.sourceRevision,
            normalizationVersion: 'fixture-v1',
          ),
        ],
        navigation: <LibraryTocEntry>[
          for (final entry in toc.entries)
            LibraryTocEntry(
              id: entry.chapterKey,
              collectionId: 'fixture-book-001',
              itemId: entry.chapterKey,
              parentId: null,
              kind: 'chapter',
              level: 0,
              title: entry.title,
              orderIndex: entry.orderIndex,
              startCharacterOffset: 0,
              endCharacterOffset: 1,
            ),
        ],
      );

      expect(results.single.bookKey, 'book-001');
      expect(detail.bookKey, 'book-001');
      expect(toc.entries.map((entry) => entry.chapterKey), [
        'chapter-002',
        'chapter-001',
      ]);
      expect(toc.entries.map((entry) => entry.orderIndex), [2, 1]);
      expect(firstChapter.entry.chapterKey, 'chapter-002');
      expect(firstChapter.body.canonical.contentId, 'book-001:chapter-002');
      expect(secondChapter.body.canonical.contentId, 'book-001:chapter-001');
      expect(content.identity.sourceKind, ReaderContentSourceKinds.online);
      expect(content.navigation.map((entry) => entry.id), [
        'chapter-002',
        'chapter-001',
      ]);
    },
  );
}

LibraryCollection _collection({
  required String id,
  required String sourceId,
  required String title,
  required int length,
}) {
  return LibraryCollection(
    id: id,
    sourceId: sourceId,
    title: title,
    subtitle: null,
    itemCount: 1,
    normalizedCharacterLength: length,
    detectedEncoding: TextEncoding.utf8,
    sourceSize: length,
    importedAt: DateTime.utc(2026, 8, 1),
  );
}

String _fixture(String name) {
  final file = File(
    p.join(Directory.current.path, 'test', 'fixtures', 'web_sources', name),
  );
  if (!file.existsSync()) {
    throw StateError('Missing offline web fixture: ${file.path}');
  }
  return file.readAsStringSync();
}

String _attribute(String attributes, String name) {
  final match = RegExp('$name="([^"]*)"').firstMatch(attributes);
  if (match == null) throw StateError('Missing fixture attribute: $name');
  return match.group(1)!;
}

String _htmlText(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

mixin _FixtureReaderProjection {
  RemoteSourceKind get remoteKind;

  String get sourceKind => ReaderContentSourceKinds.online;

  bool canAdapt(LibraryCollection collection) =>
      collection.sourceId.startsWith('fixture:web-');

  bool canAdaptRemote(RemoteSource source) => source.kind == remoteKind;

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
        sourceRevision: documents.isEmpty ? null : documents.first.contentHash,
      ),
      metadata: ReaderContentMetadata.fromCollection(collection),
      documents: documents,
      navigation: navigation,
      normalizedCharacterLength: collection.normalizedCharacterLength,
    );
  }
}

final class _FixtureArticleAdapter
    with _FixtureReaderProjection
    implements WebArticleSourceAdapter {
  _FixtureArticleAdapter()
    : source = WebArticleSource(
        id: RemoteSourceId('fixture:web-article'),
        endpoint: Uri.parse('https://fixture.example'),
        listUri: Uri.parse('https://fixture.example/articles'),
        articleUri: Uri.parse('https://fixture.example/articles/001'),
        ruleSetId: 'fixture-article-rules',
      );

  @override
  final WebArticleSource source;

  @override
  RemoteSourceKind get remoteKind => RemoteSourceKind.webArticle;

  @override
  Future<WebArticleListPage> list(WebArticleListRequest request) async {
    if (request.uri != source.listUri) {
      throw ArgumentError.value(request.uri, 'uri', 'unexpected fixture URI');
    }
    final html = _fixture('article_list.html');
    final items = <WebArticleListItem>[];
    for (final match in RegExp(
      r'<article-card\b([^>]*)>(.*?)</article-card>',
      dotAll: true,
    ).allMatches(html)) {
      final attributes = match.group(1)!;
      final body = match.group(2)!;
      final uri = RegExp(r'<a href="([^"]+)">([^<]+)</a>').firstMatch(body)!;
      final date = RegExp(
        r'<time datetime="([^"]+)"',
      ).firstMatch(body)!.group(1);
      items.add(
        WebArticleListItem(
          identity: _attribute(attributes, 'data-id'),
          title: uri.group(2)!,
          uri: Uri.parse(uri.group(1)!),
          summary: _htmlText(
            RegExp(
              r'<p class="summary">(.*?)</p>',
              dotAll: true,
            ).firstMatch(body)!.group(1)!,
          ),
          publishedAt: DateTime.parse(date!),
        ),
      );
    }
    return WebArticleListPage(items: items, sourceRevision: 'fixture-v1');
  }

  @override
  Future<WebArticleDocument> open(WebArticleListItem item) async {
    final number = item.identity.split('-').last;
    final html = _fixture('article_$number.html');
    final article = RegExp(
      r'<article\b([^>]*)>(.*?)</article>',
      dotAll: true,
    ).firstMatch(html)!;
    final attributes = article.group(1)!;
    final body = RegExp(
      r'<article-body>(.*?)</article-body>',
      dotAll: true,
    ).firstMatch(article.group(2)!)!.group(1)!;
    return WebArticleDocument(
      item: item,
      author: _attribute(attributes, 'data-author'),
      body: WebSourceBody(
        canonical: CanonicalContent(
          contentId: _attribute(attributes, 'data-id'),
          sourceRevision: 'fixture-v1',
          text: _htmlText(body),
        ),
      ),
      ruleSet: const WebRuleSetRef(id: 'fixture-article-rules'),
    );
  }
}

final class _FixtureBookAdapter
    with _FixtureReaderProjection
    implements WebBookSourceAdapter {
  _FixtureBookAdapter()
    : source = WebBookSource(
        id: RemoteSourceId('fixture:web-book'),
        endpoint: Uri.parse('https://fixture.example'),
        bookKey: 'book-001',
        ruleSetId: 'fixture-book-rules',
      );

  @override
  final WebBookSource source;

  @override
  RemoteSourceKind get remoteKind => RemoteSourceKind.webBook;

  @override
  Future<List<WebBookSearchResult>> search(WebBookSearchRequest request) async {
    final html = _fixture('book_search.html');
    return [
      for (final match in RegExp(
        r'<book-result\b([^>]*)>(.*?)</book-result>',
        dotAll: true,
      ).allMatches(html))
        WebBookSearchResult(
          bookKey: _attribute(match.group(1)!, 'data-key'),
          title: RegExp(
            r'<a href="([^"]+)">([^<]+)</a>',
          ).firstMatch(match.group(2)!)!.group(2)!,
          detailUri: Uri.parse(
            RegExp(
              r'<a href="([^"]+)">',
            ).firstMatch(match.group(2)!)!.group(1)!,
          ),
          author: _htmlText(
            RegExp(
              r'<span class="author">(.*?)</span>',
              dotAll: true,
            ).firstMatch(match.group(2)!)!.group(1)!,
          ),
        ),
    ];
  }

  @override
  Future<WebBookDetail> openDetail(WebBookSearchResult result) async {
    final html = _fixture('book_detail.html');
    final book = RegExp(
      r'<book\b([^>]*)>(.*?)</book>',
      dotAll: true,
    ).firstMatch(html)!;
    return WebBookDetail(
      bookKey: _attribute(book.group(1)!, 'data-key'),
      title: _attribute(book.group(1)!, 'data-title'),
      author: _attribute(book.group(1)!, 'data-author'),
      detailUri: result.detailUri,
      description: _htmlText(
        RegExp(
          r'<p class="description">(.*?)</p>',
          dotAll: true,
        ).firstMatch(book.group(2)!)!.group(1)!,
      ),
      ruleSet: const WebRuleSetRef(id: 'fixture-book-rules'),
    );
  }

  @override
  Future<WebBookTableOfContents> loadTableOfContents(
    WebBookDetail detail,
  ) async {
    final html = _fixture('book_toc.html');
    final toc = RegExp(
      r'<toc\b([^>]*)>(.*?)</toc>',
      dotAll: true,
    ).firstMatch(html)!;
    return WebBookTableOfContents(
      bookKey: _attribute(toc.group(1)!, 'data-book'),
      sourceRevision: 'fixture-v1',
      entries: [
        for (final match in RegExp(
          r'<chapter\b([^>]*)>(.*?)</chapter>',
          dotAll: true,
        ).allMatches(toc.group(2)!))
          WebBookTocEntry(
            chapterKey: _attribute(match.group(1)!, 'data-key'),
            title: match.group(2)!.trim(),
            orderIndex: int.parse(_attribute(match.group(1)!, 'data-order')),
            chapterUri: Uri.parse(_attribute(match.group(1)!, 'href')),
          ),
      ],
    );
  }

  @override
  Future<WebBookChapter> openChapter(
    WebBookDetail detail,
    WebBookTocEntry entry,
  ) async {
    final chapterNumber = entry.chapterKey.replaceFirst('chapter-', '');
    final html = _fixture('book_chapter_$chapterNumber.html');
    final chapter = RegExp(
      r'<chapter\b([^>]*)>(.*?)</chapter>',
      dotAll: true,
    ).firstMatch(html)!;
    final body = RegExp(
      r'<chapter-body>(.*?)</chapter-body>',
      dotAll: true,
    ).firstMatch(chapter.group(2)!)!.group(1)!;
    return WebBookChapter(
      bookKey: _attribute(chapter.group(1)!, 'data-book'),
      entry: entry,
      body: WebSourceBody(
        canonical: CanonicalContent(
          contentId:
              '${detail.bookKey}:${_attribute(chapter.group(1)!, 'data-key')}',
          sourceRevision: 'fixture-v1',
          text: _htmlText(body),
        ),
      ),
      ruleSet: detail.ruleSet ?? const WebRuleSetRef(id: 'fixture-book-rules'),
    );
  }
}
