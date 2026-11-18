import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Requests between POS on the café Wi-Fi are signed with the café's LAN key
/// (HMAC-SHA256), so another phone on the same Wi-Fi can't send orders or payments.
///
/// Signed text: METHOD \n PATH \n DEVICE_ID \n TIMESTAMP_MS \n SHA256(BODY) (hex)
class LanSigner {
  LanSigner(this._lanKey);
  final String _lanKey;

  /// Tablets' clocks can be off a little; requests also carry a unique id, so a
  /// replayed request is ignored anyway.
  static const maxClockSkew = Duration(minutes: 10);

  Future<String> sign({
    required String method,
    required String path,
    required String deviceId,
    required int timestampMs,
    String body = '',
  }) async {
    final bodyHash = await Sha256().hash(utf8.encode(body));
    final text = '$method\n$path\n$deviceId\n$timestampMs\n${_hex(bodyHash.bytes)}';
    final mac = await Hmac.sha256().calculateMac(utf8.encode(text), secretKey: SecretKey(utf8.encode(_lanKey)));
    return base64Url.encode(mac.bytes).replaceAll('=', '');
  }

  Future<bool> verify({
    required String method,
    required String path,
    required String deviceId,
    required int timestampMs,
    required String signature,
    required DateTime now,
    String body = '',
  }) async {
    final skew = now.millisecondsSinceEpoch - timestampMs;
    if (skew.abs() > maxClockSkew.inMilliseconds) return false;
    final expected = await sign(method: method, path: path, deviceId: deviceId, timestampMs: timestampMs, body: body);
    return _constantTimeEquals(expected, signature);
  }

  static String _hex(List<int> bytes) => [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// Header names and the port of the Hub.
abstract final class HubProtocol {
  static const port = 7700;
  static const deviceHeader = 'x-kahwti-device';
  static const timestampHeader = 'x-kahwti-ts';
  static const signatureHeader = 'x-kahwti-sig';
}
