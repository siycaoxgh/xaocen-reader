import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../sources/remote/remote_http_transport.dart';
import '../remote/remote_source.dart';
import 'account_models.dart';
import 'device_identity.dart';

/// Account transport facade. It deliberately owns no UI and never stores the
/// access token. Refresh credentials are kept by the OS secure-storage plugin.
final class XaocenAccountClient {
  XaocenAccountClient({
    RemoteHttpTransport? transport,
    FlutterSecureStorage? storage,
    Uri? apiBase,
    String? platform,
    String? profileId,
  }) : _transport = transport ?? RemoteHttpTransport(),
       _storage = storage ?? const FlutterSecureStorage(),
       apiBase = apiBase ?? Uri.parse(XaocenAccountProduct.apiBase),
       platform = platform ?? XaocenAccountProduct.windowsPlatform,
       profileId = profileId ?? 'default';

  final RemoteHttpTransport _transport;
  final FlutterSecureStorage _storage;
  final Uri apiBase;
  final String platform;
  final String profileId;
  AccountSession? _session;

  AccountSession? get session => _session;
  bool get isSignedIn => _session != null && !_session!.isExpired;

  Future<AccountSession?> restoreSession() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null || refresh.isEmpty) return null;
    try {
      return _session = await refreshSession(refresh);
    } on AccountApiException catch (error) {
      if (error.statusCode == 401 ||
          error.code == 'invalid_grant' ||
          error.code == 'invalid_refresh_token') {
        await _storage.delete(key: _refreshKey);
      }
      return null;
    }
  }

  Future<DeviceAuthorization> startDeviceAuthorization({
    String? deviceName,
    String? devicePublicKey,
  }) async {
    final result = await _post('auth/device/start', {
      'productId': XaocenAccountProduct.productId,
      'platform': platform,
      'deviceName': deviceName ?? _defaultDeviceName(),
      // ignore: use_null_aware_elements, map if-elements cannot use `...?`
      if (devicePublicKey case final key?) 'devicePublicKey': key,
    });
    return DeviceAuthorization.fromJson(result);
  }

  Future<DeviceAuthorizationStatus> deviceStatus(String deviceCode) async {
    final result = await _post('auth/device/status', {
      'deviceCode': deviceCode,
    });
    return DeviceAuthorizationStatus.fromJson(result);
  }

  Future<AccountSession> deviceToken(String deviceCode) async {
    final session = AccountSession.fromJson(
      await _post('auth/device/token', {'deviceCode': deviceCode}),
    );
    return _saveSession(session);
  }

  Future<AccountSession> refreshSession([String? refreshToken]) async {
    final token = refreshToken ?? await _storage.read(key: _refreshKey);
    if (token == null || token.isEmpty) {
      throw const AccountApiException(
        code: 'reauthorization_required',
        message: '需要重新授权',
      );
    }
    final session = AccountSession.fromJson(
      await _post('auth/device/refresh', {'refreshToken': token}),
    );
    return _saveSession(session);
  }

  Future<void> logout() async {
    final token = await _storage.read(key: _refreshKey);
    if (token != null && token.isNotEmpty) {
      try {
        await _post('auth/device/logout', {
          'refreshToken': token,
        }, bearerToken: _session?.accessToken);
      } catch (_) {}
    }
    _session = null;
    await _storage.delete(key: _refreshKey);
  }

  Future<void> revoke() async {
    final token = await _storage.read(key: _refreshKey);
    if (token != null && token.isNotEmpty) {
      await _post('auth/device/revoke', {
        'refreshToken': token,
      }, bearerToken: _session?.accessToken);
    }
    _session = null;
    await _storage.delete(key: _refreshKey);
  }

  Future<AccountProfile> accountMe() async =>
      AccountProfile.fromJson(await _get('account/me'));

  Future<List<AccountEntitlement>> entitlements() async {
    final decoded = await _get('account/entitlements');
    final values =
        decoded['entitlements'] ?? decoded['items'] ?? const <Object?>[];
    if (values is! List) return const <AccountEntitlement>[];
    return values
        .whereType<Map>()
        .map(
          (value) => AccountEntitlement.fromJson(value.cast<String, Object?>()),
        )
        .toList(growable: false);
  }

  Future<Map<String, Object?>> checkOfflineLicense(
    String compactLicense,
  ) async {
    final identity = await DeviceIdentity(storage: _storage).loadOrCreate();
    final payload = await OfflineLicenseVerifier().verify(
      compactLicense: compactLicense,
      expectedPlatform: platform,
      expectedDeviceId: identity.deviceId,
    );
    await _storage.write(key: _offlineLicenseKey, value: compactLicense.trim());
    return payload;
  }

  Future<OfflineAuthorizationRequest> requestOfflineAuthorization({
    required String deviceName,
    required String devicePublicKey,
  }) async {
    final result = await _post('account/offline/request', {
      'productId': XaocenAccountProduct.productId,
      'platform': platform,
      'deviceName': deviceName,
      'devicePublicKey': devicePublicKey,
    }, bearerToken: _session?.accessToken);
    return OfflineAuthorizationRequest.fromJson(result);
  }

  Future<String> issueOfflineLicense(String requestId) async {
    final result = await _post('account/offline-license', {
      'requestId': requestId,
    }, bearerToken: _session?.accessToken);
    final license = result['compactLicense'];
    if (license is! String || license.isEmpty) {
      throw const AccountProtocolException('离线授权响应缺少 compactLicense');
    }
    return license;
  }

  Future<Map<String, Object?>> offlineCheck({String? productVersion}) async {
    final license = await readOfflineLicense();
    if (license == null) throw const AccountProtocolException('尚未导入离线授权');
    final identity = await DeviceIdentity(storage: _storage).loadOrCreate();
    return _post('auth/offline/check', {
      'compactLicense': license,
      'devicePublicKey': identity.publicKeySpkiPem,
      // ignore: use_null_aware_elements, map if-elements cannot use `...?`
      if (productVersion case final version?) 'productVersion': version,
    });
  }

  Future<Map<String, Object?>> offlineRefresh({String? productVersion}) async {
    final license = await readOfflineLicense();
    if (license == null) throw const AccountProtocolException('尚未导入离线授权');
    final identity = await DeviceIdentity(storage: _storage).loadOrCreate();
    final result = await _post('auth/offline/refresh', {
      'compactLicense': license,
      'devicePublicKey': identity.publicKeySpkiPem,
      // ignore: use_null_aware_elements, map if-elements cannot use `...?`
      if (productVersion case final version?) 'productVersion': version,
    });
    final updated = result['compactLicense'];
    if (updated is String && updated.isNotEmpty) {
      await _storage.write(key: _offlineLicenseKey, value: updated);
    }
    return result;
  }

  Future<String?> readOfflineLicense() =>
      _storage.read(key: _offlineLicenseKey);
  Future<void> clearOfflineLicense() =>
      _storage.delete(key: _offlineLicenseKey);

  Future<void> close() => _transport.close();

  Future<AccountSession> _saveSession(AccountSession session) async {
    _session = session;
    // Access token intentionally remains in memory; only refresh is persisted.
    await _storage.write(key: _refreshKey, value: session.refreshToken);
    return session;
  }

  Future<Map<String, Object?>> _get(String path) async {
    final response = await _transport.execute(
      _plan('GET', path),
      bearerToken: _session?.accessToken,
    );
    return _decode(response);
  }

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body, {
    String? bearerToken,
  }) async {
    final bytes = utf8.encode(jsonEncode(body));
    final response = await _transport.execute(
      _plan('POST', path),
      bodyBytes: bytes,
      bearerToken: bearerToken ?? _session?.accessToken,
    );
    return _decode(response);
  }

  RemoteRequestPlan _plan(String method, String path) => RemoteRequestPlan(
    method: method,
    uri: Uri.parse(
      '${apiBase.toString().replaceFirst(RegExp(r'/$'), '')}/$path',
    ),
    headers: RemoteHeaders({
      'content-type': 'application/json',
      'accept': 'application/json',
    }),
    capabilities: const RemoteRequestCapabilities(
      allowedHeaders: {'content-type', 'accept'},
      followRedirects: false,
      timeout: Duration(seconds: 20),
    ),
  );

  Map<String, Object?> _decode(RemoteHttpResponse response) {
    Map<String, Object?> body = <String, Object?>{};
    try {
      final decoded = jsonDecode(response.decodeText());
      if (decoded is Map) body = decoded.cast<String, Object?>();
    } catch (_) {
      // Non-JSON responses are represented as a protocol error below.
    }
    if (!response.isSuccess) {
      throw AccountApiException(
        code: (body['code'] ?? 'http_${response.statusCode}').toString(),
        message: (body['message'] ?? '账号服务请求失败').toString(),
        requestId: body['requestId'] as String?,
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  String get _refreshKey => 'xaocen.account.$profileId.refreshToken';
  String get _offlineLicenseKey => 'xaocen.account.$profileId.offlineLicense';
  String _defaultDeviceName() =>
      'XAOCEN Reader ${sha256.convert(utf8.encode('${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}')).toString().substring(0, 8)}';
}
