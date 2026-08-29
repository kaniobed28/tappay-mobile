import 'package:dio/dio.dart';

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

/// Machine-readable error code from the backend, when it sent one alongside the message
/// (e.g. `payer_phone_required`). Null when the failure carries no code.
String? apiErrorCode(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['code'] is String) return data['code'] as String;
  }
  return null;
}

/// The payer has no usable mobile number on file, so mobile money cannot charge them.
const payerPhoneRequired = 'payer_phone_required';
