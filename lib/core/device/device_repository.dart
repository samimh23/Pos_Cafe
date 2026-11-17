import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../api/pos_api.dart';
import '../db/app_database.dart';
import 'secret_store.dart';

/// Who this POS is, once paired. Not secret — stored in the local DB.
class DeviceIdentity {
  final String deviceId, deviceCode, role, tenantId, branchId, name;

  const DeviceIdentity({
    required this.deviceId,
    required this.deviceCode,
    required this.role,
    required this.tenantId,
    required this.branchId,
    required this.name,
  });

  bool get isHub => role == 'hub';

  Map<String, Object?> toJson() => {
    'deviceId': deviceId,
    'deviceCode': deviceCode,
    'role': role,
    'tenantId': tenantId,
    'branchId': branchId,
    'name': name,
  };

  factory DeviceIdentity.fromJson(Map<String, dynamic> j) => DeviceIdentity(
    deviceId: j['deviceId'],
    deviceCode: j['deviceCode'],
    role: j['role'],
    tenantId: j['tenantId'],
    branchId: j['branchId'],
    name: j['name'],
  );
}

/// Model layer for the device: pairing, identity, secrets.
class DeviceRepository {
  DeviceRepository(this._db, this._secrets, this._api);

  final AppDatabase _db;
  final SecretStore _secrets;
  final PosApi _api;

  static const _identityKey = 'device_identity';

  Future<DeviceIdentity?> load() async {
    final raw = await _db.getKv(_identityKey);
    if (raw == null || await _secrets.read(SecretKeys.deviceToken) == null) return null;
    return DeviceIdentity.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// 1. create an Ed25519 key pair (private key never leaves the device)
  /// 2. send code + name + public key to the backend
  /// 3. keep the token and private key in secure storage, the identity in the DB
  Future<DeviceIdentity> pair({required String code, required String name}) async {
    final algo = Ed25519();
    final keyPair = await algo.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();

    final res = await _api.pair(code: code, name: name, publicKey: _b64(publicKey.bytes));

    await _secrets.write(SecretKeys.deviceToken, res.token);
    await _secrets.write(SecretKeys.devicePrivateKey, _b64(await keyPair.extractPrivateKeyBytes()));

    final identity = DeviceIdentity(
      deviceId: res.deviceId,
      deviceCode: res.deviceCode,
      role: res.role,
      tenantId: res.tenantId,
      branchId: res.branchId,
      name: name,
    );
    await _db.setKv(_identityKey, jsonEncode(identity.toJson()));
    return identity;
  }

  /// Asks the server if the token is still valid. Throws [ApiException]
  /// (`DEVICE_DISABLED`, `UNAUTHORIZED`, or network error when offline).
  Future<void> checkWithServer() => _api.me();

  /// Forget the pairing (device disabled, or reset during development).
  /// Local data (menu, pending events) is kept.
  Future<void> forget() async {
    await _secrets.delete(SecretKeys.deviceToken);
    await _secrets.delete(SecretKeys.devicePrivateKey);
    await _db.deleteKv(_identityKey);
  }

  static String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
}
