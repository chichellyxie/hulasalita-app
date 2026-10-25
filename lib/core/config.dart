/// App-wide settings.
///
/// Change the server address without editing code:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
///
/// Default 10.0.2.2 = your computer, as seen from the Android emulator.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const int dailyCap = 150;
}
