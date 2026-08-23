import 'legacy_tag_mapping.dart';

/// Safe, non-executing subset of Legacy static transforms.
///
/// A single `##literal` suffix is treated as a literal prefix removal. The
/// `||` operator is treated as an ordered fallback only when every branch has
/// the same value action and node kind. Regex replacement, templates, scripts
/// and indexed selectors are rejected rather than guessed.
final class LegacyStaticTransformResult {
  const LegacyStaticTransformResult({
    required this.selector,
    required this.fallbackSelectors,
    required this.attribute,
    this.removePrefix,
  });

  final String? selector;
  final List<String> fallbackSelectors;
  final String? attribute;
  final String? removePrefix;
}

final class LegacyStaticTransform {
  const LegacyStaticTransform._();

  static LegacyStaticTransformResult parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      throw const LegacyStaticTransformException('规则不能为空');
    }
    final branches = value.split('||').map((item) => item.trim()).toList();
    if (branches.any((branch) => branch.isEmpty)) {
      throw const LegacyStaticTransformException('|| 分支不能为空');
    }
    final parsed = branches.map(_parseBranch).toList(growable: false);
    final first = parsed.first;
    for (final candidate in parsed.skip(1)) {
      if (candidate.attribute != first.attribute ||
          (candidate.selector == null) != (first.selector == null) ||
          candidate.removePrefix != first.removePrefix) {
        throw const LegacyStaticTransformException(
          '|| 分支必须使用相同的取值动作、节点类型和字面前缀',
        );
      }
    }
    final fallbacks = <String>[];
    for (final candidate in parsed.skip(1)) {
      final selector = candidate.selector;
      if (selector != null &&
          selector != first.selector &&
          !fallbacks.contains(selector)) {
        fallbacks.add(selector);
      }
    }
    return LegacyStaticTransformResult(
      selector: first.selector,
      fallbackSelectors: List.unmodifiable(fallbacks),
      attribute: first.attribute,
      removePrefix: first.removePrefix,
    );
  }

  static _Branch _parseBranch(String raw) {
    final parts = raw.split('##');
    if (parts.length > 2) {
      throw const LegacyStaticTransformException('## 多段替换属于正则/替换语法，需人工确认');
    }
    final expression = parts.first.trim();
    if (expression.isEmpty) {
      throw const LegacyStaticTransformException('## 前缺少字段规则');
    }
    final removePrefix = parts.length == 2 ? _literalPrefix(parts[1]) : null;
    final mapped = expression.contains('@tag.')
        ? _mapTag(expression)
        : _mapCss(expression);
    return _Branch(
      selector: mapped.selector.isEmpty ? null : mapped.selector,
      attribute: mapped.attribute,
      removePrefix: removePrefix,
    );
  }

  static LegacyTagMappingResult _mapTag(String expression) {
    try {
      return LegacyTagMapping.map(expression)!;
    } on LegacyTagMappingException catch (error) {
      throw LegacyStaticTransformException(error.message);
    }
  }

  static LegacyTagMappingResult _mapCss(String expression) {
    final match = RegExp(
      r'^(.*)@([A-Za-z][A-Za-z0-9_:.-]*)$',
    ).firstMatch(expression);
    final selector = _normalizeSelector(match?.group(1) ?? expression);
    final action = match?.group(2)?.toLowerCase();
    if (selector.isEmpty) {
      if (action == 'text' || action == 'html') {
        return const LegacyTagMappingResult(selector: '');
      }
      if (action == 'href' || action == 'src' || action == 'content') {
        return LegacyTagMappingResult(selector: '', attribute: action);
      }
      throw const LegacyStaticTransformException('规则缺少可验证 selector');
    }
    if (action != null &&
        !const <String>{
          'text',
          'html',
          'href',
          'src',
          'content',
        }.contains(action)) {
      throw LegacyStaticTransformException('使用不支持的动作 @$action');
    }
    if (RegExp(r'(?:^|[\s>+~])\.-?\d+(?:\b|$)').hasMatch(selector)) {
      throw const LegacyStaticTransformException('使用位置索引，当前无法保证 CSS 语义一致');
    }
    return LegacyTagMappingResult(
      selector: selector,
      attribute: action == 'href' || action == 'src' || action == 'content'
          ? action
          : null,
    );
  }

  static String _literalPrefix(String raw) {
    final prefix = raw.trim();
    if (prefix.isEmpty || prefix.length > 80 || prefix.contains('\n')) {
      throw const LegacyStaticTransformException('## 前缀必须是短的非空字面文本');
    }
    if (RegExp(r'[\\^\$\.\*\+\?\(\)\[\]\{\}\|]').hasMatch(prefix)) {
      throw const LegacyStaticTransformException('## 内容包含正则元字符，需人工确认');
    }
    return prefix;
  }

  static String _normalizeSelector(String value) {
    var selector = value.trim();
    selector = selector.replaceAllMapped(
      RegExp(r'(^|[\s>+~])class\.'),
      (match) => '${match.group(1)}.',
    );
    return selector;
  }
}

final class _Branch {
  const _Branch({required this.selector, this.attribute, this.removePrefix});

  final String? selector;
  final String? attribute;
  final String? removePrefix;
}

final class LegacyStaticTransformException implements Exception {
  const LegacyStaticTransformException(this.message);

  final String message;

  @override
  String toString() => message;
}
