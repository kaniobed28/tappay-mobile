import 'package:tappay/core/network/api_client.dart';
import 'package:tappay/features/payments/data/payment_models.dart';
import 'package:tappay/features/requests/data/request_models.dart';

/// Targeted "please pay me" requests between TapPay users.
class RequestsApi {
  final ApiClient _client;
  const RequestsApi(this._client);

  /// Ask a known user (by [target] email or phone) to pay you [amount] (minor units).
  Future<PaymentRequestModel> createRequest({required String target, required int amount, String? note}) async {
    final res = await _client.dio.post('/payments/requests', data: {
      'target': target,
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return PaymentRequestModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Requests I've been asked to pay.
  Future<List<PaymentRequestModel>> incomingRequests() async {
    final res = await _client.dio.get('/payments/requests/incoming');
    return (res.data as List).map((e) => PaymentRequestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Requests I've sent out.
  Future<List<PaymentRequestModel>> outgoingRequests() async {
    final res = await _client.dio.get('/payments/requests/outgoing');
    return (res.data as List).map((e) => PaymentRequestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaymentRequestModel> declineRequest(String id) async {
    final res = await _client.dio.post('/payments/requests/$id/decline');
    return PaymentRequestModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentRequestModel> cancelRequest(String id) async {
    final res = await _client.dio.post('/payments/requests/$id/cancel');
    return PaymentRequestModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Pay a request — returns checkout info like the normal pay flow.
  Future<PaymentResult> payRequest(String id) async {
    final res = await _client.dio.post('/payments/requests/$id/pay');
    return PaymentResult.fromJson(res.data as Map<String, dynamic>);
  }
}
