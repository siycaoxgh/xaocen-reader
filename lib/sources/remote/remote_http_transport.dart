import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/remote/remote_source.dart';
import 'standard_feed_parser.dart';

/// A response returned by the platform-neutral HTTP transport.
final class RemoteHttpResponse {
  RemoteHttpResponse({
    required this.requestedUri,
    required this.finalUri,
    required this.statusCode,
    required Map<String, List<String>> headers,
    required List<int> bodyBytes,
  }) : headers = _freezeHeaders(headers),
       bodyBytes = List.unmodifiable(bodyBytes);

  final Uri requestedUri;
  final Uri finalUri;
  final int statusCode;
  final Map<String, List<String>> headers;
  final List<int> bodyBytes;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  String? header(String name) => headers[name.trim().toLowerCase()]?.join(', ');

  String? get contentType => header('content-type');

  String get charset => _detectCharset(contentType, bodyBytes);

  String decodeText() => decodeRemoteText(bodyBytes, charset: charset);

  static Map<String, List<String>> _freezeHeaders(
    Map<String, List<String>> source,
  ) => Map<String, List<String>>.unmodifiable({
    for (final entry in source.entries)
      entry.key.toLowerCase(): List<String>.unmodifiable(entry.value),
  });
}

enum RemoteHttpFailureKind {
  invalidRequest,
  timeout,
  network,
  responseTooLarge,
  unsupportedCharset,
  httpStatus,
  redirectOutsideSource,
}

final class RemoteHttpException implements Exception {
  const RemoteHttpException({
    required this.kind,
    required this.message,
    this.uri,
    this.statusCode,
  });

  final RemoteHttpFailureKind kind;
  final String message;
  final Uri? uri;
  final int? statusCode;

  @override
  String toString() => 'RemoteHttpException($kind): $message';
}

/// Small HTTP transport that executes an already validated RemoteRequestPlan.
/// It owns no cookies, credentials, WebView, cache or retry policy.
final class RemoteHttpTransport {
  RemoteHttpTransport({HttpClient? client})
    : _client = client ?? HttpClient(),
      _ownsClient = client == null;

  final HttpClient _client;
  final bool _ownsClient;
  bool _closed = false;

  Future<RemoteHttpResponse> execute(
    RemoteRequestPlan plan, {
    List<int>? bodyBytes,
    String? bearerToken,
  }) async {
    if (_closed) {
      throw const RemoteHttpException(
        kind: RemoteHttpFailureKind.invalidRequest,
        message: 'transport 已关闭',
      );
    }
    final timeout = plan.capabilities.timeout;
    try {
      final request = await _client
          .openUrl(plan.method, plan.uri)
          .timeout(timeout);
      request.followRedirects = plan.capabilities.followRedirects;
      request.maxRedirects = 5;
      for (final entry in plan.headers.values.entries) {
        request.headers.set(entry.key, entry.value);
      }
      // Authentication is supplied out-of-band so RemoteHeaders can never
      // accidentally persist or log a bearer secret.  Account clients keep
      // the access token in memory and pass it only for this request.
      if (bearerToken != null && bearerToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $bearerToken',
        );
      }
      if (bodyBytes != null) {
        request.contentLength = bodyBytes.length;
        request.add(bodyBytes);
      }
      final response = await request.close().timeout(timeout);
      final body = await _readBody(
        response,
        maxBytes: plan.capabilities.maxResponseBytes,
        timeout: timeout,
        uri: plan.uri,
      );
      final headers = <String, List<String>>{};
      response.headers.forEach((name, values) {
        headers[name.toLowerCase()] = List<String>.from(values);
      });
      return RemoteHttpResponse(
        requestedUri: plan.uri,
        finalUri: response.redirects.isEmpty
            ? plan.uri
            : response.redirects.last.location,
        statusCode: response.statusCode,
        headers: headers,
        bodyBytes: body,
      );
    } on RemoteHttpException {
      rethrow;
    } on TimeoutException catch (error) {
      throw RemoteHttpException(
        kind: RemoteHttpFailureKind.timeout,
        message: '请求超时: $error',
        uri: plan.uri,
      );
    } on SocketException catch (error) {
      throw RemoteHttpException(
        kind: RemoteHttpFailureKind.network,
        message: '网络请求失败: $error',
        uri: plan.uri,
      );
    } on HttpException catch (error) {
      throw RemoteHttpException(
        kind: RemoteHttpFailureKind.network,
        message: 'HTTP 请求失败: $error',
        uri: plan.uri,
      );
    } on FormatException catch (error) {
      throw RemoteHttpException(
        kind: RemoteHttpFailureKind.invalidRequest,
        message: '请求格式无效: $error',
        uri: plan.uri,
      );
    }
  }

  Future<RemoteFeedFetchResult> fetchStandardFeed({
    required StandardFeedSource source,
    RemoteHeaders? headers,
  }) async {
    final plan = source.planRequest(uri: source.endpoint, headers: headers);
    final response = await execute(plan);
    if (!source.accepts(response.finalUri)) {
      throw RemoteHttpException(
        kind: RemoteHttpFailureKind.redirectOutsideSource,
        message: '重定向地址不属于当前来源: ${response.finalUri}',
        uri: response.finalUri,
      );
    }
    if (!response.isSuccess) {
      throw RemoteHttpException(
        kind: RemoteHttpFailureKind.httpStatus,
        message: 'Feed 返回 HTTP ${response.statusCode}',
        uri: response.finalUri,
        statusCode: response.statusCode,
      );
    }
    final parsed = const StandardFeedParser().parse(
      xml: response.decodeText(),
      source: source,
    );
    return RemoteFeedFetchResult(response: response, feed: parsed);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (_ownsClient) _client.close(force: true);
  }

  Future<List<int>> _readBody(
    HttpClientResponse response, {
    required int maxBytes,
    required Duration timeout,
    required Uri uri,
  }) async {
    final bytes = <int>[];
    try {
      await response
          .forEach((chunk) {
            if (bytes.length + chunk.length > maxBytes) {
              throw const RemoteHttpException(
                kind: RemoteHttpFailureKind.responseTooLarge,
                message: '响应超过来源声明的大小上限',
              );
            }
            bytes.addAll(chunk);
          })
          .timeout(timeout);
    } on RemoteHttpException {
      rethrow;
    } on TimeoutException catch (error) {
      throw RemoteHttpException(
        kind: RemoteHttpFailureKind.timeout,
        message: '读取响应超时: $error',
        uri: uri,
      );
    }
    return bytes;
  }
}

final class RemoteFeedFetchResult {
  const RemoteFeedFetchResult({required this.response, required this.feed});

  final RemoteHttpResponse response;
  final StandardFeedParseResult feed;
}

String decodeRemoteText(List<int> bytes, {required String charset}) {
  final normalized = charset.trim().toLowerCase().replaceAll('_', '-');
  final data = Uint8List.fromList(bytes);
  switch (normalized) {
    case 'utf-8':
    case 'utf8':
      final value = utf8.decode(data, allowMalformed: true);
      return value.startsWith('\uFEFF') ? value.substring(1) : value;
    case 'utf-16':
      if (data.length >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
        return _decodeUtf16(data.sublist(2), littleEndian: true);
      }
      if (data.length >= 2 && data[0] == 0xFE && data[1] == 0xFF) {
        return _decodeUtf16(data.sublist(2), littleEndian: false);
      }
      return _decodeUtf16(data, littleEndian: true);
    case 'utf-16le':
    case 'utf16le':
      return _decodeUtf16(
        data.length >= 2 && data[0] == 0xFF && data[1] == 0xFE
            ? data.sublist(2)
            : data,
        littleEndian: true,
      );
    case 'utf-16be':
    case 'utf16be':
      return _decodeUtf16(
        data.length >= 2 && data[0] == 0xFE && data[1] == 0xFF
            ? data.sublist(2)
            : data,
        littleEndian: false,
      );
    case 'us-ascii':
    case 'ascii':
      return ascii.decode(data, allowInvalid: true);
    case 'iso-8859-1':
    case 'latin-1':
    case 'latin1':
    case 'windows-1252':
      return latin1.decode(data);
    default:
      throw RemoteHttpException(
        kind: RemoteHttpFailureKind.unsupportedCharset,
        message: '不支持的响应字符集: $charset',
      );
  }
}

String _decodeUtf16(Uint8List bytes, {required bool littleEndian}) {
  final units = <int>[];
  for (var index = 0; index + 1 < bytes.length; index += 2) {
    units.add(
      littleEndian
          ? bytes[index] | (bytes[index + 1] << 8)
          : (bytes[index] << 8) | bytes[index + 1],
    );
  }
  return String.fromCharCodes(units);
}

String _detectCharset(String? contentType, List<int> bytes) {
  final match = contentType == null
      ? null
      : RegExp(
          r'''charset\s*=\s*["']?([^;\s"']+)''',
          caseSensitive: false,
        ).firstMatch(contentType);
  if (match != null) return match.group(1)!.trim();
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return 'utf-16le';
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return 'utf-16be';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return 'utf-8';
  }
  return 'utf-8';
}
