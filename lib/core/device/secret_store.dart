import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';

/// Where secrets live (device token, private key). An interface so tests can use memory.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Windows Credential Manager / Android Keystore. Keys are separated per [PosProfile].
class SecureSecretStore implements SecretStore {
  SecureSecretStore([this._profile = PosProfile.defaultProfile]);
  final PosProfile _profile;
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: _profile.secretKey(key));

  @override
  Future<void> write(String key, String value) => _storage.write(key: _profile.secretKey(key), value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: _profile.secretKey(key));
}

class MemorySecretStore implements SecretStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

abstract final class SecretKeys {
  static const deviceToken = 'device_token';
  static const devicePrivateKey = 'device_private_key';
}
