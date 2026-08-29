import 'package:dio/dio.dart';
import 'package:tappay/core/network/api_client.dart';
import 'package:tappay/features/merchants/data/merchant_models.dart';

/// Merchant profile and takings.
class MerchantsApi {
  final ApiClient _client;
  const MerchantsApi(this._client);

  Future<MerchantModel> registerMerchant(String businessName, {String? category, String? currency}) async {
    final res = await _client.dio.post('/merchants', data: {
      'businessName': businessName,
      'category': ?category,
      'currency': ?currency,
    });
    return MerchantModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MerchantModel?> myMerchant() async {
    try {
      final res = await _client.dio.get('/merchants/me');
      return MerchantModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<AnalyticsModel?> analytics() async {
    try {
      final res = await _client.dio.get('/merchants/me/analytics');
      return AnalyticsModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // no merchant profile yet
      rethrow;
    }
  }
}
