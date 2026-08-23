import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/remote/remote_source.dart';
import 'package:xaocen_reader/domain/remote/web_source_contracts.dart';
import 'package:xaocen_reader/sources/remote/remote_http_transport.dart';
import 'package:xaocen_reader/sources/remote/web_article_runtime.dart';

void main() {
  final enabled = const String.fromEnvironment('XAOCEN_WEB_ARTICLE_POC') == '1';

  test(
    'fetches the public RFC article through the minimal WebArticle runtime',
    () async {
      final endpoint = const String.fromEnvironment('XAOCEN_LIVE_SOURCE_URL');
      if (endpoint.isEmpty) {
        fail('Set XAOCEN_LIVE_SOURCE_URL locally for live network POC');
      }
      final uri = Uri.parse(endpoint);
      final source = WebArticleSource(
        id: RemoteSourceId('poc-rfc-editor'),
        endpoint: uri,
        articleUri: uri,
        ruleSetId: 'generic-html-v1',
        requestCapabilities: const RemoteRequestCapabilities(
          followRedirects: true,
          timeout: Duration(seconds: 20),
          maxResponseBytes: 16 * 1024 * 1024,
        ),
      );
      final transport = RemoteHttpTransport();
      addTearDown(transport.close);
      final outcome = await WebArticleHttpRuntime(transport: transport)
          .tryFetch(
            source: source,
            item: WebArticleListItem(
              identity: 'rfc-9110',
              title: 'HTTP Semantics',
              uri: uri,
            ),
          );

      expect(outcome.isSuccess, isTrue, reason: outcome.failure?.message);
      expect(outcome.document!.body.canonical.text.length, greaterThan(1000));
      expect(outcome.document!.body.canonical.text, contains('HTTP'));
    },
    skip: !enabled
        ? 'Set XAOCEN_WEB_ARTICLE_POC=1 for live network POC'
        : false,
  );
}
