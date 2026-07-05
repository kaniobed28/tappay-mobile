import 'package:dio/dio.dart';
import '../config.dart';
import '../models/models.dart';
import 'auth_service.dart';

/// Thin typed wrapper over the TapPay backend. Attaches the Firebase/dev bearer
/// token to every request via an interceptor.
class ApiClient {
  final AuthService _auth;
  late final Dio _dio;

  ApiClient(this._auth) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _auth.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // ---- Users ----
  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('/users/me');
    return res.data as Map<String, dynamic>;
  }

  // ---- Merchant ----
  Future<MerchantModel> registerMerchant(String businessName, {String? category, String? currency}) async {
    final res = await _dio.post('/merchants', data: {
      'businessName': businessName,
      'category': ?category,
      'currency': ?currency,
    });
    return MerchantModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MerchantModel?> myMerchant() async {
    try {
      final res = await _dio.get('/merchants/me');
      return MerchantModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<AnalyticsModel?> analytics() async {
    try {
      final res = await _dio.get('/merchants/me/analytics');
      return AnalyticsModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // no merchant profile yet
      rethrow;
    }
  }

  Future<void> registerDevice({required String deviceId, String? platform, String? pushToken}) async {
    await _dio.post('/users/me/devices', data: {
      'deviceId': deviceId,
      'platform': ?platform,
      'pushToken': ?pushToken,
    });
  }

  // ---- Sessions ----
  Future<SessionPayload> createSession({required int amount, String? description, String channel = 'NFC'}) async {
    final res = await _dio.post('/sessions', data: {
      'amount': amount,
      if (description != null && description.isNotEmpty) 'description': description,
      'channel': channel,
    });
    return SessionPayload.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SessionPayload> resolveSession(String id) async {
    final res = await _dio.get('/sessions/$id');
    return SessionPayload.fromJson(res.data as Map<String, dynamic>);
  }

  // ---- Payments ----
  Future<PaymentResult> pay(String sessionId) async {
    final res = await _dio.post('/payments', data: {'sessionId': sessionId});
    return PaymentResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TransactionModel> getTransaction(String id) async {
    final res = await _dio.get('/payments/$id');
    return TransactionModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Merchant refunds a payment they received (full refund when [amount] is null).
  Future<TransactionModel> refund(String id, {int? amount, String? reason}) async {
    final res = await _dio.post('/payments/$id/refund', data: {
      'amount': ?amount,
      'reason': ?reason,
    });
    return TransactionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TransactionModel>> history() async {
    final res = await _dio.get('/payments');
    return (res.data as List).map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---- Notifications ----
  Future<List<NotificationModel>> notifications() async {
    final res = await _dio.get('/notifications');
    return (res.data as List).map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }
}

/// Extracts a human-friendly message from a Dio error.
String apiErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      return m is List ? m.join(', ') : m.toString();
    }
    return e.message ?? 'Network error';
  }
  return e.toString();
}
