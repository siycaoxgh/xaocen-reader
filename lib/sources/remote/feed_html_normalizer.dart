/// Converts the small HTML fragments commonly embedded in RSS/Atom fields to
/// readable plain text for the existing text Reader.
///
/// This is deliberately not a web renderer: it never loads a URL, executes
/// script, or attempts to resolve remote images. Links and images are kept as
/// readable placeholders so an item cannot leak raw markup into the Reader.
final class FeedHtmlNormalizer {
  const FeedHtmlNormalizer._();

  static const noBodyMessage = '订阅源未提供正文';

  static String normalize(String? html) {
    if (html == null || html.trim().isEmpty) return '';
    var value = html
        .replaceAll(RegExp(r'<!--[\s\S]*?-->', caseSensitive: false), '')
        .replaceAll(RegExp(r'<!\[CDATA\[', caseSensitive: false), '')
        // Some Atom producers emit several adjacent CDATA blocks.  Remove
        // every closing marker, not only the final one, so XML framing never
        // becomes visible Reader text even when a feed splits its payload.
        .replaceAll(RegExp(r'\]\]>', caseSensitive: false), '');

    // Remove non-content blocks before handling the remaining inline markup.
    value = value.replaceAll(
      RegExp(
        r'<\s*(script|style|noscript|template)\b[^>]*>[\s\S]*?<\s*/\s*\1\s*>',
        caseSensitive: false,
      ),
      '',
    );

    value = value.replaceAllMapped(_anchorPattern, (match) {
      final label = normalize(match.group(2));
      final href = _decodeEntities(match.group(1) ?? '').trim();
      if (label.isEmpty) return _safeUrlOrEmpty(href);
      final safeHref = _safeUrlOrEmpty(href);
      return safeHref.isEmpty ? label : '$label ($safeHref)';
    });
    value = value.replaceAllMapped(_imagePattern, (match) {
      final alt = normalize(
        _imageAltPattern.firstMatch(match.group(0)!)?.group(1),
      );
      return alt.isEmpty ? '[图片]' : '[图片：$alt]';
    });

    // Block boundaries are meaningful in a text Reader even though the tags
    // themselves are not. List items receive a small readable marker.
    value = value
        .replaceAll(
          RegExp(r'<\s*(?:br|hr)\s*/?\s*>', caseSensitive: false),
          '\n',
        )
        .replaceAll(
          RegExp(
            r'<\s*/\s*(?:p|div|section|article|header|footer|h[1-6]|li|blockquote|pre|tr|table)\s*>',
            caseSensitive: false,
          ),
          '\n',
        )
        .replaceAll(RegExp(r'<\s*li\b[^>]*>', caseSensitive: false), '\n• ')
        .replaceAll(
          RegExp(
            r'<\s*(?:p|div|section|article|header|footer|h[1-6]|blockquote|pre|tr|table)\b[^>]*>',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'<[^>]+>', caseSensitive: false), '');

    // Decode after tag handling so an escaped literal such as &lt;p&gt; does
    // not become a renderer instruction. A second conservative tag pass keeps
    // malformed feeds from exposing executable-looking markup to the Reader.
    value = _decodeEntities(value).replaceAll(RegExp(r'<[^>]+>'), '');
    return _collapseWhitespace(value);
  }

  /// Returns safe HTTP(S) image references in source order.  This is kept
  /// separate from [normalize] so the canonical Reader text never contains a
  /// remote URL and the existing UTF-16 offsets remain unchanged.
  static List<Uri> extractImageUris(String? html, {Uri? baseUri}) {
    if (html == null || html.trim().isEmpty) return const <Uri>[];
    final result = <Uri>[];
    final seen = <String>{};
    for (final match in _imagePattern.allMatches(html)) {
      final tag = match.group(0)!;
      final raw = _imageSrcPattern.firstMatch(tag)?.group(1)?.trim();
      if (raw == null || raw.isEmpty) continue;
      final decoded = _decodeEntities(raw);
      final uri = Uri.tryParse(decoded);
      final resolved = uri != null && uri.hasScheme
          ? uri
          : baseUri?.resolve(decoded);
      if (resolved == null ||
          !{'http', 'https'}.contains(resolved.scheme.toLowerCase())) {
        continue;
      }
      if (seen.add(resolved.toString())) result.add(resolved);
    }
    return List.unmodifiable(result);
  }

  static String selectBody({String? content, String? fallback}) {
    final normalizedContent = normalize(content);
    if (normalizedContent.isNotEmpty &&
        !_isLinkOnly(content, normalizedContent)) {
      return normalizedContent;
    }
    final normalizedFallback = normalize(fallback);
    if (normalizedFallback.isNotEmpty &&
        !_isLinkOnly(fallback, normalizedFallback)) {
      return normalizedFallback;
    }
    return noBodyMessage;
  }

  static bool _isLinkOnly(String? raw, String normalized) {
    if (raw == null || raw.trim().isEmpty) return false;
    if (_anchorPattern.hasMatch(raw) &&
        raw.replaceAll(_anchorPattern, '').trim().isEmpty) {
      return true;
    }
    return RegExp(
      r'^(?:https?://|mailto:)[^\s]+$',
      caseSensitive: false,
    ).hasMatch(normalized.trim());
  }

  static String _safeUrlOrEmpty(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !{'http', 'https', 'mailto'}.contains(uri.scheme)) {
      return '';
    }
    return value;
  }

  static String _collapseWhitespace(String value) => value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n[ \t]+'), '\n')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  static String _decodeEntities(String value) => value.replaceAllMapped(
    RegExp(
      r'&(?:#x([0-9a-f]+)|#([0-9]+)|([a-z][a-z0-9]+));?',
      caseSensitive: false,
    ),
    (match) {
      final hex = match.group(1);
      final decimal = match.group(2);
      if (hex != null || decimal != null) {
        final codePoint = int.tryParse(
          hex ?? decimal!,
          radix: hex == null ? 10 : 16,
        );
        if (codePoint != null && codePoint >= 0 && codePoint <= 0x10FFFF) {
          return String.fromCharCode(codePoint);
        }
        return match.group(0)!;
      }
      return _namedEntities[match.group(3)!.toLowerCase()] ?? match.group(0)!;
    },
  );

  static final _anchorPattern = RegExp(
    r'''<\s*a\b[^>]*?\bhref\s*=\s*["']([^"']+)["'][^>]*>([\s\S]*?)<\s*/\s*a\s*>''',
    caseSensitive: false,
  );
  static final _imagePattern = RegExp(
    r'''<\s*img\b[^>]*?/?>''',
    caseSensitive: false,
  );
  static final _imageAltPattern = RegExp(
    r'''\balt\s*=\s*["']([^"']*)["']''',
    caseSensitive: false,
  );
  static final _imageSrcPattern = RegExp(
    r'''\b(?:src|data-src|data-original)\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );
  static final _namedEntities = <String, String>{
    'amp': '&',
    'apos': "'",
    'bull': '•',
    'copy': '©',
    'gt': '>',
    'hellip': '…',
    'laquo': '«',
    'ldquo': '“',
    'lt': '<',
    'mdash': '—',
    'nbsp': ' ',
    'ndash': '–',
    'quot': '"',
    'raquo': '»',
    'rdquo': '”',
    'reg': '®',
    'trade': '™',
  };
}
