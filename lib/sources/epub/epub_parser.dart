import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'epub_models.dart';

/// Minimal, local EPUB package parser.
///
/// This stage intentionally handles package metadata, manifest/spine order,
/// EPUB 3 navigation and EPUB 2 NCX navigation. CSS, scripts, media, DRM and
/// remote resources are outside the ReaderContent foundation.
final class EpubParser {
  const EpubParser();

  Future<EpubBook> parseFile(File file) async {
    if (!await file.exists()) {
      throw EpubParseException('EPUB 文件不存在: ${file.path}');
    }
    return parseBytes(await file.readAsBytes(), sourceName: file.path);
  }

  EpubBook parseBytes(List<int> bytes, {String sourceName = 'book.epub'}) {
    late final Map<String, List<int>> files;
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      files = <String, List<int>>{
        for (final file in archive.files)
          if (file.isFile)
            _normalizeZipPath(file.name): List<int>.from(
              file.content as List<int>,
            ),
      };
    } catch (error) {
      throw EpubParseException('无法读取 EPUB ZIP 容器: $error');
    }

    final containerPath = 'META-INF/container.xml';
    final containerBytes = files[containerPath];
    if (containerBytes == null) {
      throw const EpubParseException('EPUB 缺少 META-INF/container.xml');
    }
    final container = _parseXml(containerBytes, containerPath);
    final rootfile = _allElements(
      container.rootElement,
    ).firstWhereOrNull((element) => element.localName == 'rootfile');
    final packagePath = rootfile?.getAttribute('full-path');
    if (packagePath == null || packagePath.trim().isEmpty) {
      throw const EpubParseException('EPUB container 未声明 package rootfile');
    }
    final normalizedPackagePath = _normalizeZipPath(packagePath);
    final packageBytes = files[normalizedPackagePath];
    if (packageBytes == null) {
      throw EpubParseException('EPUB package 不存在: $normalizedPackagePath');
    }

    final package = _parseXml(packageBytes, normalizedPackagePath);
    final metadataElement = _firstDescendant(package.rootElement, 'metadata');
    final manifestElement = _firstDescendant(package.rootElement, 'manifest');
    final spineElement = _firstDescendant(package.rootElement, 'spine');
    if (manifestElement == null || spineElement == null) {
      throw const EpubParseException('EPUB package 缺少 manifest 或 spine');
    }

    final packageDirectory = p.posix.dirname(normalizedPackagePath);
    final manifest = <String, _ManifestItem>{};
    for (final item in _childElements(manifestElement, 'item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type');
      if (id == null || href == null || mediaType == null || id.isEmpty) {
        continue;
      }
      manifest[id] = _ManifestItem(
        id: id,
        href: _resolveZipPath(packageDirectory, href),
        mediaType: mediaType,
        properties: item.getAttribute('properties') ?? '',
      );
    }

    final packageTitle = _metadataValue(metadataElement, 'title');
    final packageAuthor = _metadataValue(metadataElement, 'creator');
    final coverItem = _coverManifestItem(metadataElement, manifest);
    final metadata = EpubBookMetadata(
      title: packageTitle ?? _fallbackTitle(sourceName),
      author: packageAuthor,
      description: _metadataValue(metadataElement, 'description'),
      titleSource: packageTitle == null ? 'fileName' : 'autoDetected',
      authorSource: packageAuthor == null ? 'unknown' : 'autoDetected',
      coverHref: coverItem?.href,
      coverMediaType: coverItem?.mediaType,
    );

    final spine = <EpubSpineItem>[];
    final referencedImageHrefs = <String>{
      if (metadata.coverHref != null) metadata.coverHref!,
    };
    for (final itemref in _childElements(spineElement, 'itemref')) {
      final idref = itemref.getAttribute('idref');
      if (idref == null) continue;
      final item = manifest[idref];
      if (item == null) {
        throw EpubParseException('spine 引用了不存在的 manifest item: $idref');
      }
      final contentBytes = files[item.href];
      if (contentBytes == null) {
        throw EpubParseException('spine 文档不存在: ${item.href}');
      }
      final parsedDocument = _extractDocument(
        contentBytes,
        item.href,
        manifest,
      );
      referencedImageHrefs.addAll(
        parsedDocument.images.map((image) => image.href),
      );
      spine.add(
        EpubSpineItem(
          id: item.id,
          href: item.href,
          mediaType: item.mediaType,
          text: parsedDocument.text,
          linear: itemref.getAttribute('linear')?.toLowerCase() != 'no',
          title: _documentTitle(contentBytes, item.href),
          styleRuns: parsedDocument.styleRuns,
          images: parsedDocument.images,
        ),
      );
    }
    if (spine.isEmpty) {
      throw const EpubParseException('EPUB spine 为空');
    }

    final navigation = _parseNavigation(
      files: files,
      manifest: manifest,
      spine: spine,
      spineElement: spineElement,
      packageDirectory: packageDirectory,
    );
    final assets = <EpubAsset>[];
    for (final href in referencedImageHrefs) {
      final item = manifest.values
          .where((value) => value.href == href)
          .firstOrNull;
      final bytes = files[href];
      if (item == null || bytes == null || !_isSupportedImage(item.mediaType)) {
        continue;
      }
      assets.add(
        EpubAsset(
          href: href,
          mediaType: item.mediaType,
          bytes: List.unmodifiable(bytes),
        ),
      );
    }
    return EpubBook(
      packagePath: normalizedPackagePath,
      metadata: metadata,
      spine: spine,
      navigation: navigation,
      assets: assets,
    );
  }

  List<EpubNavigationItem> _parseNavigation({
    required Map<String, List<int>> files,
    required Map<String, _ManifestItem> manifest,
    required List<EpubSpineItem> spine,
    required XmlElement spineElement,
    required String packageDirectory,
  }) {
    final navItem = manifest.values.where((item) {
      return item.properties
          .split(RegExp(r'\s+'))
          .any((property) => property.toLowerCase() == 'nav');
    }).firstOrNull;
    if (navItem != null && files.containsKey(navItem.href)) {
      return _parseEpub3Navigation(files[navItem.href]!, navItem.href, spine);
    }

    final ncxId = spineElement.getAttribute('toc');
    final ncxItem = ncxId == null ? null : manifest[ncxId];
    final fallbackNcx = manifest.values
        .where((item) => item.mediaType == 'application/x-dtbncx+xml')
        .firstOrNull;
    final selectedNcx = ncxItem ?? fallbackNcx;
    if (selectedNcx != null && files.containsKey(selectedNcx.href)) {
      return _parseNcxNavigation(
        files[selectedNcx.href]!,
        selectedNcx.href,
        spine,
      );
    }
    return const <EpubNavigationItem>[];
  }

  List<EpubNavigationItem> _parseEpub3Navigation(
    List<int> bytes,
    String navPath,
    List<EpubSpineItem> spine,
  ) {
    final document = _parseXml(bytes, navPath);
    final navElements = _allElements(
      document.rootElement,
    ).where((element) => element.localName == 'nav').toList();
    final nav =
        navElements.where((element) {
          final type = element.attributes
              .where((attribute) => attribute.localName == 'type')
              .map((attribute) => attribute.value.toLowerCase())
              .firstOrNull;
          return type?.split(RegExp(r'\s+')).contains('toc') == true;
        }).firstOrNull ??
        navElements.firstOrNull;
    if (nav == null) return const <EpubNavigationItem>[];
    final list = _allElements(
      nav,
    ).where((element) => element.localName == 'ol').firstOrNull;
    if (list == null) return const <EpubNavigationItem>[];

    final result = <EpubNavigationItem>[];
    void visitList(XmlElement ol, int level, int? parentIndex) {
      for (final li in _childElements(ol, 'li')) {
        var currentParentIndex = parentIndex;
        final anchor = _childElements(li, 'a').firstOrNull;
        final href = anchor?.getAttribute('href');
        final title = anchor?.innerText.trim() ?? _directText(li).trim();
        if (href != null && title.isNotEmpty) {
          final index = result.length;
          result.add(
            EpubNavigationItem(
              title: title,
              href: _resolveZipPath(p.posix.dirname(navPath), href),
              level: level,
              spineIndex: _spineIndexForHref(
                spine,
                _resolveZipPath(p.posix.dirname(navPath), href),
              ),
              parentIndex: currentParentIndex,
            ),
          );
          currentParentIndex = index;
        }
        for (final nested in _childElements(li, 'ol')) {
          visitList(nested, level + 1, currentParentIndex);
        }
      }
    }

    visitList(list, 0, null);
    return result;
  }

  List<EpubNavigationItem> _parseNcxNavigation(
    List<int> bytes,
    String ncxPath,
    List<EpubSpineItem> spine,
  ) {
    final document = _parseXml(bytes, ncxPath);
    final navMap = _firstDescendant(document.rootElement, 'navMap');
    if (navMap == null) return const <EpubNavigationItem>[];
    final result = <EpubNavigationItem>[];
    void visit(XmlElement parent, int level, int? parentIndex) {
      for (final navPoint in _childElements(parent, 'navPoint')) {
        final title =
            _firstDescendant(navPoint, 'text')?.innerText.trim() ?? '';
        final src = _firstDescendant(navPoint, 'content')?.getAttribute('src');
        var nextParent = parentIndex;
        if (src != null && title.isNotEmpty) {
          final href = _resolveZipPath(p.posix.dirname(ncxPath), src);
          final index = result.length;
          result.add(
            EpubNavigationItem(
              title: title,
              href: href,
              level: level,
              spineIndex: _spineIndexForHref(spine, href),
              parentIndex: parentIndex,
            ),
          );
          nextParent = index;
        }
        visit(navPoint, level + 1, nextParent);
      }
    }

    visit(navMap, 0, null);
    return result;
  }

  int? _spineIndexForHref(List<EpubSpineItem> spine, String href) {
    final target = _normalizeZipPath(href.split('#').first);
    for (var index = 0; index < spine.length; index++) {
      if (spine[index].href == target) return index;
    }
    return null;
  }

  _ParsedEpubDocument _extractDocument(
    List<int> bytes,
    String path,
    Map<String, _ManifestItem> manifest,
  ) {
    final document = _parseXml(bytes, path);
    final buffer = StringBuffer();
    final styles = <_RawStyleRun>[];
    final images = <_RawImageReference>[];
    const blockElements = <String>{
      'article',
      'blockquote',
      'div',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'li',
      'p',
      'pre',
      'section',
      'tr',
    };
    const ignoredElements = <String>{'head', 'script', 'svg'};
    final cssRules = _parseCssRules(document);

    void lineBreak() {
      if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
        buffer.write('\n');
      }
    }

    void visit(XmlNode node, _EpubStyle inherited) {
      if (node is XmlElement) {
        final name = node.localName.toLowerCase();
        if (name == 'style') return;
        if (ignoredElements.contains(name)) return;
        if (name == 'br') lineBreak();
        final block = blockElements.contains(name);
        if (block) lineBreak();
        final style = inherited.merge(
          _styleForElement(node, name, cssRules),
          headingLevel: RegExp(r'^h([1-6])$').firstMatch(name) == null
              ? null
              : int.parse(RegExp(r'^h([1-6])$').firstMatch(name)!.group(1)!),
        );
        if (name == 'img') {
          final src = node.getAttribute('src');
          if (src != null && src.trim().isNotEmpty) {
            final href = _resolveZipPath(p.posix.dirname(path), src);
            images.add(
              _RawImageReference(
                rawOffset: buffer.length,
                href: href,
                altText: node.getAttribute('alt'),
                width: _parseDimension(node.getAttribute('width')),
                height: _parseDimension(node.getAttribute('height')),
              ),
            );
          }
        }
        final start = buffer.length;
        for (final child in node.children) {
          visit(child, style);
        }
        final end = buffer.length;
        if (end > start &&
            (style.bold || style.italic || style.headingLevel != null)) {
          styles.add(
            _RawStyleRun(
              start: start,
              end: end,
              bold: style.bold || style.headingLevel != null,
              italic: style.italic,
              headingLevel: style.headingLevel,
            ),
          );
        }
        if (block) lineBreak();
      } else if (node is XmlText) {
        final value = node.value.replaceAll(RegExp(r'\s+'), ' ');
        buffer.write(value);
      }
    }

    visit(document.rootElement, const _EpubStyle());
    final normalized = _normalizeWithRanges(buffer.toString(), styles, images);
    return normalized;
  }

  Map<String, _EpubStyle> _parseCssRules(XmlDocument document) {
    final rules = <String, _EpubStyle>{};
    for (final style in _allElements(
      document.rootElement,
    ).where((element) => element.localName.toLowerCase() == 'style')) {
      final css = style.innerText;
      for (final match in RegExp(r'([^{}]+)\{([^{}]+)\}').allMatches(css)) {
        final value = _styleFromDeclarations(match.group(2)!);
        for (final selector in match.group(1)!.split(',')) {
          final key = selector.trim().toLowerCase();
          if (key.startsWith('.') ||
              key.startsWith('#') ||
              RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(key)) {
            rules[key] = (rules[key] ?? const _EpubStyle()).merge(value);
          }
        }
      }
    }
    return rules;
  }

  _EpubStyle _styleForElement(
    XmlElement element,
    String name,
    Map<String, _EpubStyle> cssRules,
  ) {
    var style = cssRules[name] ?? const _EpubStyle();
    if (name == 'b' || name == 'strong') {
      style = style.merge(const _EpubStyle(bold: true));
    }
    if (name == 'i' || name == 'em' || name == 'cite') {
      style = style.merge(const _EpubStyle(italic: true));
    }
    final className = element.getAttribute('class');
    if (className != null) {
      for (final token in className.split(RegExp(r'\s+'))) {
        style = style.merge(
          cssRules['.${token.toLowerCase()}'] ?? const _EpubStyle(),
        );
      }
    }
    final id = element.getAttribute('id');
    if (id != null) {
      style = style.merge(
        cssRules['#${id.toLowerCase()}'] ?? const _EpubStyle(),
      );
    }
    final inline = element.getAttribute('style');
    if (inline != null) style = style.merge(_styleFromDeclarations(inline));
    return style;
  }

  _EpubStyle _styleFromDeclarations(String declarations) {
    var bold = false;
    var italic = false;
    for (final declaration in declarations.split(';')) {
      final parts = declaration.split(':');
      if (parts.length < 2) continue;
      final property = parts.first.trim().toLowerCase();
      final value = parts.sublist(1).join(':').trim().toLowerCase();
      if (property == 'font-weight') {
        bold =
            value == 'bold' ||
            value == 'bolder' ||
            (int.tryParse(value) ?? 0) >= 600;
      } else if (property == 'font-style') {
        italic = value == 'italic' || value == 'oblique';
      }
    }
    return _EpubStyle(bold: bold, italic: italic);
  }

  _ParsedEpubDocument _normalizeWithRanges(
    String raw,
    List<_RawStyleRun> rawStyles,
    List<_RawImageReference> rawImages,
  ) {
    final include = List<bool>.filled(raw.length, false);
    var lineStart = 0;
    var hasOutput = false;
    while (lineStart <= raw.length) {
      final newline = raw.indexOf('\n', lineStart);
      final lineEnd = newline < 0 ? raw.length : newline;
      var left = lineStart;
      var right = lineEnd;
      while (left < right && raw.codeUnitAt(left) <= 0x20) {
        left++;
      }
      while (right > left && raw.codeUnitAt(right - 1) <= 0x20) {
        right--;
      }
      if (left < right) {
        if (hasOutput && newline >= 0) {
          include[newline] = true;
        }
        for (var index = left; index < right; index++) {
          include[index] = true;
        }
        hasOutput = true;
      }
      if (newline < 0) break;
      lineStart = newline + 1;
    }
    final boundaries = List<int>.filled(raw.length + 1, 0);
    final output = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      boundaries[index] = output.length;
      if (include[index]) output.write(raw[index]);
      boundaries[index + 1] = output.length;
    }
    final text = output.toString().trim();
    final trimDelta = output.length - text.length;
    int mapOffset(int rawOffset) =>
        (boundaries[rawOffset.clamp(0, raw.length)] - trimDelta)
            .clamp(0, text.length)
            .toInt();
    final styles = <EpubInlineStyleRun>[];
    for (final run in rawStyles) {
      final start = mapOffset(run.start);
      final end = mapOffset(run.end);
      if (end > start) {
        styles.add(
          EpubInlineStyleRun(
            startCharacterOffset: start,
            endCharacterOffset: end,
            bold: run.bold,
            italic: run.italic,
            headingLevel: run.headingLevel,
          ),
        );
      }
    }
    final images = <EpubImageReference>[];
    for (final image in rawImages) {
      images.add(
        EpubImageReference(
          characterOffset: mapOffset(image.rawOffset),
          href: image.href,
          altText: image.altText,
          width: image.width,
          height: image.height,
        ),
      );
    }
    return _ParsedEpubDocument(text: text, styleRuns: styles, images: images);
  }

  static double? _parseDimension(String? value) {
    if (value == null) return null;
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  static bool _isSupportedImage(String mediaType) => const <String>{
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  }.contains(mediaType.toLowerCase());

  String _documentTitle(List<int> bytes, String path) {
    try {
      final document = _parseXml(bytes, path);
      final title = _firstDescendant(
        document.rootElement,
        'title',
      )?.innerText.trim();
      if (title != null && title.isNotEmpty) return title;
      final heading = _allElements(document.rootElement).firstWhereOrNull(
        (element) => RegExp(r'^h[1-6]$').hasMatch(element.localName),
      );
      if (heading != null && heading.innerText.trim().isNotEmpty) {
        return heading.innerText.trim();
      }
    } on EpubParseException {
      // The containing spine parse will report malformed content if needed.
    }
    return p.posix.basenameWithoutExtension(path);
  }

  XmlDocument _parseXml(List<int> bytes, String path) {
    try {
      return XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));
    } catch (error) {
      throw EpubParseException('EPUB XML 无法解析 ($path): $error');
    }
  }

  static String? _metadataValue(XmlElement? metadata, String localName) {
    final value = metadata == null
        ? null
        : _firstDescendant(metadata, localName)?.innerText.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// EPUB 3 uses `properties="cover-image"`; EPUB 2 commonly stores the
  /// image manifest id in `<meta name="cover" content="…">`.  Prefer the
  /// explicit EPUB 3 declaration, then use the EPUB 2 metadata fallback.
  static _ManifestItem? _coverManifestItem(
    XmlElement? metadata,
    Map<String, _ManifestItem> manifest,
  ) {
    final propertyCover = manifest.values.where((item) {
      return item.properties
          .split(RegExp(r'\s+'))
          .any((property) => property.toLowerCase() == 'cover-image');
    }).firstOrNull;
    if (propertyCover != null && _isSupportedImage(propertyCover.mediaType)) {
      return propertyCover;
    }

    if (metadata == null) return null;
    for (final element in _allElements(metadata)) {
      if (element.localName.toLowerCase() != 'meta') continue;
      final name = element.getAttribute('name')?.trim().toLowerCase();
      if (name != 'cover') continue;
      final id = element.getAttribute('content')?.trim();
      final item = id == null ? null : manifest[id];
      if (item != null && _isSupportedImage(item.mediaType)) return item;
    }
    return null;
  }

  static String _fallbackTitle(String sourceName) {
    final name = p.posix.basenameWithoutExtension(sourceName);
    return name.trim().isEmpty ? '未命名 EPUB' : name;
  }

  static XmlElement? _firstDescendant(XmlElement root, String localName) =>
      _allElements(
        root,
      ).firstWhereOrNull((element) => element.localName == localName);

  static Iterable<XmlElement> _allElements(XmlElement root) sync* {
    yield root;
    for (final child in root.children.whereType<XmlElement>()) {
      yield* _allElements(child);
    }
  }

  static Iterable<XmlElement> _childElements(
    XmlElement parent,
    String localName,
  ) => parent.children.whereType<XmlElement>().where(
    (element) => element.localName == localName,
  );

  static String _directText(XmlElement element) {
    return element.children
        .whereType<XmlText>()
        .map((node) => node.value)
        .join(' ');
  }

  static String _resolveZipPath(String base, String href) {
    final withoutFragment = href.split('#').first.split('?').first;
    final decoded = Uri.decodeFull(withoutFragment);
    return _normalizeZipPath(
      p.posix.join(
        base,
        decoded.startsWith('/') ? decoded.substring(1) : decoded,
      ),
    );
  }

  static String _normalizeZipPath(String path) {
    final normalized = p.posix.normalize(path.replaceAll('\\', '/'));
    return normalized.startsWith('./') ? normalized.substring(2) : normalized;
  }
}

final class _ManifestItem {
  const _ManifestItem({
    required this.id,
    required this.href,
    required this.mediaType,
    required this.properties,
  });

  final String id;
  final String href;
  final String mediaType;
  final String properties;
}

final class _ParsedEpubDocument {
  const _ParsedEpubDocument({
    required this.text,
    required this.styleRuns,
    required this.images,
  });

  final String text;
  final List<EpubInlineStyleRun> styleRuns;
  final List<EpubImageReference> images;
}

final class _RawStyleRun {
  const _RawStyleRun({
    required this.start,
    required this.end,
    required this.bold,
    required this.italic,
    this.headingLevel,
  });

  final int start;
  final int end;
  final bool bold;
  final bool italic;
  final int? headingLevel;
}

final class _RawImageReference {
  const _RawImageReference({
    required this.rawOffset,
    required this.href,
    this.altText,
    this.width,
    this.height,
  });

  final int rawOffset;
  final String href;
  final String? altText;
  final double? width;
  final double? height;
}

final class _EpubStyle {
  const _EpubStyle({this.bold = false, this.italic = false, this.headingLevel});

  final bool bold;
  final bool italic;
  final int? headingLevel;

  _EpubStyle merge(_EpubStyle other, {int? headingLevel}) => _EpubStyle(
    bold: bold || other.bold,
    italic: italic || other.italic,
    headingLevel: headingLevel ?? other.headingLevel ?? this.headingLevel,
  );
}

final class EpubParseException implements Exception {
  const EpubParseException(this.message);

  final String message;

  @override
  String toString() => 'EpubParseException: $message';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}
