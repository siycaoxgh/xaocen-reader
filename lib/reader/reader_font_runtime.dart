import 'package:flutter/services.dart';

import '../data/repositories/reader_font_repository.dart';
import '../domain/reader/reader_font.dart';

/// Loads app-managed fonts into the Flutter font registry once per process.
final class ReaderFontRuntime {
  final Map<String, Future<String?>> _loads = <String, Future<String?>>{};

  Future<String?> load(ReaderFontAsset asset, ReaderFontRepository repository) {
    return _loads.putIfAbsent(asset.fontId, () async {
      if (asset.availability != ReaderFontAvailability.available) return null;
      try {
        final bytes = await repository.readBytes(asset);
        final data = Uint8List.fromList(bytes);
        final loader = FontLoader(asset.runtimeFamily)
          ..addFont(Future<ByteData>.value(ByteData.sublistView(data)));
        await loader.load();
        await repository.touch(asset.fontId);
        return asset.runtimeFamily;
      } catch (_) {
        return null;
      }
    });
  }
}
