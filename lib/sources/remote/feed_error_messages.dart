import 'dart:async';
import 'dart:io';

import 'remote_http_transport.dart';
import 'standard_feed_parser.dart';

/// Converts transport/parser failures to short, user-facing refresh messages.
/// Internal exception text and URLs are intentionally not exposed verbatim.
String describeFeedRefreshFailure(Object error) {
  if (error is RemoteHttpException) {
    return switch (error.kind) {
      RemoteHttpFailureKind.httpStatus =>
        '服务器返回 HTTP ${error.statusCode ?? '错误'}',
      RemoteHttpFailureKind.timeout => '请求超时，请检查网络后重试',
      RemoteHttpFailureKind.network => '网络连接失败，请检查网络后重试',
      RemoteHttpFailureKind.redirectOutsideSource => '订阅地址重定向到不受支持的地址',
      RemoteHttpFailureKind.unsupportedCharset => '订阅内容的字符编码暂不支持',
      RemoteHttpFailureKind.responseTooLarge => '订阅内容过大，无法加载',
      RemoteHttpFailureKind.invalidRequest => '订阅地址或请求无效',
    };
  }
  if (error is StandardFeedParseException || error is FormatException) {
    return '订阅内容格式无法解析';
  }
  if (error is TimeoutException) return '请求超时，请检查网络后重试';
  if (error is SocketException || error is HttpException) {
    return '网络连接失败，请检查网络后重试';
  }
  return '刷新失败，请检查订阅地址和网络';
}
