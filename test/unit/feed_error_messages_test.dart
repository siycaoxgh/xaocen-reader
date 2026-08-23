import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/sources/remote/feed_error_messages.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/standard_feed_parser.dart';

void main() {
  test('maps transport and parser failures to understandable Chinese text', () {
    expect(
      describeFeedRefreshFailure(
        const RemoteHttpException(
          kind: RemoteHttpFailureKind.httpStatus,
          message: 'server error',
          statusCode: 503,
        ),
      ),
      '服务器返回 HTTP 503',
    );
    expect(
      describeFeedRefreshFailure(
        const RemoteHttpException(
          kind: RemoteHttpFailureKind.timeout,
          message: 'timed out',
        ),
      ),
      contains('超时'),
    );
    expect(
      describeFeedRefreshFailure(const StandardFeedParseException('bad XML')),
      contains('格式无法解析'),
    );
    expect(
      describeFeedRefreshFailure(TimeoutException('timeout')),
      contains('超时'),
    );
  });
}
