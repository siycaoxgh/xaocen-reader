import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform font capability.  Runtime IDs are stable namespaced strings; the
/// native channel only returns family names and never leaks platform objects.
final class ReaderSystemFontChoice {
  const ReaderSystemFontChoice({required this.id, required this.familyName});

  final String id;
  final String familyName;
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
      final names =
          (raw ?? const <dynamic>[])
              .whereType<String>()
              .map((name) => name.trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return [
        const ReaderSystemFontChoice(id: 'systemDefault', familyName: '系统默认'),
        ...names.map(
          (name) => ReaderSystemFontChoice(
            id: _stableId(platform, name),
            familyName: name,
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

  static String _stableId(TargetPlatform platform, String family) {
    final normalized = family
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${platform.name}.system.family.$normalized';
  }
}
