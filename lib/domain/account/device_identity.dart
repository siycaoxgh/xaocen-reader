import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_models.dart';

/// Device identity used by offline authorization. Private key material never
/// leaves the OS secure-storage boundary; the public key is safe to encode in
/// a QR transport payload.
final class DeviceIdentity {
  DeviceIdentity({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _publicKey = 'xaocen.account.device.publicKey';
  static const _privateKey = 'xaocen.account.device.privateKey';

  Future<DeviceIdentityInfo> loadOrCreate() async {
    final existingPublic = await _storage.read(key: _publicKey);
    final existingPrivate = await _storage.read(key: _privateKey);
    if (existingPublic != null &&
        existingPrivate != null &&
        existingPublic.isNotEmpty &&
        existingPrivate.isNotEmpty) {
      final bytes = base64Url.decode(base64Url.normalize(existingPublic));
      return DeviceIdentityInfo(publicKey: bytes, deviceId: _deviceId(bytes));
    }
    final keyPair = await Ed25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicBytes = publicKey.bytes;
    await _storage.write(key: _publicKey, value: base64UrlEncode(publicBytes));
    await _storage.write(
      key: _privateKey,
      value: base64UrlEncode(privateBytes),
    );
    return DeviceIdentityInfo(
      publicKey: publicBytes,
      deviceId: _deviceId(publicBytes),
    );
  }

  String _deviceId(List<int> publicKey) =>
      sha256.convert(publicKey).toString().substring(0, 32);
}

final class DeviceIdentityInfo {
  const DeviceIdentityInfo({required this.publicKey, required this.deviceId});

  final List<int> publicKey;
  final String deviceId;

  String get publicKeyBase64 => base64Encode(Uint8List.fromList(publicKey));
  String get qrPayload => jsonEncode({
    'type': 'xaocen-account-device',
    'version': 1,
    'productId': XaocenAccountProduct.productId,
    'platform': currentAccountPlatform().wireName,
    'deviceId': deviceId,
    'publicKey': publicKeySpkiPem,
  });
  String get publicKeySpkiPem {
    final der = <int>[..._spkiPrefix, ...publicKey];
    final encoded = base64Encode(der);
    final lines = <String>[];
    for (var i = 0; i < encoded.length; i += 64) {
      final end = i + 64 < encoded.length ? i + 64 : encoded.length;
      lines.add(encoded.substring(i, end));
    }
    return '-----BEGIN PUBLIC KEY-----\n${lines.join('\n')}\n-----END PUBLIC KEY-----';
  }

  // SubjectPublicKeyInfo prefix for Ed25519 (OID 1.3.101.112).
  static const _spkiPrefix = <int>[
    0x30,
    0x2a,
    0x30,
    0x05,
    0x06,
    0x03,
    0x2b,
    0x65,
    0x70,
    0x03,
    0x21,
    0x00,
  ];
}
