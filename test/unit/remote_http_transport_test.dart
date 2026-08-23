import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';

void main() {
  late HttpServer server;
  late Uri base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://${server.address.host}:${server.port}');
  });

  tearDown(() => server.close(force: true));

  StandardFeedSource source(
    String path, {
    Duration timeout = const Duration(seconds: 2),
    bool followRedirects = false,
    int maxResponseBytes = 1024 * 1024,
  }) => StandardFeedSource(
    id: RemoteSourceId('test-feed'),
    endpoint: base.resolve(path),
    format: 'rss',
    requestCapabilities: RemoteRequestCapabilities(
      allowedHeaders: const {'accept', 'x-test'},
      timeout: timeout,
      followRedirects: followRedirects,
      maxResponseBytes: maxResponseBytes,
    ),
  );

  test(
    'executes a planned request and preserves status, headers and UTF-8',
    () async {
      final received = Completer<String>();
      server.listen((request) async {
        received.complete(request.headers.value('x-test') ?? '');
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType(
            'application',
            'rss+xml',
            charset: 'utf-8',
          )
          ..headers.set('x-response', 'ok')
          ..write('<rss><channel><title>测试</title></channel></rss>');
        await request.response.close();
      });
      final transport = RemoteHttpTransport();
      addTearDown(transport.close);

      final plan = source('/feed').planRequest(
        uri: source('/feed').endpoint,
        headers: RemoteHeaders({'X-Test': 'request-value'}),
      );
      final response = await transport.execute(plan);

      expect(await received.future, 'request-value');
      expect(response.statusCode, HttpStatus.ok);
      expect(response.header('X-Response'), 'ok');
      expect(response.charset, 'utf-8');
      expect(response.decodeText(), contains('测试'));
    },
  );

  test('follows redirects only when the source capability allows it', () async {
    server.listen((request) async {
      if (request.uri.path == '/redirect') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, '/feed');
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('ok');
      }
      await request.response.close();
    });
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);

    final noFollow = await transport.execute(
      source('/redirect').planRequest(uri: source('/redirect').endpoint),
    );
    expect(noFollow.statusCode, HttpStatus.found);

    final followSource = source('/redirect', followRedirects: true);
    final followed = await transport.execute(
      followSource.planRequest(uri: followSource.endpoint),
    );
    expect(followed.statusCode, HttpStatus.ok);
    expect(followed.finalUri.path, '/feed');
  });

  test('fetchStandardFeed connects HTTP transport to the RSS parser', () async {
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType(
          'application',
          'rss+xml',
          charset: 'utf-8',
        )
        ..write(
          '<rss version="2.0"><channel><title>在线 Feed</title>'
          '<item><title>条目</title><guid>id-1</guid>'
          '<description>正文</description></item></channel></rss>',
        );
      await request.response.close();
    });
    final feedSource = source('/feed');
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);

    final result = await transport.fetchStandardFeed(source: feedSource);

    expect(result.response.isSuccess, isTrue);
    expect(result.feed.title, '在线 Feed');
    expect(result.feed.items.single.title, '条目');
  });

  test('enforces response size and timeout boundaries', () async {
    server.listen((request) async {
      if (request.uri.path == '/slow') {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      request.response
        ..statusCode = HttpStatus.ok
        ..write('0123456789');
      await request.response.close();
    });
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);

    final limited = source('/feed', maxResponseBytes: 4);
    await expectLater(
      transport.execute(limited.planRequest(uri: limited.endpoint)),
      throwsA(
        isA<RemoteHttpException>().having(
          (error) => error.kind,
          'kind',
          RemoteHttpFailureKind.responseTooLarge,
        ),
      ),
    );
    final slow = source('/slow', timeout: const Duration(milliseconds: 20));
    await expectLater(
      transport.execute(slow.planRequest(uri: slow.endpoint)),
      throwsA(
        isA<RemoteHttpException>().having(
          (error) => error.kind,
          'kind',
          RemoteHttpFailureKind.timeout,
        ),
      ),
    );
  });

  test('decodes UTF-16 and rejects unsupported charsets explicitly', () {
    final bytes = <int>[0xFF, 0xFE];
    for (final unit in '标题'.codeUnits) {
      bytes
        ..add(unit & 0xFF)
        ..add(unit >> 8);
    }
    expect(decodeRemoteText(bytes, charset: 'utf-16le'), '标题');
    expect(
      () => decodeRemoteText(utf8.encode('x'), charset: 'gbk'),
      throwsA(
        isA<RemoteHttpException>().having(
          (error) => error.kind,
          'kind',
          RemoteHttpFailureKind.unsupportedCharset,
        ),
      ),
    );
  });

  test('non-success status is surfaced by feed fetch', () async {
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write('unavailable');
      await request.response.close();
    });
    final feedSource = source('/feed');
    final transport = RemoteHttpTransport();
    addTearDown(transport.close);

    await expectLater(
      transport.fetchStandardFeed(source: feedSource),
      throwsA(
        isA<RemoteHttpException>()
            .having(
              (error) => error.kind,
              'kind',
              RemoteHttpFailureKind.httpStatus,
            )
            .having(
              (error) => error.statusCode,
              'status',
              HttpStatus.serviceUnavailable,
            ),
      ),
    );
  });
}
