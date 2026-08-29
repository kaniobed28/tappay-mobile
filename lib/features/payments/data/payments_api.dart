import 'package:tappay/core/network/api_client.dart';
import 'package:tappay/features/payments/data/payment_models.dart';

/// Settlement: starting a payment, polling it, refunding it, listing history.
class PaymentsApi {
  final ApiClient _client;
  const PaymentsApi(this._client);

  Future<PaymentResult> pay(String sessionId) async {
    final res = await _client.dio.post('/payments', data: {'sessionId': sessionId});
    return PaymentResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TransactionModel> getTransaction(String id) async {
    final res = await _client.dio.get('/payments/$id');
    return TransactionModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Merchant refunds a payment they received (full refund when [amount] is null).
  Future<TransactionModel> refund(String id, {int? amount, String? reason}) async {
    final res = await _client.dio.post('/payments/$id/refund', data: {
      'amount': ?amount,
      'reason': ?reason,
    });
    return TransactionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TransactionModel>> history() async {
    final res = await _client.dio.get('/payments');
    return (res.data as List).map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
