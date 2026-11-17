/// Build-time config. Override with:
///   flutter run -d windows --dart-define=API_URL=https://api.example.com
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');

  /// How often the background sync runs when the app is open.
  static const syncInterval = Duration(seconds: 15);
}
