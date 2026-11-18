import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Checks a staff PIN OFFLINE against the hash sent by the backend.
/// Format: "pbkdf2-sha256$ITERATIONS$SALT_B64URL$HASH_B64URL" — same as
/// Backend_Platform src/shared/pin.ts (shared test vector in pin_test.dart).
Future<bool> verifyPin(String pin, String stored) async {
  final parts = stored.split(r'$');
  if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations < 1) return false;
  try {
    final salt = _b64(parts[2]);
    final expected = _b64(parts[3]);
    // A damaged or truncated hash must refuse the PIN, never crash (PBKDF2 needs >= 64 bits).
    if (salt.isEmpty || expected.length < 16) return false;
    final algo = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: expected.length * 8);
    final key = await algo.deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);
    return _constantTimeEquals(await key.extractBytes(), expected);
  } on FormatException {
    return false;
  }
}

bool isValidPin(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

List<int> _b64(String s) => base64Url.decode(base64Url.normalize(s));

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
