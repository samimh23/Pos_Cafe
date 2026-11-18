import 'dart:io' show Platform;

/// Build-time config. Override with:
///   flutter run -d windows --dart-define=API_URL=https://api.example.com
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');

  /// How often the background sync runs when the app is open.
  static const syncInterval = Duration(seconds: 15);

  /// Lets several POS run on ONE computer (testing a Hub + a second till):
  ///   PowerShell: $env:POS_PROFILE="2"; .\build\windows\x64\runner\Debug\pos_cafe.exe
  /// or at build time: --dart-define=POS_PROFILE=2. Empty = the normal POS.
  static final profile = PosProfile.parse(
    Platform.environment['POS_PROFILE'] ?? const String.fromEnvironment('POS_PROFILE'),
  );
}

/// Each profile has its own database and its own secrets (token, private key),
/// so it pairs as a separate device.
class PosProfile {
  const PosProfile._(this.name);

  /// '' = default profile.
  final String name;

  static const defaultProfile = PosProfile._('');

  /// Letters, digits, - and _ only (it ends up in a file name); anything else → default.
  static PosProfile parse(String? raw) {
    final v = raw?.trim() ?? '';
    return RegExp(r'^[A-Za-z0-9_-]{1,20}$').hasMatch(v) ? PosProfile._(v) : defaultProfile;
  }

  bool get isDefault => name.isEmpty;

  /// SQLite file name: pos_cafe, pos_cafe_2…
  String get databaseName => isDefault ? 'pos_cafe' : 'pos_cafe_$name';

  /// Secure-storage key: device_token, profile_2.device_token…
  String secretKey(String key) => isDefault ? key : 'profile_$name.$key';
}
