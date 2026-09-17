import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/account/account_models.dart';

void main() {
  test('device authorization uses protocol defaults and camel-case fields', () {
    final value = DeviceAuthorization.fromJson({
      'deviceCode': 'device-1',
      'userCode': 'ABCD-EFGH',
      'verificationUri': 'https://auth.xaocen.studio/device',
    });
    expect(value.deviceCode, 'device-1');
    expect(value.interval, const Duration(seconds: 5));
    expect(value.expiresIn, const Duration(seconds: 900));
  });

  test('session requires both access and refresh token', () {
    expect(
      () => AccountSession.fromJson({'accessToken': 'a'}),
      throwsA(isA<AccountProtocolException>()),
    );
  });

  test('offline license rejects wrong product before network use', () async {
    final payload = base64UrlEncode(
      utf8.encode(
        jsonEncode({
          'keyId': 'primary',
          'productId': 'other-product',
          'platform': XaocenAccountProduct.androidPlatform,
        }),
      ),
    );
    final license = '$payload.${base64UrlEncode(List<int>.filled(64, 0))}';
    expect(
      () => OfflineLicenseVerifier().verify(
        compactLicense: license,
        expectedPlatform: XaocenAccountProduct.androidPlatform,
        expectedDeviceId: null,
      ),
      throwsA(isA<AccountProtocolException>()),
    );
  });
}
