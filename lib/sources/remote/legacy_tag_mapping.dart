/// A deliberately small, non-executing mapper for the Legacy `@tag.*`
/// descendant syntax.
///
/// Only tag traversal and the existing bounded value actions are supported.
/// Indexes, boolean branches, replacements, templates and scripts are
/// rejected instead of being guessed.
final class LegacyTagMappingResult {
  const LegacyTagMappingResult({
    required this.selector,
    this.attribute,
  });

  final String selector;
  final String? attribute;
}

final class LegacyTagMapping {
  const LegacyTagMapping._();

  static LegacyTagMappingResult? map(String raw) {
    final value = raw.trim();
    if (!value.contains('@tag.')) return null;

    if (value.contains('##') ||
        value.contains('||') ||
        value.contains('{{') ||
        RegExp(
          r'(?:@get\s*:|@put\s*:|@js\s*:|<js>|javascript\s*:)',
          caseSensitive: false,
        ).hasMatch(value)) {
      throw const LegacyTagMappingException(
        '规则包含替换、模板或脚本语法，@tag 映射拒绝猜测',
      );
    }

    final candidateAction = RegExp(
      r'@([A-Za-z][A-Za-z0-9_:.-]*)$',
    ).firstMatch(value);
    // `@tag.<name>` is traversal syntax, not a value action.  Treat a
    // trailing tag token as part of the selector so chained traversal and
    // invalid index forms are validated below.
    final actionMatch = candidateAction != null &&
            candidateAction.group(1)!.toLowerCase().startsWith('tag.')
        ? null
        : candidateAction;
    final action = actionMatch?.group(1)?.toLowerCase();
    final path = actionMatch == null
        ? value
        : value.substring(0, actionMatch.start);
    final selectorParts = path.split('@tag.');
    final base = _normalizeBase(selectorParts.first);
    final tags = <String>[];
    for (final rawTag in selectorParts.skip(1)) {
      final tag = rawTag.trim();
      if (!RegExp(r'^(?:\*|[A-Za-z][A-Za-z0-9:-]*)$').hasMatch(tag)) {
        throw LegacyTagMappingException(
          '不支持的 @tag 片段：@$tag（索引/分支/复合动作需人工确认）',
        );
      }
      tags.add(tag);
    }
    final selector = <String>[if (base.isNotEmpty) base, ...tags].join(' ');
    if (selector.isEmpty) {
      throw const LegacyTagMappingException('@tag 规则缺少可验证的 selector');
    }

    final attribute = switch (action) {
      null || 'text' || 'html' => null,
      'href' || 'src' || 'content' => action,
      _ => throw LegacyTagMappingException('不支持的 @tag 动作：@$action'),
    };
    return LegacyTagMappingResult(
      selector: selector,
      attribute: attribute,
    );
  }

  static String _normalizeBase(String value) {
    var selector = value.trim();
    selector = selector.replaceAllMapped(
      RegExp(r'(^|[\s>+~])class\.'),
      (match) => '${match.group(1)}.',
    );
    return selector;
  }
}

final class LegacyTagMappingException implements Exception {
  const LegacyTagMappingException(this.message);

  final String message;

  @override
  String toString() => message;
}
