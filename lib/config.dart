/// App-wide configuration.
class AppConfig {
  /// Base URL of the TapPay backend API.
  ///
  /// Android emulator reaches the host machine via 10.0.2.2.
  /// Override at build time: `--dart-define=API_BASE_URL=https://api.example.com/api`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
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
