import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../device/secret_store.dart';
import '../money/money.dart';

/// Where customers open the Kahwti app (the receipt QR points there).
///   flutter run --dart-define=WEB_URL=https://kahwti.tn
const webUrl = String.fromEnvironment('WEB_URL', defaultValue: 'http://localhost:3001');

/// Signs the loyalty QR printed on receipts, with this POS's private key (made at pairing).
/// The backend checks it with the public key it received then: a customer can't invent
/// a receipt or change its total. Works offline: nothing is sent when printing.
///
/// Format (same as backend src/shared/receipts.ts): `payload.signature`, both base64url,
/// payload = JSON {o: orderId, d: deviceId, n: receiptNumber, t: total millimes, at: unix seconds}.
class ReceiptSigner {
  ReceiptSigner(this._secrets, this._deviceId);

  final SecretStore _secrets;
  final String? Function() _deviceId;

  /// null when this POS isn't paired (no key).
  Future<String?> code({
    required String orderId,
    required String receiptNumber,
    required Money total,
    required DateTime at,
  }) async {
    final seed = await _secrets.read(SecretKeys.devicePrivateKey);
    final deviceId = _deviceId();
    if (seed == null || deviceId == null) return null;
    final payload = _b64(
      utf8.encode(
        jsonEncode({
          'o': orderId,
          'd': deviceId,
          'n': receiptNumber,
          't': total.millimes,
          'at': at.millisecondsSinceEpoch ~/ 1000,
        }),
      ),
    );
    final algo = Ed25519();
    final keyPair = await algo.newKeyPairFromSeed(base64Url.decode(base64Url.normalize(seed)));
    final signature = await algo.sign(utf8.encode(payload), keyPair: keyPair);
    return '$payload.${_b64(signature.bytes)}';
  }

  /// What the phone camera opens: the claim page of the customer app.
  static String url(String code) => '$webUrl/r/$code';

  static String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
}
