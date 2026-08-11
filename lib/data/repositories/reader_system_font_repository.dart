import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/reader/reader_font.dart';

/// Platform font capability.  Runtime IDs are stable namespaced strings; the
/// native channel only returns family names and never leaks platform objects.
final class ReaderSystemFontChoice implements ReaderFontDescriptor {
  const ReaderSystemFontChoice({
    required this.id,
    required this.familyName,
    String? displayName,
  }) : displayName = displayName ?? familyName;

  final String id;
  @override
  final String familyName;
  @override
  final String displayName;

  @override
  String get fontId => id;

  @override
  ReaderFontSource get source => ReaderFontSource.system;
}

final class ReaderSystemFontRepository {
  static const _windowsChannel = MethodChannel('xaocen/windows_fonts');
  static const _androidChannel = MethodChannel('xaocen.reader/fonts');

  Future<List<ReaderSystemFontChoice>> listAvailable() async {
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.windows &&
        platform != TargetPlatform.android) {
      return const [
        ReaderSystemFontChoice(id: 'systemDefault', familyName: '系统默认'),
      ];
    }
    final channel = platform == TargetPlatform.windows
        ? _windowsChannel
        : _androidChannel;
    try {
      final raw = await channel.invokeMethod<List<dynamic>>(
        'listAvailableFonts',
      );
      final descriptors = _decodeDescriptors(raw);
      return [
        const ReaderSystemFontChoice(id: 'systemDefault', familyName: '系统默认'),
        ...descriptors.map(
          (name) => ReaderSystemFontChoice(
            id: name.id ?? _stableId(platform, name.familyName),
            familyName: name.familyName,
            displayName: name.displayName,
          ),
        ),
      ];
    } on MissingPluginException {
      return const [
        ReaderSystemFontChoice(id: 'systemDefault', familyName: '系统默认'),
      ];
    } catch (_) {
      return const [
        ReaderSystemFontChoice(id: 'systemDefault', familyName: '系统默认'),
      ];
    }
  }

  static List<({String? id, String familyName, String displayName})>
  _decodeDescriptors(List<dynamic>? raw) {
    final values =
        <String, ({String? id, String familyName, String displayName})>{};
    for (final item in raw ?? const <dynamic>[]) {
      String? id;
      String? family;
      String? display;
      if (item is String) {
        family = item.trim();
        display = family;
      } else if (item is Map) {
        final idValue = item['id'];
        final familyValue = item['familyName'];
        final displayValue = item['displayName'];
        if (idValue is String && idValue.trim().isNotEmpty) {
          id = idValue.trim();
        }
        if (familyValue is String) family = familyValue.trim();
        if (displayValue is String) display = displayValue.trim();
        display ??= family;
      }
      if (family == null || family.isEmpty) continue;
      values[family.toLowerCase()] = (
        id: id,
        displayName: display?.isNotEmpty == true ? display! : family,
        familyName: family,
      );
    }
    final result = values.values.toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    return result;
  }

  static String _stableId(TargetPlatform platform, String family) {
    final normalized = family
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${platform.name}.system.family.$normalized';
  }
}
