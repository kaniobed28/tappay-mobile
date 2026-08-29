import 'package:dio/dio.dart';
import 'package:tappay/core/config/app_config.dart';
import 'package:tappay/features/auth/data/auth_service.dart';

/// Transport for the TapPay backend: base URL, timeouts, auth header and retry policy.
///
/// It deliberately knows nothing about endpoints — each feature owns its own typed API
/// (`PaymentsApi`, `SessionsApi`, …) built on top of [dio].
class ApiClient {
  final AuthService _auth;
  late final Dio _dio;

  ApiClient(this._auth) {
    // Generous timeouts: the free-tier backend cold-starts in ~30-60s after idle,
    // and mobile-network handshakes can be slow. A short timeout here made every
    // first-open request fail with "Network error".
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 40),
      receiveTimeout: const Duration(seconds: 40),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _auth.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // Retry idempotent GETs once on connection-level failures (cold start,
        // flaky mobile network). Never retry writes — payments must not double-fire.
        final retriable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;
        if (retriable && e.requestOptions.method == 'GET' && e.requestOptions.extra['retried'] != true) {
          try {
            e.requestOptions.extra['retried'] = true;
            final res = await _dio.fetch(e.requestOptions);
            return handler.resolve(res);
          } catch (_) {/* fall through to the original error */}
        }
        handler.next(e);
      },
    ));
  }

  /// The configured transport. Feature APIs issue their requests through this.
  Dio get dio => _dio;

  /// Fire-and-forget ping that wakes a sleeping (free-tier) backend so the first
  /// real request doesn't eat the cold-start delay.
  Future<void> warmUp() async {
    try {
      await _dio.get('/health',
          options: Options(receiveTimeout: const Duration(seconds: 75), extra: {'retried': true}));
    } catch (_) {/* best effort */}
  }
}
