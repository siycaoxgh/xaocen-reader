import 'dart:collection';

import '../reader/reader_content.dart';

/// Remote source kinds are semantic boundaries, not transport implementations.
///
/// A source describes what is being read; it does not perform a network call.
/// Fetching, caching, authentication storage and retry policy belong to a
/// future platform-neutral transport layer.
enum RemoteSourceKind { standardFeed, webArticle, webBook }

extension RemoteSourceKindName on RemoteSourceKind {
  String get wireName => switch (this) {
    RemoteSourceKind.standardFeed => 'standardFeed',
    RemoteSourceKind.webArticle => 'webArticle',
    RemoteSourceKind.webBook => 'webBook',
  };
}

enum RemoteAuthScheme { bearer, basic, apiKey, cookie }

enum RemoteCookieMode { disabled, session, persistentJar }

/// Stable reference to a source or a stored credential.  It intentionally
/// contains no secret, cookie value or platform account object.
final class RemoteSourceId {
  RemoteSourceId(String value) : value = value.trim() {
    if (this.value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'RemoteSource id 不能为空');
    }
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      other is RemoteSourceId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class RemoteCredentialRef {
  const RemoteCredentialRef({required this.id, required this.scheme});

  final String id;
  final RemoteAuthScheme scheme;
}

final class RemoteCookieJarRef {
  const RemoteCookieJarRef({required this.id});

  final String id;
}

/// Header values are deliberately separate from auth/cookie references.
/// Authorization, Cookie and Set-Cookie cannot be smuggled into this map.
final class RemoteHeaders {
  RemoteHeaders([Map<String, String> values = const <String, String>{}])
    : values = UnmodifiableMapView<String, String>({
        for (final entry in values.entries)
          _normalizeName(entry.key): entry.value,
      }) {
    for (final name in this.values.keys) {
      if (_secretHeaderNames.contains(name)) {
        throw ArgumentError.value(
          name,
          'headers',
          '敏感认证/ Cookie header 必须通过 credential 或 cookie jar 引用',
        );
      }
    }
  }

  final Map<String, String> values;

  static const _secretHeaderNames = <String>{
    'authorization',
    'cookie',
    'set-cookie',
    'proxy-authorization',
  };

  static String _normalizeName(String name) => name.trim().toLowerCase();
}

/// Capabilities are the security and resource boundary shared by all remote
/// source types.  They do not grant permission by themselves; a future
/// transport must enforce them before creating a real request.
final class RemoteRequestCapabilities {
  const RemoteRequestCapabilities({
    this.allowedHeaders = const <String>{},
    this.authSchemes = const <RemoteAuthScheme>{},
    this.cookieMode = RemoteCookieMode.disabled,
    this.followRedirects = false,
    this.maxResponseBytes = 8 * 1024 * 1024,
    this.timeout = const Duration(seconds: 20),
  });

  final Set<String> allowedHeaders;
  final Set<RemoteAuthScheme> authSchemes;
  final RemoteCookieMode cookieMode;
  final bool followRedirects;
  final int maxResponseBytes;
  final Duration timeout;

  bool allowsAuth(RemoteAuthScheme scheme) => authSchemes.contains(scheme);

  bool allowsHeader(String name) =>
      allowedHeaders.contains(name.trim().toLowerCase());

  bool get allowsCookies => cookieMode != RemoteCookieMode.disabled;
}

/// A request plan is data only.  It is safe to log/validate as a plan because
/// it carries credential references, never credential or cookie values.
final class RemoteRequestPlan {
  RemoteRequestPlan({
    required String method,
    required this.uri,
    required this.headers,
    required this.capabilities,
    this.credential,
    this.cookieJar,
  }) : method = method.trim().toUpperCase() {
    if (this.method.isEmpty) {
      throw ArgumentError.value(method, 'method', '请求方法不能为空');
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw ArgumentError.value(uri, 'uri', '只允许 http/https 远程来源');
    }
    if (capabilities.maxResponseBytes <= 0 ||
        capabilities.timeout <= Duration.zero) {
      throw ArgumentError.value(capabilities, 'capabilities', '资源限制必须为正数');
    }
    if (credential != null &&
        !capabilities.authSchemes.contains(credential!.scheme)) {
      throw ArgumentError.value(credential, 'credential', '来源未声明该认证方式');
    }
    if (cookieJar != null && !capabilities.allowsCookies) {
      throw ArgumentError.value(cookieJar, 'cookieJar', '来源未启用 Cookie jar');
    }
    for (final header in headers.values.keys) {
      if (!capabilities.allowsHeader(header)) {
        throw ArgumentError.value(header, 'headers', '来源未声明该 header');
      }
    }
  }

  final String method;
  final Uri uri;
  final RemoteHeaders headers;
  final RemoteRequestCapabilities capabilities;
  final RemoteCredentialRef? credential;
  final RemoteCookieJarRef? cookieJar;
}

/// Common semantic contract shared by RSS/Atom, article rules and book rules.
/// It is intentionally transport-free: no `http`, WebView, JS or Android
/// implementation is allowed to leak into this domain contract.
abstract interface class RemoteSource {
  RemoteSourceId get id;
  RemoteSourceKind get kind;
  Uri get endpoint;
  RemoteRequestCapabilities get requestCapabilities;

  bool accepts(Uri uri);

  RemoteRequestPlan planRequest({
    required Uri uri,
    String method,
    RemoteHeaders? headers,
    RemoteCredentialRef? credential,
    RemoteCookieJarRef? cookieJar,
  });
}

abstract base class _BaseRemoteSource implements RemoteSource {
  _BaseRemoteSource({
    required this.id,
    required this.endpoint,
    required this.requestCapabilities,
  });

  @override
  final RemoteSourceId id;
  @override
  final Uri endpoint;
  @override
  final RemoteRequestCapabilities requestCapabilities;

  @override
  bool accepts(Uri uri) =>
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty &&
      (uri.host == endpoint.host || uri.host.endsWith('.${endpoint.host}'));

  @override
  RemoteRequestPlan planRequest({
    required Uri uri,
    String method = 'GET',
    RemoteHeaders? headers,
    RemoteCredentialRef? credential,
    RemoteCookieJarRef? cookieJar,
  }) {
    if (!accepts(uri)) {
      throw ArgumentError.value(uri, 'uri', 'URI 不属于该 RemoteSource');
    }
    return RemoteRequestPlan(
      method: method,
      uri: uri,
      headers: headers ?? RemoteHeaders(),
      capabilities: requestCapabilities,
      credential: credential,
      cookieJar: cookieJar,
    );
  }
}

/// RSS/Atom feed: a time-ordered collection of article items.
final class StandardFeedSource extends _BaseRemoteSource {
  StandardFeedSource({
    required super.id,
    required super.endpoint,
    required this.format,
    super.requestCapabilities = const RemoteRequestCapabilities(),
    this.refreshInterval = const Duration(minutes: 15),
  });

  final String format;
  final Duration refreshInterval;

  @override
  RemoteSourceKind get kind => RemoteSourceKind.standardFeed;
}

/// Rule-driven single web article.  The rule set is an identity/reference;
/// this stage does not execute selectors or JavaScript.
final class WebArticleSource extends _BaseRemoteSource {
  WebArticleSource({
    required super.id,
    required super.endpoint,
    required this.articleUri,
    required this.ruleSetId,
    super.requestCapabilities = const RemoteRequestCapabilities(),
    this.listUri,
    this.canonicalUri,
  });

  final Uri articleUri;
  final String ruleSetId;

  /// Optional list/index endpoint for the article-source flow.  It is an
  /// endpoint declaration only; no list request is executed here.
  final Uri? listUri;
  final Uri? canonicalUri;

  @override
  RemoteSourceKind get kind => RemoteSourceKind.webArticle;

  @override
  bool accepts(Uri uri) =>
      super.accepts(uri) &&
      (uri == endpoint || uri == articleUri || uri == listUri);
}

/// Rule-driven online book: stable book identity plus ordered chapter source.
final class WebBookSource extends _BaseRemoteSource {
  WebBookSource({
    required super.id,
    required super.endpoint,
    required this.bookKey,
    required this.ruleSetId,
    this.searchEndpoint,
    this.searchQueryParameter = 'q',
    super.requestCapabilities = const RemoteRequestCapabilities(),
    this.refreshInterval = const Duration(hours: 1),
  }) : assert(searchQueryParameter.isNotEmpty),
       assert(!searchQueryParameter.contains('='));

  final String bookKey;
  final String ruleSetId;

  /// Optional independent search page. When absent, [endpoint] is used.
  final Uri? searchEndpoint;

  /// Query parameter used by the source's search endpoint. The generic
  /// default is `q`; sources whose native endpoint uses `key`, `keyword`, or
  /// another name declare it explicitly instead of relying on a fixture.
  final String searchQueryParameter;
  final Duration refreshInterval;

  @override
  RemoteSourceKind get kind => RemoteSourceKind.webBook;
}

/// Future bridge: once a remote snapshot is persisted into existing
/// ContentSource/Collection/Document projections, its normal adapter is used
/// to produce ReaderContent.  This interface prevents a remote source from
/// inventing a second Reader or Locator implementation.
abstract interface class RemoteSourceReaderAdapter
    implements ReaderContentAdapter {
  RemoteSourceKind get remoteKind;
  bool canAdaptRemote(RemoteSource source);
}

/// Configuration codecs (including a future Legado-compatible JSON codec)
/// are extension points only.  No JSON parser or network importer is shipped
/// in M5.9c-0.
abstract interface class RemoteSourceConfigCodec {
  String get format;
  int get version;
  bool canDecode(Map<String, Object?> json);
  RemoteSource decode(Map<String, Object?> json);
  Map<String, Object?> encode(RemoteSource source);
}

abstract final class RemoteSourceConfigFormats {
  static const legadoJson = 'legado-json';
}
