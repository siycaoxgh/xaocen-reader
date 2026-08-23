import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Downloads only article images explicitly referenced by a feed item.
///
/// The cache is deliberately bounded and profile-local. A failed or
/// non-image response simply returns null; the Reader keeps its text and can
/// still show the source link/alt marker.
final class FeedImageCache {
  FeedImageCache({required this.directory, HttpClient? client})
    : _client = client ?? HttpClient();

  static const maxBytes = 8 * 1024 * 1024;
  final Directory directory;
  final HttpClient _client;

  Future<File?> fetch(Uri uri) async {
    if (!{'http', 'https'}.contains(uri.scheme.toLowerCase())) return null;
    final key = sha256.convert(uri.toString().codeUnits).toString();
    final file = File('${directory.path}${Platform.pathSeparator}$key.img');
    if (await file.exists() && await file.length() > 0) return file;
    HttpClientResponse? response;
    try {
      final request = await _client
          .getUrl(uri)
          .timeout(const Duration(seconds: 12));
      request.followRedirects = true;
      request.maxRedirects = 4;
      response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final contentType = response.headers.contentType?.mimeType.toLowerCase();
      if (contentType != null && !contentType.startsWith('image/')) return null;
      final bytes = <int>[];
      await for (final chunk in response) {
        if (bytes.length + chunk.length > maxBytes) return null;
        bytes.addAll(chunk);
      }
      if (bytes.isEmpty) return null;
      await directory.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
      return file;
    } on Object {
      return null;
    }
  }

  void close() => _client.close(force: true);
}
