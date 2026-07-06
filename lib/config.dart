/// App-wide configuration.
class AppConfig {
  /// Base URL of the TapPay backend API.
  ///
  /// Defaults to the deployed backend so the app works on any device out of the box.
  /// For local development override at build time, e.g.
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090/api`
  /// (10.0.2.2 = host machine from the Android emulator; the local backend
  /// listens on the port set in backend/.env — currently 8090).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tappay-api.onrender.com/api',
  );

  /// Deep-link scheme the Paystack callback redirects to.
  static const String callbackScheme = 'tappay';

  /// Socket.IO server origin (the API base without the trailing `/api`).
  static String get socketUrl {
    var base = apiBaseUrl;
    if (base.endsWith('/api')) base = base.substring(0, base.length - '/api'.length);
    return base;
  }
}
