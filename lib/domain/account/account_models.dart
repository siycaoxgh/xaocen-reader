import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

/// Product constants are intentionally kept in one place.  They are sent to
/// Account for device authorization and are not inferred from the executable.
abstract final class XaocenAccountProduct {
  static const productId = 'xaocen-reader';
  static const windowsPlatform = 'windows-x64';
  static const androidPlatform = 'android';
  static const apiBase = 'https://auth.xaocen.studio/v1';
  static const offlineLicenseKeyId = 'primary';
}

enum AccountPlatform { windowsX64, android }

extension AccountPlatformWireName on AccountPlatform {
  String get wireName => switch (this) {
    AccountPlatform.windowsX64 => XaocenAccountProduct.windowsPlatform,
    AccountPlatform.android => XaocenAccountProduct.androidPlatform,
  };
}

AccountPlatform currentAccountPlatform() {
  return Platform.isAndroid
      ? AccountPlatform.android
      : AccountPlatform.windowsX64;
}

final class AccountSession {
  const AccountSession({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
    this.accountId,
    this.tokenType = 'Bearer',
    this.scope = const <String>[],
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final String? accountId;
  final String tokenType;
  final List<String> scope;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now().toUtc());

  factory AccountSession.fromJson(Map<String, Object?> json) {
    final access = json['accessToken'] ?? json['access_token'];
    final refresh = json['refreshToken'] ?? json['refresh_token'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw const AccountProtocolException('token 响应缺少会话字段');
    }
    final expires = json['expiresAt'] ?? json['expires_at'];
    return AccountSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: expires is String ? DateTime.tryParse(expires)?.toUtc() : null,
      accountId: (json['accountId'] ?? json['account_id']) as String?,
      tokenType:
          (json['tokenType'] ?? json['token_type']) as String? ?? 'Bearer',
      scope: (json['scope'] is List)
          ? (json['scope'] as List).whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }
}

final class DeviceAuthorization {
  const DeviceAuthorization({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.verificationUriComplete,
    required this.expiresIn,
    required this.interval,
    this.requestId,
  });

  final String deviceCode;
  final String userCode;
  final Uri verificationUri;
  final Uri? verificationUriComplete;
  final Duration expiresIn;
  final Duration interval;
  final String? requestId;

  factory DeviceAuthorization.fromJson(Map<String, Object?> json) {
    final device = json['deviceCode'] ?? json['device_code'];
    final user = json['userCode'] ?? json['user_code'];
    final uri = json['verificationUri'] ?? json['verification_uri'];
    if (device is! String || user is! String || uri is! String) {
      throw const AccountProtocolException('device/start 响应字段无效');
    }
    final complete =
        json['verificationUriComplete'] ?? json['verification_uri_complete'];
    return DeviceAuthorization(
      deviceCode: device,
      userCode: user,
      verificationUri: Uri.parse(uri),
      verificationUriComplete: complete is String && complete.isNotEmpty
          ? Uri.tryParse(complete)
          : null,
      expiresIn: Duration(
        seconds: _intValue(json['expiresIn'] ?? json['expires_in'], 900),
      ),
      interval: Duration(seconds: _intValue(json['interval'], 5)),
      requestId: json['requestId'] as String? ?? json['request_id'] as String?,
    );
  }
}

final class DeviceAuthorizationStatus {
  const DeviceAuthorizationStatus({required this.status, this.message});

  final String status;
  final String? message;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isTerminal =>
      status == 'denied' || status == 'expired' || status == 'consumed';

  factory DeviceAuthorizationStatus.fromJson(Map<String, Object?> json) =>
      DeviceAuthorizationStatus(
        status: (json['status'] ?? '').toString().toLowerCase(),
        message: json['message'] as String?,
      );
}

final class OfflineAuthorizationRequest {
  const OfflineAuthorizationRequest({
    required this.requestId,
    required this.status,
    this.expiresAt,
  });

  final String requestId;
  final String status;
  final DateTime? expiresAt;

  factory OfflineAuthorizationRequest.fromJson(Map<String, Object?> json) =>
      OfflineAuthorizationRequest(
        requestId: (json['requestId'] ?? json['request_id'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        expiresAt: json['expiresAt'] is String
            ? DateTime.tryParse(json['expiresAt'] as String)?.toUtc()
            : null,
      );
}

final class AccountProfile {
  const AccountProfile({
    required this.accountId,
    this.displayName,
    this.avatarUrl,
    this.email,
  });

  final String accountId;
  final String? displayName;
  final String? avatarUrl;
  final String? email;

  factory AccountProfile.fromJson(Map<String, Object?> json) => AccountProfile(
    accountId: (json['accountId'] ?? json['id'] ?? '').toString(),
    displayName: json['displayName'] as String? ?? json['name'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    // Email is display-only account metadata and is never persisted locally.
    email: json['email'] as String?,
  );
}

final class AccountEntitlement {
  const AccountEntitlement({
    required this.entitlementId,
    required this.productId,
    required this.status,
    this.licenseType,
    this.expiresAt,
    this.offlineAuthorizationAvailable = false,
  });

  final String entitlementId;
  final String productId;
  final String status;
  final String? licenseType;
  final DateTime? expiresAt;
  final bool offlineAuthorizationAvailable;

  factory AccountEntitlement.fromJson(Map<String, Object?> json) =>
      AccountEntitlement(
        entitlementId: (json['entitlementId'] ?? json['id'] ?? '').toString(),
        productId: (json['productId'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        licenseType: json['licenseType'] as String?,
        expiresAt: json['expiresAt'] is String
            ? DateTime.tryParse(json['expiresAt'] as String)?.toUtc()
            : null,
        offlineAuthorizationAvailable:
            json['offlineAuthorizationAvailable'] == true,
      );
}

final class AccountApiException implements Exception {
  const AccountApiException({
    required this.code,
    required this.message,
    this.requestId,
    this.statusCode,
  });

  final String code;
  final String message;
  final String? requestId;
  final int? statusCode;

  @override
  String toString() => 'AccountApiException($code): $message';
}

final class AccountProtocolException implements Exception {
  const AccountProtocolException(this.message);
  final String message;
  @override
  String toString() => 'AccountProtocolException: $message';
}

/// A compact license verifier.  The signature covers the base64url payload
/// segment exactly, as required by AUTHORIZATION-2.0.
final class OfflineLicenseVerifier {
  OfflineLicenseVerifier({Ed25519? algorithm})
    : _algorithm = algorithm ?? Ed25519();

  final Ed25519 _algorithm;

  Future<Map<String, Object?>> verify({
    required String compactLicense,
    required String expectedPlatform,
    required String? expectedDeviceId,
    DateTime? now,
  }) async {
    final parts = compactLicense.trim().split('.');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      throw const AccountProtocolException('离线授权字符串格式无效');
    }
    final encodedPayload = parts[0];
    final payloadBytes = _decodeUrl(encodedPayload);
    final signatureBytes = _decodeUrl(parts[1]);
    final dynamic decoded = jsonDecode(utf8.decode(payloadBytes));
    if (decoded is! Map) throw const AccountProtocolException('离线授权载荷无效');
    final payload = decoded.cast<String, Object?>();
    if (payload['keyId'] != XaocenAccountProduct.offlineLicenseKeyId) {
      throw const AccountProtocolException('离线授权公钥不受信任');
    }
    if (payload['productId'] != XaocenAccountProduct.productId ||
        payload['platform'] != expectedPlatform) {
      throw const AccountProtocolException('离线授权不属于当前产品或平台');
    }
    if (expectedDeviceId != null && payload['deviceId'] != expectedDeviceId) {
      throw const AccountProtocolException('离线授权不属于当前设备');
    }
    final expires = _date(payload['expiresAt'] ?? payload['expires_at']);
    if (expires != null && !expires.isAfter((now ?? DateTime.now()).toUtc())) {
      throw const AccountProtocolException('离线授权已过期');
    }
    final publicKey = SimplePublicKey(
      _publicKeyBytes,
      type: KeyPairType.ed25519,
    );
    final valid = await _algorithm.verify(
      utf8.encode(encodedPayload),
      signature: Signature(signatureBytes, publicKey: publicKey),
    );
    if (!valid) throw const AccountProtocolException('离线授权签名验证失败');
    return payload;
  }

  static final List<int> _publicKeyBytes = base64.decode(
    '7QaPUj1ZkJya2P2p072FhsNIa9iDHq7E4SRk3mDemCo=',
  );

  static List<int> _decodeUrl(String value) =>
      base64Url.decode(base64Url.normalize(value));
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}

int _intValue(Object? value, int fallback) =>
    value is num && value > 0 ? value.toInt() : fallback;
