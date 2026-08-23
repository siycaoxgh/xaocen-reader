import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_content.dart';
import 'package:xaocen_reader/sources/epub/epub_parser.dart';
import 'package:xaocen_reader/sources/epub/epub_reader_content_adapter.dart';

List<int> _fixtureEpub({bool useNcx = false}) {
  final archive = Archive();
  void add(String path, String content) {
    archive.addFile(ArchiveFile.string(path, content));
  }

  add('mimetype', 'application/epub+zip');
  add('META-INF/container.xml', '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OPS/package.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>''');
  add('OPS/package.opf', '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0"${useNcx ? ' toc="ncx"' : ''}>
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>EPUB 测试书</dc:title><dc:creator>测试作者</dc:creator><dc:description>简介</dc:description>
  </metadata>
  <manifest>
    <item id="chapter-one" href="text/one.xhtml" media-type="application/xhtml+xml"/>
    <item id="chapter-two" href="text/two.xhtml" media-type="application/xhtml+xml"/>
    ${useNcx ? '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>' : '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'}
  </manifest>
  <spine${useNcx ? ' toc="ncx"' : ''}>
    <itemref idref="chapter-one"/><itemref idref="chapter-two"/>
  </spine>
</package>''');
  add(
    'OPS/text/one.xhtml',
    '''<html xmlns="http://www.w3.org/1999/xhtml"><head><title>第一章</title><style>.x{}</style></head><body><h1>第一章</h1><p>第一段内容。</p><p>第二段内容。</p></body></html>''',
  );
  add(
    'OPS/text/two.xhtml',
    '''<html xmlns="http://www.w3.org/1999/xhtml"><head><title>第二章</title></head><body><h1>第二章</h1><p>第二章内容。</p></body></html>''',
  );
  if (useNcx) {
    add(
      'OPS/toc.ncx',
      '''<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/"><navMap><navPoint><navLabel><text>第一章</text></navLabel><content src="text/one.xhtml"/><navPoint><navLabel><text>第二节</text></navLabel><content src="text/two.xhtml"/></navPoint></navPoint></navMap></ncx>''',
    );
  } else {
    add(
      'OPS/nav.xhtml',
      '''<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><body><nav epub:type="toc"><ol><li><a href="text/one.xhtml#start">第一章</a><ol><li><a href="text/two.xhtml">第二节</a></li></ol></li></ol></nav></body></html>''',
    );
  }
  return ZipEncoder().encode(archive)!;
}

List<int> _renderingFixtureEpub() {
  final archive = Archive();
  void add(String path, String content) {
    archive.addFile(ArchiveFile.string(path, content));
  }

  add('mimetype', 'application/epub+zip');
  add(
    'META-INF/container.xml',
    '<container><rootfiles><rootfile full-path="OPS/package.opf"/></rootfiles></container>',
  );
  add(
    'OPS/package.opf',
    '''<package xmlns="http://www.idpf.org/2007/opf" version="3.0"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>渲染测试</dc:title></metadata><manifest><item id="chapter" href="text/chapter.xhtml" media-type="application/xhtml+xml"/><item id="image" href="images/pixel.png" media-type="image/png"/></manifest><spine><itemref idref="chapter"/></spine></package>''',
  );
  add(
    'OPS/text/chapter.xhtml',
    '''<html xmlns="http://www.w3.org/1999/xhtml"><head><style>.em{font-style: italic}</style></head><body><h1>标题</h1><p><strong>粗体</strong>与<span class="em">斜体</span>。</p><p><img src="../images/pixel.png" alt="插图" width="10" height="20"/>图片后文字</p></body></html>''',
  );
  archive.addFile(ArchiveFile('OPS/images/pixel.png', 4, [0, 0, 0, 0]));
  return ZipEncoder().encode(archive)!;
}

List<int> _coverFixtureEpub({bool epub2Meta = false}) {
  final archive = Archive();
  void add(String path, String content) {
    archive.addFile(ArchiveFile.string(path, content));
  }

  add('mimetype', 'application/epub+zip');
  add(
    'META-INF/container.xml',
    '<container><rootfiles><rootfile full-path="OPS/package.opf"/></rootfiles></container>',
  );
  add(
    'OPS/package.opf',
    '''<package xmlns="http://www.idpf.org/2007/opf" version="3.0"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>封面测试书</dc:title><dc:creator>封面作者</dc:creator>${epub2Meta ? '<meta name="cover" content="cover"/>' : ''}</metadata><manifest><item id="cover" href="images/cover.png" media-type="image/png"${epub2Meta ? '' : ' properties="cover-image"'}/><item id="chapter" href="chapter.xhtml" media-type="application/xhtml+xml"/></manifest><spine><itemref idref="chapter"/></spine></package>''',
  );
  add(
    'OPS/chapter.xhtml',
    '<html><body><h1>正文</h1><p>没有引用封面图片。</p></body></html>',
  );
  archive.addFile(ArchiveFile('OPS/images/cover.png', 4, [1, 2, 3, 4]));
  return ZipEncoder().encode(archive)!;
}

void main() {
  test('EPUB parser preserves package metadata, spine order and EPUB3 TOC', () {
    final book = const EpubParser().parseBytes(_fixtureEpub());

    expect(book.metadata.title, 'EPUB 测试书');
    expect(book.metadata.author, '测试作者');
    expect(book.spine.map((item) => item.id), ['chapter-one', 'chapter-two']);
    expect(book.spine.map((item) => item.title), ['第一章', '第二章']);
    expect(book.spine.first.text, contains('第一段内容。'));
    expect(book.navigation.map((item) => item.title), ['第一章', '第二节']);
    expect(book.navigation.map((item) => item.level), [0, 1]);
    expect(book.navigation.map((item) => item.parentIndex), [null, 0]);
    expect(book.navigation.map((item) => item.spineIndex), [0, 1]);
  });

  test('EPUB parser supports EPUB2 NCX fallback in original order', () {
    final book = const EpubParser().parseBytes(_fixtureEpub(useNcx: true));

    expect(book.navigation.map((item) => item.title), ['第一章', '第二节']);
    expect(book.navigation.map((item) => item.level), [0, 1]);
    expect(book.navigation.map((item) => item.spineIndex), [0, 1]);
  });

  test(
    'EPUB adapter produces ReaderContent with UTF-16 ranges and metadata',
    () {
      final book = const EpubParser().parseBytes(_fixtureEpub());
      final content = const EpubReaderContentAdapter().adaptBook(
        book: book,
        contentId: 'epub-book-1',
        sourceId: 'epub-source:book-hash',
      );

      expect(content.identity.sourceKind, ReaderContentSourceKinds.epub);
      expect(content.metadata.title, 'EPUB 测试书');
      expect(content.metadata.author, '测试作者');
      expect(content.documents, hasLength(2));
      expect(content.documents.first.startCharacterOffset, 0);
      expect(
        content.documents[1].startCharacterOffset,
        content.documents.first.endCharacterOffset + 2,
      );
      expect(content.navigation.map((entry) => entry.parentId), [
        null,
        'epub-book-1:toc:0',
      ]);
      expect(
        content.navigation.every(
          (entry) => entry.endCharacterOffset > entry.startCharacterOffset,
        ),
        isTrue,
      );
    },
  );

  test('invalid EPUB fails at the package boundary', () {
    expect(
      () => const EpubParser().parseBytes(utf8.encode('not a zip')),
      throwsA(isA<EpubParseException>()),
    );
  });

  test(
    'EPUB rendering annotations preserve UTF-16 ranges and image assets',
    () {
      final book = const EpubParser().parseBytes(_renderingFixtureEpub());
      final item = book.spine.single;

      expect(item.text, contains('标题'));
      expect(item.text, contains('粗体与斜体。'));
      expect(item.styleRuns, isNotEmpty);
      expect(item.styleRuns.any((run) => run.bold), isTrue);
      expect(item.styleRuns.any((run) => run.italic), isTrue);
      expect(item.images, hasLength(1));
      expect(item.images.single.href, 'OPS/images/pixel.png');
      expect(
        item.images.single.characterOffset,
        lessThanOrEqualTo(item.text.length),
      );
      expect(book.assets.single.href, 'OPS/images/pixel.png');
    },
  );

  test('EPUB package cover-image is detected even when not in spine', () {
    final book = const EpubParser().parseBytes(_coverFixtureEpub());

    expect(book.metadata.coverHref, 'OPS/images/cover.png');
    expect(book.metadata.coverMediaType, 'image/png');
    expect(book.assets.map((asset) => asset.href), ['OPS/images/cover.png']);
    expect(book.metadata.titleSource, 'autoDetected');
    expect(book.metadata.authorSource, 'autoDetected');
  });

  test('EPUB2 cover metadata is detected as a package asset', () {
    final book = const EpubParser().parseBytes(
      _coverFixtureEpub(epub2Meta: true),
    );

    expect(book.metadata.coverHref, 'OPS/images/cover.png');
    expect(book.assets.single.mediaType, 'image/png');
  });
}
